use src/common/modal.tcl
use src/common/model_extractor.tcl
use src/common/ddl_dialog.tcl

class IndexDialog {
	inherit Modal ModelExtractor DdlDialog

	constructor {args} {
		Modal::constructor {*}$args -resizable 1 -expandcontainer 1
	} {}

	protected {
		variable _db ""
		variable _colWidgets
		variable _colFrame ""
		variable _colFrameObj ""
		variable _availGrid ""
		variable _usedGrid ""
		variable _indexModel ""
		variable _similarModel ""
		variable _index ""
		variable _okLabel ""
		variable _tables [list]
		variable _preselectTable ""
		variable _sqliteVersion 3
		variable _modelSqliteVersion 3
		variable _tableForLabel
		variable _widget

		method getSize {}
		method parseInputModel {}
		method createSql {}
		method validateForSql {}
		method getTable {}
		method getDdlContextDb {}
		method getDatabase {}
	}

	public {
		variable checkState

		method okClicked {}
		method cancelClicked {}
		method grabWidget {}
		method updateConstrStates {}
		method refreshColumns {}
		method refreshTables {}
		method updateState {}
		method selectSameValues {}
		method addSelected {}
		method removeSelected {}
		method moveDown {}
		method moveUp {}
	}
}

body IndexDialog::constructor {args} {
	parseArgs {
		-db {set _db $value}
		-model {set _indexModel $value}
		-similarmodel {set _similarModel $value}
		-preselecttable {set _preselectTable $value}
		-index {set _index $value}
		-oklabel {set _okLabel $value}
	}

	if {$_db != "" && [$_db getHandler] == "::Sqlite3"} {
		set _sqliteVersion 3
	} else {
		set _sqliteVersion 2
	}

	if {$_index != ""} {
		if {$_db != ""} {
			if {$_indexModel == ""} {
				set _indexModel [getModel $_db $_index "index"]
			}
		} else {
			error "Given -index to IndexDialog but no -db."
		}
	}

	if {$_similarModel != "" && [$_similarModel isa Statement2CreateIndex]} {
		set _modelSqliteVersion 2
	} else {
		set _modelSqliteVersion 3
	}

	set table ""
	if {$_indexModel != ""} {
		set table [$_indexModel getValue onTable]
	} elseif {$_similarModel != ""} {
		set table [$_similarModel getValue onTable]
	}

	set _tabs [ttk::notebook $_root.tabs]
	set top [ttk::frame $_tabs.top]
	set ddl [ttk::frame $_tabs.ddl]
	$_tabs add $top -text [mc {Index}]
	$_tabs add $ddl -text DDL
	pack $_tabs -side top -fill both -padx 3 -pady 5 -expand 1

	set topFrame [ttk::frame $top.topFrame]
	pack $topFrame -side top -fill x

	set w db
	set checkState($w) ""
	ttk::frame $topFrame.$w
	ttk::frame $topFrame.$w.f
	ttk::label $topFrame.$w.f.l -text [mc {Database:}] -justify left
	set _widget(db) [ttk::combobox $topFrame.$w.e -textvariable [scope checkState]($w) -state readonly]
	pack $topFrame.$w.f -side top -fill x
	pack $topFrame.$w.f.l -side left
	pack $topFrame.$w.e -side bottom -fill x
	pack $topFrame.$w -side left -fill x
	bind $_widget(db) <<ComboboxSelected>> "$this refreshTables"

	if {$_db != ""} {
		set checkState($w) [$_db getName]
	}

	set w name
	set checkState($w) ""
	ttk::frame $topFrame.$w
	ttk::frame $topFrame.$w.f
	ttk::label $topFrame.$w.f.l -text [mc {Index name:}] -justify left
	set _widget(name) [ttk::entry $topFrame.$w.e -textvariable [scope checkState]($w)]
	pack $topFrame.$w.f -side top -fill x
	pack $topFrame.$w.f.l -side left
	pack $topFrame.$w.e -side bottom -fill x
	pack $topFrame.$w -side left -fill x -padx 1 -expand 1
	$topFrame.$w.e selection range 0 end
	$topFrame.$w.e icursor end

	set w table
	set checkState($w) $table
	set tabframe $top.db_and_table.$w
	ttk::frame $top.$w
	ttk::frame $top.$w.f
	ttk::label $top.$w.f.l -text [mc {Table:}] -justify left
	set _widget(table) [ttk::combobox $top.$w.e -width 40 -textvariable [scope checkState]($w) -state readonly]
	pack $top.$w.f -side top -fill x
	pack $top.$w.f.l -side left
	pack $top.$w.e -side bottom -fill x
	pack $top.$w -side top -fill x
	bind $top.$w.e <<ComboboxSelected>> "$this refreshColumns"

	set w uniq
	ttk::frame $top.$w
	ttk::checkbutton $top.$w.check -text [mc {Unique}] -variable [scope checkState]($w)
	pack $top.$w.check -side left
	pack $top.$w -side top -fill x -pady 10
	set checkState($w) 0

	# Columns
	set w $top.main
	ttk::panedwindow $w -orient horizontal
	pack $w -side top -fill both -expand 1

	# Available columns
	set w $top.main.avail
	ttk::frame $w
	
	set _availGrid [Grid $w.grid -basecol 0 -xscroll 0 -drawgrid 1 -rowselection 1 -selectionchanged [list $this updateState] -doubleclicked [list $this addSelected]]
	pack $_availGrid -side top -fill both -expand 1

	$_availGrid addColumn [mc {Available}]
	$_availGrid columnsEnd 1

	# Used columns
	set w $top.main.used
	ttk::frame $w

	ttk::frame $w.btns
	ttk::frame $w.btns.in
	set _widget(addSelected) [ttk::button $w.btns.in.right -image img_move_right -command "$this addSelected"]
	set _widget(removeSelected) [ttk::button $w.btns.in.left -image img_move_left -command "$this removeSelected"]
	pack $w.btns.in.right -side top -pady 10
	pack $w.btns.in.left -side top -pady 10
	pack $w.btns.in -side left
	pack $w.btns -side left -fill y

	set _usedGrid [Grid $w.grid -basecol 0 -xscroll 0 -drawgrid 1 -rowselection 1 -selectionchanged [list $this updateState] -doubleclicked [list $this removeSelected]]
	pack $_usedGrid -side left -fill both -expand 1

	$_usedGrid addColumn [mc {Indexed}]
	$_usedGrid addColumn [mc {Sort}] window
	if {$_sqliteVersion == 3} {
		$_usedGrid addColumn [mc {Collate}] window
	}
	$_usedGrid columnsEnd 1

	ttk::frame $w.order
	ttk::frame $w.order.in
	set _widget(moveUp) [ttk::button $w.order.in.up -image img_move_up -command "$this moveUp"]
	set _widget(moveDown) [ttk::button $w.order.in.down -image img_move_down -command "$this moveDown"]
	pack $w.order.in.up -side top -pady 10
	pack $w.order.in.down -side top -pady 10
	pack $w.order.in -side left
	pack $w.order -side right -fill y

	# Adding both lists
	$top.main add $top.main.avail -weight 1
	$top.main add $top.main.used -weight 2
	
	# Filling databases
	foreach db [DBTREE dblist] {
		if {![$db isOpen]} continue
		lappend dblist [$db getName]
	}
	$_widget(db) configure -values $dblist

	# Ddl tab
	set _ddlEdit [SQLEditor $ddl.editor -yscroll true]
	pack $_ddlEdit -side top -fill both -expand 1
	$_ddlEdit readonly

	# Bottom part of dialog
	ttk::frame $_root.d
	pack $_root.d -side bottom -fill x -padx 3 -pady 3

	ttk::button $_root.d.ok -text [mc {Create}] -command "$this clicked ok" -compound left -image img_ok
	pack $_root.d.ok -side left
	ttk::button $_root.d.cancel -text [mc {Cancel}] -command "$this clicked cancel" -compound left -image img_cancel
	pack $_root.d.cancel -side right

	refreshTables

	if {$_preselectTable != ""} {
		set checkState(table) "$_preselectTable"
		if {$_index == "" && $_indexModel == "" && $_similarModel == ""} {
			set checkState(name) "idx_$_preselectTable"
		}
		refreshColumns
	}

	if {$_okLabel != ""} {
		$_root.d.ok configure -text $_okLabel
	} elseif {$_indexModel != ""} {
		$_root.d.ok configure -text [mc {Change}]
	}

	parseInputModel
	updateState
	initDdlDialog
}

body IndexDialog::parseInputModel {} {
	set skipErrors 0
	if {$_indexModel != ""} {
		set model $_indexModel
	} else {
		set skipErrors 1
		set model $_similarModel
	}

	array set _tableForLabel {}
	if {$model != ""} {
		# Database and table
		set table [$model getValue onTable]
		if {$_preselectTable == ""} {
			$_widget(table) configure -values [list $table]
			set checkState(table) $table
		}
		set checkState(name) [$model getValue indexName]
		set checkState(uniq) [$model getValue isUnique]
		$_widget(table) configure -state disabled
		$_widget(db) configure -state disabled

		# Columns
		set sortedList [list]
		foreach idxCol [$model cget -indexColumns] {
			set colName [$idxCol getValue columnName]
			set collation 0
			set collationName ""
			if {$_sqliteVersion == 3 && $_modelSqliteVersion == 3} {
				set collation [$idxCol getValue collation]
				set collationName [$idxCol getValue collationName]
			}
			set order [$idxCol getValue order]
			set checkState(col_collate:$colName) ""
			set checkState(col_sort:$colName) ""
			if {$collation} {
				set checkState(col_collate:$colName) $collationName
			}
			if {$order != ""} {
				set checkState(col_sort:$colName) $order
			}
			$_availGrid hideRow $checkState(col:$colName)
			$_usedGrid showRow $checkState(used_col:$colName)
			lappend sortedList $checkState(used_col:$colName)
		}

		# Sorting columns in order like in the model
		set prevId [lindex $sortedList 0]
		$_usedGrid moveRowToBegining $prevId
		foreach rowId [lrange $sortedList 1 end] {
			$_usedGrid moveRowAfter $rowId $prevId
			set prevId $rowId
		}
	}
}

body IndexDialog::grabWidget {} {
	return $_widget(name)
}

body IndexDialog::okClicked {} {
	set top $_tabs.top
	set closeWhenOkClicked 0
	set ok 0
	set ret [createSql]
	if {$ret == -1} return

	if {$ret != ""} {
		set sqls [list]
		if {$_indexModel != ""} {
			set indexName [$_indexModel getValue indexName]
			lappend sqls "DROP INDEX [wrapObjName $indexName [$_db getDialect]]"
			set busyTitle [mc {Modifying index}]
			set busyMessage [mc {Modifying index '%s'} $indexName]
		} else {
			set busyTitle [mc {Creating index}]
			set busyMessage [mc {Creating index '%s'} $checkState(name)]
		}
		lappend sqls $ret
		set sql [join $sqls \;]
	
		set progress [BusyDialog::show $busyTitle $busyMessage false 50 false]
		BusyDialog::autoProgress 20

		if {[catch {
			set queryExecutor [QueryExecutor ::#auto $_db]
			$queryExecutor configure -execInThread true
			set execResult [$queryExecutor exec $sql]
			delete object $queryExecutor

			set ok 1
			set closeWhenOkClicked 1

			TASKBAR signal DBTree [list REFRESH DB_OBJ $_db]
		} err]} {
			set errCode [$_db errorcode]
			BusyDialog::hide
			if {$errCode == 19} { ;# constraint violated
				YesNoDialog .selectNotUnique -type warning \
					-message [mc "Unique index cannot be created,\nbecause selected columns contain duplicates.\nDo you want to see those values?"] \
					-title [mc {Unique values}]
				if {[.selectNotUnique exec]} {
					$this selectSameValues
					set closeWhenOkClicked 1
				}
			} else {
				cutOffStdTclErr err
				Error $err
			}
		} else {
			BusyDialog::hide
		}
	}

	if {$ok} {
		set tab [getTable]
		TASKBAR signal TableWin [list REFRESH $tab]
		TASKBAR signal DBTree [list REFRESH DB_OBJ $_db]
	}
}

body IndexDialog::selectSameValues {} {
	set tab [getTable]

	# Opening SQL editor
	set title [mc {Same values for '%s'} $tab]
	if {[TASKBAR taskExists $title]} {
		set task [TASKBAR getTaskByTitle $title]
		set edit [$task getWinObj]
	} else {
		set edit [MainWindow::openSqlEditor $title]
		set task [TASKBAR getTaskByTitle $title]
	}
	$edit setDatabase $_db

	# Creating SQL
	set dialect [$_db getDialect]
	set cols [list]
	set grpCols [list]
	set countCols [list]
	foreach idx [array names checkState col:*] {
		if {$checkState($idx) != "1"} continue
		set colName [string range $idx 4 end]
		lappend cols "[wrapObjName $colName $dialect]"
		lappend grpCols "[wrapObjName $colName $dialect]"
		set countName "count($colName)"
		lappend cols "count([wrapObjName $colName $dialect]) AS [wrapObjName $countName $dialect]"
		lappend countCols "count([wrapObjName $colName $dialect]) > 1"
	}

	set sqlCols [join $cols {, }]
	set sqlGrpCols [join $grpCols {, }]
	set sqlCountCols [join $countCols { AND }]
	set sqlTable [wrapObjName $tab $dialect]
	set sql "SELECT $sqlCols FROM $sqlTable GROUP BY $sqlGrpCols HAVING $sqlCountCols;\n"

	# Executing query
	$edit setSQL $sql
	$edit execQuery
	update idletasks
	$task setActive
}

body IndexDialog::validateForSql {} {
	set cols [list]
	foreach idx [array names checkState col:*] {
		if {$checkState($idx) != "1"} continue
		lappend cols ""
	}

	if {[llength $cols] == 0} {
		return [mc {You have to select at least one column.}]
	}

	set name $checkState(name)
	if {[string trim $name] == ""} {
		return [mc {You have to specify index name.}]
	}

	return ""
}

body IndexDialog::createSql {} {
	set sql "CREATE "
	if {$checkState(uniq)} {
		append sql "UNIQUE "
	}

	set cols [list]
	foreach colName [$_usedGrid getColIdxData 0] {
		set col "[wrapObjName $colName [$_db getDialect]]"
		if {$checkState(col_collate:$colName) != ""} {
			append col " COLLATE $checkState(col_collate:$colName)"
		}
		if {$checkState(col_sort:$colName) != ""} {
			append col " $checkState(col_sort:$colName)"
		}
		lappend cols $col
	}

	if {[llength $cols] == 0} {
		Error [mc {You have to select at least one column.}]
		after 10 "focus $_widget(name)"
		return -1
	}

	set name $checkState(name)
	if {[string trim $name] == ""} {
		Error [mc {You have to specify index name.}]
		return -1
	}

	set tab [getTable]
	append sql "INDEX [wrapObjName $name [$_db getDialect]] ON [wrapObjName $tab [$_db getDialect]] ([join $cols {, }])"
	return $sql
}

body IndexDialog::getTable {} {
	return $checkState(table)
}

body IndexDialog::getDatabase {} {
	return [DBTREE getDBByName $checkState(db)]
}

body IndexDialog::refreshTables {} {
	set db [getDatabase]
	if {$db == ""} return

	set _db $db
	$_ddlEdit setDB $db
	set _tables [$_db getTables]
	$_widget(table) configure -values $_tables
	refreshColumns
}

body IndexDialog::refreshColumns {} {
	set table $checkState(table)
	if {$table ni $_tables} return

	catch {array unset checkState col_enabled:*}
	catch {array unset checkState col_sort:*}
	catch {array unset checkState col_collate:*}
	catch {array unset checkState col:*}
	catch {array unset checkState backcol:*}
	catch {array unset _colWidgets}

	$_availGrid delRows
	$_usedGrid delRows

	set i 1
	foreach row [$_db getTableInfo $table] {
		# Available grid
		set rowname [stripColName [dict get $row name]]
		set rowId [$_availGrid addRow [list $rowname]]

		set checkState(col:$rowname) $rowId

		# Used grid
		set checkState(col_enabled:$rowname) $i
		ttk::combobox $_usedGrid.sort$i -values $::sortOrders -state readonly -width 5 -textvariable [scope checkState](col_sort:$rowname)
		set checkState(col_sort:$rowname) ""

		set checkState(col_collate:$rowname) ""
		set _colWidgets($rowname) [list $_usedGrid.sort$i]
		if {$_sqliteVersion == 3} {
			ttk::combobox $_usedGrid.collate$i -values $::collationTypes -state readonly -width 10 -textvariable [scope checkState](col_collate:$rowname)
			lappend _colWidgets($rowname) $_usedGrid.collate$i
			set rowId [$_usedGrid addRow [list $rowname $_usedGrid.sort$i $_usedGrid.collate$i]]
		} else {
			set rowId [$_usedGrid addRow [list $rowname $_usedGrid.sort$i]]
		}
		$_usedGrid hideRow $rowId

		set checkState(used_col:$rowname) $rowId

		incr i
	}

	updateState
}

body IndexDialog::addSelected {} {
	set rowId [$_availGrid getSelectedRow]
	if {$rowId == ""} return

	set column [lindex [$_availGrid getRowData $rowId] 1]
	if {[$_availGrid hasDownAvailable]} {
		$_availGrid goToCell next
	} elseif {[$_availGrid hasUpAvailable]} {
		$_availGrid goToCell prev
	}
	$_availGrid hideRow $rowId

	$_usedGrid moveRowToEnd $checkState(used_col:$column)
	$_usedGrid showRow $checkState(used_col:$column)

	updateState
}

body IndexDialog::removeSelected {} {
	set rowId [$_usedGrid getSelectedRow]
	if {$rowId == ""} return

	set column [lindex [$_usedGrid getRowData $rowId] 1]
	if {[$_usedGrid hasDownAvailable]} {
		$_usedGrid goToCell next
	} elseif {[$_usedGrid hasUpAvailable]} {
		$_usedGrid goToCell prev
	}
	$_usedGrid hideRow $rowId

	$_availGrid showRow $checkState(col:$column)

	updateState
}

body IndexDialog::moveUp {} {
	set rowId [$_usedGrid getSelectedRow]
	if {$rowId == ""} return

	$_usedGrid moveRowUp $rowId

	updateState
}

body IndexDialog::moveDown {} {
	set rowId [$_usedGrid getSelectedRow]
	if {$rowId == ""} return

	$_usedGrid moveRowDown $rowId

	updateState
}

body IndexDialog::updateState {} {
	set selected [$_availGrid getSelectedRow]
	set usedSelected [$_usedGrid getSelectedRow]
	foreach {var idx} {
		selected addSelected
		usedSelected removeSelected
	} {
		if {[set $var] != ""} {
			$_widget($idx) configure -state normal
		} else {
			$_widget($idx) configure -state disabled
		}
	}

	set rows [$_usedGrid count visible]
	set index [$_usedGrid getRowIndex $usedSelected]
	
	set btn1 disabled
	set btn2 disabled

	if {$usedSelected != ""} {
		if {$index > 0} {
			set btn1 normal
		}
		if {$index < $rows} {
			set btn2 normal
		}
	}

	$_widget(moveUp) configure -state $btn1
	$_widget(moveDown) configure -state $btn2
}

body IndexDialog::getSize {} {
	return [list 500 340]
}

body IndexDialog::getDdlContextDb {} {
	return $_db
}

body IndexDialog::cancelClicked {} {
	return 0
}
