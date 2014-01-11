use src/grids/dbgrid.tcl
use src/shortcuts.tcl
use src/grid_hints.tcl

#>
# @class DataGrid
# Grid widget used to display and edit table data.
#<
class DataGrid {
	inherit DBGrid Shortcuts GridHints

	#>
	# @var realFormat
	# Double values representation format.
	#<
	final common realFormat {%1.1f}

	#>
	# @method constructor
	# @param args Parameters passed to {@class DBGrid}.
	#<
	constructor {args} {
		DBGrid::constructor {*}$args -readonly 0 -multicell 1
	} {}

	protected {
		#>
		# @arr _rowItemNum
		# Array of row numbers. Each row of grid has it's number starting from 1.<br>
		# Indexes of array are <b>TkTreeCtrl</b> row IDs.
		#<
		variable _rowItemNum

		#>
		# @var _newRow
		# If there is new, uncommited row, then this variable keeps <b>TkTreeCtrl</b> ID of that row.
		#<
		variable _newRow ""

		#>
		# @arr _colItem
		# Array of column identifiers. Indexes of array are column names and values ar <b>TkTreeCtrl</b> IDs.
		# Indexes are all lowercase. It's mandatory!
		#<
		variable _colItem

		#>
		# @var _tableWin
		# Contains parent MDI window object, which is of {@class TableWin} type.
		#<
		variable _tableWin ""

		#>
		# @arr _colPk
		# Array of boolean values determinating if a column is primary key.<br>
		# Indexes of array are <b>TkTreeCtrl</b> row IDs.
		#<
		variable _colPk

		#>
		# @arr _colDescription
		# Description of column. Dict keys:
		# <ul>
		# <li><code>type</code> - string (actual column datatype as defined in DDL)<br>
		# <li><code>pk</code> - boolean<br>
		# <li><code>fk</code> - boolean<br>
		# <li><code>fkColumn</code> - string<br>
		# <li><code>fkTable</code> - string<br>
		# <li><code>notnull</code> - boolean<br>
		# <li><code>unique</code> - boolean<br>
		# <li><code>collate</code> - boolean<br>
		# <li><code>collateName</code> - string<br>
		# <li><code>check</code> - boolean<br>
		# <li><code>checkExpr</code> - string
		# <li><code>default</code> - boolean<br>
		# <li><code>defaultValue</code> - string<br>
		# </ul>
		#>

		#<
		variable _colDescription

		#>
		# @arr _colNotNull
		# Array of boolean values determinating if a column has NOT NULL property.<br>
		# Indexes of array are <b>TkTreeCtrl</b> row IDs.
		#<
		variable _colNotNull

		#>
		# @arr _colDefault
		# Array of boolean values determinating if a column has default value defined. Empty value is synonym to no default value.<br>
		# Indexes of array are <b>TkTreeCtrl</b> row IDs.
		#<
		variable _colDefault

		#>
		# @var _contextMenu
		# Context menu widget.
		#<
		variable _contextMenu ""

		#>
		# @var _sortChangeCommand
		# Command to be executed when sorting order is requested.
		#<
		variable _sortChangeCommand ""

		variable _displayRowId 0
		
		method getValueForEdit {it col}
		method prepareColumnsForCommits {type cols}
		method cleanupColumnsAfterCommits {type cols successfulCommit}
	}

	public {
		#>
		# @method addColumn
		# @param title Title of new column.
		# @param type Type of data that will be keept in this column. Valid values are described in {@method Grid::addColumn}. The only new type that this class introduces is: '<code>blob</code>'.
		# @param columnDesc Dictionary widh constraints and type informations.
		# Adds new column to the grid.
		# @return New column (related to <b>TkTreeCtrl</b>).
		# @overloaded Grid
		#<
		method addColumn {title {type "text"} {columnDesc ""}}

		#>
		# @method addRow
		# @param data List of values for new row. List has to contain exactly the same number of values as number of columns in the grid.
		# @param rowid ROWID taken from sqlite for this row.
		# @param new Boolean value determinating if the new row is already in sqlite database (then it's <code>false</code>) or it's newly added by user and waits for commit to database (then it's <code>true</code>).
		# Adds new row to the grid.
		# This implementation supports NULL values using informations from database handler.
		# @overloaded Grid
		#<
		method addRow {data rowid {new 0} {refreshWidth true}}

		#>
		# @method delRows
		# Deletes all rows from grid. This implementation takes care about additional variables from this class.
		# @overloaded Grid
		#<
		method delRows {}
		method delRow {it}

		#>
		# @method delSelected
		# Deletes currently selected row.
		# @return '1' if deleted row was the new one and '0' otherwise.
		# @overloaded Grid
		#<
		method delSelected {}

		#>
		# @method commitNewRow
		# Commits (adds to pending commits list) last added row.
		#<
		method commitNewRow {}

		method commitPendingNewRow {it}
		method commitPendingRowDeletion {it rowId}
		method commitPendingRowEdit {it col value}
		method canCommitEdit {it col}

		#>
		# @method commitNewRowExternal
		# Commits new row to database. It differs from {@method commitNewRow} in many ways.
		# It's much cheaper method, which just assigns row order number (first column) and sets row type to '<code>regular</code>'.
		#<
		method commitNewRowExternal {}

# 		method rollbackNewRow {}

		#>
		# @method reset
		# Deletes all rows and columns and clears all necessary variables.
		#<
		method reset {}

		#>
		# @method deleteCurrentRow
		# Deletes currently selected row, including deletion of it from database.
		#<
		method deleteCurrentRow {}

		#>
		# @method addRowPairs
		# @param data List of {columnName value} pairs.
		# @param rowid ROWID taken from sqlite for this row.
		# @param refreshWidth If true, then width of grid is refreshed. It calls Tk command [update], so set it to false for mass adding rows and call {@method refreshWidth} from upper level.
		# This is alternative to {@method addRow} method, that allows to give column values in relation to their names, not in order they occur in the grid.
		# Each element of <i>data</i> list is pair of 2 elements: column name and value for it.
		#<
		method addRowPairs {data rowid {refreshWidth true}}

		#>
		# @method setActive
		# @param item Row ID to set active status for.
		# @param column Column ID to set active status for.
		# Sets active status to new cell identified by row ID and column ID.
		# @overloaded Grid
		#<
		method setActive {item column}

		#>
		# @method getSelectedRowId
		# @return Sqlite ROWID related to currently selected row in the grid.
		#<
		method getSelectedRowId {}

		#>
		# @method setSelectedRowId
		# @param rowid ROWID to set.
		# Assigns new ROWID to currently selected row in grid data view.
		#<
		method setSelectedRowId {rowid}

		#>
		# @method updateShortcuts
		# @overloaded Shortcuts
		#<
		method updateShortcuts {}

		#>
		# @method clearShortcuts
		# @overloaded Shortcuts
		#<
		method clearShortcuts {}

		#>
		# @method takeFocus
		# Forces focus for {@var _tree} widget.
		#<
		method takeFocus {}

		#>
		# @method contextMenuPopup
		# @param x X coordinate to post the menu at.
		# @param y Y coordinate to post the menu at.
		# Pops up the context menu at given coordinates and selects cell under these coordinates.
		# If there is no row or column at X-Y, then nothing happens.
		#<
		method contextMenuPopup {x y}

		#>
		# @method setRowData
		# @param item Row ID to set new data for (ID is related to <b>TkTreeCtrl</b>).
		# @param data List of data values to set.
		# Sets new values for all columns in given row. Columns in the grid are filled with same order as values in list.
		# This implementation supports NULL values using informations from database handler.
		# @overload Grid
		#<
		method setRowData {item data}

		#>
		# @method handleClick
		# @overloaded Grid
		#<
		method handleClick {x y {modifiers ""}}

		#>
		# @method handleDoubleClick
		# @overloaded Grid
		#<
		method handleDoubleClick {x y {modifiers ""}}

		#>
		# @method handleHeaderClicked
		# @param columnId ID of column clicked.
		# In this class it does nothing. Some overloaded versions of implementation might sort data or something else.
		#<
		method handleHeaderClicked {columnId}

		#>
		# @method setSortChangeCommand
		# @param cmd New command to be called.
		# Changes command to call when sorting order change is requested.
		#<
		method setSortChangeCommand {cmd}

		#>
		# @method getText
		# @overloaded Grid
		#<
		method getText {item}

		#>
		# @method duplicateRow
		# Duplicates currently selected row as new row (so it has to be commited).
		#<
		method duplicateRow {}

		#>
		# @method paste
		# @overloaded Grid
		#<
		method paste {}

		#>
		# @method renumberRows
		# Refreshes numbers column, so rows are numbered correctly.
		# Useful after deleting or adding row.
		#<
		method renumberRows {}

		method getRowId {it col}
		method getColumnTable {col}
		method switchTo {rowIdOrNum}
		method isEditPossible {it col}
		method getHelpHintdata {col}
		method setRowValueForAllCells {item value}
		method fillHint {it col hintTable}
		method createSelectFromMarked {}
		method isRowNew {it}
		method isSelectedRowNew {}
	}
}

body DataGrid::constructor {args} {
	initHints $_tree

	set _contextMenu [menu $_tree.cm -borderwidth 1 -activeborderwidth 1 -tearoff 0]
	bind $_tree <Any-Key> "if {\[$this checkForEdit %A %A %s]} break"
	bind $_tree <Button-$::RIGHT_BUTTON> "$this contextMenuPopup %x %y; tk_popup $_contextMenu %X %Y"

	updateShortcuts
	upvar this tWin
	set _tableWin $tWin
	eval itk_initialize $args

	refreshWidth
}

body DataGrid::contextMenuPopup {x y} {
	set item [$_tree identify $x $y]
	set rows 0
	set cells 0
	if {[lindex $item 0] == "item" && [lindex $item 3] != "0"} {
		set it [lindex $item 1]
		set col [lindex $item 3]

		set area [getMarkedArea]
		set markedItems [concat {*}$area]
		if {[list $it $col] ni $markedItems} {
			setActive $it $col
			set area [getMarkedArea]
			set markedItems [concat {*}$area]
		}
		set cells [llength $markedItems]
		set rows [llength $area]
	}

	$_contextMenu delete 0 end
	$_contextMenu add command -compound left -image img_db_insert_custom -label [mc "Add custom number of rows"] -command [list $_tableWin addRows]
	$_contextMenu add command -compound left -image img_db_insert -label [mc "Insert new row"] -command [list $_tableWin addRow]
	if {$rows > 0} {
		if {$rows > 1} {
			set delRowTxt [mc "Delete selected rows"]
		} else {
			set delRowTxt [mc "Delete selected row"]
		}
		$_contextMenu add command -compound left -image img_db_delete -label $delRowTxt -command [list $_tableWin delRow]
		$_contextMenu add separator
		if {$cells == 1} {
			$_contextMenu add command -compound left -image img_edit_cell -label [mc "Edit cell value"] -command [list $this edit [list $it $col]]
			$_contextMenu add command -compound left -image img_edit_blob -label [mc "Edit cell value in BLOB editor"] -command [list $this edit [list $it $col] true]
		}
		if {$rows == 1} {
			$_contextMenu add command -compound left -image img_duplicate -label [mc "Duplicate row"] -command [list $this duplicateRow]
		}
		$_contextMenu add command -compound left -image img_setnull -label [mc "Set NULL value"] -command [list $this setMassNull $markedItems]
		$_contextMenu add separator
		$_contextMenu add command -compound left -image img_wand -label [mc "Generate SELECT from selected cells"] -command [list $this createSelectFromMarked]
		$_contextMenu add separator
		$_contextMenu add command -compound left -image img_db_post -label [mc "Commit selected cells"] -command [list $this commitAll $markedItems]
		$_contextMenu add command -compound left -image img_db_cancel -label [mc "Rollback selected cells"] -command [list $this rollbackAll $markedItems]
		$_contextMenu add separator
		$_contextMenu add command -compound left -image img_select_all_square -label [mc "Select all"] -command [list $this selectAll]
		$_contextMenu add command -compound left -image img_copy -label [mc "Copy"] -command [list $this copyMarked]
		$_contextMenu add command -compound left -image img_paste -label [mc "Paste"] -command [list $this paste]
	}
	$_contextMenu add separator
	if {$_displayRowId} {
		$_contextMenu add command -compound left -image img_rownum -label [mc "Show ordinals"] -command [list $this switchTo "rownum"]
	} else {
		$_contextMenu add command -compound left -image img_rowid -label [mc "Show ROWIDs"] -command [list $this switchTo "rowid"]
	}
	leaveWidget ;# MacOSX needs this
}

body DataGrid::addColumn {title {type "text"} {columnDesc ""}} {
	set c [Grid::addColumn $title $type]
	set _colItem([string tolower $title]) $c
	if {$columnDesc != ""} {
		set _colPk($c) [dict get $columnDesc pk]
		set _colNotNull($c) [dict get $columnDesc notnull]
		set _colDefault($c) [dict get $columnDesc defaultValue]
	} else {
		set _colPk($c) 0
		set _colNotNull($c) 0
		set _colDefault($c) 0
	}
	set _colDescription($c) $columnDesc
	return $c
}

body DataGrid::getHelpHintdata {col} {
	return $_colDescription($col)
}

body DataGrid::fillHint {it col hintTable} {
	set description [getHelpHintdata $col]

	$hintTable setTitle [mc {Column: %s} $_colName($col)]
	$hintTable addRow [mc {Type:}] [dict get $description type]
	
	if {$it != ""} {
		# If hint is for header, there's not "it".
		$hintTable addRow "ROWID:" $_rowId($it)
	}

	set constrCnt 0
	foreach var {pk fk notnull unique check default collate} {
		set $var [dict get $description $var]
		if {[set $var]} {
			incr constrCnt
		}
	}

	# Constraints
	set constrContainer ""
	if {$constrCnt > 0} {
		set constrContainer [$hintTable addGroup [mc {Constraints:}]]
		$constrContainer setMode "img-label"
	}

	set dialect [$_db getDialect]

	set fkArg "[wrapObjIfNeeded [dict get $description fkTable] $dialect] ([wrapObjIfNeeded [dict get $description fkColumn] $dialect])"
	set checkArg [dict get $description checkExpr]
	set defaultArg [dict get $description defaultValue]
	set collateArg [dict get $description collateName]
	foreach var {
		pk fk notnull unique check default collate
	} format [list \
		"" "%s: %s" "" "" "%s (%s)" "%s (%s)" "%s: %s" \
	] label {
		"PRIMARY KEY"
		"FOREIGN KEY"
		"NOT NULL"
		"UNIQUE"
		"CHECK"
		"DEFAULT"
		"COLLATE"
	} argVar {
		"" "fkArg" "" "" "checkArg" "defaultArg" "collateArg"
	} img {
		img_constr_pk
		img_fk_col
		img_constr_notnull
		img_constr_uniq
		img_constr_check
		img_constr_default
		img_constr_collate
	} {
		if {[set $var]} {
			if {$argVar == ""} {
				$constrContainer addRow $img $label
			} else {
				$constrContainer addRow $img [format $format $label [set $argVar]]
			}
		}
	}
}

body DataGrid::getText {item} {
	lassign $item it col
	if {$_colType($col) in [list "window" "image"]} {
		return ""
	}

	if {[$_tree item element cget $it $col e_text -data] == "null"} {
		set value ""
	} else {
		set value [$_tree item element cget $it $col e_text -text]
	}
	return $value
}

body DataGrid::takeFocus {} {
	focus $_tree
}

body DataGrid::getValueForEdit {it col} {
	if {[isRowPendingForCommit $it]} {
		if {[$_tree item element cget $it $col e_text -data] == "null"} {
			set value [list "" 1]
		} else {
			set value [list [$_tree item element cget $it $col e_text -text] 0]
		}
	} else {
		set value [list [$_db onecolumn "SELECT [wrapObjName $_colName($col) [$_db getDialect]] FROM [wrapObjName $_table [$_db getDialect]] WHERE ROWID = $_rowId($it)"] 0]
		if {[$_db isNull [lindex $value 0]]} {
			set value [list "" 1]
		}
	}
	return $value
}

body DataGrid::canCommitEdit {it col} {
	# New rows are commited with commitNewRow
	expr {$it != $_newRow}
}

body DataGrid::isRowNew {it} {
	set exists [info exists _rowType($it)]
	expr {$it != "" && $exists && $_rowType($it) == "new"}
}

body DataGrid::isSelectedRowNew {} {
	isRowNew [lindex $_selected 0]
}

body DataGrid::switchTo {rowIdOrNum} {
	if {$rowIdOrNum ni [list "rowid" "rownum"]} {
		error "Unsupported switch to: $rowIdOrNum"
	}

	if {$rowIdOrNum == "rowid" && $_displayRowId} return
	if {$rowIdOrNum == "rownum" && !$_displayRowId} return

	if {[llength $_cols] == 0} return

	set col [lindex $_cols 0]
	switch -- $rowIdOrNum {
		"rowid" {
			set _displayRowId 1
			setColumnName $col "ROWID"
		}
		"rownum" {
			set _displayRowId 0
			setColumnName $col "#"
		}
	}

	foreach rowItem [getAllRows] {
		if {$_displayRowId} {
			setCellData $rowItem $col $_rowId($rowItem) false
		} else {
			setCellData $rowItem $col $_rowItemNum($rowItem) false
		}
	}
	refreshWidth

	$_tableWin markToFillForm
}

body DataGrid::addRow {data rowid {new 0} {refreshWidth true}} {
	if {$new && $_newRow != ""} {
		if {[commitNewRow] != 0} return
	}
	if {$new && $_selected != ""} {
		set it [$_tree item create -prevsibling [lindex $_selected 0]]
	} else {
		set it [$_tree item create]
		$_tree item lastchild root $it
	}

	set firstColVal $_rowNum
	if {$_displayRowId} {
		set firstColVal $rowid
	}

	set firstCol 1
	foreach w [concat [expr {$new ? "*" : $firstColVal}] $data] c $_cols {
		$_tree item style set $it $c s_text
		if {[$_db isNull $w] || $new} {
			if {$firstCol} {
				unsetNullStyle $it $c $w
			} else {
				setNullStyle $it $c $w
			}
		} else {
			unsetNullStyle $it $c $w
		}
		set firstCol 0
	}
	set _rowItemNum($it) $_rowNum
	incr _rowNum
	set _rowId($it) $rowid
	set _rowType($it) [expr {$new ? "new" : "regular"}]
	if {$new} {
		$_tree see $it
		set col [$_tree column id "first visible next visible"]
		setActive $it $col
		markForCommit $it "" "new" $it ""
	}
	if {$refreshWidth} {
		refreshWidth
	}
	return $it
}

body DataGrid::isEditPossible {it col} {
	expr {
		$_newRow != "" && $it == $_newRow ||
		[isRowPendingForCommitAsNew $it] ||
		[info exists _rowId($it)] && $_rowId($it) != "" && ![$_db isNull $_rowId($it)] &&
		![isRowPendingForCommitAsDeleted $it]
	}
	#	[info exists _rowId($it:)] && [lindex $_toCommit($it:) 0] == "new" ||
}


body DataGrid::addRowPairs {data rowid {refreshWidth true}} {
	set firstColVal $_rowNum
	if {$_displayRowId} {
		set firstColVal $rowid
	}

	set it [$_tree item create]
	foreach w [concat [list [list # $firstColVal]] $data] {
		set name [lindex $w 0]
		set value [lindex $w 1]
		
# 		puts "x: [encoding system]"
# 		puts "data: $name [encoding convertto utf-8 $value]"
		set lowerName [string tolower $name]
		set c $_colItem($lowerName)
		$_tree item style set $it $c s_text
		if {[$_db isNull $value]} {
			setNullStyle $it $c $value
		} else {
			unsetNullStyle $it $c $value
		}
		$_tree item lastchild root $it
	}
	set _rowItemNum($it) $_rowNum
	incr _rowNum
	set _rowId($it) $rowid
	set _rowType($it) "regular"
	if {$refreshWidth} {
		refreshWidth
	}
}

body DataGrid::commitNewRowExternal {} {
	# It's called from "form view" for example
	if {$_newRow == ""} {return 0}
	set _rowType($_newRow) regular
	#$_tree item element configure $_newRow 0 e_text -text $_rowItemNum($_newRow) -fill $foreground_color -font [list $font]
	#$_tableWin disableNewRowBtns
	set _newRow ""
	return 0
}

body DataGrid::commitNewRow {} {
	if {$_newRow == ""} {return 0}
	markForCommit $_newRow "" "new" $_newRow ""
	set _newRow ""
	return 0
}

body DataGrid::setRowValueForAllCells {item value} {
	set colId [$_tree column id "first"]
	for {set i -1} {$colId != "" && $colId != "tail"} {incr i} {
		if {$i < 0} {
			set colId [$_tree column id "$colId next"]
			continue
		}
		if {[$_db isNull $value]} {
			$_tree item element configure [lindex $item 0] $colId e_text -text "NULL" -fill $null_foreground_color -data "null" -font [list $italicFont]
		} else {
			$_tree item element configure [lindex $item 0] $colId e_text -text $value -data "" -fill $foreground_color -font [list $font]
		}
		set colId [$_tree column id "$colId next"]
	}
}

body DataGrid::setRowData {item data} {
	set colId [$_tree column id "first"]
	for {set i -1} {$colId != "" && $colId != "tail"} {incr i} {
		if {$i < 0} {
			set colId [$_tree column id "$colId next"]
			continue
		}
		set val [lindex $data $i]
		if {[$_db isNull $val]} {
			$_tree item element configure [lindex $item 0] $colId e_text -text "NULL" -fill $null_foreground_color -data "null" -font [list $italicFont]
		} else {
			$_tree item element configure [lindex $item 0] $colId e_text -text $val -data "" -fill $foreground_color -font [list $font]
		}
		set colId [$_tree column id "$colId next"]
	}
}

body DataGrid::delRow {it} {
	foreach idx [array names _toCommit $it:*] {
		unset _toCommit($idx)
	}
	if {$it == $_newRow} {
		set _newRow ""
	}
	return [Grid::delRow $it]
}

body DataGrid::delRows {} {
	Grid::delRows
	array unset _toCommit
	array unset _rowItemNum
	array unset _rowId
	array unset _rowType
	array set _toCommit {}
}

body DataGrid::reset {} {
	Grid::reset
	catch {array unset _toCommit}
	array set _toCommit {}

	set _newRow ""
	set firstCol [lindex $_cols 0]

	set tmpItem $_colItem(#)
	catch {array unset _colItem}
	set _colItem(#) $tmpItem

	set it $_colItem(#)
	foreach varName [list _colPk _colNotNull _colDefault _colDescription] {
		set tmpItem [set ${varName}($it)]
		catch {array unset ${varName}}
		set ${varName}($it) $tmpItem
	}

	set _selected ""
}

body DataGrid::delSelected {} {
	if {$_selected == ""} {return 0}

	set toRollbackAll [list]
	foreach rowItem [getMarkedRows] {
		# In case of deleting new row
		lassign $rowItem it col
		if {[info exists _toCommit($it:)]} {
			lassign $_toCommit($it:) type data oldData
			if {$type == "new"} {
				lappend toRollbackAll [list $it ""]
				continue
			} elseif {$type == "del"} {
				continue
			}
		}

		markForCommit $rowItem "" "del" $_rowId($rowItem) [getRowDataWithNull $rowItem]
	}

	if {[llength $toRollbackAll] > 0} {
		set _newRow "" ;# this is necessary to be done here, because rollbackAll -> delRow -> setSelection -> setActive -> commitNewRow
		rollbackAll $toRollbackAll
	}
	return 0
}

body DataGrid::commitPendingNewRow {it} {
	if {$it == ""} {return 0}
	set dialect [$_db getDialect]
	set id ""
	set sql "INSERT INTO [wrapObjName $_table $dialect] "
	set cols [list]
	set vals [list]
	set nulls [list]
	foreach c [lrange $_cols 1 end] {
		lappend cols $_colName($c)
	}
	array set colData {}
	foreach colName $cols {
		set c $_colItem([string tolower $colName])
		set type $_colType($c)
		if {[$_tree item element cget $it $c e_text -data] == "null"} {
			lappend nulls 1
			set val ""
		} else {
			lappend nulls 0
			set val [$_tree item element cget $it $c e_text -text]
		}
		set colData($colName) $val
		lappend vals $colData($colName)
		#lappend vals $val
	}

	# Filtering optional columns
	array set pk {
		predefined 0
		value ""
	}
	set realCols [list]
	set realValsVars [list]
	foreach c $cols v $vals nil $nulls {
		set colIt $_colItem([string tolower $c])
		set v2 $v
		if {$nil} {
			if {$_colPk($colIt) && [llength $cols] > 1} {
				# PK but with more columns
				continue
			} elseif {$_colDefault($colIt) != "" && ![$_db isNull $_colDefault($colIt)]} {
				# Null, but DEFAULT is defind.
				continue
			} elseif {$_colPk($colIt)} {
				# PK as single column
				if {$nil && $_colNotNull($colIt)} {
					# MaxID
					set maxId [$_db onecolumn [encode "SELECT max([wrapObjName $c $dialect]) FROM [wrapObjName $_table $dialect]"]]
					if {[$_db isNull $maxId]} {
						set maxId 0
					} else {
						incr maxId
					}
					set nil 0
					set v $maxId
				}
			} elseif {$_colNotNull($colIt)} {
				Warning [mc {%s column has NOT NULL constraint. You have to fill value for it.} $c]
				return 1
			}
		} elseif {$_colPk($colIt)} {
			set pk(predefined) 1
			set pk(value) $v
		}
		set colNameAttached [::md5::md5 [join $c _]]
		if {[isNumericColumn $colIt] && ([string is double $v] || [string is wideinteger $v])} {
			if {$v == 0} {
				set value_$colNameAttached [expr {$v}]
			} else {
				set value_$colNameAttached [expr {[string trimleft $v 0]}]
			}
		} else {
			set value_$colNameAttached $v
		}
		if {$nil} {
			lappend realValsVars "null"
		} else {
			lappend realValsVars \$value_$colNameAttached
		}
		lappend realCols $c
	}

	# Getting all togather and executing
	if {[llength $realCols] == 0} {
		append sql "DEFAULT VALUES;"
	} else {
		append sql "("
		append sql [join [wrapColNames $realCols $dialect] ","]
		append sql ") VALUES ("
		append sql [join $realValsVars ","]
		append sql ");"
	}
		append sql "SELECT ROWID as id FROM [wrapObjName $_table $dialect] ORDER BY ROWID DESC LIMIT 1;"
	if {[catch {
		set id [$_db onecolumn [encode $sql]]
	} res]} {
		cutOffStdTclErr res
		Error [mc "Error while adding new row:\n%s" $res]
		return 1 ;# 1 means reedit value
	}

	# If some error occured durinc query execution, we won't get ROWID.
	if {[string trim $id] == ""} {
		return 1 ;# 1 means reedit value
	}
	$_tree item element configure $it 0 e_text -text $_rowItemNum($it) -fill $foreground_color -font [list $font]
	set _rowType($it) regular
	set _rowId($it) $id


	# Tricky fix for bug (win32, sqlite2, UTF-8 chars): http://forum.sqlitestudio.pl/viewtopic.php?f=4&t=3860
	if {[$_db getDialect] == "sqlite2" && [os] == "win32"} {
		set sql "UPDATE [wrapObjName $_table $dialect] SET "
		set pairs [list]
		foreach col [wrapColNames $realCols $dialect] var $realValsVars {
			lappend pairs "$col = $var"
		}
		append sql [join $pairs ", "]
		append sql " WHERE ROWID = $id"
		if {[catch {
			$_db eval $sql
		} res]} {
			cutOffStdTclErr res
			Error [mc "Error while updating new row:\n%s" $res]
			return 1 ;# 1 means reedit value
		}
	}

	# Refreshing inserted data (defaults, PKS, etc)
	set newRowData [list]
	$_db eval "SELECT * FROM [wrapObjName $_table $dialect] WHERE ROWID = $id" R {
		foreach cid $R(*) {
			lappend newRowData $R($cid)
		}
	}
	setRowData $it $newRowData
	#$_tree item lastchild root $newRow
	#renumberRows

	#set newRow ""
	return 0
}

body DataGrid::commitPendingRowEdit {it col value} {
	lassign $value valueData null
	# Calling an update
	if {[catch {
		if {$null} {
			set finalValue "NULL"
		} elseif {[isNumericColumn $col] && ([string is double $valueData] || [string is wideinteger $valueData])} {
			if {$valueData == 0} {
				set valueData [expr {$valueData}]
			} else {
				set valueData [expr {[string trimleft $valueData 0]}]
			}
			set finalValue {$valueData}
		} else {
			set finalValue {$valueData}
		}
		set q "UPDATE [wrapObjName $_table [$_db getDialect]] SET [wrapObjName [$_tree column cget $col -text] [$_db getDialect]] = $finalValue WHERE ROWID = $_rowId($it)"
		$_db eval $q
	} res]} {
		cutOffStdTclErr res
		set dialog [YesNoDialog .editError[randcrap 3] -message [mc "Error while updating cell value:\n%s\n\nWhat would you like to do?" $res] \
			-first [mc {Re-edit value}] -firsticon "" -second [mc {Return to value before edition}] -secondicon "" \
			-type error -title [mc {Error}]]
		if {![$dialog exec]} {
			rollbackEdit [list $it $col]
# 			unmarkForCommit $it $col
			return 2 ;# 2 means return to previous value
		}
		# It's necessary to force update before focusing edit widget,
		# because of FocusOut event on that widget.
		# No longer true.
# 		update
# 		after 1
# 		update
		focus $_editItem
		return 1
	} else {
		# Refreshing ROWID if needed (only if modified column was PK = ROWID).
		if {$_colPk($col)} {
			set description [getHelpHintdata $col]
			if {[string toupper [dict get $description type]] == "INTEGER"} {
				set _rowId($it) $valueData
			}
		}
	}
	return 0
}

body DataGrid::commitPendingRowDeletion {it rowId} {
	if {[catch {
		$_db eval "DELETE FROM [wrapObjName $_table [$_db getDialect]] WHERE ROWID = $rowId"
	} error]} {
		set errCode [$_db errorcode]
		switch -- $errCode {
			19 {
				cutOffStdTclErr error
				Warning [mc "Cannot delete row(s), because it violates constraint. Details:\n%s" $error]
			}
			default {
				Error [mc "Error while deleting selected rows:\n%s" $error]
			}
		}
		return 1
	}
	delRow $it
	return 0
}

body DataGrid::deleteCurrentRow {} {
	delSelected
}

body DataGrid::setActive {item column} {
	if {$_newRow != "" && $item != $_newRow} {
		if {$_editItem != ""} {
			eval [bind $_editItem <FocusOut>]
		}
		if {[commitNewRow]} return
	}
	Grid::setActive $item $column
}

body DataGrid::getSelectedRowId {} {
	if {$_selected == ""} {
		return ""
	}
	set item $_selected

	return $_rowId([lindex $item 0])
}

body DataGrid::setSelectedRowId {rowid} {
	if {$_selected == ""} {
		return ""
	}
	set item $_selected
	set _rowId([lindex $item 0]) $rowid
}

body DataGrid::updateShortcuts {} {
	bind $_tree <${::Shortcuts::deleteRow}> [list $this deleteCurrentRow]
	bind $_tree <${::Shortcuts::insertRow}> [list $this addRow "" "" 1]
	bind $_tree <${::Shortcuts::eraseRow}> [list $this clearCurrentCell]
	bind $_tree <${::Shortcuts::editInBlobEditor}> [list $this editSelectedInEditor]
}

body DataGrid::clearShortcuts {} {
	bind $_tree <${::Shortcuts::deleteRow}> ""
	bind $_tree <${::Shortcuts::insertRow}> ""
	bind $_tree <${::Shortcuts::eraseRow}> ""
}

body DataGrid::handleClick {x y {modifiers ""}} {
	Grid::handleClick $x $y
	set item [$_tree identify $x $y]
	switch -- [lindex $item 0] {
		"header" {
			if {[lindex $item 2] != ""} return
			handleHeaderClicked [lindex $item 1]
		}
		"item" {
			# Selecting entire row
			if {[dict get $item column] == [lindex $_cols 0] || $modifiers == "control"} {
				markRow [dict get $item item]
			}
		}
	}
}

body DataGrid::handleDoubleClick {x y {modifiers ""}} {
	Grid::handleDoubleClick $x $y
	set item [$_tree identify $x $y]
	switch -- [lindex $item 0] {
		"header" {
			if {[lindex $item 2] != ""} return
			handleHeaderClicked [lindex $item 1]
		}
	}
}

body DataGrid::handleHeaderClicked {columnId} {
 	if {$columnId == [$_tree column id "first"]} return
	if {$columnId == "tail"} return
	set direction "ASC"
	set arr "down"
	set currArr [$_tree column cget $columnId -arrow]
	if {$currArr != "none"} {
		if {$currArr == "down"} {
			set direction DESC
			set arr "up"
		} else {
			set direction ASC
			set arr "down"
		}
	} else {
		# Clearing other column from arrow
		foreach c $_cols {
			$_tree column configure $c -arrow none
		}
	}
	set colText [$_tree column cget $columnId -text]
	{*}$_sortChangeCommand $colText $direction

	# Now, after data is refreshed, we need to search column by text,
	# to get column ID in new columns set.
	set columnId ""
	foreach c $_cols {
		if {[$_tree column cget $c -text] == $colText} {
			set columnId $c
		}
	}
	if {$columnId == ""} {
		puts stderr "Assert: Cannot find column after changing sort order."
		return
	}
	$_tree column configure $columnId -arrow $arr
}

body DataGrid::setSortChangeCommand {cmd} {
	set _sortChangeCommand $cmd
}

body DataGrid::duplicateRow {} {
	if {$_selected == ""} return
	if {$_marked != "" && $_marked != $_selected} return
	set dataWithNull [lrange [getSelectedRowDataWithNull] 1 end]
	set data [list]
	foreach col $dataWithNull {
		if {[lindex $col 1]} {
			lappend data ""
		} else {
			lappend data [lindex $col 0]
		}
	}
	set it [addRow "" "" 1]
	setRowData [list $it ""] $data
}

body DataGrid::paste {} {
	if {![Grid::paste]} return
	set start [getTopLeftMarkedCell]
	if {$start == ""} return

	set rows [Grid::processClipboardForPaste $start]
	if {$rows == ""} return

	# Pasting into pending commits
	lassign $start it col
	set startCol $col
	set startRow $it
	for {set rowIdx 0} {$it != "" && $rowIdx < [llength $rows]} {incr rowIdx} {
		set col $startCol
		set row [lindex $rows $rowIdx]
		set sqlCols [list]
		for {set colIdx 0} {$col != "" && $col != "tail" && $colIdx < [llength $row]} {incr colIdx} {
			#set sqlValue_$colIdx [lindex $row $colIdx]
			markForCommit $it $col "edit" [list [lindex $row $colIdx] 0] [getCellDataWithNull $it $col]
			set col [$_tree column id "$col next"]
		}
		set it [$_tree item id "$it next visible"]
	}

	# Pasting into grid cells
	set it $startRow
	for {set rowIdx 0} {$it != "" && $rowIdx < [llength $rows]} {incr rowIdx} {
		set col $startCol
		set row [lindex $rows $rowIdx]
		for {set colIdx 0} {$col != "" && $col != "tail" && $colIdx < [llength $row]} {incr colIdx} {
			set colData [lindex $row $colIdx]
			$_tree item element configure $it $col e_text -text $colData -data "" -fill $foreground_color -font [list $font]
			set col [$_tree column id "$col next"]
		}
		set it [$_tree item id "$it next visible"]
	}
	refreshWidth
}

body DataGrid::renumberRows {} {
	set _rowNum [$_tableWin getBaseRowNum]
	set col [$_tree column id "first"]
	set it [$_tree item id "root firstchild visible"]
	while {$it != ""} {
		#if {[$_tree item element cget $it $col e_text -text] ni [list "*" "-"]} {
			set firstColVal $_rowNum
			if {$_displayRowId} {
				set firstColVal $_rowId($it)
			}
			$_tree item element configure $it $col e_text -text $firstColVal
		#}
		set _rowItemNum($it) $_rowNum
		set it [$_tree item id "$it next visible"]
		incr _rowNum
	}
	$_tableWin refreshTotalNumberOfRows
	refreshWidth
}

body DataGrid::getRowId {it col} {
	return $_rowId($it)
}

body DataGrid::getColumnTable {col} {
	return $_table
}

body DataGrid::prepareColumnsForCommits {type cols} {
}

body DataGrid::cleanupColumnsAfterCommits {type cols successfulCommit} {
}

body DataGrid::createSelectFromMarked {} {
	set area [getMarkedArea]
	if {[llength $area] == 0} {
		return
	}

	set dialect [$_db getDialect]

	# Determinating selected columns and values for them
	array set values {}
	array set nulls {}
	array set idxTranslation {}
	foreach cell [lindex $area 0] {
		lassign $cell it col
		set values($col) [list]
		set nulls($col) 0
	}
	
	foreach row $area {
		foreach cell $row {
			lassign $cell it col
			lassign [getCellDataWithNull $it $col] data isnull
			if {$isnull} {
				set nulls($col) 1
			} elseif {$data ni $values($col)} {
				lappend values($col) $data
			}
		}
	}

	# Generating condition tokens
	set condition [list]
	foreach col [array names values] {
		set colName [wrapObjIfNeeded $_colName($col) $dialect]
		
		# Values
		set valueCondition [list]
		set valLgt [llength $values($col)]
		if {$valLgt > 0} {
			lappend valueCondition $colName
			
			if {$valLgt > 1} {
				lappend valueCondition IN "("
			} else {
				lappend valueCondition "="
			}
			
			foreach val $values($col) {
				if {$val != "" && [string is integer $val] || [string is double $val]} {
					lappend valueCondition $val
				} else {
					lappend valueCondition [wrapString $val]
				}
				lappend valueCondition ","
			}
			
			set valueCondition [lrange $valueCondition 0 end-1] ;# remove last period
			if {$valLgt > 1} {
				lappend valueCondition ")"
			}
		}
		
		# NULLs
		set nullCondition [list]
		if {$nulls($col) > 0} {
			lappend nullCondition $colName IS NULL
		}
		
		set valueTokenCnt [llength $valueCondition]
		set nullTokenCnt [llength $nullCondition]
		if {$valueTokenCnt > 0 && $nullTokenCnt > 0} {
			lappend condition "(" {*}$valueCondition OR {*}$nullCondition ")"
		} elseif {$valueTokenCnt > 0} {
			lappend condition {*}$valueCondition
		} elseif {$nullTokenCnt > 0} {
			lappend condition {*}$nullCondition
		}
		lappend condition AND
	}
	set condition [lrange $condition 0 end-1] ;# remove last AND
	set condition [join $condition " "]
	
	set e [MAIN openSqlEditor]
	if {$e == ""} {
		debug "Could not open editor!"
		return
	}

	set sql "SELECT * FROM [wrapObjIfNeeded $_table $dialect] WHERE $condition"
	set sql [Formatter::format $sql $_db]
	
	set date [clock format [clock seconds] -format %c]
	set win [$_parent getTitle]
	set commentStr [mc "SQL query generated at %s\nusing selected cells from window '%s'." $date $win]
	set comment "-- "
	append comment [join [split $commentStr \n] "\n-- "]
	append comment "\n--\n"

	$e setDatabase $_db
	$e setSQL "$comment\n$sql"
}
