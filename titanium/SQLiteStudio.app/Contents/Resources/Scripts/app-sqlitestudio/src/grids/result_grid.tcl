use src/grids/dbgrid.tcl
use src/grid_hints.tcl

class ResultGrid {
	inherit DBGrid Shortcuts GridHints

	common realFormat {%1.1f}

	constructor {args} {
		DBGrid::constructor {*}$args -multicell 1 -readonly 0
	} {}

	private {
		variable _tableCols
		variable _colTable
		variable _colDatabase
		variable _column

		#>
		# @var _contextMenu
		# Context menu widget.
		#<
		variable _contextMenu ""
	}

	protected {
		method getValueForEdit {it col}
		method prepareColumnsForCommits {type cols}
		method cleanupColumnsAfterCommits {type cols successfulCommit}
		method canCommitEdit {it col}
		method copyValueToLinkedCells {srcDatabase srcTable srcColumn srcRowId srcIt srcCol value}
	}

	public {
		method addColumn {columnDict rowType}
		method edit {item {forceBlobMode false}}
		#>
		# @method addRow
		# @param data List of row values. Each value for one column.
		# Adds new row and increments row number ({@_rowNum}).
		# This implementation supports NULL values using informations from database handler.
		# @overload Grid
		# @return New row ID (related to <b>TkTreeCtrl</b>).
		#<
		method addRow {data rowids {refreshWidth true}}
		method getColumns {{includeRowNum false}}
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
		# @method contextMenuPopup
		# @param x X coordinate to post the menu at.
		# @param y Y coordinate to post the menu at.
		# Pops up the context menu at given coordinates and selects cell under these coordinates.
		# If there is no row or column at X-Y, then nothing happens.
		#<
		method contextMenuPopup {x y}

		#>
		# @method takeFocus
		# Forces focus for {@var _tree} widget.
		#<
		method takeFocus {}

		method getTableForColumn {col}
		method refreshTableColumns {}
		method getRowId {it {col ""}}
		method getColumnTable {col}
		method commitPendingRowEdit {it col value}
		method renumberRows {}
		method isEditPossible {it col}
		method fillHint {it col hintTable}
		method handleClick {x y {modifiers ""}}

		#>
		# @method updateShortcuts
		# @overloaded Shortcuts
		#<
		method updateShortcuts {}
		method clearShortcuts {}

		#>
		# @method reset
		# @overloaded Grid
		#<
		method reset {}

		#>
		# @method paste
		# @overloaded Grid
		#<
		method paste {}

		method createSelectFromMarked {}
		method isRowNew {it}
		method isSelectedRowNew {}
	}
}

body ResultGrid::constructor {args} {
	set _tableCols() ""
	set _contextMenu [menu $_tree.cm -borderwidth 1 -activeborderwidth 1 -tearoff 0]
	initHints $_tree
	bind $_tree <Button-$::RIGHT_BUTTON> "$this contextMenuPopup %x %y; tk_popup $_contextMenu %X %Y"
	bind $_tree <Any-Key> [list $this checkForEdit %A %A %s]
	bind $_tree <BackSpace> [list $this clearCurrentCell]
	eval itk_initialize $args
}

body ResultGrid::contextMenuPopup {x y} {
	set item [$_tree identify $x $y]
	if {[lindex $item 0] != "item"} return
	if {[lindex $item 3] == "0"} return

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

	$_contextMenu delete 0 end
	if {[llength $rows] > 0} {
		set editable [isEditPossible $it $col]
		if {$editable} {
			$_contextMenu add command -compound left -image img_edit_cell -label [mc "Edit cell value"] -command [list $this edit [list $it $col]]
			$_contextMenu add command -compound left -image img_edit_blob -label [mc "Edit cell value in BLOB editor"] -command [list $this edit [list $it $col] true]
			$_contextMenu add command -compound left -image img_setnull -label [mc "Set NULL value"] -command [list $this setMassNull $markedItems]
			$_contextMenu add separator
		}
		$_contextMenu add command -compound left -image img_wand -label [mc "Generate SELECT from selected cells"] -command [list $this createSelectFromMarked]
		$_contextMenu add separator
		$_contextMenu add command -compound left -image img_select_all_square -label [mc "Select all"] -command [list $this selectAll]
		$_contextMenu add command -compound left -image img_copy -label [mc "Copy"] -command [list $this copyMarked]
		if {$editable} {
			$_contextMenu add command -compound left -image img_paste -label [mc "Paste"] -command [list $this paste]
		}
	}
	leaveWidget ;# MacOSX needs this
}

body ResultGrid::addColumn {columnDict rowType} {
	# This is necessary because Grid::constructor uses it to add rownum column
	# and it doesn't pass entire dict, just single "#".
	if {$rowType == "rownum"} {
		set c [Grid::addColumn $columnDict $rowType]
		set _column($c) ""
		set _colTable($c) ""
		set _colDatabase($c) ""
		return $c
	}

	set name [dict get $columnDict displayName]

	# Find unique name
	set tempName $name
	set i 1
	while {[columnExists $tempName]} {
		set tempName "$name:$i"
		incr i
	}
	set name $tempName

	# Extract desctiption
	set database [dict get $columnDict database]
	set table [dict get $columnDict table]
	set column [dict get $columnDict column]
	set type [dict get $columnDict type]

	# Find out column type
	if {$type == ""} {
		set type "text"
	} elseif {[string match "*(*)" $type]} {
		set type [lindex [regexp -inline {(.*)\(.*\)} $type] 1]
	}
	set type [string tolower [string trim $type]]

	if {$type in [list "window" "image"]} {
		# This is specific type. We cannot use it as a type.
		set type "text"
	}

	set c [Grid::addColumn $name $type]
	set _column($c) $column
	set _colTable($c) $table
	set _colDatabase($c) $database
	return $c
}

body ResultGrid::refreshTableColumns {} {
	foreach c $_cols {
		set db [DBTREE getDBByName $_colDatabase($c)]

		foreach row [$_db getTableInfo $_colTable($c) $db] {
			if {[string equal -nocase [dict get $row name] $_column($c)]} {
				set type [dict get $row type]
				if {[string match "*(*)" $type]} {
					set type [lindex [regexp -inline {(.*)\(.*\)} $type] 1]
				}
				set type [string tolower [string trim $type]]

				set _colType($c) $type
				break
			}
		}
	}
}

body ResultGrid::getValueForEdit {it col} {
	if {[isRowPendingForCommit $it]} {
		if {[$_tree item element cget $it $col e_text -data] == "null"} {
			set value [list "" 1]
		} else {
			set value [list [$_tree item element cget $it $col e_text -text] 0]
		}
	} else {
		set dataSource [wrapObjName $_colTable($col) [$_db getDialect]]
		if {$_colDatabase($col) != ""} {
			set db [DBTREE getDBByName $_colDatabase($col)]
			set attachName [$_db attach $db]
			set dataSource "$attachName.$dataSource"
		}
		if {[catch {$_db onecolumn "SELECT [wrapObjName $_column($col) [$_db getDialect]] FROM $dataSource WHERE ROWID = $_rowId($it:$col)"} value]} {
			set value [list "" 1] ;# table was most probably deleted
		} else {
			set value [list $value 0]
		}
		if {$_colDatabase($col) != ""} {
			$_db detach $db
		}
		if {[$_db isNull [lindex $value 0]]} {
			set value [list "" 1]
		}
	}
	return $value
}

body ResultGrid::edit {item {forceBlobMode false}} {
	set result [DBGrid::edit $item $forceBlobMode]
	if {!$result} {
		if {$_parent != ""} {
			lassign $item it col
			set status [$_parent getStatusField]
			$status addMessage "\n"
			$status addMessage [mc {Column '%s' is not editable. Only columns with corresponding ROWID in the table are editable or SQL query was too complicated.} $_colName($col)] error
		}
	}
	return $result
}

body ResultGrid::canCommitEdit {it col} {
	return true
}

body ResultGrid::addRow {data rowids {refreshWidth true}} {
	set it [Grid::addRow $data $refreshWidth]

	foreach c [lrange $_cols 1 end] w $data rowid $rowids {
		set _rowId($it:$c) $rowid
		if {[$_db isNull $w]} {
			setNullStyle $it $c $w
		}
	}
}

body ResultGrid::getColumns {{includeRowNum false}} {
	set cols [$_tree column list]
	if {$itk_option(-basecol) && !$includeRowNum} {
		set cols [lrange $cols 1 end]
	}
	set list [list]
	foreach c $cols {
		lappend list [list $c $_column($c) $_colType($c) $_colTable($c) $_colDatabase($c)]
	}
	return $list
}

body ResultGrid::setRowData {item data} {
	set colId [$_tree column id 0]
	for {set i -1} {$colId != "" && $colId != "tail"} {incr i} {
		if {$i < 0} {
			set colId [$_tree column id "$colId next"]
			continue
		}
		set val [lindex $data $i]
		if {[$_db isNull $val]} {
			set f [concat $font italic]
			$_tree item element configure [lindex $item 0] $colId e_text -text "NULL" -fill $null_foreground_color -data "null" -font [list $f]
		} else {
			$_tree item element configure [lindex $item 0] $colId e_text -text $val -data "" -fill $foreground_color -font [list $font]
		}
		set colId [$_tree column id "$colId next"]
	}
	refreshWidth
}

body ResultGrid::takeFocus {} {
	focus $_tree
}

body ResultGrid::getTableForColumn {col} {
	if {[info exists _colTable($col)]} {
		return $_colTable($col)
	} else {
		return ""
	}
}

body ResultGrid::fillHint {it col hintTable} {
	$hintTable setTitle [mc {Column: %s} $_colName($col)]

	# Rest of rows
	if {[info exists _rowId($it:$col)]} {
		set rowid $_rowId($it:$col)
	} else {
		set rowid ""
	}

	set dialect [$_db getDialect]

	set itemsToDisplay 0
	foreach var {
		colDb
		colTable
		type
		rowId
	} label [list \
		[mc {Database:}] \
		[mc {Table:}] \
		[mc {Data type:}] \
		{ROWID:} \
	] value [list \
		$_colDatabase($col) \
		$_colTable($col) \
		$_colType($col) \
		$rowid \
	] {
		if {$var == "colDb" && $_colDatabase($col) == ""} {
			continue ;# this column isn't directly related to table, is result of expression, or alias
		}

		if {$var == "colTable" && $_colTable($col) == ""} {
			continue ;# this column isn't directly related to table, is result of expression, or alias
		}

		if {$var == "rowId" && $rowid == ""} {
			continue ;# usually same case as above
		}

		$hintTable addRow $label $value
		incr itemsToDisplay
	}

	if {$itemsToDisplay == 0} {
		$hintTable setMode "-label"
		$hintTable addRow "" [mc {No details are available on this cell.}]
	}
}

body ResultGrid::paste {} {
	if {![Grid::paste]} return
	set start [getTopLeftMarkedCell]
	if {$start == ""} return

	set rows [Grid::processClipboardForPaste $start]
	if {$rows == ""} return

	lassign $start it col
	set startCol $col
	set startRow $it

	# Detecting multiple rows with same rowId
	set it $startRow
	set duplicateRowId ""
	array set rowIdsByColumn {}
	for {set rowIdx 0} {$it != "" && $rowIdx < [llength $rows]} {incr rowIdx} {
		set col $startCol
		set row [lindex $rows $rowIdx]
		for {set colIdx 0} {$col != "" && $col != "tail" && $colIdx < [llength $row]} {incr colIdx} {
			if {![info exists _rowId($it:$col)]} continue
			set rowid $_rowId($it:$col)
			if {$rowid == "" || [$_db isNull $rowid]} continue
			if {![info exists rowIdsByColumn($col)]} {
				set rowIdsByColumn($col) [list $rowid]
			} else {
				if {$rowid in $rowIdsByColumn($col)} {
					set duplicateRowId [list $rowid $_colName($col)]
					break
				}
				lappend rowIdsByColumn($col) $rowid
			}
			set col [$_tree column id "$col next"]
		}
		set it [$_tree item id "$it next visible"]
	}
	if {$duplicateRowId != ""} {
		set dialog [YesNoDialog .yesno -title [mc {Duplicated ROWID}] -message [mc "There is more than one row with ROWID=%s affected by paste operation.\nIn this case unpredictable results may occure. Proceed?" [lindex $duplicateRowId 0]]]
		if {![$dialog exec]} {
			return
		}
	}

	# Pasting into pending commits
	set it $startRow
	for {set rowIdx 0} {$it != "" && $rowIdx < [llength $rows]} {incr rowIdx} {
		set col $startCol
		set row [lindex $rows $rowIdx]
		for {set colIdx 0} {$col != "" && $col != "tail" && $colIdx < [llength $row]} {incr colIdx} {
			set sqlValue [lindex $row $colIdx]
			if {![info exists _rowId($it:$col)]} continue
			set rowid $_rowId($it:$col)
			if {$rowid == "" || [$_db isNull $rowid]} continue

			# Executing update for single cell
			markForCommit $it $col "edit" [list $sqlValue 0] [getCellDataWithNull $it $col]
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
			if {![info exists _rowId($it:$col)]} continue
			set rowid $_rowId($it:$col)
			if {$rowid == "" || [$_db isNull $rowid]} continue
			$_tree item element configure $it $col e_text -text $colData -data "" -fill $foreground_color -font [list $font]
			set col [$_tree column id "$col next"]
		}
		set it [$_tree item id "$it next visible"]
	}

	refreshWidth
}

body ResultGrid::getColumnTable {col} {
	if {[info exists _colTable($col)]} {
		return $_colTable($col)
	} else {
		return ""
	}
}

body ResultGrid::getRowId {item {col ""}} {
	if {$col == ""} {
		lassign $item it col
	} else {
		set it $item
	}
	if {[info exists _rowId($it:$col)]} {
		return $_rowId($it:$col)
	} else {
		return ""
	}
}

body ResultGrid::reset {} {
	set firstCol [lindex $_cols 0]
	set tmpTable $_colTable($firstCol)
	set tmpDb $_colDatabase($firstCol)
	DBGrid::reset
	catch {array unset _colTable}
	catch {array unset _colDatabase}
	set _colTable($firstCol) $tmpTable
	set _colDatabase($firstCol) $tmpDb
}

body ResultGrid::commitPendingRowEdit {it col value} {
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

		set dataSource [wrapObjName $_colTable($col) [$_db getDialect]]
		if {$_colDatabase($col) != ""} {
			set db [DBTREE getDBByName $_colDatabase($col)]
			set attachName [$_db getAttachName $db]
			set dataSource "$attachName.$dataSource"
		}

		set q "UPDATE $dataSource SET [wrapObjName $_column($col) [$_db getDialect]] = $finalValue WHERE ROWID = $_rowId($it:$col)"
		$_db eval $q
		
		# Now copy the same value to other cells that reflect exactly the same database cell
		copyValueToLinkedCells $_colDatabase($col) $_colTable($col) $_column($col) $_rowId($it:$col) $it $col $value
	} res]} {
		cutOffStdTclErr res
		set dialog [YesNoDialog .editError[randcrap 3] -message [mc "Error while updating cell value:\n%s\n\nWhat would you like to do?" $res] \
			-first [mc {Re-edit value}] -firsticon "" -second [mc {Return to value before edition}] -secondicon "" \
			-type error -title [mc {Error}]]
		if {![$dialog exec]} {
			rollbackEdit
			return 2 ;# 2 means return to previous value
		}
		focus $_editItem
		return 1
	}
	return 0
}

body ResultGrid::copyValueToLinkedCells {srcDatabase srcTable srcColumn srcRowId srcIt srcCol value} {
	set rows [getAllRows]
	foreach col [lrange $_cols 1 end] {
		if {![string equal -nocase $_colDatabase($col) $srcDatabase]} continue
		if {![string equal -nocase $_colTable($col) $srcTable]} continue
		if {![string equal -nocase $_column($col) $srcColumn]} continue

		foreach it $rows {
			if {$_rowId($it:$col) != $srcRowId} continue
			if {$it == $srcIt && $col == $srcCol} continue ;# don't do this for the same cell

			setCellDataWithNull $it $col $value
		}
	}
}

body ResultGrid::renumberRows {} {
	# Doesn't need to do anything, since ResultGrid allows only to edit existing rows.
	# No deletion or adding is possible.
}

body ResultGrid::isEditPossible {it col} {
	expr {
		[info exists _rowId($it:)] && [lindex $_toCommit($it:) 0] == "new" || \
		[info exists _rowId($it:$col)] && $_rowId($it:$col) != "" && \
		![$_db isNull $_rowId($it:$col)] && \
		[info exists _colTable($col)] && $_colTable($col) != "" && \
		($_colDatabase($col) == "" || [DBTREE getDBByName $_colDatabase($col)] != "") &&
		![catch {$_db onecolumn "SELECT 1 FROM [wrapObjIfNeeded $_colTable($col) [$_db getDialect]]"}]
	}
}

body ResultGrid::updateShortcuts {} {
	bind $_tree <${::Shortcuts::eraseRow}> [list $this clearCurrentCell]
	bind $_tree <${::Shortcuts::editInBlobEditor}> [list $this editSelectedInEditor]
}

body ResultGrid::clearShortcuts {} {
	bind $_tree <${::Shortcuts::eraseRow}> ""
}

body ResultGrid::handleClick {x y {modifiers ""}} {
	Grid::handleClick $x $y
	set item [$_tree identify $x $y]
	switch -- [lindex $item 0] {
		"item" {
			# Selecting entire row
			if {[dict get $item column] == [lindex $_cols 0] || $modifiers == "control"} {
				markRow [dict get $item item]
			}
		}
	}
}

body ResultGrid::prepareColumnsForCommits {type cols} {
	if {$type == "all"} {
		set cols [lrange $_cols 1 end]
	}

	foreach c $cols {
		if {$_colDatabase($c) != ""} {
			set db [DBTREE getDBByName $_colDatabase($c)]
			$_db attach $db
		}
	}
}

body ResultGrid::cleanupColumnsAfterCommits {type cols successfulCommit} {
	if {$type == "all"} {
		set cols [lrange $_cols 1 end]
	}

	foreach c $cols {
		if {$_colDatabase($c) != ""} {
			set db [DBTREE getDBByName $_colDatabase($c)]
			$_db detach $db
		}
	}
}

body ResultGrid::createSelectFromMarked {} {
	# Validating and parsing
	if {$_parent == ""} return

	set area [getMarkedArea]
	
	if {[llength $area] == 0} {
		return
	}

	set dialect [$_db getDialect]
	set status [$_parent getStatusField]
	set query [$_parent getQueryForExport]
	set parser [itcl::local UniversalParser #auto $_db]
	$parser configure -expectedTokenParsing false
	
	lassign [$parser parseSql $query] parsedDict expectedDict
	if {[dict get $parsedDict returnCode] != 0} {
		$status addMessage [mc {Could not parse SQL while trying to generate requested query: %s}] error
		return
	}
	
	set parsedObj [dict get $parsedDict object]
	if {[$parsedObj cget -branchName] != "selectStmt"} {
		set stmt [lindex [$parsedObj cget -allTokens] 0 1]
		$status addMessage [mc {Cannot use '%s' statement to generate requested query.} [string toupper $stmt]] error
		return
	}
	if {[$parsedObj cget -explainKeyword]} {
		$status addMessage [mc {Cannot use '%s' statement to generate requested query.} "EXPLAIN"] error
		return
	}
	
	# Determinating column list of the query
	set viewName [wrapObjIfNeeded [$_db getUniqueObjName "temp_view"] $dialect]
	set columns [list]
	$_db eval "CREATE TEMP VIEW $viewName AS $query"
	foreach col [$_db getTableInfo $viewName] {
		lappend columns [dict get $col name]
	}
	$_db eval "DROP VIEW $viewName"

	# Extracting original tokens
	set select [$parsedObj getValue subStatement]
	set core [lindex [$select cget -selectCores] end] ;# shouldn't be more than 1 core
	set where [$core cget -where]
	set having [$core cget -having]
	set groupBy [$core cget -groupBy]
	set coreTokens [$core cget -allTokens]
	set allTokens [$select cget -allTokens]
 
	# Determinating selected columns and values for them
	array set values {}
	array set nulls {}
	array set idxTranslation {}
	foreach cell [lindex $area 0] {
		lassign $cell it col
		set colIdx [getColumnIndexById $col false]
		if {$colIdx < 0} {
			set err [mc {Cannot determinate selected column with ID=%s.} $ID]
			$status addMessage [mc {Error occurred while trying to generate the query: %s} $err] error
			return
		}
		set values($col) [list]
		set nulls($col) 0
		set idxTranslation($colIdx) $col
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
	set conditionTokens [list]
	foreach colIdx [array names idxTranslation] {
		set col $idxTranslation($colIdx)
		# If wrapping is enabled here, than "HAVING sum(col)" gets wrapped
		#set colName [wrapObjIfNeeded [lindex $columns $colIdx] $dialect]
		set colName [lindex $columns $colIdx]
		
		# Values
		set valueConditionTokens [list]
		set valLgt [llength $values($col)]
		if {$valLgt > 0} {
			lappend valueConditionTokens [list OTHER $colName 0 0]
			
			if {$valLgt > 1} {
				lappend valueConditionTokens [list KEYWORD IN 0 0]
				lappend valueConditionTokens [list PAR_LEFT "(" 0 0]
			} else {
				lappend valueConditionTokens [list OPERATOR "=" 0 0]
			}
			
			foreach val $values($col) {
				if {$val != "" && [string is integer $val]} {
					lappend valueConditionTokens [list INTEGER $val 0 0]
				} elseif {$val != "" && [string is double $val]} {
					lappend valueConditionTokens [list FLOAT $val 0 0]
				} else {
					lappend valueConditionTokens [list STRING [wrapString $val] 0 0]
				}
				lappend valueConditionTokens [list OPERATOR "," 0 0]
			}
			
			set valueConditionTokens [lrange $valueConditionTokens 0 end-1] ;# remove last period
			if {$valLgt > 1} {
				lappend valueConditionTokens [list PAR_RIGHT ")" 0 0]
			}
		}
		
		# NULLs
		set nullConditionTokens [list]
		if {$nulls($col) > 0} {
			lappend nullConditionTokens [list OTHER $colName 0 0]
			lappend nullConditionTokens [list KEYWORD IS 0 0]
			lappend nullConditionTokens [list KEYWORD NULL 0 0]
		}
		
		set valueTokenCnt [llength $valueConditionTokens]
		set nullTokenCnt [llength $nullConditionTokens]
		if {$valueTokenCnt > 0 && $nullTokenCnt > 0} {
			lappend conditionTokens [list PAR_LEFT "(" 0 0]
			lappend conditionTokens {*}$valueConditionTokens
			lappend conditionTokens [list KEYWORD OR 0 0]
			lappend conditionTokens {*}$nullConditionTokens
			lappend conditionTokens [list PAR_RIGHT ")" 0 0]
		} elseif {$valueTokenCnt > 0} {
			lappend conditionTokens {*}$valueConditionTokens
		} elseif {$nullTokenCnt > 0} {
			lappend conditionTokens {*}$nullConditionTokens
		}
		lappend conditionTokens [list KEYWORD AND 0 0]
	}
	set conditionTokens [lrange $conditionTokens 0 end-1] ;# remove last AND

	# WHERE/HAVING or no condition yet?
	if {$having != ""} {
		set mode "having"
	} elseif {$groupBy != ""} {
		set mode "group"
	} elseif {$where != ""} {
		set mode "where"
	} else {
		set mode "none"
	}

	# Find out where to put new tokens and generate new token sets
	switch -- $mode {
		"having" - "where" {
			if {$mode == "having"} {
				set origTokens [$having cget -allTokens]
			} else {
				set origTokens [$where cget -allTokens]
			}
			set startIdx [lsearch -exact $allTokens [lindex $origTokens 0]]
			set endIdx [lsearch -exact $allTokens [lindex $origTokens end]]

			set tokens [list]
			lappend tokens [list PAR_LEFT "(" 0 0]]
			lappend tokens {*}$origTokens
			lappend tokens [list PAR_RIGHT ")" 0 0]
			lappend tokens [list KEYWORD "AND" 0 0]
			lappend tokens [list PAR_LEFT "(" 0 0]
			lappend tokens {*}$conditionTokens
			lappend tokens [list PAR_RIGHT ")" 0 0]
			
			set allTokens [lreplace $allTokens $startIdx $endIdx {*}$tokens]
		}
		"none" - "group" {
			set insertIdx [lsearch -exact $allTokens [lindex $coreTokens end]]
			incr insertIdx
			
			set tokens [list]
			if {$mode == "group"} {
				lappend tokens [list KEYWORD HAVING 0 0]
			} else {
				lappend tokens [list KEYWORD WHERE 0 0]
			}
			lappend tokens {*}$conditionTokens
			
			set allTokens [linsert $allTokens $insertIdx {*}$tokens]
		}
		default {
			error "Invalid mode: $mode"
		}
	}
	
	set e [MAIN openSqlEditor]
	if {$e == ""} {
		debug "Could not open editor!"
		return
	}

	set sql [Formatter::format [Lexer::detokenize $allTokens] $_db]
	
	set date [clock format [clock seconds] -format %c]
	set win [$_parent getTitle]
	set commentStr [mc "The SQL query has been generated at %s\nusing selected results from window '%s'.\nThe original query was:\n%s" $date $win [string trim $query]]
	set comment "-- "
	append comment [join [split $commentStr \n] "\n-- "]
	append comment "\n--\n"

	$e setDatabase $_db
	$e setSQL "$comment\n$sql"
}

body ResultGrid::isRowNew {it} {
	return false
}

body ResultGrid::isSelectedRowNew {} {
	return false
}
