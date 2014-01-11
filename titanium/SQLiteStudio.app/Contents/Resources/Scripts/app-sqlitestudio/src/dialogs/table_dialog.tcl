use src/common/modal.tcl
use src/common/ui_state_handler.tcl
use src/common/model_extractor.tcl
use src/common/ddl_dialog.tcl

class TableDialog {
	inherit Modal UiStateHandler ModelExtractor DdlDialog

	constructor {args} {
		Modal::constructor {*}$args -resizable 1 -expandcontainer 1
	} {}
	destructor {}

	protected {
		variable _labelToType
		variable _typeToLabel
		variable _modelClassToType
		variable _typeToModelClass
		variable _dialogClassToType
		variable _typeToDialogClass
		variable _sortedLabels ""

		variable _db ""
		variable _colGrid ""
		variable _widget
		variable _tableModel ""
		variable _table ""
		variable _tableGiven 0
		variable _similar false
		variable _makeCopy false
		variable _copyName ""
		variable _columnToEdit ""
		variable _editColumn false
		variable _sqliteVersion 3
		variable _modelSqliteVersion 3
		variable _pkConfig ""
		variable _uniqConfig ""
		variable _fkConfig ""
		variable _chkConfig ""
		variable _dragColumnObj ""
		variable _constrGrid ""
		variable _lastTableName ""
		variable _tableConstrModels [dict create]
		variable _tableConstrSeq -1
		variable _tableConstrWidgets [dict create]

		list_variable _columns

		method createDatabaseAndTable {}
		method createColumns {}
		method createTableConstraints {}
		method getSelectedColumnModel {}
		method getColumnModelByName {colName}
		method getColumnModelByXY {x y}

		method parseInputModel {}
		method createSql {}
		method createColumnSql {colModel}
		method createGlobalConstrSqls {}
		method createPkSql {model}
		method createFkSql {model}
		method createUniqSql {model}
		method createChkSql {model}
		method createTransferSql {fromTable toTable}
		method renameSqlite2Table {from to}
		method collectTriggersForTable {oldTable newTable}
		method collectIndexesForTable {oldTable newTable}
		method collectViewsForTable {oldTable newTable}
		method generateBackupTableName {oldTableName newTableName}
		method renameTable {oldTableName backupTable}
		method handleFks {oldTableName}
		method handleFkAction {action model oldTableName}
		method handleFkActionMatched {action fullToken tokensToRemove}
		method validateForSql {}
		method getDdlContextDb {}
		method getTableConstrType {idx}
		method addTableConstraintFromModel {model}
		method addTableConstraintInternal {}
		method alterTable {oldTableName newTableName newDdl}
		method refreshTableConstrValues {{idx ""}}
		method columnNameChanged {from to}
		method columnDeleted {name}
		method tableNameChanged {from to}
		method isGlobalPk {colName}
		method isGlobalFk {colName}
		method isGlobalUniq {colName}
		method initMaps {}
	}

	public {
		variable uiVar

		method okClicked {}
		method cancelClicked {}
		method grabWidget {}
		method refreshGrab {{w ""}}
		method addColumn {}
		method editColumn {{columnName ""} {byName false}}
		method delColumn {}
		method getColumnList {}
		method updateUiState {}
		method refreshColumns {{selectedModel ""}}
		method getTableName {}
		method getOriginalTableName {}
		method getColumns {}
		method validate {}
		method updateDatabase {}
		method columnExists {name}
		method columnDrag {}
		method columnDrop {x y}
		method columnEnterLeaveHint {enterOrLeave col}
		method addTableConstraint {}
		method delTableConstraint {}
		method updateTableConstrState {}
		method tableConstrTypeChanged {idx}
		method tableConstrTypeChangedWithCheck {idx}
		method configConstr {idx}
		method tableNameChangedHandler {args}
	}
}

body TableDialog::constructor {args} {
	parseArgs {
		-db {set _db $value}
		-model {set _tableModel $value}
		-table {
			set _table $value
			set _tableGiven 1
		}
		-similar {set _similar $value}
		-copyname {set _copyName $value}
		-makecopy {set _makeCopy $value}
		-editcolumn {
			set _columnToEdit $value
			set _editColumn true
		}
	}

	initMaps

	if {$_db != "" && [$_db getHandler] == "::Sqlite3"} {
		set _sqliteVersion 3
	} else {
		set _sqliteVersion 2
	}

	if {$_tableGiven} {
		if {$_db != ""} {
			if {$_tableModel == ""} {
				set _tableModel [getModel $_db $_table "table"]
			}
		} else {
			error "Given -table to TableDialog but no -db."
		}
	}

	if {$_tableModel != "" && [$_tableModel isa Statement2CreateIndex]} {
		set _modelSqliteVersion 2
	} else {
		set _modelSqliteVersion 3
	}

	#
	# Main part
	#
	set _tabs [ttk::notebook $_root.tabs]
	set top [ttk::frame $_tabs.top]
	set ddl [ttk::frame $_tabs.ddl]
	$_tabs add $top -text [mc {Table}]
	$_tabs add $ddl -text DDL
	pack $_tabs -side top -fill both -padx 3 -pady 5 -expand 1

	ttk::labelframe $top.table -text [mc {Table:}]
	ttk::labelframe $top.columns -text [mc {Columns:}]
	ttk::labelframe $top.const -text [mc {Table constraints:}]

	pack $top.table -side top -fill both -pady 3
	pack $top.columns -side top -fill both -pady 3 -ipady 5 -ipadx 5 -expand 1
	pack $top.const -side top -fill both -pady 3

	# Essential contents of dialog
	createDatabaseAndTable
	createColumns
	createTableConstraints

	# Ddl tab
	set _ddlEdit [SQLEditor $ddl.editor -yscroll true]
	pack $_ddlEdit -side top -fill both -expand 1
	$_ddlEdit readonly

	#
	# Bottom buttons
	#
	set bottom [ttk::frame $_root.bottom]

	# Ok button
	ttk::button $bottom.ok -text [mc {Create}] -command "$this clicked ok" -compound left -image img_ok
	pack $bottom.ok -side left

	# Cancel button
	ttk::button $bottom.cancel -text [mc {Cancel}] -command "$this clicked cancel" -compound left -image img_cancel
	pack $bottom.cancel -side right

	pack $_root.bottom -side bottom -fill x -padx 3 -pady 3

	# Parse input table model
	if {$_tableModel != ""} {
		parseInputModel
		if {$_makeCopy} {
			set uiVar(tableName) $_copyName
			$_widget(dblist) configure -state disabled
		} elseif {$_similar} {
			set _tableModel ""
			set uiVar(tableName) ""
		} else {
			$_widget(dblist) configure -state disabled
			set uiVar(tableName) $_table
			$bottom.ok configure -text [mc {Change}]
		}
	}

	if {$_editColumn} {
		set _initScript [list $this editColumn $_columnToEdit true]
	}

	# Binds
	set tree [$_colGrid getWidget]
	bind $tree <Insert> "$this addColumn; break"
	bind $tree <space> "$this editColumn; break"
	bind $tree <Delete> "$this delColumn; break"

	# Update ui
	updateUiState
	initDdlDialog

	# Auto tracing self-FK names
	trace add variable [scope uiVar](tableName) write [list $this tableNameChangedHandler]
	set _lastTableName $uiVar(tableName)


	after idle [list $_widget(name) icursor end]
}

body TableDialog::destructor {} {
	delete object {*}[dict values $_tableConstrModels]
}

body TableDialog::initMaps {} {
	array set _modelClassToType {
		"::TableDialogPkModel" "pk"
		"::TableDialogFkModel" "fk"
		"::TableDialogUniqModel" "uniq"
		"::TableDialogChkModel" "chk"
	}
	array set _labelToType [list \
			[mc {Primary key}] "pk" \
			[mc {Foreign key}] "fk" \
			[mc {Unique}] "uniq" \
			[mc {Check condition}] "chk" \
		]
	set _sortedLabels [list \
			[mc {Primary key}] \
			[mc {Foreign key}] \
			[mc {Unique}] \
			[mc {Check condition}] \
		]
	array set _dialogClassToType {
		"::TableDialogPk" "pk"
		"::TableDialogFk" "fk"
		"::TableDialogUniq" "uniq"
		"::TableDialogChk" "chk"
	}

	# Reverse maps
	reverseArray _modelClassToType _typeToModelClass
	reverseArray _labelToType _typeToLabel
	reverseArray _dialogClassToType _typeToDialogClass
}

body TableDialog::createDatabaseAndTable {} {
	upvar top top

	set dbframe [ttk::frame $top.table.db]
	ttk::label $dbframe.label -text [mc {Database:}] -justify left
	set _widget(dblist) [ttk::combobox $dbframe.list -textvariable [scope uiVar](databaseName)]
	pack $dbframe.label -side top -fill x
	pack $dbframe.list -side bottom -fill x
	pack $dbframe -side left -padx 3 -pady 2
	bind $_widget(dblist) <<ComboboxSelected>> "$this updateDatabase"

	set uiVar(tableName) ""
	set tableframe [ttk::frame $top.table.table]
	ttk::label $tableframe.label -text [mc {Table name:}]
	set _widget(name) [ttk::entry $tableframe.list -textvariable [scope uiVar](tableName)]
	pack $tableframe.label -side top -fill x
	pack $tableframe.list -side bottom -fill x -expand 1
	pack $tableframe -side right -fill x -padx 3 -pady 2 -expand 1

	# Filling available databases list
	foreach db [DBTREE dblist] {
		if {![$db isOpen]} continue

		if {[$db getHandler] == "::Sqlite3"} {
			set version 3
		} else {
			set version 2
		}
		if {$version != $_sqliteVersion} continue

		lappend _dbList [$db getName]
	}
	$dbframe.list configure -values $_dbList -state readonly
	$dbframe.list set [$_db getName]
}

body TableDialog::createColumns {} {
	upvar top top

	if {[os] == "win32"} {
		# Because of the reason unknown to me if column edition dialog is being
		# open without this delay under Windows, then it instantly looses focus,
		# even it's a modal dialog... This happens only when editing by doubleClick.
		# It might have something to do with TkTreeCtrl and it's double click handling,
		# but I'm not sure and it's hard to debug.
		# Therefore this nasty hack stays here for now.
		set dblClickCmd [list after 100 [list $this editColumn]]
	} else {
		set dblClickCmd [list $this editColumn]
	}
	
	set _colGrid [Grid $top.columns.grid -xscroll false -basecol true -selectionchanged "$this updateUiState" -rowselection 1 \
		-doubleclicked $dblClickCmd -enablednd true -dragcmd "$this columnDrag" -dropcmd "$this columnDrop" \
		-columnentercmd "$this columnEnterLeaveHint enter" -columnleavecmd "$this columnEnterLeaveHint leave" -readonly 1]
		
	$_colGrid setSize 400 150
	pack $top.columns.grid -side left -fill both -expand 1 -padx 3 -pady 2
	$_colGrid addColumn [mc {Name}]
	$_colGrid addColumn [mc {Data type}]
	$_colGrid addColumn "P" image ;# PK
	if {$_sqliteVersion == 3} {
		$_colGrid addColumn "F" image ;# FK
	}
	$_colGrid addColumn "U" image ;# UNIQ
	$_colGrid addColumn "H" image ;# CHK
	$_colGrid addColumn "N" image ;# NOTNULL
	if {$_sqliteVersion == 3} {
		$_colGrid addColumn "C" image ;# COLLATE
	}
	$_colGrid addColumn "D" image ;# DEFAULT
	$_colGrid columnConfig 1 -width 150 -maxwidth 150

	if {$_sqliteVersion == 3} {
		set columns {3 4 5 6 7 8 9}
	} else {
		set columns {3 4 5 6 7}
	}

	foreach i $columns {
		$_colGrid columnConfig $i -width 22
	}
	$_colGrid columnsEnd 2

	bind $_widget(name) <Tab> "$_colGrid selectByIdx 0 0"

	set btns [ttk::frame $top.columns.buttons]
	pack $top.columns.buttons -side right -padx 4

	set _widget(addColumn) [ttk::button $btns.new -text [mc {Add column}] -command "$this addColumn" -compound left -image img_grid_insert_column]
	set _widget(editColumn) [ttk::button $btns.edit -text [mc {Edit selected}] -command "$this editColumn" -compound left -image img_grid_edit_column -state disabled]
	set _widget(delColumn) [ttk::button $btns.delete -text [mc {Delete selected}] -command "$this delColumn" -compound left -image img_grid_delete_column -state disabled]

	pack $btns.new $btns.edit $btns.delete -side top -fill x -pady 2
}

body TableDialog::createTableConstraints {} {
	upvar top top

	set inFrame [ttk::frame $top.const.inner_frame]

	set _constrGrid [RichGrid $inFrame.tableConstrGrid -xscroll false -basecol true -drawgrid true \
		-rowselection true -showheader true -selectionchanged "$this updateTableConstrState"]
	$_constrGrid setSize 200 100
	$_constrGrid addColumn [mc {Type}] window
	$_constrGrid addColumn [mc {Details}] text
	$_constrGrid addColumn [mc {Configure}] window
	$_constrGrid columnConfig 1 -width 150 -maxwidth 150
	$_constrGrid columnsEnd 2
	pack $_constrGrid -fill x -side left -expand 1
	
	ttk::frame $inFrame.btns
	set _widget(addTableConstr) [ttk::button $inFrame.btns.add -image img_add -command [list $this addTableConstraint]]
	set _widget(delTableConstr) [ttk::button $inFrame.btns.del -image img_delete2 -command [list $this delTableConstraint]]
	pack $inFrame.btns.add $inFrame.btns.del -side top -pady 2
	pack $inFrame.btns -side right -padx 5
	updateTableConstrState
	
	pack $inFrame -fill x -pady 5
}

body TableDialog::columnEnterLeaveHint {enterOrLeave col} {
	if {$enterOrLeave == "enter"} {
		set cmd helpHint_onEnter
	} else {
		set cmd helpHint_onLeave
	}
	switch -- $col {
		3 {
			$cmd $_colGrid [mc {Primary key}]
		}
		4 {
			$cmd $_colGrid [mc {Foreign key}]
		}
		5 {
			$cmd $_colGrid [mc {Unique}]
		}
		6 {
			$cmd $_colGrid [mc {Check condition}]
		}
		7 {
			$cmd $_colGrid [mc {Not NULL}]
		}
		8 {
			$cmd $_colGrid [mc {Collate}]
		}
		9 {
			$cmd $_colGrid [mc {Default value}]
		}
	}
}

body TableDialog::grabWidget {} {
	return $_widget(name)
}

body TableDialog::columnDrag {} {
	set _dragColumnObj [getSelectedColumnModel]
}

body TableDialog::columnDrop {x y} {
	# Identifying drop area
	set targetColumn [getColumnModelByXY $x $y]

	if {$targetColumn == ""} {
		set targetColumn [lindex $_columns end]
	}

	if {$targetColumn == ""} {
		# Seems like no columns in grid, even we just dragged one.
		# It's best to drop this method at this moment.
		return
	}

	if {[string equal $targetColumn $_dragColumnObj]} {
		# We don't need to d&d from src to trg
		return
	}

	lassign [Dnd::getDndData] type data
	if {[string trimleft $type :] != [string trimleft $_colGrid :]} return

	# If moving from top to bottom, then we need to increase index to insert row after target, not before.
	set srcIdx [lsearch -exact $_columns $_dragColumnObj]
	set trgIdx [lsearch -exact $_columns $targetColumn]
	set modifier 0
	if {$srcIdx < $trgIdx} {
		set modifier 1
	}

	# Removing moved column from old position
	lremove _columns $_dragColumnObj

	# Inserting moved column to new position
	set idx [lsearch -exact $_columns $targetColumn]
	incr idx $modifier
	set _columns [linsert $_columns $idx $_dragColumnObj]

	# Clearing drag cache
	set _dragColumnObj ""

	# Refreshing view
	refreshColumns
}

body TableDialog::addColumn {} {
	catch {destroy .columnDialog}
	ColumnDialog .columnDialog -title [mc {Add column}] -parent $path -db $_db -tabledialog $this -skipmacbottomframe 1
	set newColumnModel [.columnDialog exec]
	if {$newColumnModel == ""} return
	lappend _columns $newColumnModel
	refreshColumns
}

body TableDialog::editColumn {{columnName ""} {byName false}} {
	# Getting current column model
	if {$byName} {
		if {[catch {
			set columnModel [getColumnModelByName $columnName]
		}]} {
			# Column is no longer in table (while clicked on it in TableWin)
			Warning [mc {Column '%s' is no longer in table '%s', so you cannot edit it. Table was probably modified by other application.} $columnName $_table]
			return
		}
	} else {
		set columnModel [getSelectedColumnModel]
	}
	if {$columnModel == ""} {
		# No selected row? It should be impossible to call this method.
# 		error "No selected row while call to TableDialog::editColumn! Please report this."
		return
	}

	set oldName [$columnModel cget -name]

	catch {destroy .columnDialog}
	ColumnDialog .columnDialog -title [mc {Edit column}] -parent $path -model $columnModel -db $_db -tabledialog $this -skipmacbottomframe 1
	set columnModel [.columnDialog exec]
	if {$columnModel == ""} return
	#$_tableModel replaceColumns $modelIndex $columnModel
	columnNameChanged $oldName [$columnModel cget -name]
}

body TableDialog::delColumn {} {
	# Getting current column model
	set columnModel [getSelectedColumnModel]
	if {$columnModel == ""} {
		# No selected row? It should be impossible to call this method.
# 		error "No selected row while call to TableDialog::delColumn! Please report this."
		return
	}

	set delColName [$columnModel cget -name]
	set yesno [YesNoDialog .delColumn -title [mc {Delete column}] -message [mc {Are you sure you want to delete column '%s'?} $delColName]]
	if {![$yesno exec]} return

	if {![$_colGrid goToCell next]} {
		$_colGrid goToCell prev
	}

	# Delete column
	lremove _columns $columnModel
	delete object $columnModel

	# Refreshing columns for constraints
	columnDeleted $delColName
}

body TableDialog::getColumnModelByName {colName} {
	set idx 0
	set found false
	foreach row [$_colGrid get] {
		if {[string equal [lindex $row 0] $colName]} {
			set found true
			break
		}
		incr idx
	}
	if {!$found} {
		error "No such column '$colName' while getting it's model for edition."
	}
	set rows [$_colGrid getAllRows]
	return [$_colGrid getRowTags [lindex $rows $idx]]
}

body TableDialog::getSelectedColumnModel {} {
	set selRow [$_colGrid getSelectedRow]
	if {$selRow == ""} {
		return ""
	}

	return [$_colGrid getRowTags [lindex $selRow 0]]
}

body TableDialog::getColumnModelByXY {x y} {
	set row [$_colGrid identify $x $y]
	if {[llength $row] == 0} {
		return ""
	}

	return [$_colGrid getRowTags [lindex $row 0]]
}

body TableDialog::updateUiState {} {
	# Edit/Del buttons
	if {[$_colGrid getSelectedRow] != "" && $_db != ""} {
		$_widget(editColumn) configure -state normal
		$_widget(delColumn) configure -state normal
	} else {
		$_widget(editColumn) configure -state disabled
		$_widget(delColumn) configure -state disabled
	}
}

body TableDialog::refreshColumns {{selectedModel ""}} {
	# Cleaning array for columns
	$_colGrid delRows
	set firstCol [lindex [$_colGrid getColumns] 0 0]

	# Re-adding columns
	foreach colModel $_columns {
		# Determinating column description
		set name [$colModel cget -name]
		set datatype [$colModel cget -type]
		if {[$colModel cget -size] != "" || [$colModel cget -precision] != ""} {
			set sizes [list]
			if {[$colModel cget -size] != ""} {
				lappend sizes [$colModel cget -size]
			}
			if {[$colModel cget -precision] != ""} {
				lappend sizes [$colModel cget -precision]
			}
			append datatype " ([join $sizes {, }])"
		}

		foreach imgVar {pk fk uniq check notnull collate default} \
				globConstrMethod {"isGlobalPk" "isGlobalFk" "isGlobalUniq" "" "" "" ""} \
				fieldName {columns localColumns columns "" "" "" ""} \
				image {img_primary_key img_fk_col img_constr_uniq img_constr_check
					img_constr_notnull img_constr_collate img_constr_default} {
			######################################################################
			if {$_sqliteVersion == 2 && $imgVar in [list "fk" "collate"]} continue
			set $imgVar ""
			if {[$colModel cget -$imgVar] || $globConstrMethod != "" && [$globConstrMethod $name]} {
				set $imgVar $image
			}
		}

		if {$_sqliteVersion == 3} {
			set rowId [$_colGrid addRow [list $name $datatype $pk $fk $uniq $check $notnull $collate $default]]
		} else {
			set rowId [$_colGrid addRow [list $name $datatype $pk $uniq $check $notnull $default]]
		}
		$_colGrid setRowTags $rowId $colModel

		if {$selectedModel != "" && $colModel == $selectedModel} {
			$_colGrid select $rowId $firstCol
		}
	}
	updateUiState
}

body TableDialog::updateDatabase {} {
	set _db [DBTREE getDBByName $uiVar(databaseName)]
	if {[$_db getHandler] == "::Sqlite3"} {
		set _sqliteVersion 3
	} else {
		set _sqliteVersion 2
	}

	updateUiState
}

body TableDialog::addTableConstraintFromModel {model} {
	set i [addTableConstraintInternal]
	dict set _tableConstrModels $i $model
	refreshTableConstrValues $i
}

body TableDialog::addTableConstraint {} {
	set i [addTableConstraintInternal]
	tableConstrTypeChanged $i
}

body TableDialog::delTableConstraint {} {
	set it [$_constrGrid getSelectedRow]
	if {$it == ""} return

	if {![$_constrGrid goToCell next]} {
		$_constrGrid goToCell prev
	}

	set i [$_constrGrid getRowTags $it]
	$_constrGrid delRow $it
	destroy {*}[dict get $_tableConstrWidgets $i]
	delete object [dict get $_tableConstrModels $i]
	dict unset _tableConstrWidgets $i
	dict unset _tableConstrModels $i

	updateTableConstrState
	refreshColumns
}

body TableDialog::getTableConstrType {idx} {
	set w [$_constrGrid getWidget]
	return $_labelToType([$w.type_$idx get])
}

body TableDialog::tableConstrTypeChangedWithCheck {idx} {
	set model [dict get $_tableConstrModels $idx]
	if {![$model validate true]} {
		set dialog [YesNoDialog .yesno -title [mc {Constraint change}] -message [mc "Are you sure you want to change constraint type?\nCurrent constraint configuration will be lost."]]
		if {![$dialog exec]} {
			refreshTableConstrValues $idx
			return
		}
	}
	tableConstrTypeChanged $idx
}

body TableDialog::tableConstrTypeChanged {idx} {
	set newType [getTableConstrType $idx]
	if {[dict exists $_tableConstrModels $idx]} {
		set oldModel [dict get $_tableConstrModels $idx]
		set oldType $_modelClassToType([$oldModel info class])
		if {$oldType == $newType} {
			return
		}

		delete object $oldModel
		dict unset _tableConstrModels $idx
	}

	dict set _tableConstrModels $idx [$_typeToModelClass($newType) ::#auto]

	refreshColumns
	refreshTableConstrValues $idx
}

body TableDialog::refreshTableConstrValues {{idx ""}} {
	if {$idx != ""} {
		set idxList [list $idx]
	} else {
		set idxList [dict keys $_tableConstrModels]
	}

	foreach idx $idxList {
		set model [dict get $_tableConstrModels $idx]
		set widgets [dict get $_tableConstrWidgets $idx]
		lassign $widgets comboType configBtn
		set it [$_constrGrid getRowByIdx $idx]

		$comboType set $_typeToLabel($_modelClassToType([$model info class]))

		$_constrGrid setCellData $it [$_constrGrid getColumnIdByIndex 2] [$model getLabelForDisplay] ;# colIdx=0 is rowNum col
	}
}

body TableDialog::addTableConstraintInternal {} {
	set i [incr _tableConstrSeq]
	set w [$_constrGrid getWidget]
	set types $_sortedLabels
	
	# Creating widgets
	set typeCombo [ttk::combobox $w.type_$i -values $types -width 10 -state readonly]
	bind $typeCombo <<ComboboxSelected>> "$this tableConstrTypeChangedWithCheck $i"
	$typeCombo set [lindex $types 0]
	set configBtn [ttk::button $w.config_$i -text [mc {Configure}] -image img_small_more_opts -compound right -command "$this configConstr $i"]

	# Clam theme quickfix
	if {$::ttk::currentTheme == "clam"} {
		$configBtn configure -style TButtonThin
	}

	# Add row
	set it [$_constrGrid addRow [list $typeCombo "" $configBtn]]

	# Add bindings
	set firstCol [lindex [$_constrGrid getColumns] 0 0]
	foreach widget [list $typeCombo $configBtn] {
		bind $widget <ButtonPress-1> "$_constrGrid select $it $firstCol"
	}

	# Overwrite "scrollable" bindings
	$_constrGrid makeWidgetScrollable $typeCombo true

	# Metadata
	$_constrGrid setRowTags $it $i
	dict set _tableConstrWidgets $i [list $typeCombo $configBtn]

	return $i
}

body TableDialog::updateTableConstrState {} {
	set it [$_constrGrid getSelectedRow]
	$_widget(delTableConstr) configure -state [expr {$it == "" ? "disabled" : "normal"}]
}

body TableDialog::configConstr {idx} {
	set model [dict get $_tableConstrModels $idx]
	set widgets [dict get $_tableConstrWidgets $idx]
	lassign $widgets comboType configBtn
	set it [$_constrGrid getRowByIdx $idx]
	set type [getTableConstrType $idx]

	set dialog [$_typeToDialogClass($type) $this.#auto -model $model -db $_db -tabledialog $this]
	if {[$dialog exec]} {
		refreshColumns
		refreshTableConstrValues $idx
	}
}

body TableDialog::isGlobalPk {colName} {
	foreach model [dict values $_tableConstrModels] {
		set type $_modelClassToType([$model info class])
		if {$type != "pk"} continue
		
		if {[lsearch -nocase [$model getColumnNames] $colName] > -1} {
			return 1
		}
	}
	return 0
}

body TableDialog::isGlobalFk {colName} {
	foreach model [dict values $_tableConstrModels] {
		set type $_modelClassToType([$model info class])
		if {$type != "fk"} continue
		
		if {[lsearch -nocase [$model cget -localColumns] $colName] > -1} {
			return 1
		}
	}
	return 0
}

body TableDialog::isGlobalUniq {colName} {
	foreach model [dict values $_tableConstrModels] {
		set type $_modelClassToType([$model info class])
		if {$type != "uniq"} continue

		if {[lsearch -nocase [$model getColumnNames] $colName] > -1} {
			return 1
		}
	}
	return 0
}

body TableDialog::parseInputModel {} {
	set uiVar(tableName) [$_tableModel getValue tableName]

	# Parsing column models
	foreach colDef [$_tableModel getValue columnDefs] {
		set colModel [TableDialogColumnModel ::#auto]
		set name [$colDef getValue columnName]
		$colModel configure -name $name -oldName $name -fromInput 1

		# Type
		set typeDef [$colDef getValue typeName]
		if {$typeDef != ""} {
			$colModel configure -type [$typeDef getListValue name] \
				-size [$typeDef getValue size] -precision [$typeDef getValue precision]
		}

		# Column constraints
		foreach constrDef [$colDef getListValue columnConstraints] {
			switch -- [$constrDef getValue branchIndex] {
				0 {
					# PK
					set conflictModel [$constrDef getValue conflictClause]
					set conflict ""
					if {$conflictModel != ""} {
						set conflict [$conflictModel getValue clause]
					}
					$colModel configure -pk 1 -pkNamed [$constrDef getValue namedConstraint] \
						-pkName [$constrDef getValue constraintName] -pkConflict $conflict -pkOrder [$constrDef getValue order]
					if {$_sqliteVersion == 3 && $_modelSqliteVersion == 3} {
						$colModel configure -pkAutoIncr [$constrDef getValue autoincrement]
					}
				}
				1 {
					# NOT NULL
					set notKeyword [$constrDef getValue notKeyword]
					if {$notKeyword} {
						set conflictModel [$constrDef getValue conflictClause]
						set conflict ""
						if {$conflictModel != ""} {
							set conflict [$conflictModel getValue clause]
						}
						$colModel configure -notnull 1 -notnullNamed [$constrDef getValue namedConstraint] \
							-notnullName [$constrDef getValue constraintName] -notnullConflict $conflict
					}
				}
				2 {
					# UNIQUE
					set conflictModel [$constrDef getValue conflictClause]
					set conflict ""
					if {$conflictModel != ""} {
						set conflict [$conflictModel getValue clause]
					}
					$colModel configure -uniq 1 -uniqNamed [$constrDef getValue namedConstraint] \
						-uniqName [$constrDef getValue constraintName] -uniqConflict $conflict
				}
				3 {
					# CHECK
					set conflictModel [$constrDef getValue conflictClause]
					set conflict ""
					if {$conflictModel != ""} {
						set conflict [$conflictModel getValue clause]
					}
					$colModel configure -check 1 -checkNamed [$constrDef getValue namedConstraint] \
						-checkName [$constrDef getValue constraintName] \
						-checkConflict $conflict

					set expr [$constrDef getValue expr]
					if {$expr != ""} {
						$colModel configure -checkExpr [$expr toSql]
					}
				}
				4 {
					# DEFAULT
					$colModel configure -default 1 -defaultNamed [$constrDef getValue namedConstraint] \
						-defaultName [$constrDef getValue constraintName]

					if {[$constrDef getValue expr] != ""} {
						set expr [$constrDef getValue expr]
						$colModel configure -defaultValue [$expr toSql] -defaultIsLiteral 0
					} else {
						$colModel configure -defaultValue [$constrDef getValue literalValue] -defaultIsLiteral 1
					}
				}
				5 {
					# COLLATE
					if {$_sqliteVersion == 2 || $_modelSqliteVersion == 2} continue
					$colModel configure -collate 1 -collateNamed [$constrDef getValue namedConstraint] \
						-collateName [$constrDef getValue constraintName] -collationName [$constrDef getValue collationName]
				}
				6 {
					# FK
					if {$_sqliteVersion == 2 || $_modelSqliteVersion == 2} continue
					$colModel configure -fk 1 -fkNamed [$constrDef getValue namedConstraint] \
						-fkName [$constrDef getValue constraintName]

					set fkModel [$constrDef getValue foreignKey]

					$colModel configure -fkTable [$fkModel getValue tableName] \
						-fkColumn [lindex [$fkModel getListValue columnNames] 0] \
						-fkOnUpdate [$fkModel getValue onUpdate] -fkMatch [$fkModel getValue matchName] \
						-fkOnDelete [$fkModel getValue onDelete]

					if {[$fkModel getValue deferrableKeyword]} {
						if {[$fkModel getValue notKeyword]} {
							$colModel configure -fkDeferrable "NOT DEFERRABLE"
						} else {
							$colModel configure -fkDeferrable "DEFERRABLE"
						}
						if {[$fkModel getValue initiallyKeyword]} {
							if {[$fkModel getValue deferredKeyword]} {
								$colModel configure -fkInitially "INITIALLY DEFERRED"
							} else {
								$colModel configure -fkInitially "INITIALLY IMMEDIATE"
							}
						}
					}
				}
			}
		}

		lappend _columns $colModel
	}

	# Table constraints
	foreach pkModel [$_tableModel getPks] {
		set pk [TableDialogPkModel ::#auto]
		set conflictModel [$pkModel getValue conflictClause]
		set conflict ""
		if {$conflictModel != ""} {
			set conflict [$conflictModel getValue clause]
		}
		$pk configure -named [$pkModel getValue namedConstraint] -name [$pkModel getValue constraintName] \
			-conflict $conflict -sqliteVersion $_sqliteVersion
		if {$_sqliteVersion == 3} {
			if {$_modelSqliteVersion == 3} {
				$pk configure -autoincrement [$pkModel getValue autoincrement]
				foreach col [$pkModel getListValue indexedColumns] {
					$pk addColumns [list [$col getValue columnName] [list [$col getValue collation] [$col getValue collationName]] [$col getValue order]]
				}
			} else {
				foreach col [$pkModel getListValue indexedColumns] {
					$pk addColumns [list [$col getValue columnName] [list 0 ""] ""]
				}
			}
		} else {
			if {$_modelSqliteVersion == 2} {
				foreach col [$pkModel getListValue columnNames] {
					$pk addColumns $col
				}
			} else {
				foreach col [$pkModel getListValue indexedColumns] {
					$pk addColumns [$col getValue columnName]
				}
			}
		}
		addTableConstraintFromModel $pk
	}

	foreach uniqModel [$_tableModel getUniqs] {
		set uniq [TableDialogUniqModel ::#auto]
		set conflictModel [$uniqModel getValue conflictClause]
		set conflict ""
		if {$conflictModel != ""} {
			set conflict [$conflictModel getValue clause]
		}
		$uniq configure -named [$uniqModel getValue namedConstraint] -name [$uniqModel getValue constraintName] \
			-conflict $conflict -sqliteVersion $_sqliteVersion
		if {$_sqliteVersion == 3} {
			if {$_modelSqliteVersion == 3} {
				foreach col [$uniqModel getListValue indexedColumns] {
					$uniq addColumns [list [$col getValue columnName] [list [$col getValue collation] [$col getValue collationName]] [$col getValue order]]
				}
			} else {
				foreach col [$uniqModel getListValue indexedColumns] {
					$uniq addColumns [list [$col getValue columnName] [list 0 ""] ""]
				}
			}
		} else {
			if {$_modelSqliteVersion == 2} {
				foreach col [$uniqModel getListValue columnNames] {
					$uniq addColumns $col
				}
			} else {
				foreach col [$uniqModel getListValue indexedColumns] {
					$uniq addColumns [$col getValue columnName]
				}
			}
		}
		addTableConstraintFromModel $uniq
	}

	if {$_sqliteVersion == 3 && $_modelSqliteVersion == 3} {
		foreach fkModel [$_tableModel getFks] {
			set fk [TableDialogFkModel ::#auto]
			$fk configure -named [$fkModel getValue namedConstraint] -name [$fkModel getValue constraintName] \
				-localColumns [$fkModel getListValue columnNames] -sqliteVersion $_sqliteVersion

			set fkClause [$fkModel getValue foreignKey]
			if {$fkClause == ""} {
				error "fkClause empty while parsing fkModel!"
			}

			$fk configure \
				-foreignTable [$fkClause getValue tableName] \
				-foreignColumns [$fkClause getListValue columnNames] \
				-onDelete [$fkClause getValue onDelete] \
				-onUpdate [$fkClause getValue onUpdate] \
				-match [$fkClause getValue matchName]

			if {[$fkClause getValue deferrableKeyword]} {
				if {[$fkClause getValue notKeyword]} {
					$fk configure -deferrable "NOT DEFERRABLE"
				} else {
					$fk configure -deferrable "DEFERRABLE"
				}
				if {[$fkClause getValue initiallyKeyword]} {
					if {[$fkClause getValue deferredKeyword]} {
						$fk configure -initially "INITIALLY DEFERRED"
					} else {
						$fk configure -initially "INITIALLY IMMEDIATE"
					}
				}
			}
			addTableConstraintFromModel $fk
		}
	}

	foreach chkModel [$_tableModel getChks] {
		set chk [TableDialogChkModel ::#auto]
		set conflictModel [$chkModel getValue conflictClause]
		set conflict ""
		if {$conflictModel != ""} {
			set conflict [$conflictModel getValue clause]
		}

		set expr ""
		if {[$chkModel getValue expr] != ""} {
			set expr [[$chkModel getValue expr] toSql]
		}
		$chk configure -named [$chkModel getValue namedConstraint] -name [$chkModel getValue constraintName] \
			-expr $expr -conflict $conflict -sqliteVersion $_sqliteVersion
		addTableConstraintFromModel $chk
	}

	# Updating columns
	refreshColumns
}

body TableDialog::refreshGrab {{w ""}} {
	if {$w == "" || [string first "." $w 1] == -1} {
		Modal::refreshGrab
	}
}

body TableDialog::validateForSql {} {
	set i 1
	foreach model [dict values $_tableConstrModels] {
		set type $_modelClassToType([$model info class])
		set dialogClass $_typeToDialogClass($type)
		if {[${dialogClass}::validate $model true]} {
			set label $_typeToLabel($type)
			return [mc {Table constraint number %s (%s) is not configured correctly.} $i $label]
		}
		incr i
	}
	if {[llength $_columns] == 0} {
		return [mc {There's no column defined.}]
	}
	return ""
}

body TableDialog::validate {} {
	set i 1
	foreach model [dict values $_tableConstrModels] {
		set type $_modelClassToType([$model info class])
		set dialogClass $_typeToDialogClass($type)
		if {[${dialogClass}::validate $model true]} {
			set label $_typeToLabel($type)
			Error [mc {Table constraint number %s (%s) is not configured correctly.} $i $label]
		}
		incr i
	}
	if {[llength $_columns] == 0} {
		Error [mc {There's no column defined.}]
		return 1
	}

	if {$_tableModel != ""} {
		set oldTableName [$_tableModel getValue tableName]
	}

	set tableName [string tolower $uiVar(tableName)]
	set type [$_db onecolumn {SELECT type FROM sqlite_master WHERE lower(name) = $tableName}]
	if {$type != "" && [info exists oldTableName] && ![string equal [stripObjName $oldTableName] $uiVar(tableName)]} {
		switch -- $type {
			"table" {
				Error [mc "There is already a table with name '%s'. Please change the name of this table." $uiVar(tableName)]
			}
			"index" {
				Error [mc "There is already an index with name '%s'. Please change the name of this index." $uiVar(tableName)]
			}
			"trigger" {
				Error [mc "There is already a trigger with name '%s'. Please change the name of this trigger." $uiVar(tableName)]
			}
			"view" {
				Error [mc "There is already a view with name '%s'. Please change the name of this view." $uiVar(tableName)]
			}
		}
		return 1
	}
	return 0
}

body TableDialog::columnExists {name} {
	foreach col $_columns {
		if {[string equal -nocase $name [$col cget -name]]} {
			return true
		}
	}
	return false
}

body TableDialog::createTransferSql {fromTable toTable} {
	set srcCols [list]
	set dstCols [list]
	foreach colModel $_columns {
		if {![$colModel cget -fromInput]} continue
		set name [$colModel cget -name]
		set oldName [$colModel cget -oldName]
		lappend dstCols "[wrapObjName $name [$_db getDialect]]"
		lappend srcCols "[wrapObjName $oldName [$_db getDialect]]"
	}
	set src [join $srcCols ", "]
	set dst [join $dstCols ", "]
	#puts "from table: $fromTable"
	return "INSERT INTO [wrapObjName $toTable [$_db getDialect]] ($dst) SELECT $src FROM [wrapObjName $fromTable [$_db getDialect]]"
}

body TableDialog::renameSqlite2Table {from to} {
	set srcCols [list]
	foreach colModel $_columns {
		if {![$colModel cget -fromInput]} continue
		set oldName [$colModel cget -oldName]
		lappend srcCols "[wrapObjName $oldName [$_db getDialect]]"
	}
	set src [join $srcCols ", "]
	$_db eval "CREATE TABLE [wrapObjName $to [$_db getDialect]] AS SELECT $src FROM [wrapObjName $from [$_db getDialect]]"
	$_db eval "DROP TABLE [wrapObjName $from [$_db getDialect]]"
}

body TableDialog::collectTriggersForTable {oldTable newTable} {
	set trigs [list]
	set dialect [$_db getDialect]
	set parser [UniversalParser ::#auto $_db]
	$parser configure -expectedTokenParsing false
	
	set result [dict create returnCode 0 triggers $trigs]
	set mode [$_db mode]
	$_db eval {SELECT name, sql FROM sqlite_master WHERE type = 'trigger'} row {
		$parser parseSql $row(sql)
		set parsedDict [$parser get]
		set obj [dict get $parsedDict object]

		if {[dict get $parsedDict returnCode] != 0} {
			# Problem with parsing trigger
			YesNoDialog .trigParseProblem -type warning \
				-message [mc "Cannot parse DDL for trigger '%s',\nso cannot recreate it after table modification.\nDo you want to continue?" $row(name)] \
				-title [mc {Trigger parsing problem}]

			if {![.trigParseProblem exec]} {
				$_db $mode
				dict set result returnCode 1
				delete object $parser
				return $result
			}
		}

		set trigStatement [$obj getValue subStatement]
		set trigTable [$trigStatement getValue tableName]
		if {[string equal -nocase $trigTable $oldTable]} {
			$trigStatement replaceTableToken [wrapObjName $newTable $dialect]
			lappend trigs [list $row(name) [$trigStatement toSql]]
		}
		$parser freeObjects
	}
	$_db $mode
	delete object $parser
	dict set result triggers $trigs
	return $result
}

body TableDialog::collectIndexesForTable {oldTable newTable} {
	set indexes [list]
	set dialect [$_db getDialect]
	set parser [UniversalParser ::#auto $_db]
	$parser configure -expectedTokenParsing false
	set result [dict create returnCode 0 indexes $indexes]
	set mode [$_db mode]
	$_db short
	$_db eval {SELECT name, sql FROM sqlite_master WHERE type = 'index'} row {
		if {[string trim $row(sql)] == "" || [$_db isNull $row(sql)]} continue ;# ommit system indexes
		$parser parseSql $row(sql)
		set parsedDict [$parser get]
		set obj [dict get $parsedDict object]

		if {[dict get $parsedDict returnCode] != 0} {
			# Problem with parsing index
			YesNoDialog .idxParseProblem -type warning \
				-message [mc "Cannot parse DDL for index '%s',\nso cannot recreate it after table modification.\nDo you want to continue?" $row(name)] \
				-title [mc {Index parsing problem}]

			if {![.idxParseProblem exec]} {
				$_db $mode
				dict set result returnCode 1
				delete object $parser
				return $result
			}
		}

		set idxStatement [$obj getValue subStatement]
		set idxTable [$idxStatement getValue onTable]
		if {[string equal -nocase $idxTable $oldTable]} {
			$idxStatement replaceTableToken [wrapObjName $newTable $dialect]
			lappend indexes [list $row(name) [$idxStatement toSql]]
		}
		$parser freeObjects
	}
	$_db $mode
	delete object $parser
	dict set result indexes $indexes
	return $result
}

body TableDialog::collectViewsForTable {oldTable newTable} {
	set views [list]
	set dialect [$_db getDialect]
	set parser [UniversalParser ::#auto $_db]
	$parser configure -expectedTokenParsing false
	set result [dict create returnCode 0 views $views]
	set mode [$_db mode]
	$_db short
	$_db eval {SELECT name, sql FROM sqlite_master WHERE type = 'view'} row {
		if {[string trim $row(sql)] == "" || [$_db isNull $row(sql)]} continue ;# ommit inexisting objects
		$parser parseSql $row(sql)
		set parsedDict [$parser get]
		set obj [dict get $parsedDict object]

		if {[dict get $parsedDict returnCode] != 0} {
			# Problem with parsing view
			YesNoDialog .viewParseProblem -type warning \
				-message [mc "Cannot parse DDL for view '%s',\nso cannot recreate it after table modification.\nDo you want to continue?" $row(name)] \
				-title [mc {View parsing problem}]

			if {![.viewParseProblem exec]} {
				$_db $mode
				dict set result returnCode 1
				delete object $parser
				return $result
			}
		}

		set viewStatement [$obj getValue subStatement]
		set subSelect [$viewStatement getValue subSelect]
		$subSelect setContextTokensMode true
		set tokens [$subSelect getContextInfo "ALL_TABLE_NAMES"]
		$subSelect setContextTokensMode false
		
		set allTokens [$viewStatement cget -allTokens]
		set newToken [list OTHER [wrapObjIfNeeded $newTable $dialect] 0 0]
		set counter 0
		foreach tableDict $tokens {
			set tableToken [dict get $tableDict table]
			if {[string equal -nocase [lindex $tableToken 1] $oldTable]} {
				set allTokens [lmap [list $tableToken $newToken] $allTokens]
				incr counter
			}
		}
		if {$counter > 0} {
			set sql "DROP VIEW [wrapObjIfNeeded $row(name) $dialect]; "
			append sql [Lexer::detokenize $allTokens]
			lappend views [list $row(name) $sql]
		}
		$parser freeObjects
	}
	$_db $mode
	delete object $parser
	dict set result views $views
	return $result
}

body TableDialog::generateBackupTableName {oldTableName newTableName} {
	set backupTable "${newTableName}_bak0"
	set backupTableName [string tolower $backupTable]
	set i 1
	while {[$_db onecolumn {SELECT rootpage FROM sqlite_master WHERE lower(name) = $backupTableName}] != "" || [string equal $backupTable $oldTableName]} {
		set backupTable "[string range ${backupTable} 0 end-1]$i"
		set backupTableName [string tolower $backupTable]
		incr i
	}
	return [list $backupTable $backupTableName]
}

body TableDialog::renameTable {oldTableName backupTable} {
	if {$_sqliteVersion == 2} {
		# For SQLite2 we don't have ALTER TABLE, so we need to copy all data to backup table
		renameSqlite2Table $oldTableName $backupTable
	} else {
		# SQlite3 supports renaming tables, so we just rename it
		$_db eval "ALTER TABLE [wrapObjName $oldTableName [$_db getDialect]] RENAME TO [wrapObjName $backupTable [$_db getDialect]];"
	}
}

body TableDialog::handleFks {oldTableName} {
	if {$_sqliteVersion == 2} {return 1}

	set dialect [$_db getDialect]
	
	# Collecting all fks to this table
	set fks [dict create]
	foreach dbTable [$_db eval {SELECT name FROM sqlite_master WHERE type = 'table' AND name <> $oldTableName}] {
		$_db eval "PRAGMA foreign_key_list([wrapObjName $dbTable $dialect])" fkRow {
			if {[string equal -nocase $fkRow(table) $oldTableName] && ![string equal -nocase $dbTable $oldTableName]} {
				dict lappend fks $fkRow(to) [dict create from $fkRow(from) table $dbTable]
			}
		}
	}

	if {[dict size $fks] == 0} {return 1}

	# Collecting all existing (after edition) columns
	set changedCols [dict create]
	set allCols [list]
	foreach colModel $_columns {
		set name [$colModel cget -name]
		if {![$colModel cget -fromInput]} {
			lappend allCols $name
			continue
		}
		set oldName [$colModel cget -oldName]
		lappend allCols $oldName
		if {![string equal -nocase $oldName $name]} {
			dict set changedCols $oldName $name
		}
	}

	# Generating list of actions, which tell if some referenced column has changed or has been deleted.
	set actions [dict create]
	dict for {targetCol detailList} $fks {
		foreach details $detailList {
			set table [dict get $details table]
			if {$targetCol in $allCols} {
				if {[dict exists $changedCols $targetCol]} {
					set newTarget [dict get $changedCols $targetCol]
					dict lappend actions $table [dict merge [dict create action "rename" to $targetCol newTarget $newTarget] $details]
				}
			} else {
				dict lappend actions $table [dict merge [dict create action "remove" to $targetCol] $details]
			}
		}
	}
	set logicalActions $actions ;# copy this form of actions to generate report to user at the end

	# Prepare parser
	set parser [UniversalParser ::#auto $_db]
	$parser configure -expectedTokenParsing false

	# Going through actions and converting them into simple "replace token in tokenized sql" actions.
	set unhandledTables [list]
	set tokenActions [dict create]
	set tableTokens [dict create]
	dict for {table actions} $actions {
		$parser freeObjects
		if {[catch {set model [getModel $_db $table $parser]} err]} {
			if {$::errorCode == 5} {
				error $err
			}
		}

		if {(![info exists model] || $model == "") && ![isSupportedSystemTable $table] || [$_db isVirtualTable $table]} {
			if {$table ni $unhandledTables} {
				lappend unhandledTables $table
			}
			continue
		}

		dict set tableTokens $table [$model cget -allTokens]

		foreach action $actions {
			dict lappend tokenActions $table [handleFkAction $action $model $oldTableName]
		}
	}
	
	# Executing simple token replacing actions
	set newDdls [dict create]
	dict for {table allTokens} $tableTokens {
		set replaceMap [list]
		foreach action [dict get $tokenActions $table] {
			set old [dict get $action old]
			set new [dict get $action new]
			switch -- [dict get $action action] {
				"replace" {
					lappend replaceMap $old $new
				}
				"remove" {
					foreach singleToken $old {
						lremove allTokens $singleToken
					}
				}
			}
		}
		set allTokens [lmap $replaceMap $allTokens]
		dict set newDdls $table [Lexer::detokenize $allTokens]
	}

	delete object $parser

	# Creating warning message
	set msgs [list]
	if {[llength $unhandledTables] > 0} {
		lappend msgs [mc "Could not parse following table DDLs, therfore none of their foreign keys referencing table '%s' will be recreated:\n\n%s." $oldTableName [join [lsort -dictionary $unhandledTables] ", "]]
	}
	
	set removeActions [list]
	dict for {table actions} $logicalActions {
		foreach action $actions {
			if {[dict get $action action] != "remove"} continue
			lappend removeActions $action
		}
	}
	if {[llength $removeActions] > 0} {
		set refs [list]
		foreach action $removeActions {
			set table [dict get $action table]
			set from [dict get $action from]
			set to [dict get $action to]
			lappend refs [mc "%s(%s) referencing %s(%s)" $table $from $oldTableName $to]
		}
		lappend msgs [mc "Following foreign keys won't be recreated, because they'd not be valid anymore:\n\n%s" [join $refs ",\n"]]
	}

	if {[llength $msgs] > 0} {
		lappend msgs [mc {Do you want to continue anyway?}]
		set msg [join $msgs "\n\n"]
		if {![YesNoDialog::warning $msg]} {
			return 0
		}
	}

	set unhandledTables [list]
	dict for {table ddl} $newDdls {
		lassign [generateBackupTableName $table $table] newTableName lowerCaseTableName
		renameTable $table $newTableName
		if {[catch {
			$_db eval $ddl
			$_db eval "INSERT INTO [wrapObjName $table $dialect] SELECT * FROM [wrapObjName $newTableName $dialect]"
			$_db eval "DROP TABLE [wrapObjName $newTableName $dialect]"
		} err]} {
			lappend unhandledTables "$table ($err)"
		}
	}

	if {[llength $unhandledTables] > 0} {
		set msg [mc "Following tables won't be recreated with proper foreign keys due to database errors:\n\n%s\n\nDo you want to continue anyway?" [join $unhandledTables ",\n"]]
		if {![YesNoDialog::warning $msg]} {
			return 0
		}
	}

	return 1
}

body TableDialog::handleFkAction {action model oldTableName} {
	set from [dict get $action from]
	set to [dict get $action to]
	set table [dict get $action table]

	set found 0

	# Looking in columns
	foreach colModel [$model getListValue columnDefs] {
		if {![string equal -nocase [$colModel getValue columnName] $from]} continue

		set fkConstr [$colModel getFk]
		if {$fkConstr == ""} continue
		set fkModel [$fkConstr getValue foreignKey]
		if {![string equal -nocase [$fkModel getValue tableName] $oldTableName]} continue
		if {![string equal -nocase [lindex [$fkModel getValue columnNames] 0] $to]} continue

		set found 1
		set fullToken [lindex [$fkModel cget -columnNames] 0]
		set constrTokens [$fkConstr cget -allTokens]
		return [handleFkActionMatched $action $fullToken $constrTokens]
	}
	
	if {$found} {
		# This should never happen and if it dees, then actions were constructed incorrectly.
		error "TableDialog::handleFkAction: fk found, but not returned from function!"
	}

	# Not in columns? Look into table global constraints
	foreach tableFkConstr [$model getFks] {
		set fkModel [$tableFkConstr getValue foreignKey]
		if {$fkModel == ""} continue
		if {![string equal -nocase [$fkModel getValue tableName] $oldTableName]} continue

		set columns [$fkModel getListValue columnNames]
		set colIdx [lsearch -exact -nocase $columns $to]
		if {$colIdx == -1} continue

		set found 1
		set fullToken [lindex [$fkModel cget -columnNames] $colIdx]
		set constrTokens [$tableFkConstr cget -allTokens]
		
		# If previous token is period, then we need to remove it as well
		set allModelTokens [$model cget -allTokens]
		set previousTokenIdx [lsearch -exact $allModelTokens [lindex $constrTokens 0]]
		incr previousTokenIdx -1
		set previousToken [lindex $allModelTokens $previousTokenIdx]
		if {[lindex $previousToken 0] == "OPERATOR" && [lindex $previousToken 1] == ","} {
			set constrTokens [linsert $constrTokens 0 $previousToken]
		}
		
		return [handleFkActionMatched $action $fullToken $constrTokens]
	}

	error "TableDialog::handleFkAction called for '$oldTableName', but no matching FK found for action: $action"
}

body TableDialog::handleFkActionMatched {action fullToken tokensToRemove} {
	switch -- [dict get $action action] {
		"rename" {
			set newTarget [dict get $action newTarget]
			set newToken [lreplace $fullToken 1 1 $newTarget]
			return [dict create action "replace" old $fullToken new $newToken]
		}
		"remove" {
			return [dict create action "remove" old $tokensToRemove new ""]
		}
	}
	error "TableDialog::handleFkActionMatched: unsupported action: $action"
}

body TableDialog::alterTable {oldTableName newTableName newDdl} {
	BusyDialog::show [mc {Modifying table...}] [mc {Modifying table '%s'.} $oldTableName] false 100 false determinate

	$_db begin

	if {[catch {
		# Making list of triggers for later recreation
		set triggersDict [collectTriggersForTable $oldTableName $newTableName]
		if {[dict get $triggersDict returnCode]} {
			return -code error [mc {Could not recreate triggers for modified table.}]
		}

		BusyDialog::setProgressStatic 5


		# Making list of indexes for later recreation
		set indexesDict [collectIndexesForTable $oldTableName $newTableName]
		if {[dict get $indexesDict returnCode]} {
			return -code error [mc {Could not recreate indexes for modified table.}]
		}

		BusyDialog::setProgressStatic 10

		# Making list of view for later recreation
		set viewsDict [collectViewsForTable $oldTableName $newTableName]
		if {[dict get $viewsDict returnCode]} {
			return -code error [mc {Could not recreate views for modified table.}]
		}

		BusyDialog::setProgressStatic 15

		# Check if table name was changed, then we just need to create new table and copy data from old
		if {[string equal $oldTableName $newTableName]} {
			# Table name was not changed, so we need backup table name to keep data for copying
			# Generating backup table name
			lassign [generateBackupTableName $oldTableName $newTableName] backupTable backupTableName

			BusyDialog::setProgressStatic 20

			# Renaming table
			renameTable $oldTableName $backupTable
			BusyDialog::setProgressStatic 50
			set srcTable $backupTable
		} else {
			# FKs pointing to table itself
			tableNameChangedHandler

			BusyDialog::setProgressStatic 30

			# No need to rename table, we can use existing one
			set srcTable $oldTableName
		}
		set dstTable $newTableName

		# Creating new table
		$_db eval [createSql]

		BusyDialog::setProgressStatic 60

		# Copying data
		$_db eval [createTransferSql $srcTable $dstTable]
		$_db eval "DROP TABLE [wrapObjName $srcTable [$_db getDialect]]"
		BusyDialog::setProgressStatic 90

		# Recreating triggers
		foreach trig [dict get $triggersDict triggers] {
			lassign $trig trigName trigSql
			if {[catch {$_db eval $trigSql} err]} {
				debug $err

				YesNoDialog .trigCreateProblem -type warning \
					-message [mc "It won't be possible to recreate trigger '%s' after table modification.\nDo you want to continue anyway?" $trigName] \
					-title [mc {Trigger recreation problem}]

				if {![.trigCreateProblem exec]} {
					set closeWhenOkClicked 0
					error [mc {Could not recreate triggers for modified table.}] "" $::ERRORCODE(cannotRecreateObject)
				}
			}
		}

		BusyDialog::setProgressStatic 92

		# Recreating indexes
		foreach idx [dict get $indexesDict indexes] {
			lassign $idx idxName idxSql
			if {[catch {$_db eval $idxSql} err]} {
				debug $err

				YesNoDialog .idxCreateProblem -type warning \
					-message [mc "It won't be possible to recreate index '%s' after table modification.\nDo you want to continue anyway?" $idxName] \
					-title [mc {Index recreation problem}]

				if {![.idxCreateProblem exec]} {
					set closeWhenOkClicked 0
					error [mc {Could not recreate indexes for modified table.}] "" $::ERRORCODE(cannotRecreateObject)
				}
			}
		}

		BusyDialog::setProgressStatic 94
		
		# Foreign keys adjustment
		if {![handleFks $oldTableName]} {
			set closeWhenOkClicked 0
			error [mc {Could not recreate foreign keys for tables referencing modified table.}] "" $::ERRORCODE(cannotRecreateObject)
		}

		BusyDialog::setProgressStatic 96

		# Recreating views
		foreach view [dict get $viewsDict views] {
			lassign $view viewName viewSql
			if {[catch {$_db eval $viewSql} err]} {
				debug $err

				YesNoDialog .viewCreateProblem -type warning \
					-message [mc "It won't be possible to recreate view '%s' after table modification.\nDo you want to continue anyway?" $viewName] \
					-title [mc {View recreation problem}]

				if {![.viewCreateProblem exec]} {
					set closeWhenOkClicked 0
					error [mc {Could not recreate views for modified table.}] "" $::ERRORCODE(cannotRecreateObject)
				}
			}
		}

		BusyDialog::setProgressStatic 100
	} err]} {
		debug $::errorInfo
		set errCode $::errorCode
		catch {$_db rollback}
		BusyDialog::hide
		cutOffStdTclErr err
		if {$errCode == $::ERRORCODE(noQuoteCharacterPossible)} {
			set objName [lindex [split $::errorInfo \n] 0]
			Error [mc {You cannot use all four SQL quoting characters (%s, %s, %s and %s) in one object name (which is: %s).} \" ' \[\] ` $objName]
		} elseif {$errCode == $::ERRORCODE(canceled) || $errCode == $::ERRORCODE(cannotRecreateObject)} {
			# Nothing to do here.
		} else {
			Error $err
		}
		set closeWhenOkClicked 0
		return ""
	} elseif {[catch {
		# Everything went ok, but there's possibility of constraint violation at the commit
		$_db commit
	} err]} {
		catch {$_db rollback}
		BusyDialog::hide
		cutOffStdTclErr err
		Error $err
		set closeWhenOkClicked 0
		return ""
	}

	BusyDialog::hide
}

body TableDialog::okClicked {} {
	set closeWhenOkClicked 1

	if {[validate]} {
		set closeWhenOkClicked 0
		return ""
	}

	if {$_tableModel != "" && !$_makeCopy} {
		set oldTableName [$_tableModel getValue tableName]
		set newTableName $uiVar(tableName)
		set newDdl [createSql]

		$_db setFkEnabled false
		alterTable $oldTableName $newTableName $newDdl
		$_db setFkEnabled true

		TASKBAR signal TableWin [list REFRESH $oldTableName $newTableName]
	} else {
		if {[catch {
			# Creating new table
			$_db eval [createSql]
		} err]} {
			BusyDialog::hide
			cutOffStdTclErr err
			if {$::errorCode == $::ERRORCODE(noQuoteCharacterPossible)} {
				set objName [lindex [split $::errorInfo \n] 0]
				Error [mc {You cannot use all four SQL quoting characters (%s, %s, %s and %s) in one object name (which is: %s).} \" ' \[\] ` $objName]
			} else {
				Error $err
			}
			set closeWhenOkClicked 0
			return ""
		}
	}

	# Everything went ok, so lets update rest of GUI.
	TASKBAR signal DBTree [list REFRESH DB_OBJ $_db]

	return ""
}

body TableDialog::cancelClicked {} {
	return 0
}

body TableDialog::createSql {} {
	set tableDefs [list]
	set colDefs [list]
	set globalConstraints [list]

	foreach col $_columns {
		lappend colDefs [createColumnSql $col]
	}

	# Global table constraints
	lappend globalConstraints {*}[createGlobalConstrSqls]

	# Putting all together
	lappend tableDefs [join $colDefs ", "]
	if {[llength $globalConstraints] > 0} {
		lappend tableDefs [join $globalConstraints ", "]
	}
	set tableDef [join $tableDefs ", "]
	return "CREATE TABLE [wrapObjName $uiVar(tableName) [$_db getDialect]] ($tableDef)"
}

body TableDialog::createColumnSql {colModel} {
	foreach varName {
		name type size precision
		pk pkNamed pkName pkOrder pkConflict pkAutoIncr
		notnull notnullNamed notnullName notnullConflict
		uniq uniqNamed uniqName uniqConflict
		check checkNamed checkName checkExpr checkConflict
		default defaultNamed defaultName defaultValue defaultIsLiteral
		collate collateNamed collateName collationName
		fk fkNamed fkName fkTable fkColumn fkOnUpdate fkOnDelete fkMatch fkDeferrable fkInitially
	} {
		set $varName [$colModel cget -$varName]
	}

	# Name and type
	set sql "[wrapObjName $name [$_db getDialect]]"

	if {$type != ""} {
		append sql " $type"
	}

	if {$size != "" || $precision != ""} {
		set typeSize [list]
		if {$size != ""} {
			lappend typeSize $size
		}
		if {$precision != ""} {
			lappend typeSize $precision
		}
		append sql " ([join $typeSize {, }])"
	}

	# PK
	if {$pk} {
		if {$pkNamed} {
			append sql " CONSTRAINT '$pkName'"
		}
		append sql " PRIMARY KEY"
		if {$pkOrder != ""} {
			append sql " $pkOrder"
		}
		if {$pkConflict != ""} {
			append sql " ON CONFLICT $pkConflict"
		}
		if {$_sqliteVersion == 3 && $pkAutoIncr} {
			append sql " AUTOINCREMENT"
		}
	}

	# NOTNULL
	if {$notnull} {
		if {$notnullNamed} {
			append sql " CONSTRAINT '$notnullName'"
		}
		append sql " NOT NULL"
		if {$notnullConflict != ""} {
			append sql " ON CONFLICT $notnullConflict"
		}
	}

	# UNIQUE
	if {$uniq} {
		if {$uniqNamed} {
			append sql " CONSTRAINT '$uniqName'"
		}
		append sql " UNIQUE"
		if {$uniqConflict != ""} {
			append sql " ON CONFLICT $uniqConflict"
		}
	}

	# CHECK
	if {$check} {
		if {$checkNamed} {
			append sql " CONSTRAINT '$checkName'"
		}
		append sql " CHECK($checkExpr)"
		if {$_sqliteVersion == 2 && $checkConflict != ""} {
			append sql " ON CONFLICT $checkConflict"
		}
	}

	# DEFAULT
	if {$default} {
		if {$defaultNamed} {
			append sql " CONSTRAINT '$defaultName'"
		}
		if {$defaultValue == ""} {
			set defaultValue "''"
		}
		if {$_sqliteVersion == 3 && !$defaultIsLiteral} {
			append sql " DEFAULT($defaultValue)"
		} else {
			append sql " DEFAULT '$defaultValue'"
		}
	}

	# COLLATE
	if {$_sqliteVersion == 3 && $collate} {
		if {$collateNamed} {
			append sql " CONSTRAINT '$collateName'"
		}
		append sql " COLLATE '$collationName'"
	}

	# FK
	if {$_sqliteVersion == 3 && $fk} {
		if {$fkNamed} {
			append sql " CONSTRAINT '$fkName'"
		}
		append sql " REFERENCES [wrapObjName $fkTable [$_db getDialect]]"
		if {$fkColumn != ""} {
			append sql " ([wrapObjName $fkColumn [$_db getDialect]])"
		}
		if {$fkOnUpdate != ""} {
			append sql " ON UPDATE $fkOnUpdate"
		}
		if {$fkOnDelete != ""} {
			append sql " ON DELETE $fkOnDelete"
		}
		if {$fkMatch != ""} {
			append sql " MATCH $fkMatch"
		}
		if {$fkDeferrable != ""} {
			append sql " $fkDeferrable"
		}
		if {$fkInitially != ""} {
			append sql " $fkInitially"
		}
	}

	return $sql
}

body TableDialog::createGlobalConstrSqls {} {
	set results [list]
	foreach model [dict values $_tableConstrModels] {
		set type $_modelClassToType([$model info class])
		switch -- $type {
			"pk" {
				set sql [createPkSql $model]
			}
			"fk" {
				set sql [createFkSql $model]
			}
			"uniq" {
				set sql [createUniqSql $model]
			}
			"chk" {
				set sql [createChkSql $model]
			}
		}
		lappend results $sql
	}
	return $results
}

body TableDialog::createPkSql {model} {
	foreach varName {
		named name columns conflict
	} {
		set $varName [$model cget -$varName]
	}

	set pk ""
	if {$_sqliteVersion == 3} {
		if {$named} {
			append pk "CONSTRAINT '[string map [list ' ''] $name]' "
		}
	}

	set pkColumns [list]
	foreach col $columns {
		# 'col' for SQLite2 is list of names, for SQLite3 it's list of 3-element lists: {name {collationEnabled collationName} order}
		if {$_sqliteVersion == 3} {
			lassign $col colName collation order
			lassign $collation collationEnabled collationName
			set colSql "[wrapObjName $colName [$_db getDialect]]"
			if {$collationEnabled} {
				append colSql " COLLATE '[string map [list ' ''] $collationName]'"
			}
			if {$order != ""} {
				append colSql " $order"
			}
		} else {
			set colSql "[wrapObjName $col [$_db getDialect]]"
		}
		lappend pkColumns $colSql
	}

	if {[llength $pkColumns] == 0} {
		error "No PK columns during call to createSql. It should never happen. Report this!"
	}

	append pk "PRIMARY KEY ([join $pkColumns {, }])"
	if {$conflict != ""} {
		append pk " ON CONFLICT $conflict"
	}

	return $pk
}

body TableDialog::createFkSql {model} {
	foreach varName {
		named name localColumns foreignTable foreignColumns
		onDelete onUpdate match deferrable initially
	} {
		set $varName [$model cget -$varName]
	}

	set fk ""
	if {$named} {
		append fk "CONSTRAINT '[string map [list ' ''] $name]' "
	}

	set localColsWrapped [wrapColNames $localColumns [$_db getDialect]]
	set foreignColsWrapped [wrapColNames $foreignColumns [$_db getDialect]]

	append fk "FOREIGN KEY ([join $localColsWrapped {, }]) REFERENCES [wrapObjName $foreignTable [$_db getDialect]] ([join $foreignColsWrapped {, }])"

	if {$onDelete != ""} {
		append fk " ON DELETE $onDelete"
	}

	if {$onUpdate != ""} {
		append fk " ON UPDATE $onUpdate"
	}

	if {$match != ""} {
		append fk " MATCH $match"
	}

	if {$deferrable != ""} {
		append fk " $deferrable"
	}

	if {$initially != ""} {
		append fk " $initially"
	}

	return $fk
}

body TableDialog::createUniqSql {model} {
	foreach varName {
		named name columns conflict
	} {
		set $varName [$model cget -$varName]
	}

	set uniq ""
	if {$_sqliteVersion == 3} {
		if {$named} {
			append uniq "CONSTRAINT '[string map [list ' ''] $name]' "
		}
	}

	set uniqColumns [list]
	foreach col $columns {
		# 'col' for SQLite2 is list of names, for SQLite3 it's list of 3-element lists: {name {collationEnabled collationName} order}
		if {$_sqliteVersion == 3} {
			lassign $col colName collation order
			lassign $collation collationEnabled collationName
			set colSql "[wrapObjName $colName [$_db getDialect]]"
			if {$collationEnabled} {
				append colSql " COLLATE '[string map [list ' ''] $collationName]'"
			}
			if {$order != ""} {
				append colSql " $order"
			}
		} else {
			set colSql "[wrapObjName $col [$_db getDialect]]"
		}
		lappend uniqColumns $colSql
	}

	if {[llength $uniqColumns] == 0} {
		error "No UNIQUE columns during call to createSql. It should never happen. Report this!"
	}

	append uniq "UNIQUE ([join $uniqColumns {, }])"
	if {$conflict != ""} {
		append uniq " ON CONFLICT $conflict"
	}

	return $uniq
}

body TableDialog::createChkSql {model} {
	foreach varName {
		named name expr conflict
	} {
		set $varName [$model cget -$varName]
	}

	set chk ""
	if {$_sqliteVersion == 3} {
		if {$named} {
			append chk "CONSTRAINT '[string map [list ' ''] $name]' "
		}
	}

	append chk "CHECK ($expr)"
	if {$conflict != ""} {
		append chk " ON CONFLICT $conflict"
	}

	return $chk
}

body TableDialog::getDdlContextDb {} {
	return $_db
}

body TableDialog::getTableName {} {
	return $uiVar(tableName)
}

body TableDialog::getOriginalTableName {} {
	if {$_tableModel != ""} {
		return [$_tableModel getValue tableName]
	} else {
		return ""
	}
}

body TableDialog::getColumns {} {
	return $_columns
}

body TableDialog::tableNameChangedHandler {args} {
	if {$_lastTableName == $uiVar(tableName)} return

	tableNameChanged $_lastTableName $uiVar(tableName)
	set _lastTableName $uiVar(tableName)
}

body TableDialog::columnNameChanged {from to} {
	if {$_sqliteVersion == 3} {
		# Column FK
		foreach colModel $_columns {
			if {![$colModel cget -fk]} continue
			if {[$colModel cget -fkTable] != $uiVar(tableName)} continue

			if {[$colModel cget -fkColumn] != $from} continue
			$colModel configure -fkColumn $to
		}
	}

	# Table constraints
	foreach model [dict values $_tableConstrModels] {
		$model columnNameChanged $from $to $uiVar(tableName)
	}

	refreshColumns
	refreshTableConstrValues
}

body TableDialog::columnDeleted {name} {
	set newSelectedModel [getSelectedColumnModel]
	refreshColumns $newSelectedModel

	foreach model [dict values $_tableConstrModels] {
		$model delColumn $name
	}
	refreshTableConstrValues
}

body TableDialog::tableNameChanged {from to} {
	if {$_sqliteVersion == 3} {
		# Column FK
		foreach colModel $_columns {
			if {![$colModel cget -fk]} continue
			if {[$colModel cget -fkTable] != $from} continue
			$colModel configure -fkTable $to
		}
	}

	# Table constraints
	foreach model [dict values $_tableConstrModels] {
		$model tableNameChanged $from $to
	}

	$this refreshTableConstrValues
}
