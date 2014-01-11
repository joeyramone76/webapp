use src/dialogs/table_dialog_constr.tcl

class TableDialogFk {
	inherit TableDialogConstr

	constructor {args} {
		TableDialogConstr::constructor {*}$args -title [mc {Foreign key}]
	} {}
	destructor {}

	protected {
		variable _colsGrid ""
		variable _fkTables ""
		
		method parseInputModel {}
		method storeInModel {{model ""}}
		method getSize {}
	}

	public {
		method grabWidget {}
		method updateUiState {}
		method isInvalid {}
		method updateColumns {}
		proc validate {model {skipWarnings false}}
	}
}

class TableDialogFkModel {
	public {
		variable named 0
		variable name ""
		list_variable localColumns ;# list of names
		variable foreignTable ""
		list_variable foreignColumns ;# list of names
		variable onDelete ""
		variable onUpdate ""
		variable match ""
		variable deferrable ""
		variable initially ""
		variable sqliteVersion 3
		
		method validate {{skipWarnings false}}
		method getLabelForDisplay {}
		method delColumn {colName}
		method tableNameChanged {from to}
		method columnNameChanged {from to actualTableName}
	}
}

body TableDialogFkModel::validate {{skipWarnings false}} {
	return [TableDialogFk::validate $this $skipWarnings]
}

body TableDialogFkModel::getLabelForDisplay {} {
	set cols [join $localColumns ", "]
	return "${foreignTable}($cols)"
}

body TableDialogFkModel::delColumn {colName} {
	set pos [lsearch -exact $localColumns $colName]
	set localColumns [lreplace $localColumns $pos $pos]
}

body TableDialogFkModel::tableNameChanged {from to} {
	if {$foreignTable == $from} {
		set foreignTable $to
	}
}

body TableDialogFkModel::columnNameChanged {from to actualTableName} {
	set pos [lsearch -exact $localColumns $from]
	if {$pos > -1} {
		set localColumns [lreplace $localColumns $pos $pos $to]
	}

	if {$foreignTable == $actualTableName} {
		set pos [lsearch -exact $foreignColumns $from]
		if {$pos > -1} {
			set foreignColumns [lreplace $foreignColumns $pos $pos $to]
		}
	}
}

body TableDialogFk::constructor {args} {
	set globElementsPady 10

	# Foreign table
	set _fkTables [$_db getTables]
	foreach table $_fkTables {
		if {[string match "sqlite_*" $table]} {
			lremove _fkTables $table
		}
	}

	ttk::frame $mainFrame.fkTable
	ttk::label $mainFrame.fkTable.lab -text [mc {Foreign table:}]
	set _widget(table) [ttk::combobox $mainFrame.fkTable.edit -values $_fkTables -textvariable [scope uiVar](table) -state readonly]
	set uiVar(table) ""
	pack $mainFrame.fkTable.lab -side left
	pack $mainFrame.fkTable.edit -side right -fill x -expand 1
	pack $mainFrame.fkTable -side top -fill x -padx 3 -pady 2
	bind $_widget(table) <<ComboboxSelected>> "$this updateColumns; $this updateUiState"

	# List of columns
	ttk::frame $mainFrame.cols
	set _colsGrid [Grid $mainFrame.cols.grid -basecol 0 -xscroll 0 -drawgrid 0]
	$_colsGrid addColumn [mc {Local column}] window
	$_colsGrid addColumn [mc {Foreign column}] window
	$_colsGrid columnsEnd 1
	pack $_colsGrid -side top -fill both -expand 1
	pack $mainFrame.cols -side top -fill both -expand 1 -pady $globElementsPady

	# Actions
	ttk::labelframe $mainFrame.acts -text [mc {Reactions}]
	set reactions [list "NO ACTION" "SET NULL" "SET DEFAULT" "CASCADE" "RESTRICT"]

	set w $mainFrame.acts.onUpdate
	ttk::frame $w
	set uiVar(onUpdateEnabled) 0
	set _widget(onUpdate:check) [ttk::checkbutton $w.enabled -text [mc {ON UPDATE}] -variable [scope uiVar](onUpdateEnabled) -command "$this updateUiState"]
	set uiVar(onUpdate) "NO ACTION"
	set _widget(onUpdate) [ttk::combobox $w.reaction -values $reactions -textvariable [scope uiVar](onUpdate) -state readonly -width 12]
	pack $w.enabled -side left
	pack $w.reaction -side right
	pack $w -side top -fill x -padx 3 -pady 2

	set w $mainFrame.acts.onDelete
	ttk::frame $w
	set uiVar(onDeleteEnabled) 0
	set _widget(onDelete:check) [ttk::checkbutton $w.enabled -text [mc {ON DELETE}] -variable [scope uiVar](onDeleteEnabled) -command "$this updateUiState"]
	set uiVar(onDelete) "NO ACTION"
	set _widget(onDelete) [ttk::combobox $w.reaction -values $reactions -textvariable [scope uiVar](onDelete) -state readonly -width 12]
	pack $w.enabled -side left
	pack $w.reaction -side right
	pack $w -side top -fill x -padx 3 -pady 2

	set w $mainFrame.acts.match
	ttk::frame $w
	set uiVar(matchEnabled) 0
	set _widget(match:check) [ttk::checkbutton $w.enabled -text [mc {MATCH}] -variable [scope uiVar](matchEnabled) -command "$this updateUiState"]
	set uiVar(match) ""
	set reactions [list "NONE" "PARTIAL" "FULL"]
	set uiVar(match) "NONE"
	set _widget(match) [ttk::combobox $w.reaction -values $reactions -textvariable [scope uiVar](match) -state readonly -width 12]
	pack $w.enabled -side left
	pack $w.reaction -side right
	pack $w -side top -fill x -padx 3 -pady 2

	pack $mainFrame.acts -side top -fill x -pady $globElementsPady

	# Deferred
	ttk::labelframe $mainFrame.def -text [mc {Deferred foreign key}]

	set w $mainFrame.def.deferred
	set uiVar(deferred) [lindex $::deferredValues 0]
	ttk::frame $w
	set _widget(deferred) [ttk::combobox $w.list -values $::deferredValues -textvariable [scope uiVar](deferred) -state readonly -width 20]
	bind $_widget(deferred) <<ComboboxSelected>> "$this updateUiState"
	pack $w.list -side left
	pack $w -side left -fill x -padx 3 -pady 2

	set w $mainFrame.def.initially
	set uiVar(deferredInitially) [lindex $::deferredInitiallyValues 0]
	ttk::frame $w
	set _widget(deferredInitially) [ttk::combobox $w.list -values $::deferredInitiallyValues -textvariable [scope uiVar](deferredInitially) -state readonly -width 20]
	bind $_widget(deferredInitially) <<ComboboxSelected>> "$this updateUiState"
	pack $w.list -side left
	pack $w -side right -fill x -padx 3 -pady 2

	pack $mainFrame.def -side top -fill both -padx 2 -pady $globElementsPady

	# Named constraint
	if {$_sqliteVersion == 3} {
		ttk::frame $mainFrame.name
		ttk::checkbutton $mainFrame.name.lab -text [mc {Named constraint:}] -variable [scope uiVar](named) -command "$this updateUiState"
		set _widget(constrName) [ttk::entry $mainFrame.name.edit -textvariable [scope uiVar](name)]
		set uiVar(named) 0
		set uiVar(name) ""
		pack $mainFrame.name.lab -side left
		pack $mainFrame.name.edit -side right -fill x -expand 1
		pack $mainFrame.name -side top -fill x -padx 3 -pady $globElementsPady
	}
}

body TableDialogFk::destructor {} {
}

body TableDialogFk::getSize {} {
	return [list 400 500]
}

body TableDialogFk::grabWidget {} {
	return $_colsGrid
}

body TableDialogFk::updateUiState {} {
	set fkTableSelected [expr {$uiVar(table) != ""}]
	set fkTableSelectedState [expr {$fkTableSelected ? "normal" : "disabled"}]

	if {$_sqliteVersion == 3} {
		$_widget(constrName) configure -state [expr {$uiVar(named) ? "normal" : "disabled"}]
	}

	$_widget(onDelete:check) configure -state $fkTableSelectedState
	$_widget(onUpdate:check) configure -state $fkTableSelectedState
	$_widget(match:check) configure -state $fkTableSelectedState

	$_widget(onDelete) configure -state [expr {$fkTableSelected && $uiVar(onDeleteEnabled) ? "readonly" : "disabled"}]
	$_widget(onUpdate) configure -state [expr {$fkTableSelected && $uiVar(onUpdateEnabled) ? "readonly" : "disabled"}]
	$_widget(match) configure -state [expr {$fkTableSelected && $uiVar(matchEnabled) ? "readonly" : "disabled"}]

	if {$uiVar(deferred) == ""} {
		set uiVar(deferredInitially) ""
	}
	$_widget(deferred) configure -state [expr {$fkTableSelected ? "readonly" : "disabled"}]
	$_widget(deferredInitially) configure -state [expr {$fkTableSelected && $uiVar(deferred) != "" ? "readonly" : "disabled"}]

	foreach colModel [getColumns] {
		set name [$colModel cget -name]
		set state [expr {($fkTableSelected && $uiVar(col:enabled:$name)) ? "readonly" : "disabled"}]
		$_widget(col:foreign:check:$name) configure -state $fkTableSelectedState
		$_widget(col:foreign:$name) configure -state $state
	}
}

body TableDialogFk::parseInputModel {} {
	set originalTable [$_tableDialog getOriginalTableName]
	set actualTable [$_tableDialog getTableName]
	set fkTables $_fkTables
	if {$originalTable != $actualTable} {
		set fkTables [lmap [list $originalTable $actualTable] $fkTables]
	}
	$_widget(table) configure -values $fkTables

	$_colsGrid delRows
	array unset uiVar col:*

	array set fkCols {}
	foreach localCol [$_model cget -localColumns] foreignCol [$_model cget -foreignColumns] {
		set fkCols($localCol) $foreignCol
	}

	set uiVar(table) [$_model cget -foreignTable]
	if {[$_tableDialog getTableName] == [$_widget(table) get]} {
		set fkColumns [list]
		foreach col [$_tableDialog getColumns] {
			lappend fkColumns [$col cget -name]
		}
	} else {
		set fkColumns [$_db getColumns $uiVar(table)]
	}

	set i 0
	foreach colModel [getColumns] {
		set name [$colModel cget -name]

		# Fk columns list
		set enabled [info exists fkCols($name)]
		set uiVar(col:enabled:$name) $enabled
		set uiVar(col:foreign:$name) [expr {$enabled ? $fkCols($name) : ""}]

		set _widget(col:foreign:check:$name) [ttk::checkbutton $_colsGrid.enabled$i -variable [scope uiVar](col:enabled:$name) -text $name -command "$this updateUiState"]
		set _widget(col:foreign:$name) [ttk::combobox $_colsGrid.foreign$i -values $fkColumns -state disabled -textvariable [scope uiVar](col:foreign:$name)]
		$_colsGrid addRow [list $_colsGrid.enabled$i $_colsGrid.foreign$i]
		incr i
	}

	set uiVar(named) [$_model cget -named]
	set uiVar(name) [$_model cget -name]
	set uiVar(onUpdate) [$_model cget -onUpdate]
	set uiVar(onUpdateEnabled) [expr {$uiVar(onUpdate) != ""}]
	set uiVar(onDelete) [$_model cget -onDelete]
	set uiVar(onDeleteEnabled) [expr {$uiVar(onDelete) != ""}]
	set uiVar(match) [$_model cget -match]
	set uiVar(matchEnabled) [expr {$uiVar(match) != ""}]
	set uiVar(deferred) [$_model cget -deferrable]
	set uiVar(deferredInitially) [$_model cget -initially]
}

body TableDialogFk::updateColumns {} {
	if {[$_tableDialog getTableName] == [$_widget(table) get]} {
		set columns [list]
		foreach col [$_tableDialog getColumns] {
			lappend columns [$col cget -name]
		}
	} else {
		set columns [$_db getColumns $uiVar(table)]
	}

	foreach row [$_colsGrid getAllRows] {
		set cells [$_colsGrid getRowDetails $row]
		lassign $cells localColCell fkColCell

		set colName [[lindex $localColCell 2] cget -text]
		set combo [lindex $fkColCell 2]
		set oldValue [$combo get]
		$combo configure -values $columns
		if {$oldValue in $columns} {
			$combo set $oldValue
		}
		set uiVar(col:foreign:$colName) ""
	}
}

body TableDialogFk::storeInModel {{model ""}} {
	if {$model == ""} {
		set model $_model
	}

	$model resetLocalColumns
	$model resetForeignColumns
	foreach colModel [getColumns] {
		set name [$colModel cget -name]
		if {$uiVar(col:enabled:$name)} {
			$model addLocalColumns $name
			$model addForeignColumns $uiVar(col:foreign:$name)
		}
	}

	$model configure -named $uiVar(named)
	$model configure -name $uiVar(name)
	$model configure -foreignTable $uiVar(table)
	$model configure -onUpdate $uiVar(onUpdate)
	$model configure -onDelete $uiVar(onDelete)
	$model configure -match $uiVar(match)
	$model configure -deferrable $uiVar(deferred)
	$model configure -initially $uiVar(deferredInitially)
}

body TableDialogFk::isInvalid {} {
	set tempModel [TableDialogFkModel ::#auto]
	storeInModel $tempModel
	set valid [validate $tempModel]
	delete object $tempModel
	return $valid
}

body TableDialogFk::validate {model {skipWarnings false}} {
	set named [$model cget -named]
	set name [$model cget -name]
	set localColumns [$model cget -localColumns]
	set foreignColumns [$model cget -foreignColumns]
	set foreignTable [$model cget -foreignTable]

	if {$foreignTable == ""} {
		if {!$skipWarnings} {
			Error [mc {No foreign table selected.}]
		}
		return 1
	}
	if {$named && $name == ""} {
		if {!$skipWarnings} {
			Error [mc {Constraint is marked as being named, but there's no name filled in.}]
		}
		return 1
	}
	foreach name $localColumns fkName $foreignColumns {
		if {$fkName == ""} {
			if {!$skipWarnings} {
				Error [mc {There's no foreign column assigned for local column '%s'.} $name]
			}
			return 1
		}
	}
	set cols [llength $localColumns]
	if {$cols == 0} {
		if {!$skipWarnings} {
			Error [mc {No columns are selected.}]
		}
		return 1
	}
	return 0
}
