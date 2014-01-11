use src/common/ui.tcl
use src/common/panel.tcl
use src/common/dnd.tcl

#>
# @class Grid
# Base class for all grids. It's kind of table view with capability to edit cell values,
# dynamicly add/delete rows and columns, navigate through grid with keyboard and mouse.
# This kind of widgets are common in spread sheet applications.
#<
class Grid {
	inherit UI Panel Dnd

	#>
	# @method constructor
	# @param args List of option-value paris. Handled options are described below.
	# Options:
	# <ul>
	# <li><code>-readonly</code> - <code>true</code> to forbid editing of grid contents by a user. Default: '<i>true</i>'.
	# <li><code>-yscroll</code> - <code>true</code> to show vertical scrollbar. Default: '<i>true</i>'.
	# <li><code>-xscroll</code> - <code>true</code> to show horizontal scrollbar. Default: '<i>true</i>'.
	# <li><code>-selectable</code> - <code>true</code> to let user select cells. Default: '<i>true</i>'.
	# <li><code>-basecol</code> - <code>true</code> to show additional column with row number
	# <li><code>-drawgrid</code> - <code>true</code> to draw grid with a lines, or <code>false</code> to leave grid without any lines. Default: '<i>true</i>'.
	# <li><code>-showheader</code> - <code>true</code> to show header with column names. Default: '<i>true</i>'.
	# <li><code>-clicked</code> - Tcl script to execute when any cell is clicked. You can use {@method getSelectedCell} and {@method getSelectedCellData} here. Default is empty string.
	# <li><code>-doubleclicked</code> - Tcl script to execute when any cell is double-clicked. You can use {@method getSelectedCell} and {@method getSelectedCellData} here. Default is empty string.
	# <li><code>-rowheight</code> - Height of each row. Value in pixels. Default is undefined.
	# <li><code>-navaction</code> - Tcl script to execute when selection of cell is changed. Default is empty string.
	# <li><code>-multicell</code> - <code>true</code> to allow marking/selecting more than row.
	# <li><code>-rowselection</code> - <code>true</code> to force marking/selecting always entire row.
	# <li><code>-selectionchanged</code> - script to evaluate when selection has changed. See {@var _selectionChangedScript} for details.
	# <li><code>-takefocus</code> - defines if the widget takes focus by itself. For 'window' type columns it's better for grid to not take a focus.
	# <li><code>-enablednd</code> - <code>true</code> to enable Drag&Drop support for this grid.
	# <li><code>-dragcmd</code> - Tcl script to execute when user drags item in grid. Script is executed in the Grid context.
	# <li><code>-dropcmd</code> - Tcl script to execute when user drops item in grid. The dragged data will be appended to the script as an argument. Script is executed in the Grid context.
	# <li><code>-modifycmd</code> - Tcl script to execute when any modification of data is made in the grid. Script is executed in the Grid context.
	# </ul>
	#<
	constructor {args} {}

	#>
	# @var grid_color
	# Color of grid lines. Configured by {@class CfgWin}.
	#<
	common grid_color "#888888"

	#>
	# @var background_color
	# Color of background. Configured by {@class CfgWin}.
	#<
	common background_color "white"

	#>
	# @var foreground_color
	# Color of foreground. Configured by {@class CfgWin}.
	#<
	common foreground_color "black"

	#>
	# @var selected_foreground_color
	# Color of selected cell foreground. Configured by {@class CfgWin}.
	#<
	common selected_foreground_color "black"

	#>
	# @var selected_background_color
	# Color of selected cell background. Configured by {@class CfgWin}.
	#<
	common selected_background_color "#DDDDDD"

	#>
	# @var base_col_background_color
	# Color of base column (with rows numbers) background. Configured by {@class CfgWin}.
	#<
	common base_col_background_color "gray"

	#>
	# @var null_foreground_color
	# Color of 'NULL' label for cells with null value.
	#<
	common null_foreground_color "gray"
	
	#>
	# @var select_all_on_edit
	# If true, then all contents of cell get selected when entering edition entry.
	#<
	common selectAllOnEdit 1

	#>
	# @var font
	# Font used in grid. Configured by {@class CfgWin}.
	#<
	common font "GridFont"

	#>
	# @var boldFont
	# Bold type of base font. Confiugred automatically.
	#<
	common boldFont "GridFontBold"

	common italicFont "GridFontItalic"

	common hintBoldFont "TkTooltipFontBold"

	#>
	# @var askIfCutBigClipboard
	# Configurable value in config dialog. If false, then clipboard contents that are doesn't fit
	# into grid will be cutted to fit without asking user. If true then user will be asked befor cutting.
	#<
	common askIfCutBigClipboard 1

	#>
	# @var maxColumnWidth
	# Maximum width of single grid column.
	#<
	common maxColumnWidth 600

	# Options
	opt readonly 1
	opt yscroll 1
	opt xscroll 1
	opt basecol 1
	opt drawgrid 1
	opt showheader 1
	opt clicked ""
	opt doubleclicked ""
	opt selectionchanged ""
	opt rowheight ""
	opt navaction ""
	opt multicell 0
	opt selectable 1
	opt takefocus 1
	opt rowselection 0
	opt enablednd 0
	opt dragcmd ""
	opt dropcmd ""
	opt modifycmd "" ;# not used by Grid, but by DataGrid and ResultGrid
	opt itementercmd ""
	opt itemleavecmd ""
	opt columnentercmd ""
	opt columnleavecmd ""
	opt headerentercmd ""
	opt headerleavecmd ""

	protected {
		#>
		# @var _tree
		# <b>TkTreeCtrl</b> widget object that grid is built on it.
		#<
		variable _tree ""

		#>
		# @var _cols
		# List of existing columns (column objects used by <b>TkTreeCtrl</b>).
		#<
		variable _cols [list]

		#>
		# @var _rowNum
		# Number of next row to be added. It's visible only if base column is visible.
		# @see method constructor
		# @see method setBaseRowNum
		# @see var base_col_background_color
		#<
		variable _rowNum 1

		#>
		# @var _selected
		# Currently selected cell (pair of row ID and column ID). IDs are related to <b>TkTreeCtrl</b>.
		#<
		variable _selected ""

		#>
		# @var _topLeftMark
		# Index (pair of row ID and column ID) of second corner of marked area. First corner is {@var _selected}.
		# It might be same as {@var _selected} if just one cell is selected and marked.
		#<
		variable _marked ""

		#>
		# @var _editItem
		# If grid is being edited, this variable keeps edit widget object. If grid isn't edited, this variable is empty.
		#<
		variable _editItem ""

		#>
		# @var _editItemCell
		# Keeps row and column of currently edited cell.
		#<
		variable _editItemCell [list]

		#>
		# @arr _colType
		# Data type for each of columns. Array is indexed with column IDs. IDs are related to <b>TkTreeCtrl</b>.
		#<
		variable _colType

		#>
		# @arr _colName
		# Column name for each of columns. Array is indexed with column IDs. IDs are related to <b>TkTreeCtrl</b>.
		#<
		variable _colName

		#>
		# @var _selectionChangedScript
		# Script to eval when selection has changed. %i is substituted to new row item, %c is substituted to new column item. They can be empty.
		#<
		variable _selectionChangedScript ""

		variable _xframe ""
		variable _editCellModified 0
		variable _disableModifyFlagDetection 0

		#>
		# @method setActive
		# @param item Row ID to set active status for.
		# @param column Column ID to set active status for.
		# Sets active status to new cell identified by row ID and column ID.
		#<
		method setActive {item column}

		#>
		# @method edit
		# @param item Pair of row ID and column ID that represents cell to edit.
		# Creates editing widgets and updates cell value when edit widget is commited.
		#<
		method edit {item}

		method getRowSelectionCols {}

		#>
		# @method getMarkedArea
		# @return List of identifiers of items that are in marked area (see {@var _selected} and {@var _marked}).
		#<
		method getMarkedArea {}

		#>
		# @method drawMarkedArea
		# Draws marked area cells with configured color.
		#<
		method drawMarkedArea {}
		
		method setupStdBindsForEdit {item}
	}

	public {
		#>
		# @method addColumn
		# @param title Title/name of new column.
		# @param type Data type of new column. Valid types: '<code>rownum</code>', '<code>numeric</code>', '<code>real</code>', '<code>integer</code>', '<code>int</code>', '<code>window</code>', '<code>image</code>' and '<code>text</code>'. Any other values will be interpreted as a '<code>text</code>'.
		# Creates new column. Types: '<code>window</code>' and '<code>image</code>' are treated specially. While adding new row with {@method addRow} values for columns with these types has to be respectively: Tk widget path and Tk image object.
		# @return New column ID (related to <b>TkTreeCtrl</b>).
		#<
		method addColumn {title {type "text"}}

		#>
		# @method addRow
		# @param data List of row values. Each value for one column.
		# Adds new row and increments row number ({@_rowNum}).
		# @return New row ID (related to <b>TkTreeCtrl</b>).
		#<
		method addRow {data {refreshWidth true}}

		#>
		# @method delSelected
		# Deletes selected row.
		#<
		method delSelected {}

		#>
		# @method getSelectedRow
		# @return Selected row ID (related to <b>TkTreeCtrl</b>).
		#<
		method getSelectedRow {}

		#>
		# @method getSelectedCell
		# @return Pair of row ID and column ID representing selected cell (IDs are related to <b>TkTreeCtrl</b>).
		#<
		method getSelectedCell {}

		#>
		# @method getSelectedRowData
		# @return List of values from all columns in selected row, in same order as columns.
		#<
		method getSelectedRowData {}
		method getRowData {it}

		#>
		# @method getSelectedRowData
		# @return List of values from all columns in selected row, in same order as columns. Each element of list is list of two elements: first is the value and second is boolean determinating if the value is null or not.
		#<
		method getCellData {item col}

		#>
		# @method getSelectedCellData
		# @return Data from currently selected cell.
		#<
		method getSelectedCellData {}

		#>
		# @method setSelectedRowData
		# @param data List of data values to set.
		# Sets new values for all columns in selected row. Columns in the grid are filled with same order as values in list.
		#<
		method setSelectedRowData {data}

		#>
		# @method setRowData
		# @param item Row ID to set new data for (ID is related to <b>TkTreeCtrl</b>).
		# @param data List of data values to set.
		# Sets new values for all columns in given row. Columns in the grid are filled with same order as values in list.
		#<
		method setRowData {item data {refreshWidth true}}

		#>
		# @method setCellData
		# @param item Row ID to set new data for (ID is related to <b>TkTreeCtrl</b>).
		# @param col Column ID to set new data for (ID is related to <b>TkTreeCtrl</b>).
		# @param value Data value to set.
		# Sets new value for given cell.
		#<
		method setCellData {item col data {refreshWidth true}}

		#>
		# @method columnsEnd
		# @param idx Optional, 0-based index of column to use instead of last to expand.
		# If you decide that there will be no more columns you can call this method,
		# so <b>TkTreeCtrl</b> will expand last column to fill unused area.
		#<
		method columnsEnd {{idx end}}

		#>
		# @method selectItem
		# @param x X coordinate (in pixels) of click event.
		# @param y Y coordinate (in pixels) of click event.
		# @param mark Deciedes if selecting new item should also mark cells from previous position to new one.
		# Tries to select cell under X,Y coordinates if any cell is located under them.
		# Does nothing otherwise.
		#<
		method selectItem {x y {mark false}}

		#>
		# @method selectItem
		# @param it Row ID to select (ID is related to <b>TkTreeCtrl</b>).
		# @param col Column ID to select (ID is related to <b>TkTreeCtrl</b>). If grid is has <code>-rowselection<code> mode, then this parameter is ignored.
		# @param mark Deciedes if selecting new item should also mark cells from previous position to new one.
		# Selects given cell, marking whole area optionally.
		#<
		method select {it col {mark false}}

		method selectIdxRange {fromRowIdx fromColIdx toRowIdx toColIdx}
		method selectAll {}

		#>
		# @method selectItem
		# @param rowIdx Row index to select (0-based).
		# @param colIdx Column index to select (0-based). If grid is has <code>-rowselection<code> mode, then this parameter is ignored.
		# @param mark Deciedes if selecting new item should also mark cells from previous position to new one.
		# Selects given cell, marking whole area optionally.
		#<
		method selectByIdx {rowIdx colIdx {mark false}}

		#>
		# @method markItem
		# @param x X coordinate (in pixels) of motion event.
		# @param y Y coordinate (in pixels) of motion event.
		# Tries to mark cells from {@var _selected} to X,Y coordinates, or closest to these coordinates.
		#<
		method markItem {x y}

		#>
		# @method handleClick
		# @param x X coordinate (in pixels) of cell to edit.
		# @param y Y coordinate (in pixels) of cell to edit.
		# Calls proper handler for clicked point.
		#<
		method handleClick {x y {modifiers ""}}

		#>
		# @method handleDoubleClick
		# @param x X coordinate (in pixels) of cell to edit.
		# @param y Y coordinate (in pixels) of cell to edit.
		# Calls proper handler for double-clicked point.
		#<
		method handleDoubleClick {x y {modifiers ""}}

		#>
		# @method editCurrent
		# Calls {@method edit} for currently selected cell.
		#<
		method editCurrent {}

		#>
		# @method goToCell
		# @param indexModifier TkTreeCtrl item index modifier (next/prev/last/first/left/right).
		# @param mark Deciedes if moving should also mark cells from previous position to new one.
		# Moves cell selection to visible cell placed on the given direction from current one (if possible).
		# @return 1 on success movement, or 0 when movement was impossible for some reason (out of rows/cols, no cell selected).
		#<
		method goToCell {indexModifier {mark false}}

		#>
		# @method hasUpAvailable
		# @return <code>true</code> if there is any visible row above currently selected, or <code>fals</code> otherwise. It also returns <code>false</code> if no row is selected.
		#<
		method hasUpAvailable {}

		#>
		# @method hasDownAvailable
		# @return <code>true</code> if there is any visible row below currently selected, or <code>fals</code> otherwise. It also returns <code>false</code> if no row is selected.
		#<
		method hasDownAvailable {}

		#>
		# @method reset
		# Deletes all columns and rows from grid, clears all internal variables related with them.
		#<
		method reset {}

		#>
		# @method delRows
		# Deletes all rows, leaving columns as they are.
		#<
		method delRows {}

		#>
		# @method delRow
		# @param item Row ID (related to <b>TkTreeCtrl</b>).
		# Deletes row with given ID.
		#<
		method delRow {item}

		#>
		# @method getWidget
		# @return <b>treectrl</b> widget. It gives low-level access to base widget so some custom changes can be done.
		#<
		method getWidget {}

		#>
		# @method commitEdit
		# @param item Pair of row ID and column ID (related to <b>TkTreeCtrl</b>) representing cell being edited. If ommited, then currently remembered item will be commited.
		# @param getval Ignored for this class, used by derived class. See {@method DataGrid::commitEdit} implementation code for example of using it.
		# @param val Ignored for this class, used by derived class. See {@method DataGrid::commitEdit} implementation code for example of using it.
		# This implementation of the method does nothing but destroy edit widget and give back the keyboard focus to the tree widget.
		# Derived classes needs to reimplement this method to allow commiting changes and tell the class how to do it. See {@method DataGrid::commitEdit} code for sample implementation.
		#<
		method commitEdit {{item ""} {getval no} {val ""}}

		#>
		# @method rollbackEdit
		# @param item Pair of row ID and column ID (related to <b>TkTreeCtrl</b>) representing cell being edited.
		# Destroys edit widget and gives back keyboard focus to the tree widget.
		#<
		method rollbackEdit {{item ""}}

		#>
		# @method setSelection
		# Forces keyboard focus to be set for tree widget and refreshes selected cell (refreshes user interface from {@var _selected} variable).
		#<
		method setSelection {}

		#>
		# @method columnExists
		# @param title Column name/title.
		# @return <code>true</code> if column with given name exists, or <code>false</code> otherwise.
		#<
		method columnExists {title}

		#>
		# @method setSize
		# @param w Changes required width of the widget (it still can be expanded by layout manager).
		# @param h Changes required height of the widget (it still can be expanded by layout manager).
		#<
		method setSize {w h}
		method setHeight {h}
		method setWidth {w}

		#>
		# @method columnConfig
		# @param col Column ID (related to <b>TkTreeCtrl</b>) to configure.
		# @param args Option-value pairs.
		# This method gives direct access to configuration options of all columns.
		#<
		method columnConfig {col args}

		#>
		# @method updateUISettings
		# @overloaded UI
		#<
		method updateUISettings {}

		#>
		# @method sort
		# @param column Column ID (related to <b>TkTreeCtrl</b>) to sort by.
		# Sorts data in grid in ascending order.
		#<
		method sort {{column 1}}

		#>
		# @method count
		# @return Number of rows in grid.
		#<
		method count {{mods ""}}

		#>
		# @method setBaseRowNum
		# @param val New base row number.
		# Resets base row number ({@var _rowNum}) to given value.
		#<
		method setBaseRowNum {val}

		#>
		# @method get
		# @param includeRowNum <code>true</code> if row numbers should be included, or <code>false</code> otherwise.
		# @return List of data from all rows. Each row data is a sublist with data from all its columns.
		#<
		method get {{includeRowNum false}}

		#>
		# @method getSelected
		# @param includeRowNum <code>true</code> if row numbers should be included, or <code>false</code> otherwise.
		# @return List of data from all selected rows and columns. Each row data is a sublist with data from all its selected columns.
		#<
		method getSelected {{includeRowNum false}}

		#>
		# @method getColumns
		# @param includeRowNum <code>true</code> if row numbers column should be included, or <code>false</code> otherwise.
		# @return List of columns, where each list element is a sublist with 3 elements: column ID (related to <b>TkTreeCtrl</b>), column name and column type.
		#<
		method getColumns {{includeRowNum false}}

		method getColumnsAsDisplayed {{includeRowNum false}}

		#>
		# @method getColData
		# @param colName Column name/title.
		# List of values in given column for all rows.
		#<
		method getColData {colName}

		#>
		# @method getColIdxData
		# @param colIdx Column ID (related to <b>TkTreeCtrl</b>) to get data from.
		# @return List of values in given column for all rows.
		#<
		method getColIdxData {colIdx}

		method getColIdData {colId}

		#>
		# @method destroyChilds
		# Destroys all children widgets, such as edit widget (if exists) and any others (optionally implemented in derived classes).
		#<
		method destroyChilds {}

		#>
		# @method getColumnNames
		# @return List of column names in grid.
		#<
		method getColumnNames {}

		#>
		# @method getColumnName
		# @param col Id of column.
		# @return Name of column with given index.
		#<
		method getColumnName {col}

		#>
		# @method setColumnName
		# @param col Id of column.
		# @name Name of column to set.
		# Sets new name for column.
		#<
		method setColumnName {col name}

		#>
		# @method getColumnIdByName
		# @param colName Name of column to get ID for.
		# @return ID of column with given name.
		#<
		method getColumnIdByName {colName}
		
		method getColumnIndexById {col {includeRowNum true}}

		#>
		# @method getText
		# @param item Pair of item ID and column ID that identifies cell to get text from.
		# @return Text from the cell.
		#<
		method getText {item}

		#>
		# @method setMarkedDisplay
		# @param item Pair of item ID and column ID that identifies cell to display as marked or not.
		# @param marked Deciedes if cell will be displayed as marked or not.
		# Sets marked status (true or false) display for given cell.
		#<
		method setMarkedDisplay {item marked}

		#>
		# @method clearMarkArea
		# Clears all marked area from being displayed as marked and erases {@var _marked} variable.
		#<
		method clearMarkArea {{everything false}}

		#>
		# @method getMarkedRows
		# @return Marked row identifiers.
		#<
		method getMarkedRows {}

		#>
		# @method getTopLeftMarkedCell
		# @return Top left marked cell. Might be same as {@var _selected} or empty.
		#<
		method getTopLeftMarkedCell {}

		#>
		# @method getCellPosition
		# @param item Item to get position for.
		# @param includeRowNum If <code>true</code> then horizontal position will include row numbers column.
		# @return Pair of horizontal and vertical position (numebr of cell from top and from left).
		#<
		method getCellPosition {item {includeRowNum false}}

		#>
		# @method copyMarked
		# Copies all marked cells into clipboard. Format of data stored in clipboard is applicable
		# for pasting to MS Excel or OpenOffice Calc. It also can be used for {@method paste}.
		#<
		method copyMarked {}

		#>
		# @method paste
		# Pastes data from clipboard. It interpretes data from clipboard as MS Excel or OpenOffice Calc do,
		# which means that new lines are interpreted as row separators and tabulators are interpreted
		# as column separators. To paste data containing new lines and tabulators into single cell
		# he has to enter cell edit mode and then paste it.
		#<
		method paste {}

		method processClipboardForPaste {topLeftMarkedCell}

		method getEditItem {}

		method scrolledVertically {}
		method scrolledHorizontally {}

		method getAllRows {}

		method isNumericColumn {colIt}
		method getRowDetails {rowId}
		method getRowSizeByIdx {idx}
		method getRowSize {rowId}
		method getRowByIdx {idx}
		method getRowIndex {rowId}
		method isCurrentlyEdited {}
		method getMarkedItems {}
		method setRowTags {it tags}
		method getRowTags {it}
		method onDrag {x y}
		method onDrop {x y}
		method isDndPossible {x y}
		method getDragImage {}
		method getDragLabel {}
		method identify {x y}
		method calculateWidth {}
		method refreshWidth {}
		method see {it {col ""}}
		method editCellModifiedFlagProxy {}
		method editArrowLeftRight {item side}
		method hide {}
		method show {}
		method hideRow {rowId}
		method showRow {rowId}
		method isEditCellModified {}
		method getColumnIdByIndex {idx}
		method makeWidgetScrollable {w {break false}}
		method markRow {it}
		method deselect {}
		method moveRowUp {rowId}
		method moveRowDown {rowId}
		method moveRowTo {rowId index}
		method moveRowBefore {rowId beforeRowId}
		method moveRowAfter {rowId afterRowId}
		method moveRowToBegining {rowId}
		method moveRowToEnd {rowId}
	}
}

body Grid::constructor {args} {
	ttk::frame $path.l
	pack $path.l -side left -fill both -expand 1

	eval itk_initialize $args
	if {$itk_option(-xscroll)} {
	# 	# Workaround for smooth x-scrolling. TkTreeCtrl does it by big steps, very ugly.
		set _xframe [scrolledframe::scrolledframe $path.l.sf -xscroll "$path.l.xscroll set" -xscrollcallback "$this scrolledHorizontally" -fill both]
		ttk::scrollbar $path.l.xscroll -command "$path.l.sf xview" -orient horizontal
		autoscroll $path.l.xscroll
		pack $path.l.sf -side top -fill both -expand 1
		pack $path.l.xscroll -side bottom -fill x
		set _tree $path.l.sf.scrolled.tree
	} else {
		set _tree $path.l.tree
	}

	if {$itk_option(-yscroll)} {
		itk_component add yscroll {
			ttk::scrollbar $path.scroll -command "$_tree yview" -orient vertical
		}
		pack $itk_component(yscroll) -side right -fill y
		autoscroll $itk_component(yscroll)
	}
	itk_component add tree {
		treectrl $_tree -showheader $itk_option(-showheader) -showroot no -background $background_color -border 1 -height 50 -width 100 \
			-usetheme yes -minitemheight 22 -foreground $foreground_color \
			-yscrollcommand [expr {$itk_option(-yscroll) ? "$path.scroll set" : ""}]
	}
	pack $_tree -side left -fill both -expand 1

	if {$itk_option(-rowheight) != ""} {
		$_tree configure -itemheight $itk_option(-rowheight)
	}

	$_tree configure -takefocus $itk_option(-takefocus) -highlightthickness $itk_option(-takefocus)
	$_tree column configure tail -borderwidth 1 ;# this makes header look nice under unix

	$_tree element create e_border rect -open nw -outline $grid_color -outlinewidth 1 -draw $itk_option(-drawgrid)
	$_tree element create e_text text -wrap none -lines 1 -font [list $font]
	$_tree element create e_win window -destroy true
	$_tree element create e_image image

	$_tree style create s_text
	$_tree style elements s_text [list e_border e_text]
	$_tree style layout s_text e_border -detach yes -iexpand xy
	$_tree style layout s_text e_text -ipadx 3 -ipady 3 -maxwidth $maxColumnWidth -padx 1 -pady 1

	$_tree style create s_win
	$_tree style elements s_win [list e_border e_win]
	$_tree style layout s_win e_border -detach yes -iexpand xy
	$_tree style layout s_win e_win -iexpand xy

	$_tree style create s_image
	$_tree style elements s_image [list e_border e_image]
	$_tree style layout s_image e_border -iexpand xy
	$_tree style layout s_image e_image -detach yes -iexpand xy
	$_tree style layout s_image e_image -ipadx 3 -ipady 3 -maxwidth $maxColumnWidth

	set baseCol [addColumn "#" rownum]
	$_tree column configure $baseCol -visible $itk_option(-basecol)

	# The line (3 lines actually) below causes "focus fight" (#1408)
	# and at this moment I don't see why is this line necessary.
	#if {$itk_option(-takefocus)} {
	#	bind $path <FocusIn> "focus $_tree"
	#}
	if {$itk_option(-selectable)} {
		bind $_tree <Up> "$this goToCell prev; break"
		bind $_tree <Down> "$this goToCell next; break"
		bind $_tree <Left> "$this goToCell left; break"
		bind $_tree <Right> "$this goToCell right; break"
		bind $_tree <Shift-Up> "$this goToCell prev true; break"
		bind $_tree <Shift-Down> "$this goToCell next true; break"
		bind $_tree <Shift-Left> "$this goToCell left true; break"
		bind $_tree <Shift-Right> "$this goToCell right true; break"
		bind $_tree <Next> "$this goToCell pageDown"
		bind $_tree <Prior> "$this goToCell pageUp"
		bind $_tree <End> "$this goToCell last"
		bind $_tree <Home> "$this goToCell first"
		bind $_tree <Shift-Next> "$this goToCell pageDown true"
		bind $_tree <Shift-Prior> "$this goToCell pageUp true"
		bind $_tree <Shift-End> "$this goToCell last true"
		bind $_tree <Shift-Home> "$this goToCell first true"
		bind $_tree <ButtonPress-1> "+$this selectItem %x %y"
		bind $_tree <Shift-ButtonPress-1> "$this selectItem %x %y true"
		bind $_tree <Control-a> "$this selectAll; break"
	}
# 	bind $_tree <Motion> "+$this tracePointer %x %y"
	bind $_tree <B1-Motion> "+$this markItem %x %y"
	if {$itk_option(-clicked) != ""} {
		bind $_tree <ButtonPress-1> "+$itk_option(-clicked)"
	}

	bind $_tree <Button-1> "+$this handleClick %x %y"
	bind $_tree <Double-Button-1> "$this handleDoubleClick %x %y; break"

	bind $_tree <Control-Button-1> "$this handleClick %x %y control; break"
	bind $_tree <Control-Shift-Button-1> "$this handleClick %x %y {control shift}; break"
	bind $_tree <Control-Alt-Button-1> "$this handleClick %x %y {control alt}; break"
	bind $_tree <Control-Alt-Shift-Button-1> "$this handleClick %x %y {control alt shift}; break"
	bind $_tree <Alt-Button-1> "$this handleClick %x %y alt; break"
	bind $_tree <Alt-Shift-Button-1> "$this handleClick %x %y {alt shift}; break"

	bind $_tree <Control-Double-Button-1> "$this handleDoubleClick %x %y control"
	bind $_tree <Control-Shift-Double-Button-1> "$this handleDoubleClick %x %y {control shift}"
	bind $_tree <Control-Alt-Double-Button-1> "$this handleDoubleClick %x %y {control alt}"
	bind $_tree <Control-Alt-Shift-Double-Button-1> "$this handleDoubleClick %x %y {control alt shift}"
	bind $_tree <Alt-Double-Button-1> "$this handleDoubleClick %x %y alt"
	bind $_tree <Alt-Shift-Double-Button-1> "$this handleDoubleClick %x %y {alt shift}"

	bind $_tree <Return> "$this editCurrent"
	bind $_tree <<Copy>> "$this copyMarked"
	bind $_tree <<Paste>> "$this paste"
	$_tree notify bind Grid <Scroll-y> "$this scrolledVertically"
	#bind $_tree <Scroll-y> "$this scrolledVertically"

	set _selectionChangedScript $itk_option(-selectionchanged)
# 	set _itemEnterCmd $itk_option(-itementercmd)
# 	set _itemLeaveCmd $itk_option(-itemleavecmd)
# 	set _columnEnterCmd $itk_option(-columnentercmd)
# 	set _columnLeaveCmd $itk_option(-columnleavecmd)

# 	bind $_tree <Leave> "$this leaveWidget"
# 	initTracer $_tree

	if {$itk_option(-enablednd)} {
		createDnd $_tree $_tree
	}
}

body Grid::hide {} {
	pack forget $_tree
}

body Grid::show {} {
	pack $_tree -side left -fill both -expand 1
}

body Grid::setSize {w h} {
	itk_initialize -width $w -height $h
}

body Grid::setHeight {h} {
	itk_initialize -height $h
}

body Grid::setWidth {w} {
	itk_initialize -width $w
}

body Grid::addColumn {title {type "text"}} {
	set type [string tolower $type]
	switch -- $type {
		"rownum" {
			set c [$_tree column create -text "$title" -borderwidth 1 -button no -justify right -itembackground $base_col_background_color -font $boldFont]
		}
		"numeric" - "real" - "integer" - "int" {
			set c [$_tree column create -text "$title" -borderwidth 1 -button no -justify right -font $boldFont]
		}
		"window" {
			 set c [$_tree column create -text "$title" -borderwidth 1 -button no -justify center -font $boldFont]
		}
		"image" {
			 set c [$_tree column create -text "$title" -borderwidth 1 -button no -justify center -font $boldFont]
		}
		default {
			set c [$_tree column create -text "$title" -borderwidth 1 -button no -font $boldFont]
		}
	}
	lappend _cols $c
	set _colName($c) $title
	set _colType($c) $type
	refreshWidth
	return $c
}

body Grid::isNumericColumn {colIt} {
	expr {$_colType($colIt) in [list "numeric" "real" "integer" "int" "number" "double" "float"]}
}

body Grid::calculateWidth {} {
	set wd 0
	foreach col $_cols {
		set needed [$_tree column neededwidth $col]
		set const [$_tree column width $col]
		incr wd [expr {max($needed, $const)}]
	}
	return $wd
}

body Grid::refreshWidth {} {
	if {$itk_option(-xscroll)} {
		set w [calculateWidth]
		$_tree configure -width $w
		update idletasks
		::scrolledframe::resize $_xframe
	}
}

body Grid::addRow {data {refreshWidth true}} {
	set it [$_tree item create]
	foreach w [concat $_rowNum $data] c $_cols {
		switch -- $_colType($c) {
			"window" {
				$_tree item style set $it $c s_win
				$_tree item element configure $it $c e_win -window "$w" -destroy 1
				makeWidgetScrollable $w
			}
			"image" {
				$_tree item style set $it $c s_image
				$_tree item element configure $it $c e_image -image "$w"
			}
			default {
				$_tree item style set $it $c s_text
				$_tree item element configure $it $c e_text -text "$w"
			}
		}
	}

	incr _rowNum
	$_tree item lastchild root $it
	if {$refreshWidth} {
		refreshWidth
	}
	return $it
}

body Grid::makeWidgetScrollable {w {break false}} {
	set breakCode ""
	if {$break} {
		set breakCode "break"
	}
	bind $w <Button-4> "
		$_tree yview scroll -1 units
		$breakCode
	"
	bind $w <Button-5> "
		$_tree yview scroll 1 units
		$breakCode
	"

	foreach c [winfo children $w] {
		makeWidgetScrollable $c $break
	}
}


body Grid::columnsEnd {{idx end}} {
	$_tree column configure [lindex $_cols $idx] -expand 1
}

body Grid::handleClick {x y {modifiers ""}} {
}

body Grid::handleDoubleClick {x y {modifiers ""}} {
	set item [$_tree identify $x $y]
	switch -- [lindex $item 0] {
		"item" {
			if {[lindex $item 3] == "0"} return
			edit [list [lindex $item 1] [lindex $item 3]]
		}
	}
	if {$itk_option(-doubleclicked) != ""} {
		eval $itk_option(-doubleclicked)
	}
}

body Grid::identify {x y} {
	set item [$_tree identify $x $y]
	switch -- [lindex $item 0] {
		"item" {
			if {[lindex $item 3] == "0"} return
			return [list [lindex $item 1] [lindex $item 3]]
		}
	}
	return [list]
}

body Grid::edit {item} {
	if {$itk_option(-readonly)} return
	if {[winfo exists $_editItem]} {
		destroy $_editItem
	}
	set geom [$_tree item bbox [lindex $item 0] [lindex $item 1]]
	set _editItem [entry $_tree.edit -background white -borderwidth 0 -validate key -validatecommand [list $this editCellModifiedFlagProxy]]
	if {[$_tree item element cget [lindex $item 0] [lindex $item 1] e_text -data] == "null"} {
		set value ""
	} else {
		set value [$_tree item element cget [lindex $item 0] [lindex $item 1] e_text -text]
	}
	set _disableModifyFlagDetection 1
	$_editItem insert end $value
	set _disableModifyFlagDetection 0
# 	bind $_editItem <Return> [list $this commitEdit $item]
# 	bind $_editItem <Escape> [list $this rollbackEdit $item]
# 	bind $_editItem <FocusOut> [list $this commitEdit $item]
# 	bind $_editItem <Down> [list $this goToCell next]
# 	bind $_editItem <Up> [list $this goToCell prev]
# 	bind $_editItem <Left> [list $this editArrowLeftRight $_editItem left]
# 	bind $_editItem <Right> [list $this editArrowLeftRight $_editItem right]
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
}

body Grid::setupStdBindsForEdit {item} {
	bind $_editItem <Return> [list $this commitEdit $item]
	bind $_editItem <Escape> [list $this rollbackEdit $item]
	bind $_editItem <FocusOut> [list $this commitEdit $item]
	bind $_editItem <Down> "$this goToCell next; break"
	bind $_editItem <Up> "$this goToCell prev; break"
	bind $_editItem <Left> "if {\[$this editArrowLeftRight $_editItem left]} break"
	bind $_editItem <Right> "if {\[$this editArrowLeftRight $_editItem right]} break"
	bind $_editItem <Control-a> "$_editItem selection range 0 end; break"
}

body Grid::editArrowLeftRight {item side} {
	set idx [$item index insert]
	switch -- $side {
		"left" {
			if {$idx != 0} {
				return 0
			}
		}
		"right" {
			set endIdx [$item index end]
			if {$endIdx != $idx} {
				return 0
			}
		}
		default {
			return 0
		}
	}
	goToCell $side
	return 1
}

body Grid::editCurrent {} {
	if {$_selected == ""} return
	edit $_selected
}

body Grid::editCellModifiedFlagProxy {} {
	if {$_disableModifyFlagDetection} {
		return 1
	}
	set _editCellModified 1
	return 1
}

body Grid::isEditCellModified {} {
	return $_editCellModified
}

body Grid::selectItem {x y {mark false}} {
	set item [$_tree identify $x $y]
	if {[lindex $item 0] != "item"} return
	if {[lindex $item 3] == "0"} return

	select [lindex $item 1] [lindex $item 3] $mark
}

body Grid::selectByIdx {rowIdx colIdx {mark false}} {
	set rows [getAllRows]
	set cols [getColumns]

	if {([llength $rows] - 1) < $rowIdx || $rowIdx < 0} {
		# Index out of range
		return
	}
	if {([llength $cols] - 1) < $colIdx || $colIdx < 0} {
		# Index out of range
		return
	}

	select [lindex $rows $rowIdx] [lindex $cols $colIdx 0] $mark
}

body Grid::select {it col {mark false}} {
	if {$mark && $itk_option(-multicell)} {
		set markedTmp $_marked
		setActive $it $col
		set _marked $markedTmp
		drawMarkedArea
	} elseif {$itk_option(-rowselection)} {
		lassign [getRowSelectionCols] first last
		#puts "selecting $it"
		setActive $it $first
		set _marked [list $it $last]
		drawMarkedArea
	} else {
		setActive $it $col
	}
}

body Grid::selectAll {} {
	selectIdxRange 0 0 end end
}

body Grid::selectIdxRange {fromRowIdx fromColIdx toRowIdx toColIdx} {
	if {[$_tree item count "all visible"] == 0} return

	set allColumns [lrange [$_tree column list -visible] 1 end]
	set allRows [$_tree item range "first visible" "last visible"]
	foreach {inVar outVar listVar} {
		fromRowIdx fromRow allRows
		fromColIdx fromCol allColumns
		toRowIdx toRow allRows
		toColIdx toCol allColumns
	} {
		set $outVar [lindex [set $listVar] [set $inVar]]
	}

	# Validating
	foreach {inVar listVar newIdx} {
		fromRow allRows 0
		toRow allRows end
		fromCol allColumns 0
		toCol allColumns end
	} {
		if {[set $inVar] == ""} {
			set $inVar [lindex [set $listVar] $newIdx]
			if {[set $inVar] == ""} return
		}
	}

	clearMarkArea
	set _marked [list $fromRow $fromCol]
	set _selected [list $toRow $toCol]
	drawMarkedArea
}

body Grid::markRow {it} {
	setActive $it [lindex $_cols 1]
	set _marked [list $it [lindex $_cols end]]
	drawMarkedArea
}

body Grid::markItem {x y} {
	if {!$itk_option(-multicell)} return
	set item [$_tree identify $x $y]
	if {[lindex $item 0] != "item"} return
	if {[lindex $item 3] == "0"} return
	set item [list [lindex $item 1] [lindex $item 3]]
# 	if {$item == $_marked} return
# 	if {$item == $_selected} return

	see {*}$item
	clearMarkArea
	set _marked $item
	drawMarkedArea
}

body Grid::drawMarkedArea {} {
	set newMark [getMarkedArea]
	foreach nmRow $newMark {
		foreach nm $nmRow {
			setMarkedDisplay $nm true
		}
	}
}

body Grid::clearMarkArea {{everything false}} {
	if {$_marked != "" && $_selected != ""} {
		set oldMark [getMarkedArea]
		foreach omRow $oldMark {
			foreach om $omRow {
				setMarkedDisplay $om false
			}
		}
		if {!$everything} {
			setMarkedDisplay $_selected true
		}
	}
	if {!$everything} {
		set _marked $_selected
	} else {
		set _marked [list]
		set _selected [list]
	}
}

body Grid::getTopLeftMarkedCell {} {
	if {$_selected == ""} return [list]
	if {$_marked == ""} {
		set _marked $_selected
		return $_selected
	}
	set min [expr {min([lindex $_selected 0],[lindex $_marked 0])}]

	set selCol [list [lindex $_selected 1] [$_tree column order [lindex $_selected 1] -visible]]
	set markCol [list [lindex $_marked 1] [$_tree column order [lindex $_marked 1] -visible]]
	lassign [lsort -integer -index 1 [list $selCol $markCol]] minColPair maxColPair
	set minCol [lindex $minColPair 0]

	return [list $min $minCol]
}

body Grid::getMarkedArea {} {
	if {$_selected == ""} return [list]
	if {$_marked == ""} {
		set _marked $_selected
	}

	# Determinating top and bottom bounds of marked area
	set min [expr {min([lindex $_selected 0],[lindex $_marked 0])}]
	set max [expr {max([lindex $_selected 0],[lindex $_marked 0])}]

	# Determinating left and right bounds of marked area
	set selCol [list [lindex $_selected 1] [$_tree column order [lindex $_selected 1] -visible]]
	set markCol [list [lindex $_marked 1] [$_tree column order [lindex $_marked 1] -visible]]
	lassign [lsort -integer -index 1 [list $selCol $markCol]] minColPair maxColPair
	set minCol [lindex $minColPair 0]
	set maxCol [lindex $maxColPair 0]

	# Getting list of columns to walk through them later
	set sortedColList [list]
	for {set col $minCol} {true} {set col [$_tree column id "$col next visible"]} {
		lappend sortedColList $col
		if {$col == $maxCol} {
			break
		}
	}

	# Walking through rows and their cells (using columns collected above)
	set rows [list]
	foreach r [$_tree item range $min $max] {
		set row [list]
		foreach c $sortedColList {
			lappend row [list $r $c]
		}
		lappend rows $row
	}
	return $rows
}

body Grid::getMarkedRows {} {
	if {$_selected == ""} return [list]
	if {$_marked == ""} {
		set _marked $_selected
	}
	set min [expr {min([lindex $_selected 0],[lindex $_marked 0])}]
	set max [expr {max([lindex $_selected 0],[lindex $_marked 0])}]
	return [$_tree item range $min $max]
}

body Grid::getText {item} {
	lassign $item it col
	if {$_colType($col) in [list "window" "image"]} {
		return ""
	}

	set value [$_tree item element cget $it $col e_text -text]
	return $value
}

body Grid::hasUpAvailable {} {
	if {$_selected == ""} {return 0}
	set prev [$_tree item id "[lindex $_selected 0] prev visible"]
	return [expr {$prev != ""}]
}

body Grid::hasDownAvailable {} {
	if {$_selected == ""} {return 0}
	set next [$_tree item id "[lindex $_selected 0] next visible"]
	return [expr {$next != ""}]
}

body Grid::goToCell {indexModifier {mark false}} {
	if {$_selected == ""} {return 0}
	set orient ""
	switch -- $indexModifier {
		"first" {
			set newRow [$_tree item id "first visible"]
			set newCol [lindex $_selected 1]
		}
		"last" {
			set newRow [$_tree item id "last visible"]
			set newCol [lindex $_selected 1]
		}
		"prev" - "next" {
			set newRow [$_tree item id "[lindex $_selected 0] $indexModifier visible"]
			set newCol [lindex $_selected 1]
		}
		"left" {
			if {$itk_option(-rowselection)} return
			set newRow [lindex $_selected 0]
			set newCol [$_tree column id "[lindex $_selected 1] prev visible"]
			if {$newCol == 0} {
				set newCol [lindex $_selected 1]
			}
		}
		"right" {
			if {$itk_option(-rowselection)} return
			set newRow [lindex $_selected 0]
			set newCol [$_tree column id "[lindex $_selected 1] next visible"]
		}
		"pageUp" {
			lassign [$_tree bbox content] left top right bottom
			set treeHg [expr {$bottom - $top}]
			lassign [$_tree item bbox [lindex $_selected 0]] left top right bottom
			set itemHg [expr {$bottom - $top}]
			set items [expr {int(ceil(double($treeHg) / double($itemHg))) - 2}]
			set idx [lindex $_selected 0]
			for {set i 0} {$i < $items} {incr i} {
				set idx [$_tree item id "$idx prev visible"]
				if {$idx == ""} {
					set idx [$_tree item id "first visible"]
					break
				}
			}
			set newRow $idx
			set newCol [lindex $_selected 1]
		}
		"pageDown" {
			lassign [$_tree bbox content] left top right bottom
			set treeHg [expr {$bottom - $top}]
			lassign [$_tree item bbox [lindex $_selected 0]] left top right bottom
			set itemHg [expr {$bottom - $top}]
			set items [expr {int(ceil(double($treeHg) / double($itemHg))) - 2}]
			set idx [lindex $_selected 0]
			for {set i 0} {$i < $items} {incr i} {
				set idx [$_tree item id "$idx next visible"]
				if {$idx == ""} {
					set idx [$_tree item id "last visible"]
					break
				}
			}
			set newRow $idx
			set newCol [lindex $_selected 1]
		}
		default {
			error "Unsupported index modifier: $indexModifier"
		}
	}
	if {$newRow == "" || $newCol == "" || $newCol == "tail"} {return 0}

	if {$mark && $itk_option(-multicell)} {
		set markedTmp $_marked
		setActive $newRow $newCol
		set _marked $markedTmp
		drawMarkedArea
	} elseif {$itk_option(-rowselection)} {
		lassign [getRowSelectionCols] first last
		setActive $newRow $first
		set _marked [list $newRow $last]
		drawMarkedArea
	} else {
		setActive $newRow $newCol
	}
	if {$itk_option(-navaction) != ""} {
		eval $itk_option(-navaction)
	}
	return 1
}

body Grid::deselect {} {
	clearMarkArea true
	$_tree activate root
}

body Grid::setActive {item column} {
	focus $_tree
	set c [lindex $_selected 1] ;# Old column
	set r [lindex $_selected 0] ;# Old row

	clearMarkArea

	if {$_selected != "" && [$_tree item id $r] != "" && [$_tree column id $c] != ""} {
		setMarkedDisplay $_selected false
	}

	setMarkedDisplay [list $item $column] true
	set _selected [list $item $column]
	set _marked $_selected
	$_tree activate $item
	see $item $column

	eval [string map [list %i $item %c $column] $_selectionChangedScript]
}

body Grid::setMarkedDisplay {item marked} {
	lassign $item r c

	set bg $background_color
	set fg $foreground_color
	set nullFg $null_foreground_color
	if {$marked} {
		set bg $selected_background_color
		set fg $selected_foreground_color
	}

	# Determinating column type
	switch -- $_colType($c) {
		"window" {
			set oldEl ""
		}
		"image" {
			set oldEl ""
		}
		default {
			set oldEl e_text
		}
	}
	$_tree item element configure $r $c e_border -fill $bg
	if {$oldEl != ""} {
		$_tree item element configure $r $c $oldEl -fill $fg
		if {$oldEl == "e_text" && [$_tree item element cget $r $c e_text -data] == "null"} {
			$_tree item element configure $r $c e_text -fill $nullFg
		}
	}
}

body Grid::reset {} {
	delRows
	if {[lindex $_cols 1] != ""} {
		if {[lindex $_cols 2] != ""} {
			$_tree column delete [lindex $_cols 1] [lindex $_cols end]
		} else {
			$_tree column delete [lindex $_cols 1]
		}
	}
	set _cols [lindex $_cols 0]
	set _rowNum 1
	set firstCol [lindex $_cols 0]
	set tmpType $_colType($firstCol)
	set tmpName $_colName($firstCol)
	catch {array unset _colType}
	catch {array unset _colName}
	set _colType($firstCol) $tmpType
	set _colName($firstCol) $tmpName
	set _selected ""
	refreshWidth
}

body Grid::delRows {} {
	$_tree item delete all
	set _rowNum 1
	set _selected ""
	set _marked ""
	if {$_editItem != ""} {
		destroy $_editItem
		set _editItem ""
	}
	refreshWidth
}

body Grid::getWidget {} {
	return $_tree
}

body Grid::commitEdit {{item ""} {getval no} {val ""}} {
	if {$itk_option(-readonly)} return

	if {$_editItem != ""} {
		destroy $_editItem
		set _editItem ""
	}
	set _editItemCell [list]
	set _editCellModified 0
	update idletasks
	refreshWidth
	#focus $_tree
}

body Grid::rollbackEdit {{item ""}} {
	if {$itk_option(-readonly)} return

	if {$_editItem != ""} {
		destroy $_editItem
		set _editItem ""
	}
	set _editItemCell [list]
	set _editCellModified 0
	focus $_tree ;# for some reason this focus was not set when rolled back with Esc
	update idletasks
	refreshWidth
}

body Grid::getRowSelectionCols {} {
	set first [$_tree column id "first visible"]
	set last [$_tree column id "last visible"]
	if {$itk_option(-basecol)} {
		set first [$_tree column id "$first next visible"]
	}
	return [list $first $last]
}

body Grid::setSelection {} {
	set _marked ""
	if {[llength $_selected] == 2 && [$_tree item id [lindex $_selected 0]] != "" && [$_tree column id [lindex $_selected 1]] != ""} {
		if {$itk_option(-rowselection)} {
			lassign [getRowSelectionCols] first last
			lassign $_selected fitem col
			setActive $fitem $first
			set _marked [list $fitem $last]
			drawMarkedArea
		} else {
			setActive {*}$_selected
		}
	} else {
		set fitem [$_tree item id "root firstchild visible"]
		set col [$_tree column id "first visible next visible"]
		if {$fitem != "" && $col != "" && $col != "tail"} {
			if {$itk_option(-rowselection)} {
				lassign [getRowSelectionCols] first last
				setActive $fitem $first
				set _marked [list $fitem $last]
				drawMarkedArea
			} else {
				setActive $fitem $col
			}
		} else {
			set _selected ""
			eval [string map [list %i "{}" %c "{}"] $_selectionChangedScript]
		}
	}
}

body Grid::columnExists {title} {
	foreach c $_cols {
		if {[string equal [$_tree column cget $c -text] $title]} {
			return 1
		}
	}
	return 0
}

body Grid::getColumnNames {} {
	set names [list]
	foreach c $_cols {
		lappend names [$_tree column cget $c -text]
	}
	return $names
}

body Grid::getColumnIdByName {colName} {
	foreach c $_cols {
		if {[$_tree column cget $c -text] == $colName} {
			return $c
		}
	}
	return ""
}

body Grid::getColumnIndexById {col {includeRowNum true}} {
	set i 0
	set cols [expr {$includeRowNum ? $_cols : [lrange $_cols 1 end]}]
	foreach c $cols {
		if {$c == $col} {
			return $i
		}
		incr i
	}
	return -1
}

body Grid::delSelected {} {
	if {$_selected == ""} return
	foreach rowItem [getMarkedRows] {
		$_tree item delete $rowItem
	}
	set _selected ""
	setSelection
}

body Grid::delRow {item} {
	if {$item == ""} return
	$_tree item delete [lindex $item 0]
	setSelection
}

body Grid::getSelectedRow {} {
	if {$_selected == ""} {
		return ""
	}
	return [lindex $_selected 0]
}

body Grid::getSelectedRowData {} {
	if {$_selected == ""} {
		return ""
	}
	return [getRowData [lindex $_selected 0]]
}

body Grid::getRowByIdx {idx} {
	set it [$_tree item id "first visible"]
	set i 0
	while {$it != ""} {
		if {$i == $idx} {
			return $it
		}
		set it [$_tree item id "$it next visible"]
		incr i
	}
	return ""
}

body Grid::getRowIndex {rowId} {
	set it [$_tree item id "first visible"]
	set i 0
	while {$it != ""} {
		if {$it == $rowId} {
			return $i
		}
		set it [$_tree item id "$it next visible"]
		incr i
	}
	return -1
}

body Grid::getRowSizeByIdx {idx} {
	return [getRowSize [getRowByIdx $idx]]
}

body Grid::getRowSize {rowId} {
	lassign [$_tree item bbox $rowId] left top right bottom
	return [list [expr {$right-$left}] [expr {$bottom-$top}]]
}

body Grid::getRowData {it} {
	set colId [$_tree column id "first"]
	set data [list]
	while {$colId != "" && $colId != "tail"} {
		if {$_colType($colId) in [list "window" "image"]} {
			lappend data ""
		} else {
			lappend data [$_tree item element cget $it $colId e_text -text]
		}
		set colId [$_tree column id "$colId next"]
	}
	return $data
}

body Grid::getMarkedItems {} {
	set markedItems [list]
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
	return $markedItems
}

body Grid::setSelectedRowData {data} {
	if {$_selected == ""} {
		return ""
	}
	setRowData $_selected $data
}

body Grid::setRowData {item data {refreshWidth true}} {
	set colId [$_tree column id 0]
	for {set i -1} {$colId != "" && $colId != "tail"} {incr i} {
		if {$i < 0} {
			set colId [$_tree column id "$colId next"]
			continue
		}
		set val [lindex $data $i]
		$_tree item element configure [lindex $item 0] $colId e_text -text $val -data "" -fill $foreground_color -font [list $font]
		set colId [$_tree column id "$colId next"]
	}
	if {$refreshWidth} {
		refreshWidth
	}
}

body Grid::setCellData {item col value {refreshWidth true}} {
	$_tree item element configure $item $col e_text -text $value -data "" -fill $foreground_color -font [list $font]
	if {$refreshWidth} {
		refreshWidth
	}
}

body Grid::getCellData {item col} {
	return [$_tree item element cget $item $col e_text -text]
}

body Grid::getSelectedCell {} {
	if {$_selected == ""} {
		return ""
	}
	return $_selected
}

body Grid::getSelectedCellData {} {
	if {$_selected == ""} {
		return ""
	}
	set item $_selected
	return [$_tree item element cget [lindex $item 0] [lindex $item 1] e_text -text]
}

body Grid::columnConfig {col args} {
	eval $_tree column configure $col $args
	refreshWidth
}

body Grid::updateUISettings {} {
	$_tree configure -background $background_color -foreground $foreground_color -font $font
	$_tree element configure e_border -outline $grid_color
	$_tree column configure 0 -itembackground $base_col_background_color
	$_tree element configure e_text -font [list $font]

	$_tree style layout s_text e_text -maxwidth $maxColumnWidth
	$_tree style layout s_image e_image -maxwidth $maxColumnWidth

	# Header font
	foreach colId [$_tree column list] {
		$_tree column configure $colId -font $boldFont
	}

	if {$_selected != ""} {
		lassign $_selected it col
		$_tree item element configure $it $col e_border -fill $selected_background_color
		switch -- $_colType($col) {
			"window" {
				# No-op
			}
			"image" {
				# No-op
			}
			default {
				$_tree item element configure $it $col e_text -fill $selected_foreground_color
			}
		}
	}
	refreshWidth
}

body Grid::sort {{column 1}} {
	$_tree item sort root -dictionary -column $column -element e_text
}

body Grid::count {{mods ""}} {
	return [expr {[$_tree item count {*}$mods] - 1}]
}

body Grid::getCellPosition {item {includeRowNum false}} {
	set xpos 0
	set ypos 0
	set resultX ""
	set resultY ""
	lassign $item it col

	set searchItem [$_tree item id "first visible"]
	while {$searchItem != ""} {
		if {$it == $searchItem} {
			set resultY $ypos
			break
		}
		incr ypos
		set searchItem [$_tree item id "$searchItem next visible"]
	}

	if {$includeRowNum} {
		set searchCol [$_tree column id "first"]
	} else {
		set searchCol [$_tree column id "first next"]
	}
	while {$searchCol != "" && $searchCol != "tail"} {
		if {$col == $searchCol} {
			set resultX $xpos
			break
		}
		incr xpos
		set searchCol [$_tree column id "$searchCol next"]
	}
	return [list $resultX $resultY]
}

body Grid::get {{includeRowNum false}} {
	set item [$_tree item id "first visible"]
	set list [list]

	while {$item != ""} {
		if {$includeRowNum} {
			set colId [$_tree column id "first"]
		} else {
			set colId [$_tree column id "first next"]
		}
		set rowNumId [$_tree column id 1]
		set rowData [list]
		while {$colId != "" && $colId != "tail"} {
			if {$_colType($colId) ni {image window}} {
				lappend rowData [$_tree item element cget [lindex $item 0] $colId e_text -text]
			} else {
				lappend rowData ""
			}
			set colId [$_tree column id "$colId next"]
		}
		lappend list $rowData
		set item [$_tree item id "$item next visible"]
	}

	return $list
}

body Grid::getAllRows {} {
	set item [$_tree item id "first visible"]
	set list [list]

	while {$item != ""} {
		lappend list $item
		set item [$_tree item id "$item next visible"]
	}
	return $list
}

body Grid::getRowDetails {rowId} {
	set results [list]
	foreach colDesc [getColumns] {
		lassign $colDesc col colName colType
		set type $_colType($col)
		set name $_colName($col)
		switch -- $_colType($col) {
			"window" {
				set data [$_tree item element cget $rowId $col e_win -window]
			}
			"image" {
				set data [$_tree item element cget $rowId $col e_image -image]
			}
			default {
				set data [$_tree item element cget $rowId $col e_text -text]
			}
		}
		lappend results [list $name $type $data]
	}
	return $results
}

body Grid::setBaseRowNum {val} {
	set _rowNum $val
}

body Grid::getColumns {{includeRowNum false}} {
	set cols [$_tree column list]
	if {!$includeRowNum} {
		set cols [lrange $cols 1 end]
	}
	set list [list]
	foreach c $cols {
		lappend list [list $c $_colName($c) $_colType($c)]
	}
	return $list
}

body Grid::getColumnsAsDisplayed {{includeRowNum false}} {
	set cols [$_tree column list]
	if {!$includeRowNum} {
		set cols [lrange $cols 1 end]
	}
	set list [list]
	foreach c $cols {
		lappend list [list $c [getColumnName $c] $_colType($c)]
	}
	return $list
}

body Grid::getColData {colName} {
	set list [list]
	set col ""
	set colId [$_tree column id "first"]
	while {$colId != "" && $colId != "tail"} {
		if {[$_tree column cget $colId -text] == $colName} {
			set col $colId
			break
		}
		set colId [$_tree column id "$colId next"]
	}

	if {$col == ""} {
		return $list
	}

	return [getColIdData $col]
}
	
body Grid::getColIdData {colId} {
	set item [$_tree item id "first visible"]
	set list [list]
	while {$item != ""} {
		set rowData [list]
		switch -- $_colType($colId) {
			"window" {
				set data [$_tree item element cget [lindex $item 0] $colId e_win -window]
			}
			"image" {
				set data [$_tree item element cget [lindex $item 0] $colId e_image -image]
			}
			default {
				set data [$_tree item element cget [lindex $item 0] $colId e_text -text]
			}
		}
		lappend list $data
		set item [$_tree item id "$item next visible"]
	}

	return $list
}


body Grid::getColIdxData {colIdx} {
	set list [list]
	set colId [$_tree column id "order $colIdx visible"]

	if {$colId == ""} {
		return $list
	}

	return [getColIdData $colId]
}

body Grid::destroyChilds {} {
	foreach child [winfo children $_tree] {
		destroy $child
	}
}

body Grid::copyMarked {} {
	set outRows [list]
	foreach inRow [getMarkedArea] {
		set outCols [list]
		foreach inCell $inRow {
			set val [getText $inCell]
			if {[string first "\t" $val] > -1 || [string first "\n" $val] > -1} {
				set val "\"[string map [list \" \"\"] $val]\""
			}
			lappend outCols $val
		}
		lappend outRows [join $outCols "\t"]
	}
	set data [join $outRows "\n"]
	setClipboard $data
}

body Grid::paste {} {
	set start [getTopLeftMarkedCell]
	if {$start == ""} {
		Error [mc {You have to select a cell before paste any contents.}]
		return 0
	}

	return 1
}

body Grid::getEditItem {} {
	return $_editItem
}

body Grid::processClipboardForPaste {topLeftMarkedCell} {
	if {[catch {
		set data [getClipboard]
	} err]} {
		debug "Error while trying to read from clipboard: $err"
		return
	}
	set rows [list]

	# Processing whole data to split for rows and columns
	# (when copied from SQLiteStudio or some spreadsheet).
	set quote 0
	set buff ""
	set nextValExpected 0
	set cols [list]
	foreach c [split $data ""] {
		set nextValExpected 0
		if {[string equal "\"" $c]} {
			if {!$quote && $buff == ""} {
				set quote 1
			} elseif {$quote} {
				set quote 0
			}
			append buff $c
		} elseif {[string equal "\t" $c]} {
			if {!$quote} {
				set val $buff
				set buff ""
				if {[string index $val 0] == "\"" && [string index $val end] == "\""} {
					set val [string range $val 1 end-1]
				}
				lappend cols $val
				set nextValExpected 1
			} else {
				append buff $c
			}
		} elseif {[string equal "\n" $c]} {
			if {!$quote} {
				set val $buff
				set buff ""
				if {[string index $val 0] == "\"" && [string index $val end] == "\""} {
					set val [string range $val 1 end-1]
				}
				lappend cols $val
				lappend rows $cols
				set cols [list]
			} else {
				append buff $c
			}
		} else {
			append buff $c
		}
	}

	# Processing rest from buffers
	if {$buff != "" || $nextValExpected} {
		set val $buff
		if {[string index $val 0] == "\"" && [string index $val end] == "\""} {
			set val [string range $val 1 end-1]
		}
		lappend cols $val
	}
	if {[llength $cols] > 0} {
		lappend rows $cols
	}

	# Now we have pasted data as nested list of rows and columns
	# We have to check if number of columns and rows can be pasted in whole
	# or it's too big and we have to ask user what to do.
	set maxRows 0
	set maxCols 0
	foreach row $rows {
		set lgt [llength $row]
		if {$lgt > $maxCols} {
			set maxCols $lgt
		}
		incr maxRows
	}
	set totalColumns [llength [getColumns]]
	set totalRows [count]
	lassign [getCellPosition $topLeftMarkedCell] x y

	# Let user to deciede
	# If user deciedes to cut - we cut.
	set cutTooBig 0
	if {($totalColumns-$maxCols) < $x || ($totalRows-$maxRows) < $y} {
		if {$askIfCutBigClipboard} {
			set dialog [YesNoDialog .yesno -title [mc {Cut data}] -message [mc {There are too many columns or rows to paste. Do you want to cut them and paste?}]]
			set cut [$dialog exec]
		} else {
			set cut true
		}
		if {$cut} {
			if {($totalColumns-$maxCols) < $x} {
				set maxCols [expr {$totalColumns-$x-1}] ;# -1 is for indexing by lrange - it needs end index to be excluded
				for {set rowIdx 0} {$rowIdx < [llength $rows]} {incr rowIdx} {
					set rows [lreplace $rows $rowIdx $rowIdx [lrange [lindex $rows $rowIdx] 0 $maxCols]]
				}
			}
			if {($totalRows-$maxRows) < $y} {
				set maxRows [expr {$totalRows-$y-1}] ;# -1 is for indexing by lrange - it needs end index to be excluded
				set rows [lrange $rows 0 $maxRows]
			}
		} else {
			# User canceled paste operation
			return ""
		}
	}
	if {$rows == ""} {
		set rows [list [list [list]]]
	}
	refreshWidth
	return $rows
}

body Grid::scrolledVertically {} {
	if {$_editItem != ""} {
		lassign $_editItemCell it col
		set geom [$_tree item bbox $it $col]
		lassign $geom x1 y1 x2 y2
		if {$itk_option(-xscroll)} {
			set treeWidth [winfo width $_tree]
			lassign [$_xframe xview] fromFraction toFraction
			set mod [expr {int(round($fromFraction * $treeWidth))}]
			incr x1 -$mod
			incr x2 -$mod
		}
		place $_editItem -x $x1 -y $y1 -width [expr {$x2-$x1-1}] -height [expr {$y2-$y1-1}]
	}
}

body Grid::scrolledHorizontally {} {
	if {$_editItem != ""} {
		lassign $_editItemCell it col
		set geom [$_tree item bbox $it $col]
		lassign $geom x1 y1 x2 y2
		if {$itk_option(-xscroll)} {
			set treeWidth [winfo width $_tree]
			lassign [$_xframe xview] fromFraction toFraction
			set mod [expr {int(round($fromFraction * $treeWidth))}]
			incr x1 -$mod
			incr x2 -$mod
		}
		place $_editItem -x $x1 -y $y1 -width [expr {$x2-$x1-1}] -height [expr {$y2-$y1-1}]
	}
}

body Grid::getColumnName {col} {
	return [$_tree column cget $col -text]
}

body Grid::setColumnName {col name} {
	$_tree column configure $col -text $name
}

body Grid::setRowTags {it tags} {
	$_tree item configure $it -tags $tags
}

body Grid::getRowTags {it} {
	$_tree item cget $it -tags
}

body Grid::onDrag {x y} {
	#setDndData [list $this [getSelectedAreaDataWithNull]] ;# not necessary currently
	setDndData [list $this ""]
	set cmd $itk_option(-dragcmd)
	eval $cmd
}

body Grid::onDrop {x y} {
	set cmd $itk_option(-dropcmd)
	eval $cmd $x $y
	refreshWidth
}

body Grid::isDndPossible {x y} {
	return [expr {$_selected != "" && [identify $x $y] != ""}]
}

body Grid::getDragImage {} {
	return img_column
}

body Grid::getDragLabel {} {
	set results [list]
	lassign $_selected rowId selCol
	set cols [getColumns]
	if {[llength $cols] > 0} {
		lassign [lindex $cols 0] col colName colType
		switch -- $_colType($col) {
			"window" {
				set data [$_tree item element cget $rowId $col e_win -window]
			}
			"image" {
				set data [$_tree item element cget $rowId $col e_image -image]
			}
			default {
				set data [$_tree item element cget $rowId $col e_text -text]
			}
		}
		return $data
	} else {
		return ""
	}
}

body Grid::see {it {col ""}} {
	$_tree see $it

	if {$col == ""} return

	if {$itk_option(-xscroll)} {
		lassign [$_tree item bbox $it] left top right bottom
		set canvasWidth [$_tree canvasx $right]
		set frameWidth [winfo width $_xframe]

		lassign [$_tree column bbox $col] left top right bottom
		set columnLeft [$_tree canvasx $left]
		set columnRight [$_tree canvasx $right]

		set marginFraction [expr {100.0 / double($canvasWidth)}]
#
		lassign [$_xframe xview] fromFraction toFraction

		set leftFraction [expr {$columnLeft / double($canvasWidth) - $marginFraction}]
		set rightFraction [expr {$columnRight / double($canvasWidth) + $marginFraction}]
		set rightFractionToMove [expr {($columnRight - $frameWidth) / double($canvasWidth) + $marginFraction}]

		if {$leftFraction < $fromFraction} {
			$_xframe xview moveto $leftFraction
		} elseif {$rightFraction > $toFraction} {
			$_xframe xview moveto $rightFractionToMove
		}
	} else {
		# Without scrolled frame.
		lassign [$_tree item bbox $it] left top right bottom
		set canvasWidth [$_tree canvasx $right]

		lassign [$_tree column bbox $col] left top right bottom
		set columnLeft [$_tree canvasx $left]

		set fraction [expr {$columnLeft / double($canvasWidth)}]
		$_tree xview moveto $fraction
	}
}

body Grid::isCurrentlyEdited {} {
	expr {$_editItem != ""}
}

body Grid::getColumnIdByIndex {idx} {
	set i 0
	set colId [$_tree column id "first"]
	while {$colId != "" && $colId != "tail" && $i < $idx} {
		set colId [$_tree column id "$colId next"]
		incr i
	}

	if {$colId == "" || $colId == "tail" || $i < $idx} {
		return ""
	} else {
		return $colId
	}
}

body Grid::hideRow {rowId} {
	$_tree item configure $rowId -visible 0
	if {[lindex $_selected 0] == $rowId} {
		deselect
	}
}

body Grid::showRow {rowId} {
	$_tree item configure $rowId -visible 1
}

body Grid::moveRowUp {rowId} {
	set prevId [$_tree item prevsibling $rowId]
	if {$prevId == ""} {
		return 0
	}

	$_tree item nextsibling $rowId $prevId
	return 1
}

body Grid::moveRowDown {rowId} {
	set nextId [$_tree item nextsibling $rowId]
	if {$nextId == ""} {
		return 0
	}

	$_tree item prevsibling $rowId $nextId
	return 1
}

body Grid::moveRowTo {rowId index} {
	set newId [getRowByIdx $index]
	if {$newId == ""} {
		return 0
	}
	
	$_tree item nextsibling $rowId $newId
}

body Grid::moveRowBefore {rowId beforeRowId} {
	$_tree item nextsibling $rowId $beforeRowId
}

body Grid::moveRowAfter {rowId afterRowId} {
	$_tree item prevsibling $rowId $afterRowId
}

body Grid::moveRowToBegining {rowId} {
	$_tree item firstchild root $rowId
}

body Grid::moveRowToEnd {rowId} {
	$_tree item lastchild root $rowId
}
