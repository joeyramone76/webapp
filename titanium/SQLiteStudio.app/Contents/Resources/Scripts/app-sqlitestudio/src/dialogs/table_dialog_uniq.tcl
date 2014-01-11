use src/dialogs/table_dialog_constr.tcl

class TableDialogUniq {
	inherit TableDialogConstr

	constructor {args} {
		TableDialogConstr::constructor {*}$args -title [mc {Unique}]
	} {}
	destructor {}

	protected {
		variable _colsGrid ""
		
		method parseInputModel {}
		method storeInModel {{model ""}}
		method getSize {}
	}

	public {
		method grabWidget {}
		method updateUiState {}
		method isInvalid {}
		proc validate {model {skipWarnings false}}
	}
}

class TableDialogUniqModel {
	public {
		variable named 0
		variable name ""
		list_variable columns ;# for SQLite2 it's list of names, for SQLite3 it's list of 3-element lists: {name {collationEnabled collationName} order}
		variable conflict ""
		variable sqliteVersion 3
		
		method validate {{skipWarnings false}}
		method getLabelForDisplay {}
		method getColumnNames {}
		method delColumn {colName}
		method tableNameChanged {from to} {}
		method columnNameChanged {from to actualTableName}
	}
}

body TableDialogUniqModel::delColumn {colName} {
	set pos [lsearch -exact -index 0 $columns $colName]
	if {$pos == -1} return
	set columns [lreplace $columns $pos $pos]
}

body TableDialogUniqModel::validate {{skipWarnings false}} {
	return [TableDialogUniq::validate $this $skipWarnings]
}

body TableDialogUniqModel::getColumnNames {} {
	set colList [list]
	foreach col $columns {
		lappend colList [lindex $col 0]
	}
	return $colList
}

body TableDialogUniqModel::getLabelForDisplay {} {
	if {$sqliteVersion == 3} {
		set colList [list]
		foreach col $columns {
			lappend colList [lindex $col 0]
		}
		return [join $colList ", "]
	} else {
		return [join $columns ", "]
	}
}

body TableDialogUniqModel::columnNameChanged {from to actualTableName} {
	set idx [lsearch -index 0 -exact $columns $from]
	if {$idx == -1} return
	set col [lreplace [lindex $columns $idx] 0 0 $to]
	set columns [lreplace $columns $idx $idx $col]
}

body TableDialogUniq::constructor {args} {
	# List of indexed columns
	ttk::frame $mainFrame.cols
	set _colsGrid [Grid $mainFrame.cols.grid -basecol 0 -xscroll 0 -drawgrid 0 -takefocus 0]
	$_colsGrid addColumn [mc {Column}] window
	if {$_sqliteVersion == 3} {
		$_colsGrid addColumn [mc {Collation}] window
		$_colsGrid addColumn [mc {Sort}] window
	}
	$_colsGrid columnsEnd 1
	pack $_colsGrid -side top -fill both -expand 1
	pack $mainFrame.cols -side top -fill both -expand 1

	# Named constraint
	if {$_sqliteVersion == 3} {
		ttk::frame $mainFrame.name
		ttk::checkbutton $mainFrame.name.lab -text [mc {Named constraint:}] -variable [scope uiVar](named) -command "$this updateUiState"
		set _widget(constrName) [ttk::entry $mainFrame.name.edit -textvariable [scope uiVar](name)]
		set uiVar(named) 0
		set uiVar(name) ""
		pack $mainFrame.name.lab -side left
		pack $mainFrame.name.edit -side right -fill x -expand 1
		pack $mainFrame.name -side top -fill x -padx 3 -pady 10
	}

	# Conflict clause
	ttk::frame $mainFrame.conflict
	ttk::label $mainFrame.conflict.lab -text [mc {On conflict:}]
	set uiVar(conflict) ""
	ttk::combobox $mainFrame.conflict.combo -width 12 -values [list "" "ABORT" "FAIL" "IGNORE" "REPLACE" "ROLLBACK"] -state readonly -textvariable [scope uiVar](conflict)
	pack $mainFrame.conflict.combo -side right
	pack $mainFrame.conflict.lab -side right
	pack $mainFrame.conflict -side top -fill x -padx 3 -pady 10
}

body TableDialogUniq::destructor {} {
}

body TableDialogUniq::getSize {} {
	if {$_sqliteVersion == 3} {
		return [list 500 300]
	} else {
		return [list 360 300]
	}
}

body TableDialogUniq::grabWidget {} {
	return $_colsGrid
}

body TableDialogUniq::updateUiState {} {
	if {$_sqliteVersion == 3} {
		$_widget(constrName) configure -state [expr {$uiVar(named) ? "normal" : "disabled"}]

		set enabledCols 0
		set i 0
		foreach row [$_colsGrid getAllRows] {
			# Updating all row states
			set colName [$_colsGrid.enabled$i cget -text]

			set cells [$_colsGrid getRowDetails $row]
			lassign $cells enabledCell collationCell sortCell

			set colIdxState [expr {$uiVar(col:enabled:$colName) ? "normal" : "disabled"}]
			[lindex $collationCell 2].enabled configure -state $colIdxState

			set collationState [expr {($uiVar(col:enabled:$colName) && $uiVar(col:collation:enabled:$colName)) ? "normal" : "disabled"}]
			[lindex $collationCell 2].edit configure -state $collationState

			[lindex $sortCell 2] configure -state [expr {$uiVar(col:enabled:$colName) ? "readonly" : "disabled"}]

			# Counting enabled columns
			if {$uiVar(col:enabled:$colName)} {
				incr enabledCols
			}

			incr i
		}
	}
}

body TableDialogUniq::parseInputModel {} {
	$_colsGrid delRows
	array unset uiVar col:*

	if {$_sqliteVersion == 3} {
		set collations [$_db getCollations]
	}

	set tableUniqCols [$_model cget -columns]

	set i 0
	foreach colModel [getColumns] {
		set name [$colModel cget -name]

		# Indexed column model (if any) and getting collation and sorting from it
		set collation ""
		set sort ""
		set collationEnabled 0
		set enabled 0
		if {$_sqliteVersion == 3} {
			set indexedColumn [lsearch -inline -index 0 -exact [$_model cget -columns] $name]
			if {$indexedColumn != ""} {
				set enabled 1
				set collation [lindex $indexedColumn 1 1]
				set collationEnabled [lindex $indexedColumn 1 0]
				set sort [lindex $indexedColumn 2]
			}
		} else {
			set enabled [expr {$name in $tableUniqCols}]
		}


		# Uniq columns list
		set uiVar(col:enabled:$name) $enabled
		set uiVar(col:collation:enabled:$name) $collationEnabled
		set uiVar(col:collation:name:$name) $collation
		set uiVar(col:sort:$name) $sort

		ttk::checkbutton $_colsGrid.enabled$i -variable [scope uiVar](col:enabled:$name) -text $name -command "$this updateUiState"
		if {$_sqliteVersion == 3} {
			ttk::frame $_colsGrid.collation$i
			ttk::checkbutton $_colsGrid.collation$i.enabled -variable [scope uiVar](col:collation:enabled:$name) -command "$this updateUiState"
			ttk::combobox $_colsGrid.collation$i.edit -textvariable [scope uiVar](col:collation:name:$name) -values $collations
			ttk::combobox $_colsGrid.sort$i -values [list "" "ASC" "DESC"] -state readonly -textvariable [scope uiVar](col:sort:$name)
			pack $_colsGrid.collation$i.enabled -side left
			pack $_colsGrid.collation$i.edit -side right
			$_colsGrid addRow [list $_colsGrid.enabled$i $_colsGrid.collation$i $_colsGrid.sort$i]
		} else {
			$_colsGrid addRow [list $_colsGrid.enabled$i]
		}
		incr i
	}


	if {$_sqliteVersion == 3} {
		set uiVar(named) [$_model cget -named]
		set uiVar(name) [$_model cget -name]
	}
	set uiVar(conflict) [$_model cget -conflict]
}

body TableDialogUniq::storeInModel {{model ""}} {
	if {$model == ""} {
		set model $_model
	}

	if {$_sqliteVersion == 3} {
		$model configure -named $uiVar(named)
		$model configure -name $uiVar(name)
	}
	$model configure -conflict $uiVar(conflict)

	$model resetColumns
	if {$_sqliteVersion == 3} {
		foreach colModel [getColumns] {
			set name [$colModel cget -name]
			if {$uiVar(col:enabled:$name)} {
				$model addColumns [list $name [list $uiVar(col:collation:enabled:$name) \
					$uiVar(col:collation:name:$name)] $uiVar(col:sort:$name)]
			}
		}
	} else {
		foreach colModel [getColumns] {
			set name [$colModel cget -name]
			if {$uiVar(col:enabled:$name)} {
				$model addColumns $name
			}
		}
	}
}

body TableDialogUniq::isInvalid {} {
	set tempModel [TableDialogUniqModel ::#auto]
	storeInModel $tempModel
	set valid [validate $tempModel]
	delete object $tempModel
	return $valid
}

body TableDialogUniq::validate {model {skipWarnings false}} {
	set named [$model cget -named]
	set name [$model cget -name]
	set columns [$model cget -columns]
	set conflict [$model cget -conflict]
	set sqliteVersion [$model cget -sqliteVersion]

	if {$sqliteVersion == 3} {
		if {$named && $name == ""} {
			if {!$skipWarnings} {
				Error [mc {Constraint is marked as being named, but there's no name filled in.}]
			}
			return 1
		}

		foreach col $columns {
			lassign $col name params order
			lassign $params collationEnabled collationName
			if {$collationEnabled && $collationName == ""} {
				if {!$skipWarnings} {
					Error [mc {Collation for column '%s' is enabled, but there's no collation name filled in.} $name]
				}
				return 1
			}
		}
	}

	set uniqCols [llength $columns]
	if {$uniqCols == 0} {
		if {!$skipWarnings} {
			Error [mc {No columns are selected.}]
		}
		return 1
	}
	return 0
}
