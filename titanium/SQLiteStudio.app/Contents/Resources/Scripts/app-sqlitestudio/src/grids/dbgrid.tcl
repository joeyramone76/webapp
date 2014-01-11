use src/grids/grid.tcl

class DBGrid {
	inherit Grid

	constructor {args} {
		Grid::constructor {*}$args
	} {}

	#>
	# @var startEditKeys
	# List of characters that typed from keyboard will cause edition of currently selected cell.
	#<
	final common startEditKeys {abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890}
	final common startEditKeysyms {comma period slash backslash grave bracketleft bracketright semicolon apostrophe
		KP_Divide KP_Multiply KP_Subtract KP_Add minus equal KP_Home KP_Up KP_Prior KP_Left KP_Begin KP_Right KP_End
		KP_Down KP_Next KP_Insert KP_Delete}

	common startEditKeysymMap
	array set startEditKeysymMap [string map [list %DECIMAL_POINT% $::DECIMAL_POINT] {
		minus -
		equal =
		comma ,
		period .
		slash /
		backslash \\
		grave `
		bracketleft [
		bracketright ]
		semicolon ;
		apostrophe '
		KP_Divide /
		KP_Multiply *
		KP_Subtract -
		KP_Add +
		KP_Home 7
		KP_Up 8
		KP_Prior 9
		KP_Left 4
		KP_Begin 5
		KP_Right 6
		KP_End 1
		KP_Down 2
		KP_Next 3
		KP_Insert 0
		KP_Delete %DECIMAL_POINT%
	}]

	protected {
		#>
		# @arr _rowId
		# Array that keeps ROWID of sqlite rows corresponding to rows in this grid.<br>
		# Indexes of the array are <b>TkTreeCtrl</b> row IDs and values are ROWIDs from sqlite.
		#<
		variable _rowId

		#>
		# @arr _rowType
		# Array of row types. Each row of gris has it's type. In practice all of rows has type '<code>regular</code>'
		# and zero or one row has type '<code>new</code>', which is new, uncommited row.<br>
		# Indexes of array are <b>TkTreeCtrl</b> row IDs.
		#<
		variable _rowType
		variable _table ""
		variable _db ""
		variable _toCommit
		variable _toCommitError
		variable _parent ""

		abstract method getRowId {it col}
		abstract method getColumnTable {col}
		abstract method renumberRows {}
		abstract method commitPendingNewRow {}
		abstract method commitPendingRowDeletion {it rowId}
		abstract method commitPendingRowEdit {it col value}
		abstract method getValueForEdit {it col}
		abstract method prepareColumnsForCommits {type cols}
		abstract method cleanupColumnsAfterCommits {type cols successfulCommit}
		abstract method canCommitEdit {it col}
	}

	public {
		#>
		# @method setMassNull
		# @param items List of pairs of row ID and column ID (related to <b>TkTreeCtrl</b>) representing a cells.
		# Sets NULL (not the same as empty!) value to given cells. If at least one cell cannot be set to NULL
		# (because of constraints) then whole operation is rolled back.
		#<
		method setMassNull {items}

		#>
		# @method setNull
		# @param item Pair of row ID and column ID (related to <b>TkTreeCtrl</b>) representing a cell.
		# Sets NULL (not the same as empty!) value to given cell.
		#<
		method setNull {item}

		#>
		# @method checkForEdit
		# @param key Key that was pressed.
		# @param value Value that is to be inserted for this action (when pasting it differs from <i>key</i> parameter value).
		# @param state Event state (see %s tag description in Tk 'bind' command manual).
		# Checks whether pressed key should start edition of current cell. If it's so, then it created edit widget and puts <i>value</i> into it.
		#<
		method checkForEdit {key value state}

		#>
		# @method isInlineEdit
		# @param item Pair of row ID and column ID (related to <b>TkTreeCtrl</b>) representing a cell.
		# Checks if given cell has inline value editor or it uses some external dialog (like '<code>blob</code>' cells).
		# @return <code>true</code> if cell has inline editor or <code>false</code> otherwise.
		#<
		method isInlineEdit {item}

		#>
		# @method clearCurrentCell
		# Clears value of selected cell, including commitment empty value (not a null one!) to database.
		#<
		method clearCurrentCell {}

		#>
		# @method edit
		# @param item Pair of row ID and column ID that represents cell to edit.
		# This implementation introduces support for new column type - '<code>blob</code>'.
		# @overloaded Grid
		#<
		method edit {item {forceBlobMode false}}

		#>
		# @method commitEdit
		# @param item Pair of row ID and column ID (related to <b>TkTreeCtrl</b>) representing cell being edited.
		# @param getval Boolean valaue determinating if commited value should be taken from <i>val</i> parameter (<code>true</code>) or from {@var _editItem} widget (<code>false</code>).
		# @param val Value to commit when <i>getval</i> parameter is <code>true</code>.
		# Commits new value for cell described by <i>item</i> parameter.
		# @overloaded Grid
		#<
		method commitEdit {{item ""} {getval no} {val ""}}

		method isEditing {}
		method setTable {table}
		method setDB {db}
		method getDb {}
		method handleRowNulls {data it}
		method setNullStyle {it c text}
		method unsetNullStyle {it c text}
		method addRow {data}
		method isNull {item}
		method reset {}
		method getText {item}
		method getCellsToCommit {}
		method unmarkAllForCommit {}
		method refreshMarkForCommit {}
		method displayMarkForCommit {it col type}
		method commitAll {{itColList ""}}
		method rollbackAll {{itColList ""}}
		method markForCommit {it col type dataToSet oldVal}
		method markForCommitError {it col type}
		method unmarkForCommit {it col}
		method unmarkForCommitError {it col}
		method isRowPendingForCommit {it}
		method isCellPendingForCommit {it col}
		method isRowPendingForCommitAsNew {it}
		method isSelectedRowPendingForCommit {}
		method areTherePendingCommits {}
		method getSelectedRowDataWithNull {}
		method getCellDataWithNull {item col}
		method setRowDataWithNull {item data {includeRowNum false}}
		method setCellDataWithNull {item col data}
		method getRowDataWithNull {it}
		method getSelectedAreaDataWithNull {}
		method isEditPossible {it col}
		method setParent {object}
		method isRowPendingForCommitAsDeleted {it}
		method editSelectedInEditor {}
	}
}

body DBGrid::constructor {args} {
	$_tree element create e_modBorder1 rect -open "nw" -outline blue -outlinewidth 1 -draw 0
	$_tree element create e_modBorder2 rect -open "se" -outline blue -outlinewidth 1 -draw 0
	$_tree style elements s_text [list e_border e_modBorder1 e_modBorder2 e_text]
	$_tree style layout s_text e_modBorder1 -detach yes -iexpand xy -ipadx 1 -ipady 1
	$_tree style layout s_text e_modBorder2 -detach yes -iexpand xy -ipadx 0 -ipady 0
}

body DBGrid::setTable {table} {
	set _table $table
}

body DBGrid::setDB {db} {
	set _db $db
}

body DBGrid::getDb {} {
	return $_db
}

body DBGrid::handleRowNulls {data it} {
	foreach w $data c [lrange $_cols 1 end] { ;# rowNum column has to be ommited
		switch -- $_colType($c) {
			"window" - "image" {
				# dummy, we need to handle only default case
			}
			default {
				if {[$_db isNull $w]} {
					setNullStyle $it $c $w
				} else {
					unsetNullStyle $it $c $w
				}
			}
		}
	}
}

body DBGrid::setNullStyle {it c text} {
	$_tree item element configure $it $c e_text -text "NULL" -fill $::Grid::null_foreground_color -data "null" -font $italicFont
}

body DBGrid::unsetNullStyle {it c text} {
	#$_tree item element configure $it $c e_text -text "$text"
	$_tree item element configure $it $c e_text -text "$text" -data ""
}

body DBGrid::addRow {data} {
	set it [Grid::addRow $data]
	handleRowNulls $data $it
}

body DBGrid::setNull {item} {
	set it [lindex $item 0]
	set col [lindex $item 1]
	set rowId [getRowId $it $col]
	if {$rowId == ""} return
	if {![isEditPossible $it $col]} return
	markForCommit $it $col "edit" [list "" 1] [getCellDataWithNull $it $col]
	setNullStyle $it $col ""
}

body DBGrid::setMassNull {items} {
	set f $italicFont
	array set cols {}
	array set colIds {}
	array set rowIds {}
	foreach item $items {
		lassign $item it col
		if {![isEditPossible $it $col]} continue
		markForCommit $it $col "edit" [list "" 1] [getCellDataWithNull $it $col]
		setNullStyle $it $col ""
	}
}

body DBGrid::getText {item} {
	lassign $item it col
	if {$_colType($col) in [list "window" "image"]} {
		return ""
	}

	if {[isNull $item]} {
		return ""
	} else {
		return [Grid::getText $item]
	}
}

body DBGrid::isNull {item} {
	lassign $item it col
	return [expr {[$_tree item element cget $it $col e_text -data] == "null"}]
}

body DBGrid::checkForEdit {key value state} {
	if {$_editItem != ""} {return 0}
	if {$state in [list 20 24 4 12 131080 393228 262152 262156 131084]} {return 0}
	if {[string length $key] == 1 && [string is print $key]} {
		if {$_selected == ""} {return 0}
		if {![isInlineEdit $_selected]} {return 0}

		if {$key in $startEditKeysyms} {
			set value $startEditKeysymMap($key)
		}

		edit $_selected
		if {![winfo exists $_editItem]} {
			return 0
		}
		$_editItem delete 0 end
		$_editItem insert end $value
		if {$itk_option(-modifycmd) != ""} {
			set _editCellModified 1
			eval $itk_option(-modifycmd)
		}

		return 1
	}
	return 0
}

body DBGrid::isInlineEdit {item} {
	set it [lindex $item 0]
	set col [lindex $item 1]
	set geom [$_tree item bbox $it $col]

	switch -- $_colType($col) {
		"blob" {
			return 0
		}
		default {
			return 1
		}
	}
}

body DBGrid::isEditPossible {it col} {
	return 0
}

body DBGrid::isEditing {} {
	expr {$_editItem != "" && [winfo exists $_editItem]}
}

body DBGrid::editSelectedInEditor {} {
	if {[llength $_selected] == 0} return
	$this edit $_selected true
}

body DBGrid::edit {item {forceBlobMode false}} {
	if {$_db == ""} {
		return false
	}

	lassign $item it col
	if {![$this isEditPossible $it $col]} {
		return false
	}

	if {$_editItem != "" && [winfo exists $_editItem]} {
		destroy $_editItem
		set _editItem ""
	}
	set geom [$_tree item bbox $it $col]
	set value [$this getValueForEdit $it $col]

	set editMode "normal"
	if {$_colType($col) == "blob" || [string length [lindex $value 0]] > $::QueryExecutor::visibleDataLimit || $forceBlobMode} {
		set editMode "blob"
	}

	switch -- $editMode {
		"blob" {
			if {[winfo exists .blobEdit]} {destroy .blobEdit}
			set _editItem [BlobEdit .blobEdit -message [mc {Edit BLOB entry:}] -value $value -title [mc {BLOB edit}]]
			unset value
			set res [$_editItem exec]
			set _editItem ""

			lassign $res code val
			if {!$code} {
				commitEdit $item yes $val
			} else {
				rollbackEdit $item
			}
		}
		default {
			set _editItem [entry $path.edit -background white -borderwidth 0 -validate key -validatecommand [list $this editCellModifiedFlagProxy]]
			set _disableModifyFlagDetection 1
			$_editItem insert end [lindex $value 0]
			set _disableModifyFlagDetection 0
			setupStdBindsForEdit $item
			set _editItemCell $item
			if {$::Grid::selectAllOnEdit} {
				$_editItem selection range 0 end
			}

			update idletasks
			lassign $geom x1 y1 x2 y2

			if {$itk_option(-xscroll)} {
				set treeWidth [winfo width $_tree]
				lassign [$_xframe xview] fromFraction toFraction
				set mod [expr {int(round($fromFraction * $treeWidth))}]
				incr x1 -$mod
				incr x2 -$mod
			}

			place $_editItem -x $x1 -y $y1 -width [expr {$x2-$x1-1}] -height [expr {$y2-$y1-1}]
			focus $_editItem

			$_parent updateEditorToolbar
		}
	}
	return true
}

body DBGrid::commitEdit {{item ""} {getval no} {val ""}} {
	if {$item == ""} {
		set item $_editItemCell
	}

	lassign $item it col
	if {![$this canCommitEdit $it $col]} {
		return
	}

	if {$getval} {
		lassign $val value null
	} else {
		if {$_editItem == ""} return
		if {!$_editCellModified} {
			rollbackEdit $item
			return
		}
		set value [$_editItem get]
		set null 0
	}

	markForCommit $it $col "edit" [list $value $null] [getCellDataWithNull $it $col]

	set fg $::Grid::foreground_color
	$_tree item element configure $it $col e_text -text $value -data "" -font [list ${::Grid::font}] -fill $fg
	Grid::commitEdit $item $getval $val

	if {$null} {
		setNullStyle $it $col ""
	}
}

body DBGrid::clearCurrentCell {} {
	if {$_selected == ""} return
	set area [getMarkedArea]
	setMassNull [concat {*}$area]
}

body DBGrid::setCellDataWithNull {item col value} {
	lassign $value val null
	if {$null} {
		setNullStyle $item $col ""
	} else {
		$_tree item element configure $item $col e_text -text $val -data "" -fill $foreground_color -font [list $font]
	}
}

body DBGrid::getCellDataWithNull {item col} {
	set isnull [expr {[$_tree item element cget $item $col e_text -data] == "null"}]
	return [list [$_tree item element cget $item $col e_text -text] $isnull]
}

body DBGrid::setRowDataWithNull {item data {includeRowNum false}} {
	set start -1
	if {$includeRowNum} {
		set start 0
	}
	set colId [$_tree column id 0]
	for {set i $start} {$colId != "" && $colId != "tail"} {incr i} {
		if {$i < 0} {
			set colId [$_tree column id "$colId next"]
			continue
		}
		set it [lindex $item 0]
		lassign [lindex $data $i] val null
		if {$null} {
			setNullStyle $it $colId ""
		} else {
			$_tree item element configure $it $colId e_text -text $val -data "" -fill $foreground_color -font [list $font]
		}
		set colId [$_tree column id "$colId next"]
	}
}

body DBGrid::getSelectedRowDataWithNull {} {
	if {$_selected == ""} {
		return ""
	}
	return [getRowDataWithNull [lindex $_selected 0]]
}

body DBGrid::getRowDataWithNull {it} {
	set colId [$_tree column id "first"]
	set data [list]
	while {$colId != "" && $colId != "tail"} {
		# TODO For debug, it's temporary
		if {[catch {$_tree item element cget $it $colId e_text -data} res]} {
			error "$res (Application state: _selected=$_selected, _editItem=$_editItem, column=[$_tree column cget $colId -text])"
		}

		set isnull [expr {[$_tree item element cget $it $colId e_text -data] == "null"}]
		lappend data [list [$_tree item element cget $it $colId e_text -text] $isnull]
		set colId [$_tree column id "$colId next"]
	}
	return $data
}

body DBGrid::getSelectedAreaDataWithNull {} {
	set data [list]
	foreach row [getMarkedArea] {
		set rowData [list]
		foreach cell $row {
			lassign $cell it col
			switch -- $_colType($col) {
				"window" {
					lappend rowData [list [$_tree item element cget $it $col e_win -window] false]
				}
				"image" {
					lappend rowData [list [$_tree item element cget $it $col e_image -image] false]
				}
				default {
					set isnull [expr {[$_tree item element cget $it $col e_text -data] == "null"}]
					lappend rowData [list [$_tree item element cget $it $col e_text -text] $isnull]
				}
			}
		}
		lappend data $rowData
	}
	return $data
}

body DBGrid::markForCommit {it col type dataToSet oldVal} {
	switch -- $type {
		"edit" {
			if {![info exists _toCommit($it:)]} {
				# NEW and DEL are handled at once, not by each column
				if {[info exists _toCommit($it:$col)]} {
					set oldVal [lindex $_toCommit($it:$col) 2]
				}
				set _toCommit($it:$col) [list $type $dataToSet $oldVal]
			}
		}
		"new" {
			set _toCommit($it:$col) [list $type $dataToSet $oldVal]
		}
		"del" {
			foreach idx [array names _toCommit $it:*] {
				unset _toCommit($idx)
			}
			set _toCommit($it:$col) [list $type $dataToSet $oldVal]
		}
	}
	displayMarkForCommit $it $col $type
	if {$itk_option(-modifycmd) != ""} {
		eval $itk_option(-modifycmd)
	}
}

body DBGrid::markForCommitError {it col type} {
	switch -- $type {
		"edit" {
			if {![info exists _toCommit($it:)]} {
				# NEW and DEL are handled at once, not by each column
				set _toCommitError($it:$col) 1
			}
		}
		"new" {
			set _toCommitError($it:$col) 1
		}
		"del" {
			set _toCommitError($it:$col) 1
		}
	}
	displayMarkForCommit $it $col $type
}

body DBGrid::displayMarkForCommit {it col type} {
	switch -- $type {
		"edit" {
			set bgcolor "blue"
			if {[info exists _toCommitError($it:$col)]} {
				set bgcolor "red"
			}
			$_tree item element configure $it $col e_modBorder1 -draw 1 -outline $bgcolor
			$_tree item element configure $it $col e_modBorder2 -draw 1 -outline $bgcolor
		}
		"new" {
			set bgcolor "blue"
			if {[info exists _toCommitError($it:)]} {
				set bgcolor "red"
			}
			foreach c [$_tree column list] {
				$_tree item element configure $it $c e_modBorder1 -draw 1 -outline $bgcolor
				$_tree item element configure $it $c e_modBorder2 -draw 1 -outline $bgcolor
			}
		}
		"del" {
			set bgcolor "blue"
			if {[info exists _toCommitError($it:)]} {
				set bgcolor "red"
			}
			set cols [$_tree column list]
			foreach c $cols {
				$_tree item element configure $it $c e_modBorder1 -draw 1 -outline $bgcolor
				$_tree item element configure $it $c e_modBorder2 -draw 1 -outline $bgcolor
			}
			$_tree item element configure $it [lindex $cols 0] e_text -text "-"

			# Setting nulls
			foreach c [lrange $cols 1 end] {
				$_tree item element configure $it $c e_text -text "-" -data "null" -fill $::Grid::null_foreground_color -font GridFontItalic
			}
		}
	}
}

body DBGrid::refreshMarkForCommit {} {
	foreach idx [array names _toCommit] {
		lassign $_toCommit($idx) type data oldData
		lassign [split $idx :] it col
		displayMarkForCommit $it $col $type
	}
}

body DBGrid::unmarkForCommit {it col} {
	if {$col == ""} {
		foreach c [$_tree column list] {
			$_tree item element configure $it $c e_modBorder1 -draw 0
			$_tree item element configure $it $c e_modBorder2 -draw 0
		}
	} else {
		$_tree item element configure $it $col e_modBorder1 -draw 0
		$_tree item element configure $it $col e_modBorder2 -draw 0
	}
	if {[info exists _toCommit($it:$col)]} {
		unset _toCommit($it:$col)
	}
}

body DBGrid::unmarkForCommitError {it col} {
	if {[info exists _toCommitError($it:$col)]} {
		unset _toCommitError($it:$col)
	}
}

body DBGrid::unmarkAllForCommit {} {
	foreach idx [array names _toCommit] {
		lassign [split $idx :] it col
		unmarkForCommit $it $col
	}
}

body DBGrid::getCellsToCommit {} {
	set list [list]
	foreach idx [array names _toCommit] {
		lassign [split $idx :] it col
		lappend list [list $it $col $_toCommit($idx)]
	}
	return $list
}

body DBGrid::isRowPendingForCommit {it} {
	return [expr {[llength [array names _toCommit $it:*]] > 0}]
}

body DBGrid::isCellPendingForCommit {it col} {
	return [expr {[info exists _toCommit($it:$col)] || [info exists _toCommit($it:)]}]
}

body DBGrid::isRowPendingForCommitAsNew {it} {
	if {[info exists _toCommit($it:)]} {
		set type [lindex $_toCommit($it:) 0]
		if {$type == "new"} {
			return true
		} else {
			return false
		}
	} else {
		return false
	}
}

body DBGrid::isRowPendingForCommitAsDeleted {it} {
	if {[info exists _toCommit($it:)]} {
		set type [lindex $_toCommit($it:) 0]
		if {$type == "del"} {
			return true
		} else {
			return false
		}
	} else {
		return false
	}
}

body DBGrid::areTherePendingCommits {} {
	return [expr {[llength [array names _toCommit *]] > 0}]
}

body DBGrid::isSelectedRowPendingForCommit {} {
	if {$_selected == ""} {
		return 0
	}
	return [isRowPendingForCommit [lindex $_selected 0]]
}

body DBGrid::rollbackAll {{itColList ""}} {
	set limited [expr {[llength $itColList] > 0}]

	rollbackEdit

	array set itCols {}
	if {$limited} {
		foreach itCol $itColList {
			lassign $itCol it col
			if {$col == ""} {
				set col all
			}
			lappend itCols($it) $col
		}
	}

	foreach idx [array names _toCommit] {
		lassign $_toCommit($idx) type data oldData
		lassign [split $idx :] it col

		switch -- $type {
			"new" {
				if {$limited && ![info exists itCols($it)]} {
					continue
				}

				unmarkForCommit $it ""
				delRow $it
			}
			"del" {
				if {$limited && ![info exists itCols($it)]} {
					continue
				}

				setRowDataWithNull $it $oldData true
				unmarkForCommit $it ""
			}
			"edit" {
				# Limited && (row not in filter || ("all" not in filter && col not in filter))
				if {$limited && (![info exists itCols($it)] || "all" ni $itCols($it) && $col ni $itCols($it))} {
					continue
				}

				setCellDataWithNull $it $col $oldData
				unmarkForCommit $it $col
			}
			default {
				error "Unsupported modification type while call to commitAll: $type"
			}
		}
	}

	$this renumberRows
	if {$itk_option(-modifycmd) != ""} {
		eval $itk_option(-modifycmd)
	}
}

body DBGrid::commitAll {{itColList ""}} {
	set limited [expr {[llength $itColList] > 0}]
	set wasError 0

	array set itCols {}
	if {$limited} {
		foreach itCol $itColList {
			lassign $itCol it col
			if {$col == ""} {
				set col all
			}
			lappend itCols($it) $col
		}
	}

	# Preparing grid for commits
	set type "specified"
	set cols [list]
	foreach idx [array names _toCommit] {
		lassign [split $idx :] it col
		if {$col != ""} {
			if {$col ni $cols} {
				lappend cols $col
			}
		} else {
			set type "all"
			set cols [list]
			break
		}
	}
	$this prepareColumnsForCommits $type $cols

	# Commiting
	if {[catch {
		$_db begin
		foreach idx [lsort -dictionary [array names _toCommit]] {
			lassign $_toCommit($idx) type data oldData
			lassign [split $idx :] it col

			switch -- $type {
				"new" {
					if {$limited && ![info exists itCols($it)]} {
						continue
					}

					set res [$this commitPendingNewRow $it]
					if {$res} {
						set wasError $res
						if {$res == 1} { ;# 1 means reedit value
							markForCommitError $it $col $type
						} elseif {$res == 2} { ;# 2 means return to previous value
							unmarkForCommit $it $col
							delRow $it
						}
						break
					}

					unmarkForCommitError $it $col
				}
				"del" {
					if {$limited && ![info exists itCols($it)]} {
						continue
					}

					set res [$this commitPendingRowDeletion $it $data]
					if {$res} {
						set wasError $res
						if {$res == 1} { ;# 1 means reedit value
							markForCommitError $it $col $type
						} elseif {$res == 2} { ;# 2 means return to previous value
							unmarkForCommit $it $col
							setRowDataWithNull $it $oldData
						}
						break
					}

					unmarkForCommitError $it $col
				}
				"edit" {
					# Limited && (row not in filter || ("all" not in filter && col not in filter))
					if {$limited && (![info exists itCols($it)] || "all" ni $itCols($it) && $col ni $itCols($it))} {
						continue
					}

					set res [$this commitPendingRowEdit $it $col $data]
					if {$res} {
						set wasError $res
						if {$res == 1} { ;# 1 means reedit value
							markForCommitError $it $col $type
						} elseif {$res == 2} { ;# 2 means return to previous value
							unmarkForCommit $it $col
							setCellDataWithNull $it $col $oldData
						}
						break
					}

					unmarkForCommitError $it $col
				}
				default {
					error "Unsupported modification type while call to commitAll: $type"
				}
			}
		}
	} err]} {
		set result [catch {$_db rollback} rbErr]
		catch {$this cleanupColumnsAfterCommits $type $cols false}
		if {$result} {
			error "$err\n(also error on rollback: $rbErr)"
		} else {
			error $err
		}
	}

	if {$wasError} {
		if {[catch {$_db rollback} err]} {
			debug $err
		}
		$this cleanupColumnsAfterCommits $type $cols false
		refreshMarkForCommit
	} else {
		if {[catch {$_db commit} err] && [$_db errorcode] == 19} {
			cutOffStdTclErr err
			Warning [mc "Cannot commit. Details:\n%s" $err]
			catch {$_db rollback}
			$this cleanupColumnsAfterCommits $type $cols false
			refreshMarkForCommit
			return
		}
		$this cleanupColumnsAfterCommits $type $cols true
		if {$limited} {
			# Unmarking only limited
			foreach idx [array names _toCommit] {
				lassign $_toCommit($idx) type data
				lassign [split $idx :] it col
				switch -- $type {
					"new" {
						if {$limited && ![info exists itCols($it)]} {
							continue
						}
						unmarkForCommit $it ""
					}
					"del" {
						if {$limited && ![info exists itCols($it)]} {
							continue
						}
						unmarkForCommit $it ""
					}
					"edit" {
						# Limited && (row not in filter || ("all" not in filter && col not in filter))
						if {$limited && (![info exists itCols($it)] || "all" ni $itCols($it) && $col ni $itCols($it))} {
							continue
						}
						unmarkForCommit $it $col
					}
				}
			}
		} else {
			unmarkAllForCommit
		}

		$this renumberRows
		if {$itk_option(-modifycmd) != ""} {
			eval $itk_option(-modifycmd)
		}
	}
}

body DBGrid::reset {} {
	catch {array unset _toCommit}
	array set _toCommit {}
	Grid::reset
}

body DBGrid::setParent {object} {
	set _parent $object
}
