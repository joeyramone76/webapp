use src/common/mdi_win.tcl
use src/shortcuts.tcl
use src/data_editor.tcl

#>
# @class TableWin
# Table managing MDI window. Provides data preview, friendly view of table structure,
# constraints, triggers, DDL and more.
#<
class TableWin {
	inherit MDIWin DataEditor Shortcuts

	#>
	# @method constructor
	# @param title New window title.
	# @param db Database that given table exists in.
	# @param table Table linked with the window.
	#<
	constructor {title db table} {
		MDIWin::constructor $title img_table
	} {}

	#>
	# @method destructor
	# Deletes all internal (but global) objects to clear memory, such as SQL editor widget, results grid, etc.
	#<
	destructor {}

	#>
	# @var resultsPerPage
	# Keeps number of rows displayed at once in data grid.
	# It's configured by {@class CfgWin}. It's also used by {@class EditorWin}
	# for the same role in its results grid.
	#<
	common resultsPerPage 1000

	common openTabOnCreate 0
	common rowIdsByDefault false

	private {
		#>
		# @var _db
		# {@class DB} object linked with the window.
		#<
		variable _db ""
		variable _sqliteVersion 3

		#>
		# @var _table
		# Table linked with the window (table edited in this window).
		#<
		variable _table ""

		#>
		# @var _tabs
		# Main tabs widget.
		#<
		variable _tabs ""

		#>
		# @var _cols
		# Frame (tab) with table structure (grid with column definitions is placed in it).
		#<
		variable _cols ""

		#>
		# @var _date
		# Frame (tab) with data preview.
		#<
		variable _data ""

		#>
		# @var _cons
		# Frame (tab) with constraints list.
		#<
		variable _cons ""

		#>
		# @var _idx
		# Frame (tab) with indexes list.
		#<
		variable _idx ""

		#>
		# @var _trig
		# Frame (tab) with triggers related to the edited table.
		#<
		variable _trig ""

		#>
		# @var _sql
		# Frame (tab) with table DDL code.
		#<
		variable _sql ""

		#>
		# @var _colsGrid
		# Table structure (columns list) grid object.
		#<
		variable _colsGrid ""

		#>
		# @var _dataGrid
		# Data preview grid object.
		#<
		variable _dataGrid ""

		#>
		# @var _dataForm
		# Data row edit form (form view subtab).
		#<
		variable _dataForm ""

		#>
		# @var _idxGrid
		# Indexes list grid object.
		#<
		variable _idxGrid ""

		#>
		# @var _consGrid
		# Constraints list grid object.
		#<
		variable _consGrid ""

		#>
		# @var _trigGrid
		# Triggers list grid object.
		#<
		variable _trigGrid ""

		#>
		# @var _sqlEditor
		# DDL code editor (browser) object.
		#<
		variable _sqlEditor ""

		#>
		# @var _dataTabs
		# Data subtabs widget.
		#<
		variable _dataTabs ""

		#>
		# @var _dataGridTab
		# Frame (subtab) with data preview grid.
		#<
		variable _dataGridTab ""

		#>
		# @var _dataFormTab
		# Frame (subtab) with single data row edit form.
		#<
		variable _dataFormTab ""

		#>
		# @arr _tb
		# Toolbars list. Valid indexes:<br>
		# <ul>
		# <li><code>cols</code> - Table structure (columns list) toolbar.
		# <li><code>data</code> - Data preview toolbar.
		# <li><code>dataform</code> - Data single row edit form toolbar.
		# <li><code>idx</code> - Indexes toolbar.
		# <li><code>trig</code> - Triggers toolbar.
		# </ul>
		#<
		variable _tb

		#>
		# @arr _tbt
		# Toolbar widgets (mostly buttons) list. For array indexes see source code.
		#<
		variable _tbt

		#>
		# @var _dataRead
		# It allows to set focus to data grid without reloading its data. It's used because
		# normally data is reloaded when grid gets focused (data tab has been choosen).
		#<
		variable _dataRead 0

		#>
		# @var _constrs
		# Constraints list. Each constraint element consists of:<br>
		# <code>name column default notnull pk unique collate check</code>
		#<
		variable _constrs [list]

		#>
		# @var _columns
		# Columns list. Each column element is just the column name.
		#<
		variable _columns [list]

		#>
		# @var _page
		# Current page in data grid.
		#<
		variable _page 0

		#>
		# @var _lastPage
		# Last possible page, counting by number of rows in table data.
		# It's used by "Last page" data toolbar button.
		#<
		variable _lastPage 0

		#<
		# @var _totalRows
		# Keeps track of total rows in table.
		#<
		variable _totalRows 0

		#>
		# @var _dataSorting
		# Contains two elements. First is column name that data is sorted by,
		# second is direction of sorting - <code>ASC</code> or <code>DESC</code>.
		#<
		variable _dataSorting [list]

		variable _triggersRead 0
		variable _indexRead 0

		#>
		# @method getGridObject
		# @overloaded DataEditor
		#<
		method getGridObject {}

		#>
		# @method getFormFrame
		# @overloaded DataEditor
		#<
		method getFormFrame {}
	}
	
	protected {
		method getSelectedRowDataWithNull {{limited true}}
	}

	public {
		variable filterPhrase ""

		#>
		# @method focusTab
		# Makes sure that currently choosen tab has an input focus.
		#<
		method focusTab {}

		method getFocusedTab {}

		#>
		# @method refreshColumns
		# @param doFocus <code>true</code> to set input focus to currently choosen tab, <code>false</code> otherwise.
		# @param refreshDataGridColumns <code>true</code> to delete {@var _dataGrid} columns and rows and recreate columns. <code>false</code> to leave {@var _dataGrid} without changes.
		# Refreshes table structure (columns list and their descriptions), constraints list and table DDL.
		#<
		method refreshColumns {{doFocus true} {refreshDataGridColumns true}}

		#>
		# @method refreshData
		# Refreshes table data.
		#<
		method refreshData {}

		#>
		# @method refreshIndexes
		# Refreshes indexes list.
		#<
		method refreshIndexes {}

		#>
		# @method refreshTriggers
		# Refreshes triggers related to the {@var _table}.
		#<
		method refreshTriggers {}

		#>
		# @method editTable
		# @return Table linked to the window. It's {@var _table}.
		#<
		method editTable {}
		method createSimilarTable {}

		#>
		# @method addRow
		# Adds new, virtual row. It needs to be commited (by {@method commitNewRow}) to add it to table in database.
		#<
		method addRow {}
		method addRows {}

		#>
		# @method delRow
		# Deletes currently selected row. No matter if it's new, virtual row, or regular one.
		#<
		method delRow {}

		#>
		# @method delRowInFormView
		# Does same as {@method delRow}, except it stays in form view tab.
		#<
		method delRowInFormView {}

		#>
		# @method newIndex
		# Opens new index dialog to add index for the {@var _table}.
		#<
		method newIndex {}
		method editIndex {}

		#>
		# @method delIndex
		# Delets currently selected index.
		#<
		method delIndex {}

		#>
		# @method newTrigger
		# Opens new trigger dialog to add trigger for the {@var _table}.
		#<
		method newTrigger {}
		method editTrigger {}

		#>
		# @method delTrigger
		# Deletes currently selected trigger.
		#<
		method delTrigger {}

		#>
		# @method signal
		# @overloaded Signal
		#<
		method signal {receiver data}

		#>
		# @method activated
		# @overloaded MDIWin
		#<
		method activated {}

		#>
		# @method enableRowNavBtn
		# @param list List of navigation buttons to enable. Leave it empty to affect all buttons.
		# Enables data preview navigation buttons. List of valid optional names of buttons to enable:<br>
		# <ul>
		# <li><code>refresh</code>,
		# <li><code>addrow</code>,
		# <li><code>delrow</code>,
		# <li><code>commitnew</code>,
		# <li><code>rollbacknew</code>,
		# <li><code>first</code>,
		# <li><code>prev</code>,
		# <li><code>next</code>,
		# <li><code>last</code>
		# </ul>
		#<
		method enableRowNavBtn {{list ""}}
		method enableFormNavBtn {{list ""}}

		#>
		# @method disableRowNavBtn
		# @param list List of navigation buttons to disable. Leave it empty to affect all buttons.
		# Disables data preview navigation buttons. List of valid optional names of buttons to disable:<br>
		# <ul>
		# <li><code>refresh</code>,
		# <li><code>addrow</code>,
		# <li><code>delrow</code>,
		# <li><code>commitnew</code>,
		# <li><code>rollbacknew</code>,
		# <li><code>first</code>,
		# <li><code>prev</code>,
		# <li><code>next</code>,
		# <li><code>last</code>
		# </ul>
		#<
		method disableRowNavBtn {{list ""}}
		method disableFormNavBtn {{list ""}}

		#>
		# @method nextRows
		# Switches data preview to next page (if available).
		#<
		method nextRows {}

		#>
		# @method prevRows
		# Switches data preview to previous page (if available).
		#<
		method prevRows {}

		#>
		# @method lastRows
		# Switches data preview to the last page.
		#<
		method lastRows {}

		#>
		# @method firstRows
		# Switches data preview to first page.
		#<
		method firstRows {}

		#>
		# @method formNextRow
		# Switches data form view to next row (if available).
		#<
		method formNextRow {}

		#>
		# @method formPrevRow
		# Switches data form view to previous row (if available).
		#<
		method formPrevRow {}

		#>
		# @method formLastRow
		# Switches data form view to the last row.
		#<
		method formLastRow {}

		#>
		# @method formFirstRow
		# Switches data form view to first row.
		#<
		method formFirstRow {}

		#>
		# @method addRow
		# Does same as {@method addRow}, except it stays in form view tab.
		#<
		method addRowInFormView {}

		#>
		# @method exportTable
		# Opens export dialog to export {@var _table}.
		#<
		method exportTable {}

		#>
		# @method importTable
		# Opens import dialog to import data to {@var _table}.
		#<
		method importTable {}

		#>
		# @method getSessionString
		# @overloaded Session
		#<
		method getSessionString {}

		#>
		# @method restoreSession {sessionString}
		# @overloaded Session
		#<
		proc restoreSession {sessionString}

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
		# @method sortingChanged
		# @param columnName Name of column to use when sorting.
		# @param order <code>ASC</code> or <code>DESC</code>.
		#<
		method sortingChanged {columnName order}

		#>
		# @method populateTable
		# Opens dialog for populating table.
		#<
		method populateTable {}

		#>
		# @method getBaseRowNum
		# @return Number of first row visible in the grid, basing on {@var resultsPerPage} and current {@var _page}.
		#<
		method getBaseRowNum {}

		#>
		# @method refreshTotalNumberOfRows
		# Refreshes total number of rows visible on top of table window in data tab, next to toolbars.
		#<
		method refreshTotalNumberOfRows {}

		#>
		# @method refreshWindowContents
		# @param args Optional options to be passed.
		# Possible options:
		#<
		method refreshWindowContents {args}

		#>
		# @method clearFilter
		# Clears filter phrase and refreshes data without it.
		#<
		method clearFilter {}

		method changeTable {newTable}

		method selectionChanged {type it col}

		method editSelectedColumn {}
		method editDoubleClickedColumn {x y}
		method updateEditorToolbar {}
		method reformatDdl {}
		method updateUISettings {}
		method updateFormViewToolbar {}
		method prevDataTab {}
		method nextDataTab {}
		method getDataTabs {}
		method columnEnterLeaveHint {enterOrLeave col}
		method canDestroy {}
		method getDb {}
		method getTable {}

		#>
		# @method constrSort
		# @param it1 Constraint element.
		# @param it2 Constraint element.
		# Sorts constraints by column name.
		#<
		proc constrSort {it1 it2}

		#>
		# @method formatTitle
		# @param table Table name.
		# @param db {@class DB} database object.
		# Formats window title for given database and table. Currently it makes title as following:<br>
		# <code>table (database name)</code>
		#<
		proc formatTitle {table db}

		#>
		# @method isGlobalTableConstraint
		# @param col Column name to validate. Any additional opening brackets on the right '(' will be ignored.
		# Checks if given column name (first word in column definition) is really column name or table global constraint.
		# @return <code>true</code> if column is table global constraint or <code>false</code> if it's regular column name.
		#<
		proc isGlobalTableConstraint {col}
	}
}

body TableWin::constructor {title db table} {
	if {$db != "" && [$db getHandler] == "::Sqlite3"} {
		set _sqliteVersion 3
	} else {
		set _sqliteVersion 2
	}

	# Tabs
	set _tabs [ttk::notebook $_main.tabs]
	pack $_main.tabs -side top -fill both -expand 1

	set _cols [ttk::frame $_tabs.cols]
	set _data [ttk::frame $_tabs.data]
	set _cons [ttk::frame $_tabs.cons]
	set _idx [ttk::frame $_tabs.idx]
	set _trig [ttk::frame $_tabs.triggers]
	set _sql [ttk::frame $_tabs.sql]

	$_tabs add $_cols -text [mc {Structure}]
	$_tabs add $_data -text [mc {Data}]
	#$_tabs add $_cons -text [mc {Constraints}]
	$_tabs add $_idx -text [mc {Indexes}]
	$_tabs add $_trig -text [mc {Triggers}]
	$_tabs add $_sql -text DDL

	set _dataTabs [ttk::notebook $_data.tabs]
	pack $_dataTabs -side top -fill both -expand 1
	set _dataGridTab [ttk::frame $_dataTabs.grid]
	set _dataFormTab [ttk::frame $_dataTabs.form]

	bind $_tabs <ButtonPress-1> [list $this focusWithDelay]

	$_dataTabs add $_dataGridTab -text [mc {Grid view}]
	$_dataTabs add $_dataFormTab -text [mc {Form view}]

	# Columns tab toolbar
	set _tb(cols) [Toolbar $_cols.toolbar]
	pack $_tb(cols) -side top -fill x

	set _tbt(cols:refresh) [$_tb(cols) addButton img_db_refresh [mc "Refresh table columns and DDL (%s)" ${::Shortcuts::refresh}] "$this refreshWindowContents -columnsonly true"]
	set _tbt(cols:edit) [$_tb(cols) addButton img_table_edit [mc "Edit table (%s)" "t"] "$this editTable"]
	set _tbt(cols:export) [$_tb(cols) addButton img_table_export [mc "Export table data (%s)" "x"] "$this exportTable"]
	set _tbt(cols:import) [$_tb(cols) addButton img_table_import [mc "Import data to table (%s)" "i"] "$this importTable"]
	set _tbt(cols:populate) [$_tb(cols) addButton img_populate_table [mc {Populate table (%s)} "p"] "$this populateTable"]
	set _tbt(cols:sim_table) [$_tb(cols) addButton img_table_similar [mc {Create similar table}] "$this createSimilarTable"]

	# Data tab toolbar
	set _tb(data) [Toolbar $_dataGridTab.toolbar]
	pack $_tb(data) -side top -fill x

	set _tbt(data:refresh) [$_tb(data) addButton img_db_refresh [mc "Refresh table data (%s)" ${::Shortcuts::refresh}] "$this refreshWindowContents -dataonly true"]
	$_tb(data) addSeparator
	set _tbt(data:addrowcustom) [$_tb(data) addButton img_db_insert_custom [mc "Add custom number of rows"] "$this addRows"]
	set _tbt(data:addrow) [$_tb(data) addButton img_db_insert [mc "Add new row (%s)" ${::Shortcuts::insertRow}] "$this addRow"]
	set _tbt(data:delrow) [$_tb(data) addButton img_db_delete [mc "Delete selected row (%s)" ${::Shortcuts::deleteRow}] "$this delRow"]
	set _tbt(data:commitnew) [$_tb(data) addButton img_db_post [mc "Commit changes (%s)" ${::Shortcuts::commitFormView}] "$this commitGrid"]
	set _tbt(data:rollbacknew) [$_tb(data) addButton img_db_cancel [mc "Rollback new row (%s)" ${::Shortcuts::rollbackFormView}] "$this rollbackGrid"]
	$_tb(data) addSeparator
	set _tbt(data:first) [$_tb(data) addButton img_db_first [mc "First %s rows" $resultsPerPage] "$this firstRows"]
	set _tbt(data:prev) [$_tb(data) addButton img_db_previous [mc "Previous %s rows" $resultsPerPage] "$this prevRows"]
	set _tbt(data:next) [$_tb(data) addButton img_db_next [mc "Next %s rows" $resultsPerPage] "$this nextRows"]
	set _tbt(data:last) [$_tb(data) addButton img_db_last [mc "Last %s rows" $resultsPerPage] "$this lastRows"]
	$_tb(data) addSeparator
	set _tbt(data:export) [$_tb(data) addButton img_table_export [mc "Export table data"] "$this exportTable"]
	set _tbt(data:import) [$_tb(data) addButton img_table_import [mc "Import data to table"] "$this importTable"]
	set _tbt(data:populate) [$_tb(data) addButton img_populate_table [mc {Populate table}] "$this populateTable"]
	$_tb(data) addSeparator
	set _tbt(data:filter) [$_tb(data) addEntry [mc {Enter phrase you want to look for}] [scope filterPhrase]]
	set _tbt(data:apply_filter) [$_tb(data) addButton img_filter [mc {Apply data filter}] "$this refreshWindowContents -dataonly true"]
	set _tbt(data:clr_filter) [$_tb(data) addButton img_clear_filter [mc {Clear data filter}] "$this clearFilter"]
	$_tb(data) addSeparator
	set _tbt(data:total_rows) [$_tb(data) addLabel [mc {Total rows: %s} 0] ""]

	bind $_tbt(data:filter) <Return> [list $this refreshWindowContents -dataonly true]
	bind $_tbt(data:filter) <Return> +[list after 10 [list catch [list focus $_tbt(data:filter)]]]

# 		commitnew
# 		rollbacknew
	foreach idx {
		first
		prev
		next
		last
	} {
		$_tb(data) setActive 0 $_tbt(data:$idx)
	}

	# Data tab toolbar (form view)
	set _tb(dataform) [Toolbar $_dataFormTab.toolbar]
	pack $_tb(dataform) -side top -fill x

	set _tbt(dataform:addrow) [$_tb(dataform) addButton img_db_insert [mc "Add new row (%s)" ${::Shortcuts::insertRow}] "$this addRowInFormView"]
	set _tbt(dataform:delrow) [$_tb(dataform) addButton img_db_delete [mc "Delete selected row"] "$this delRowInFormView"]
	set _tbt(dataform:commit) [$_tb(dataform) addButton img_db_post [mc "Commit changes (%s)" ${::Shortcuts::commitFormView}] "$this commitFormEdit"]
	set _tbt(dataform:rollback) [$_tb(dataform) addButton img_db_cancel [mc "Rollback changes (%s)" ${::Shortcuts::rollbackFormView}] "$this rollbackFormEdit"]
	$_tb(dataform) addSeparator
	set _tbt(dataform:first) [$_tb(dataform) addButton img_db_first [mc "First row from data grid (%s)" ${::Shortcuts::formViewFirstRow}] "$this formFirstRow"]
	set _tbt(dataform:prev) [$_tb(dataform) addButton img_db_previous [mc "Previous row from data grid (%s)" ${::Shortcuts::formViewPrevRow}] "$this formPrevRow"]
	set _tbt(dataform:next) [$_tb(dataform) addButton img_db_next [mc "Next row from data grid (%s)" ${::Shortcuts::formViewNextRow}] "$this formNextRow"]
	set _tbt(dataform:last) [$_tb(dataform) addButton img_db_last [mc "Last row from data grid (%s)" ${::Shortcuts::formViewLastRow}] "$this formLastRow"]
	$_tb(dataform) addSeparator
	set _tbt(dataform:tab_switch) [$_tb(dataform) addImageCheckButton img_form_switch_down img_tab \
		[mc "Field switching mode.\n\nClick it to make <Tab> key to insert tab characters."] \
		[mc "Tab inserting mode.\n\nClick it to make <Tab> key switch between form edit fields."] \
		"::DataEditor::useTabToJump" 1 0 {CfgWin::save [list ::DataEditor::useTabToJump $::DataEditor::useTabToJump]}]
	$_tb(dataform) addSeparator
	set _tbt(dataform:filter) [$_tb(dataform) addEntry [mc {Enter phrase you want to look for}] [scope filterPhrase]]
	set _tbt(dataform:apply_filter) [$_tb(dataform) addButton img_filter [mc {Apply data filter}] "$this refreshWindowContents -dataonly true; $this fillForm"]
	set _tbt(dataform:clr_filter) [$_tb(dataform) addButton img_clear_filter [mc {Clear data filter}] "$this clearFilter; $this fillForm"]
	$_tb(dataform) addSeparator
	set _tbt(dataform:total_rows) [$_tb(dataform) addLabel [mc {Total rows: %s} 0] ""]

	bind $_tbt(dataform:filter) <Return> "$this refreshWindowContents -dataonly true; $this fillForm"
	bind $_tbt(dataform:filter) <${::Shortcuts::insertRow}> "$this addRowInFormView; break"
	bind $_tbt(dataform:filter) <Escape> "$this rollbackFormEdit; break"
	bind $_tbt(dataform:filter) ${::Shortcuts::formViewFirstRow} "$this formFirstRow"
	bind $_tbt(dataform:filter) ${::Shortcuts::formViewPrevRow} "$this formPrevRow"
	bind $_tbt(dataform:filter) ${::Shortcuts::formViewNextRow} "$this formNextRow"
	bind $_tbt(dataform:filter) ${::Shortcuts::formViewLastRow} "$this formLastRow"
	bind $_tbt(dataform:filter) <Tab> "$this focusFirstFormWidget; break"

	# Index tab toolbar
	set _tb(idx) [Toolbar $_idx.toolbar]
	pack $_tb(idx) -side top -fill x

	set _tbt(idx:refresh) [$_tb(idx) addButton img_db_refresh [mc "Refresh table indexes (%s)" ${::Shortcuts::refresh}] "$this refreshWindowContents -indexesonly true"]
	$_tb(idx) addSeparator
	set _tbt(idx:new) [$_tb(idx) addButton img_new_index [mc "Create new index (%s)" ${::Shortcuts::insertRow}] "$this newIndex"]
	set _tbt(idx:edit) [$_tb(idx) addButton img_index_edit [mc "Edit index (%s)" "Return"] "$this editIndex"]
	set _tbt(idx:del) [$_tb(idx) addButton img_del_index [mc "Delete index (%s)" ${::Shortcuts::deleteRow}] "$this delIndex"]

	# Trigger tab toolbar
	set _tb(trig) [Toolbar $_trig.toolbar]
	pack $_tb(trig) -side top -fill x

	set _tbt(trig:refresh) [$_tb(trig) addButton img_db_refresh [mc "Refresh table triggers (%s)" ${::Shortcuts::refresh}] "$this refreshWindowContents -triggersonly true"]
	$_tb(trig) addSeparator
	set _tbt(trig:new) [$_tb(trig) addButton img_new_trigger [mc "Create new trigger (%s)" ${::Shortcuts::insertRow}] "$this newTrigger"]
	set _tbt(trig:edit) [$_tb(trig) addButton img_trigger_edit [mc "Edit trigger (%s)" "Return"] "$this editTrigger"]
	set _tbt(trig:del) [$_tb(trig) addButton img_del_trigger [mc "Delete trigger (%s)" ${::Shortcuts::deleteRow}] "$this delTrigger"]

	# Form view
	set _dataForm [ScrolledFrame $_dataFormTab.form]
	pack $_dataForm -side top -fill both -expand 1

	# Grids
	set _colsGrid [TracedDbGrid $_cols.grid -yscroll 1 -rowselection 1 -doubleclicked "$this editDoubleClickedColumn \$x \$y" \
		-columnentercmd "$this columnEnterLeaveHint enter" -columnleavecmd "$this columnEnterLeaveHint leave"]
	set _dataGrid [DataGrid $_dataGridTab.grid -clicked "$this markToFillForm" -navaction "$this markToFillForm" -modifycmd "$this updateEditorToolbar"]
	set _idxGrid [IdxGrid $_idx.grid -selectionchanged [list $this selectionChanged index %i %c] -rowselection 1]
	set _consGrid [Grid $_cons.grid -rowselection 1]
	set _trigGrid [TrigGrid $_trig.grid -selectionchanged [list $this selectionChanged trigger %i %c] -rowselection 1]
	set _sqlEditor [SQLEditor $_sql.edit -wrap word]
	pack $_cols.grid -side bottom -fill both -expand 1
	pack $_dataGrid -side bottom -fill both -expand 1
	pack $_cons.grid -side bottom -fill both -expand 1
	pack $_idx.grid -side bottom -fill both -expand 1
	pack $_trig.grid -side bottom -fill both -expand 1
	pack $_sql.edit -side bottom -fill both -expand 1

	if {$db != ""} {
		$_sqlEditor setDB $db
	}
	[$_sqlEditor getWidget] configure -state disabled

	set _db $db
	set _table $table

	$_dataGrid setParent $this
	$_colsGrid setDB $_db
	$_trigGrid setDB $_db
	$_idxGrid setDB $_db

	$_consGrid addColumn [mc {Constraint name}] text
	$_consGrid addColumn [mc {Column name}] text
	$_consGrid addColumn [mc {Default}] text
	$_consGrid addColumn [mc {Not NULL}] text
	$_consGrid addColumn [mc {Primary key}] text
	$_consGrid addColumn [mc {Unique}] text
	$_consGrid addColumn [mc {Collate}] text
	$_consGrid addColumn [mc {Check}] text
	$_consGrid addColumn [mc {Foreign key}] text

	$_idxGrid addColumn [mc {Index name}] text
	$_idxGrid addColumn [mc {On column}] text
	$_idxGrid addColumn [mc {Unique}] numeric
	$_idxGrid addColumn [mc {SQL code}] text

	$_trigGrid addColumn [mc {Trigger name}] text
	$_trigGrid addColumn [mc {On table}] text
	$_trigGrid addColumn [mc {SQL code}] text

	# Structure/columns grid
	$_colsGrid addColumn [mc {Name}]
	$_colsGrid addColumn [mc {Data type}]
	$_colsGrid addColumn "P" image ;# PK
	if {$_sqliteVersion == 3} {
		$_colsGrid addColumn "F" image ;# FK
	}
	$_colsGrid addColumn "U" image ;# UNIQ
	$_colsGrid addColumn "H" image ;# CHK
	$_colsGrid addColumn "N" image ;# NOTNULL
	if {$_sqliteVersion == 3} {
		$_colsGrid addColumn "C" image ;# COLLATE
	}
	$_colsGrid addColumn [mc {Default value}] ;# DEFAULT
	#$_colsGrid columnConfig 1 -width 150 -maxwidth 150
	if {$_sqliteVersion == 3} {
		set columns {3 4 5 6 7 8}
	} else {
		set columns {3 4 5 6}
	}
	foreach i $columns {
		$_colsGrid columnConfig $i -width 22
	}
	$_colsGrid columnsEnd

	# Data grid
	$_dataGrid setDB $_db
	$_dataGrid setTable $_table
	$_dataGrid setSortChangeCommand "$this sortingChanged"

	refreshWindowContents -data false -indexes false -triggers false

	# Finishing
	if {$openTabOnCreate == 1} {
		$_tabs select 1
		$this focusTab
	} else {
		update idletasks
		focus $_cols.grid
		$_colsGrid setSelection
	}

	if {$rowIdsByDefault} {
		$_dataGrid switchTo "rowid"
	}

	# Binds
	updateShortcuts
	bind $_tabs <<NotebookTabChanged>> "catch {$this focusTab}; break"
	#bind $_tabs <<NotebookTabChanged>> "puts x; break"
	bind $_dataTabs <<NotebookTabChanged>> "$this focusDataTab; break"
	bind [$_colsGrid getWidget] <Key-t> "$this editTable; break"
	bind [$_colsGrid getWidget] <Key-x> "$this exportTable; break"
	bind [$_colsGrid getWidget] <Key-i> "$this importTable; break"
	bind [$_colsGrid getWidget] <Key-p> "$this populateTable; break"
}

body TableWin::destructor {} {
	if {[$_dataGrid getEditItem] != ""} {
		$_dataGrid commitEdit
	}
}

body TableWin::refreshWindowContents {args} {
	set refreshColumns true
	set refreshData true
	set refreshIndexes true
	set refreshTriggers true
	set doFocus true
	set refreshDataGridColumns true
	parseArgs {
		-columns {set refreshColumns $value}
		-data {set refreshData $value}
		-indexes {set refreshIndexes $value}
		-triggers {set refreshTriggers $value}
		-focus {set doFocus $value}
		-refreshdatagridcolumns {set refreshDataGridColumns $value}
		-columnsonly {
			set val [expr {!$value}]
			set refreshColumns $value
			set refreshData $val
			set refreshIndexes $val
			set refreshTriggers $val
		}
		-dataonly {
			set val [expr {!$value}]
			set refreshColumns $val
			set refreshData $value
			set refreshIndexes $val
			set refreshTriggers $val
		}
		-indexesonly {
			set val [expr {!$value}]
			set refreshColumns $val
			set refreshData $val
			set refreshIndexes $value
			set refreshTriggers $val
		}
		-triggersonly {
			set val [expr {!$value}]
			set refreshColumns $val
			set refreshData $val
			set refreshIndexes $val
			set refreshTriggers $value
		}
	}

	set steps 0
	if {$refreshColumns} {
		incr steps
	}
	if {$refreshData} {
		incr steps
	}
	if {$refreshIndexes} {
		incr steps
	}
	if {$refreshTriggers} {
		incr steps
	}

	if {$steps == 1} {
		set dialog [BusyDialog::show [mc {Refreshing dependencies}] "" false 50 false]
		BusyDialog::autoProgress 20
	} else {
		set dialog [BusyDialog::show [mc {Refreshing dependencies}] "" false $steps false determinate]
	}

	if {$refreshColumns} {
		$dialog setMessage [mc {Refreshing table columns...}]
		update idletasks
		refreshColumns $doFocus $refreshDataGridColumns
		if {$steps > 1} {
			BusyDialog::invoke
		}
	}

	if {$refreshData} {
		$dialog setMessage [mc {Refreshing table data...}]
		update idletasks
		refreshData
		if {$steps > 1} {
			BusyDialog::invoke
		}
	}

	if {$refreshIndexes} {
		$dialog setMessage [mc {Refreshing table indexes...}]
		update idletasks
		refreshIndexes
		if {$steps > 1} {
			BusyDialog::invoke
		}
	}

	if {$refreshTriggers} {
		$dialog setMessage [mc {Refreshing table triggers...}]
		update idletasks
		refreshTriggers
		if {$steps > 1} {
			BusyDialog::invoke
		}
	}

	BusyDialog::hide
}

body TableWin::getFocusedTab {} {
	switch -glob -- [$_tabs select] {
		"*cols*" {
			return [list columns]
		}
		"*data*" {
			switch -glob -- [$_dataTabs select] {
				"*grid*" {
					return [list data grid]
				}
				"*form*" {
					return [list data frame]
				}
			}
		}
		"*cons*" {
			return [list constraints]
		}
		"*idx*" {
			return [list indexes]
		}
		"*trig*" {
			return [list triggers]
		}
		"*sql*" {
			return [list ddl]
		}
		default {
			error "Unknown tab focused: [$_tabs select]"
		}
	}
}

body TableWin::focusTab {} {
	if {[catch {
		set colsGrid [$_colsGrid getWidget]
		set dataGrid [$_dataGrid getWidget]
		set idxGrid [$_idxGrid getWidget]
		set trigGrid [$_trigGrid getWidget]
		set consGrid [$_consGrid getWidget]
		set sqlEdit [$_sqlEditor getWidget]
	}]} {
		# Since focusTab is called by event loop,
		# some of widgets above might not exist at this moment.
		return
	}
	switch -glob -- [$_tabs select] {
		"*cols*" {
			$_colsGrid setSelection
		}
		"*data*" {
			if {!$_dataRead} {
				refreshData
			}

			update idletasks
			after idle "catch {$this focusDataTab}"
		}
		"*cons*" {
			$_consGrid setSelection
			update idletasks
			after idle [list catch [list focus $consGrid]]
		}
		"*idx*" {
			if {!$_indexRead} {
				$this refreshWindowContents -indexesonly true
			}
			$_idxGrid setSelection
			update idletasks
			after idle [list catch [list focus $idxGrid]]
		}
		"*trig*" {
			if {!$_triggersRead} {
				refreshWindowContents -triggersonly true
			}
			$_trigGrid setSelection
			update idletasks
			after idle [list catch [list focus $trigGrid]]
		}
		"*sql*" {
			focus $sqlEdit
		}
	}
}

body TableWin::prevDataTab {} {
	$_dataTabs select $_dataGridTab
}

body TableWin::nextDataTab {} {
}

body TableWin::updateFormViewToolbar {} {
	if {$_formViewModified || [$_dataGrid isSelectedRowPendingForCommit]} {
 		enableFormNavBtn [list commit rollback]
	} else {
 		disableFormNavBtn [list commit rollback]
	}
	set upState [$_dataGrid hasUpAvailable]
	set downState [$_dataGrid hasDownAvailable]
	$_tb(dataform) setActive $upState $_tbt(dataform:prev)
	$_tb(dataform) setActive $upState $_tbt(dataform:first)
	$_tb(dataform) setActive $downState $_tbt(dataform:next)
	$_tb(dataform) setActive $downState $_tbt(dataform:last)
}

body TableWin::isGlobalTableConstraint {col} {
	return [expr {[string trimright [string toupper $col] "("] in [list CONSTRAINT PRIMARY FOREIGN UNIQUE CHECK]}]
}

body TableWin::reformatDdl {} {
	set ddl [$_sqlEditor getContents 1]
	$_sqlEditor setContents [Formatter::format $ddl $_db]
}

body TableWin::refreshColumns {{doFocus true} {refreshDataGridColumns true}} {
	# Refreshing creation SQL
	if {[catch {ModelExtractor::getDdl $_db $_table} SQL]} {
		Error [mc {Table '%s' doesn't have DDL in sqlite_master table or doesn't exist in database anymore. This table window will be closed now.} $_table]
		set _noUpdates true
		set _needToRecreateForm false
		after idle [list TASKBAR delTaskByTitle $_title]
		return false
	}

	$_sqlEditor setContents $SQL
	reformatDdl

	# Refreshing columns
	$_colsGrid delRows
	$_colsGrid destroyChilds
	if {$refreshDataGridColumns} {
		$_dataGrid reset
		set _dataRead 0
	}
	set colsGrid [$_colsGrid getWidget]
	set _columns [list]
	catch {unset row}

	array set columns {
		all ""
		type ""
		pk ""
		notnull ""
		unique ""
		fk ""
		collate ""
		check ""
		default ""
	}

	set parser [UniversalParser ::#auto $_db]
	$parser configure -expectedTokenParsing false
	$parser parseSql $SQL
	set results [$parser get]

	# Error handling
	if {[dict get $results returnCode]} {
		debug "Table parsing error message: [dict get $results errorMessage]"
		error [format "Cannot parse objects DDL.\nSQLite version is %s.\nThe DDL is:\n%s\n\nError stack:" [$_db onecolumn {SELECT sqlite_version()}] $SQL]
	}

	set tableModel [[dict get $results object] getValue subStatement]

	if {$tableModel == ""} {
		error "No table model for TableWin.\nTable name: $_table\nThe DDL is: $SQL\n"
	}

	# Parsing column models
	foreach colDef [$tableModel getValue columnDefs] {
		set name [$colDef getValue columnName]
		lappend columns(all) $name

		# Type
		set typeDef [$colDef getValue typeName]
		if {$typeDef != ""} {
			set typeName [$typeDef getListValue name]
			set typeSize [$typeDef getValue size]
			set typePrecision [$typeDef getValue precision]
			set sizes [list]
			if {[string trim $typeSize] != ""} {
				lappend sizes $typeSize
			}
			if {[string trim $typePrecision] != ""} {
				lappend sizes $typePrecision
			}
			if {[llength $sizes] > 0} {
				append typeName "([join $sizes {, }])"
			}
			lappend columns(type) $typeName
		} else {
			lappend columns(type) ""
		}

		# Column constraints
		foreach constrDef [$colDef getListValue columnConstraints] {
			switch -- [$constrDef getValue branchIndex] {
				0 {
					# PK
					lappend columns(pk) $name
				}
				1 {
					# NOT NULL
					set notKeyword [$constrDef getValue notKeyword]
					if {$notKeyword} {
						lappend columns(notnull) $name
					}
				}
				2 {
					# UNIQUE
					lappend columns(unique) $name
				}
				3 {
					# CHECK
					set expr [$constrDef getValue expr]
					if {$expr != ""} {
						lappend columns(check) [list $name [$expr toSql]]
# 						lappend columns(check:expr) [$expr toSql]
					} else {
						lappend columns(check) [list $name ""]
					}
				}
				4 {
					# DEFAULT
					if {[$constrDef getValue expr] != ""} {
						set expr [$constrDef getValue expr]
						set defaultValue [$expr toSql]
					} else {
						set defaultValue [$constrDef getValue literalValue]
					}
					lappend columns(default) [list $name $defaultValue]
# 					lappend columns(default:value) $defaultValue
				}
				5 {
					# COLLATE
					lappend columns(collate) [list $name [$constrDef getValue collationName]]
# 					lappend columns(collate:type) [$constrDef getValue collationName]
				}
				6 {
					# FK
					if {$_sqliteVersion == 2} continue
					set fkModel [$constrDef getValue foreignKey]
					set fkTable [$fkModel getValue tableName]
					set col [lindex [$fkModel getListValue columnNames] 0]
					lappend columns(fk) [list $name $fkTable]
					lappend columns(fk:reference:$name) $col
				}
			}
		}
# 		foreach idx1 {default fk collate check} idx2 {default:value fk:reference collate:type check:expr} {
# 			if {$name ni $columns($idx1)} {
# 				lappend columns($idx2) ""
# 			}
# 		}
	}

# 	puts "columns(check:expr): $columns(check:expr)"

	# Table constraints
	foreach pkModel [$tableModel getPks] {
		if {$_sqliteVersion == 3} {
			foreach col [$pkModel getListValue indexedColumns] {
				lappend columns(pk) [$col getValue columnName]
			}
		} else {
			foreach col [$pkModel getListValue columnNames] {
				lappend columns(pk) $col
			}
		}
	}
	foreach uniqModel [$tableModel getUniqs] {
		if {$_sqliteVersion == 3} {
			foreach col [$uniqModel getListValue indexedColumns] {
				lappend columns(unique) [$col getValue columnName]
			}
		} else {
			foreach col [$uniqModel getListValue columnNames] {
				lappend columns(unique) $col
			}
		}
	}

	if {$_sqliteVersion == 3} {
		foreach fkModel [$tableModel getFks] {
			set localColumns [$fkModel getListValue columnNames]
			set fkClause [$fkModel getValue foreignKey]
			set fkTable [$fkClause getValue tableName]
			foreach localCol $localColumns foreignCol [$fkClause getListValue columnNames] {
				lappend columns(fk) [list $localCol $fkTable]
				lappend columns(fk:reference:$localCol) $foreignCol
			}
		}
	}

	delete object $parser

	set imgs {
		img_primary_key img_constr_uniq img_constr_notnull
	}
	foreach col $columns(all) type $columns(type) {
		foreach idx {pk unique notnull} img $imgs {
			if {$col in $columns($idx)} {
				set $idx $img
			} else {
				set $idx ""
			}
		}

		# FK
		set fkWord [lsearch -nocase -exact -index 0 -inline $columns(fk) $col]
		if {$fkWord != ""} {
			set fk img_fk_col
			lassign $fkWord colName fkTable
			set fkCol $columns(fk:reference:$colName)
		} else {
			set fk ""
			set fkCol ""
			set fkTable ""
		}

		# CHECK
		set checkWord [lsearch -inline -exact -index 0 $columns(check) $col]
		if {$checkWord != ""} {
			lassign $checkWord checkBool checkExpr
			set check img_constr_check
		} else {
			set check ""
			set checkExpr [$_db getNull]
		}

		# COLLATE
		set collateWord [lsearch -inline -exact -index 0 $columns(collate) $col]
		if {$collateWord != ""} {
			lassign $collateWord collateBool collateName
			set collate img_constr_collate
		} else {
			set collate ""
			set collateName [$_db getNull]
		}

		# DEFAULT
		set defWord [lsearch -inline -exact -index 0 $columns(default) $col]
		if {$defWord != ""} {
			set default 1
			lassign $defWord defColName defaultValue
		} else {
			set default 0
			set defaultValue [$_db getNull]
		}

		# Adding to structure grid
		if {$_sqliteVersion == 3} {
			$_colsGrid addRow [list [stripColName $col] $type $pk $fk $unique $check $notnull $collate $defaultValue]
		} else {
			$_colsGrid addRow [list [stripColName $col] $type $pk $unique $check $notnull $defaultValue]
		}

		# Adding to data grid
		set isPk [expr {$pk != ""}]
		set isNotNull [expr {$notnull != ""}]
		set isUnique [expr {$unique != ""}]
		set isFk [expr {$fk != ""}]
		set isCollate [expr {$collate != ""}]
		set isCheck [expr {$check != ""}]

		lappend _columns [list $col $type $isPk $isNotNull $defaultValue]
		if {$refreshDataGridColumns} {
			set t [string tolower $type]
			if {[string match "*(*)" $t]} {
				set t [lindex [regexp -inline {(.*)\(.*\)} $t] 1]
			}

			# Adding to grid
			set colDesc [dict create pk $isPk notnull $isNotNull default $default defaultValue $defaultValue \
				unique $isUnique fk $isFk collate $isCollate check $isCheck fkColumn $fkCol fkTable $fkTable \
				collateName $collateName checkExpr $checkExpr type $type]
			$_dataGrid addColumn [stripColName $col] $t $colDesc
			#$_dataGrid addColumn $col $t $colDesc
		}
	}

	# Defining sorting column
	if {[lindex $_dataSorting 0] != ""} {
		if {[lindex $_dataSorting 0] ni [$_dataGrid getColumnNames]} {
			set _dataSorting [list "" ASC]
		}
	} else {
		set _dataSorting [list "" ASC]
	}

	# End
	if {$doFocus} {
		focusTab
	}
	return true
}

body TableWin::columnEnterLeaveHint {enterOrLeave col} {
	if {$enterOrLeave == "enter"} {
		set cmd helpHint_onEnter
	} else {
		set cmd helpHint_onLeave
	}
	if {$_sqliteVersion == 3} {
		switch -- $col {
			3 {
				$cmd $_colsGrid [mc {Primary key}]
			}
			4 {
				$cmd $_colsGrid [mc {Foreign key}]
			}
			5 {
				$cmd $_colsGrid [mc {Unique}]
			}
			6 {
				$cmd $_colsGrid [mc {Check condition}]
			}
			7 {
				$cmd $_colsGrid [mc {Not NULL}]
			}
			8 {
				$cmd $_colsGrid [mc {Collate}]
			}
		}
	} else {
		switch -- $col {
			3 {
				$cmd $_colsGrid [mc {Primary key}]
			}
			4 {
				$cmd $_colsGrid [mc {Unique}]
			}
			5 {
				$cmd $_colsGrid [mc {Check condition}]
			}
			6 {
				$cmd $_colsGrid [mc {Not NULL}]
			}
		}
	}
}

body TableWin::getBaseRowNum {} {
	return [expr {$resultsPerPage*$_page+1}]
}

body TableWin::refreshTotalNumberOfRows {} {
	set colList [list]
	foreach c $_columns {
		lassign $c name type pk notnull def
		lappend colList "[wrapObjName $name [$_db getDialect]]"
	}

	set sql "SELECT COUNT(ROWID) FROM [wrapObjName $_table [$_db getDialect]]"
	set filter ""
	if {$filterPhrase != ""} {
		set phrase [string map [list ' ''] $filterPhrase]
		set filterConditions [list]
		foreach col $colList {
			lappend filterConditions "$col LIKE '%$phrase%'"
		}
		set filter " WHERE [join $filterConditions { OR }]"
	}
	append sql $filter

	if {[catch {$_db onecolumn $sql} res]} {
		debug "Problem while reading total num of rows: $res"
		set _totalRows 0
	} else {
		set _totalRows $res
	}

	if {![validatePositiveInt $resultsPerPage]} {
		# Just to be safe
		set resultsPerPage 1000
	}

	if {![validateInt $_totalRows]} {
		# Just to be safe
		set _totalRows 0
	}

	set _lastPage [expr { int( floor( double($_totalRows) / double($resultsPerPage) ) ) }]

	if {$filterPhrase != ""} {
		set txt [mc {Total rows: %s (filtered)} $_totalRows]
	} else {
		set txt [mc {Total rows: %s} $_totalRows]
	}

	$_tbt(data:total_rows) configure -text $txt
	$_tbt(dataform:total_rows) configure -text $txt
}

body TableWin::refreshData {} {
	if {[$_dataGrid areTherePendingCommits]} {
		set dialog [YesNoDialog .yesno -title [mc {Pending commits}] -message [mc "There are uncommited data modifications.\nReloading data will cancel them.\nAre you sure you want to continue?"]]
		if {![$dialog exec]} {
			return
		}
	}

	set hideBusy 0
	if {![BusyDialog::exists]} {
		BusyDialog::show [mc {Loading data...}] [mc {Loading table '%s'...} $_table] false 50 false
		BusyDialog::autoProgress 20
		set hideBusy 1
	}

	$_dataGrid reset

	set colsRefreshed true
	set rowCnt 0
	$_dataGrid hide
	if {[catch {
		if {![refreshColumns 0]} {
			set colsRefreshed false
			BusyDialog::hide
			$_dataGrid show
			return
		}

		# Columns list
		set colList [list]
		set filterColList [list]
		foreach c $_columns {
			lassign $c name type pk notnull def
			set wrappedName [wrapObjName $name [$_db getDialect]]
			if {[string match "'*'" $wrappedName]} {
				BusyDialog::hide
				Warning [mc {Using all of %s, %s and %s characters in column name at once is highly discouraged and should be avoided at all costs. Therefor changing name of column %s in table %s is recommended. Table data won't be loaded now.} "`" "\"" "\]" $name $_table]
				return
			}
			set wrappedNameWithAlias "substr($wrappedName, 1, $::QueryExecutor::visibleDataLimit) AS $wrappedName"
			
			lappend colList $wrappedNameWithAlias
			lappend filterColList $wrappedName
		}
		set cols [join $colList {, }]

		# Filter
		set filter ""
		if {$filterPhrase != ""} {
			set phrase [string map [list ' ''] $filterPhrase]
			set filterConditions [list]
			foreach col $filterColList {
				lappend filterConditions "$col LIKE '%$phrase%'"
			}
			set filter "WHERE [join $filterConditions { OR }]"
		}

		# Number of rows
		refreshTotalNumberOfRows
		# Sorting
		$_dataGrid setBaseRowNum [getBaseRowNum]
		set sortColumn [lindex $_dataSorting 0]
		if {$sortColumn != ""} {
			set collating ""
			if {$_sqliteVersion == 3} {
				set collating "COLLATE $Sqlite3::dictionaryCollation "
			}
			set orderBy "ORDER BY [wrapObjName $sortColumn [$_db getDialect]] $collating[lindex $_dataSorting 1]"
		} else {
			set orderBy ""
		}

		# Getting data
		$_db eval "SELECT $cols, ROWID as ___rowid___ FROM [wrapObjName $_table [$_db getDialect]] $filter $orderBy LIMIT $resultsPerPage OFFSET [expr {$resultsPerPage*$_page}]" R {
			set col 1
			set data [list]
			set rowid ""
			foreach id [array names R] {
				if {$id == "*" || [string match "typeof:*" $id]} continue
				if {$id == "___rowid___"} {
					set rowid $R($id)
					continue
				}
				lappend data [list $id $R($id)]
			}
			$_dataGrid addRowPairs $data $rowid false
			incr rowCnt
			if {$rowCnt % 200 == 0} {
				update idletasks
			}
		}
	} err] == 1} {
		$_dataGrid show
		error $err
	}
	$_dataGrid show
	if {!$colsRefreshed} {
		# Refreshing columns failed, so did refreshing data. We cannot proceed.
		return
	}
	$_dataGrid refreshWidth

	# Final settings
	set _dataRead 1
	if {[getFocusedTab] == [list data grid]} {
		focus [$_dataGrid getWidget]
	}
	$_dataGrid setSelection


	if {$_page < $_lastPage} {
		enableRowNavBtn [list next last]
	} else {
		disableRowNavBtn [list next last]
	}
	if {$_page > 0} {
		enableRowNavBtn [list prev first]
	} else {
		disableRowNavBtn [list prev first]
	}

	updateEditorToolbar

	markToFillForm

	if {$hideBusy} {
		BusyDialog::hide
	}
}

body TableWin::refreshTriggers {} {
	$_trigGrid delRows

	set parser [UniversalParser ::#auto $_db]
	$parser configure -sameThread false -expectedTokenParsing false
	set mode [$_db mode]
	$_db short
	$_db eval "SELECT name, type, sql FROM sqlite_master" row {
		if {$row(type) == "trigger"} {
			set decSql [decode $row(sql)]
			$parser parseSql $decSql
			set results [$parser get]

			# Error handling
			if {[dict get $results returnCode]} {
				$_db $mode
				debug "Table parsing error message: [dict get $results errorMessage]"
				delete object $parser
				error [format "Cannot parse trigger DDL.\nSQLite version is %s.\nThe DDL is:\n%s\n\nError stack:" [$_db onecolumn {SELECT sqlite_version()}] $decSql]
			}

			set container [[dict get $results object] getValue subStatement]

			set trigTable [$container getValue tableName]
			if {$trigTable == $_table} {
				$_trigGrid addRow [list [stripColName $row(name)] $trigTable $decSql]
			}

			$parser freeObjects
		}
	}
	$_db $mode
	set _triggersRead 1
	delete object $parser
}

body TableWin::refreshIndexes {} {
	$_idxGrid delRows
	set mode [$_db mode]
	$_db short
	$_db eval "SELECT name, type, sql FROM sqlite_master" row {
		if {$row(type) == "index"} {
			if {[string match "sqlite_autoindex_*" $row(name)] || [string match "(* autoindex *)" $row(name)]} {
				continue
			}

			set re {(?i)}
			append re $::RE(table_or_column)
			append re {\s+on\s+}
			append re $::RE(table_or_column)
			append re {\s*\((.*)\)}
			lassign [regexp -inline -- $re [decode $row(sql)]] tmp name table columns
			if {![info exists columns]} continue
			set table [stripColName $table]
			if {$_table == $table} {
				set cols [list]
				foreach col [split $columns ","] {
					lappend cols [lindex [string trim $col] 0]
				}
				set cols [stripColListNames $cols]
				set unique [regexp {(?i)create\s+unique\s+index} [decode $row(sql)]]
				$_idxGrid addRow [list $row(name) [string map {, ,\ } [join $cols ,]] $unique [decode $row(sql)]]
			}
		}
	}
	$_db $mode
	set _indexRead 1
}

body TableWin::editTable {} {
	set parser [UniversalParser ::#auto $_db]
	if {[catch {set model [ModelExtractor::getModelForEditDialog $_db $_table table $parser]} err]} {
		debug $err
	}
	if {![info exists model] || $model == ""} {
		Info [mc {Table '%s' has no DDL. Probably it doesn't exist anymore, or it's system table.} $_table]
		delete object $parser
		return
	}

	catch {destroy .editTable}
	set dialog [TableDialog .editTable -title [mc {Edit table}] -db $_db -table $_table]
	$dialog exec
	delete object $parser
}

body TableWin::createSimilarTable {} {
	set parser [UniversalParser ::#auto $_db]
	if {[catch {set model [ModelExtractor::getModelForEditDialog $_db $_table table $parser]} err]} {
		debug $err
	}
	if {![info exists model] || $model == ""} {
		Info [mc {Table '%s' has no DDL. Probably it doesn't exist anymore, or it's system table.} $_table]
		return
	}

	catch {destroy .similarTable}
	set dialog [TableDialog .similarTable -title [mc {Create similar table}] -db $_db -table $_table -similar true]
	$dialog exec
}

body TableWin::editDoubleClickedColumn {x y} {
	if {[$_colsGrid identify $x $y] == ""} return
	editSelectedColumn
}

body TableWin::editSelectedColumn {} {
	# Determinating column name
	set colName [lindex [$_colsGrid getSelectedRowData] 1]

	if {![ModelExtractor::hasDdl $_db $_table]} {
		Info [mc {Table '%s' has no DDL. Probably it doesn't exist anymore, or it's system table.} $_table]
		return
	}

	catch {destroy .editTable}
	set dialog [TableDialog .editTable -title [mc {Edit table}] -db $_db -table $_table -editcolumn $colName]
	$dialog exec
}

body TableWin::constrSort {it1 it2} {
	return [string compare [lindex $it1 1] [lindex $it2 1]]
}

body TableWin::addRow {} {
	$_dataGrid addRow "" "" 1
	markToFillForm
}

body TableWin::addRows {} {
	set w .addRowsDialog
	catch {destroy $w}
	SpinDialog $w -message [mc {Enter number of rows to add:}] -from 1 -to 1000 -default 10 -title [mc {Add rows}]
	set rows [$w exec]
	if {$rows == ""} return

	# Start with i=1 to leave last addRow execution with width refreshment
	for {set i 1} {$i < $rows} {incr i} {
		$_dataGrid addRow "" "" 1 false
	}
	$_dataGrid addRow "" "" 1 true

	markToFillForm
}

body TableWin::addRowInFormView {} {
	if {$_formViewModified} {
		transferFormToGrid
	}
	set it [$_dataGrid addRow "" "" 1]
	$_dataGrid setRowValueForAllCells $it ""
	markToFillForm
	fillForm
}

body TableWin::delRowInFormView {} {
	delRow
	formNextRow
}

body TableWin::delRow {} {
	$_dataGrid deleteCurrentRow
	markToFillForm
}

body TableWin::newIndex {} {
	catch {destroy .newIndex}
	set dialog [IndexDialog .newIndex -title [mc {New index}] -db $_db -preselecttable $_table]
	$dialog exec
}

body TableWin::editIndex {} {
	set idx [lindex [$_idxGrid getSelectedRowData] 1]
	if {$idx == ""} return

	set parser [UniversalParser ::#auto $_db]
	if {[catch {set model [ModelExtractor::getModelForEditDialog $_db $idx index $parser]} err]} {
		debug $err
	}
	if {![info exists model] || $model == ""} {
		Info [mc {Index '%s' has no DDL. Probably it's system index and should not be edited.} $idx]
		delete object $parser
		return
	}

	catch {destroy .editIndex}
	set dialog [IndexDialog .editIndex -title [mc {Edit index}] -db $_db -index $idx -model $model]
	$dialog exec
	delete object $parser
}

body TableWin::delIndex {} {
	set idx [lindex [$_idxGrid getSelectedRowData] 1]
	if {$idx == ""} return
	set dialog [YesNoDialog .yesno -title [mc {Delete index}] -message [mc {Are you sure you want to delete '%s' index?} $idx]]
	if {"IF_EXISTS" in [[$_db info class]::getUnsupportedFeatures]} {
		set sql "DROP INDEX [wrapObjName $idx [$_db getDialect]]"
	} else {
		set sql "DROP INDEX IF EXISTS [wrapObjName $idx [$_db getDialect]]"
	}
	if {[$dialog exec]} {
		if {[catch {
			$_db eval $sql
		} err]} {
			cutOffStdTclErr err
			Error $err
		} else {
			DBTREE refreshSchemaForDb $_db
			TASKBAR signal TableWin [list REFRESH $_table]
		}
	}
}

body TableWin::newTrigger {} {
	catch {destroy .newTrigger}
	set dialog [TriggerDialog .newTrigger -title [mc {New trigger}] -db $_db -preselecttable $_table]
	$dialog exec
}

body TableWin::editTrigger {} {
	set trig [lindex [$_trigGrid getSelectedRowData] 1]
	if {$trig == ""} return

	set parser [UniversalParser ::#auto $_db]
	if {[catch {set model [ModelExtractor::getModelForEditDialog $_db $trig trigger $parser]} err]} {
		debug $err
	}
	if {![info exists model] || $model == ""} {
		Info [mc {Trigger '%s' has no DDL. Probably it's system trigger and should not be edited.} $trig]
		delete object $parser
		return
	}

	catch {destroy .editTrigger}
	set dialog [TriggerDialog .editTrigger -title [mc {Edit trigger}] -db $_db -trigger $trig]
	$dialog exec
	delete object $parser
}

body TableWin::delTrigger {} {
	set trig [lindex [$_trigGrid getSelectedRowData] 1]
	if {$trig == ""} return
	set dialog [YesNoDialog .yesno -title [mc {Delete trigger}] -message [mc {Are you sure you want to delete '%s' trigger?} $trig]]
	if {"IF_EXISTS" in [[$_db info class]::getUnsupportedFeatures]} {
		set sql "DROP TRIGGER [wrapObjName $trig [$_db getDialect]]"
	} else {
		set sql "DROP TRIGGER IF EXISTS [wrapObjName $trig [$_db getDialect]]"
	}
	if {[$dialog exec]} {
		# TODO: 'IF EXISTS' isn't handled by sqlite
		#$_db eval "DROP TRIGGER IF EXISTS $idx"
		$_db eval $sql
		#$_trigGrid delSelected
		DBTREE refreshSchemaForDb $_db
		TASKBAR signal TableWin [list REFRESH $_table]
	}
}

body TableWin::signal {receiver data} {
	if {[$this isa $receiver]} {
		set matchTable 0
		if {[string equal [lindex $data 1] $_table]} {
			set matchTable 1
		}
		switch -- [lindex $data 0] {
			"REFRESH" {
				if {$matchTable} {
					if {[lindex $data 2] != ""} {
						changeTable [lindex $data 2]
						changeTitle [formatTitle [lindex $data 2] [$_db getName]]
					}
					refreshColumns 0
					refreshData
					refreshIndexes
					refreshTriggers
					focusTab
				}
			}
			"REFRESH_DATA" {
				if {$matchTable} {
					refreshData
				}
			}
			"CLOSE" {
				if {$matchTable} {
					TASKBAR delTaskByTitle $_title
				}
			}
			"CLOSE_BY_DB" {
				if {[lindex $data 1] == $_db} {
					TASKBAR delTaskByTitle $_title
				}
			}
			"REFRESH_IDX" {
				set indexes [$_idxGrid getColIdxData 1]
				foreach idxName $indexes {
					if {[string equal $idxName [lindex $data 1]]} {
						refreshIndexes
						break
					}
				}
			}
			"REFRESH_TRIG" {
				set trigs [$_trigGrid getColIdxData 1]
				foreach trigName $trigs {
					if {[string equal $trigName [lindex $data 1]]} {
						refreshTriggers
						break
					}
				}
			}
		}
	}
}

body TableWin::formatTitle {table db} {
	return "$table ($db)"
}

body TableWin::activated {} {
	focusTab
}

body TableWin::enableRowNavBtn {{list ""}} {
	if {$list == ""} {
		set list [list first prev next last]
	}
	foreach idx $list {
		$_tb(data) setActive 1 $_tbt(data:$idx)
	}
}

body TableWin::disableRowNavBtn {{list ""}} {
	if {$list == ""} {
		set list [list first prev next last]
	}
	foreach idx $list {
		$_tb(data) setActive 0 $_tbt(data:$idx)
	}
}

body TableWin::enableFormNavBtn {{list ""}} {
	if {$list == ""} {
		set list [list first prev next last]
	}
	foreach idx $list {
		$_tb(dataform) setActive 1 $_tbt(dataform:$idx)
	}
}

body TableWin::disableFormNavBtn {{list ""}} {
	if {$list == ""} {
		set list [list first prev next last]
	}
	foreach idx $list {
		$_tb(dataform) setActive 0 $_tbt(dataform:$idx)
	}
}

body TableWin::formNextRow {} {
	if {$_formViewModified} {
		transferFormToGrid
	}
	$_dataGrid goToCell next
	markToFillForm
	fillForm false
}

body TableWin::formPrevRow {} {
	if {$_formViewModified} {
		transferFormToGrid
	}
	$_dataGrid goToCell prev
	markToFillForm
	fillForm false
}

body TableWin::formLastRow {} {
	if {$_formViewModified} {
		transferFormToGrid
	}
	$_dataGrid goToCell last
	markToFillForm
	fillForm false
}

body TableWin::formFirstRow {} {
	if {$_formViewModified} {
		transferFormToGrid
	}
	$_dataGrid goToCell first
	markToFillForm
	fillForm false
}

body TableWin::nextRows {} {
	if {$_page < $_lastPage} {
		incr _page
		refreshData
	}
}

body TableWin::prevRows {} {
	if {$_page > 0} {
		incr _page -1
		refreshData
	}
}

body TableWin::lastRows {} {
	if {$_page < $_lastPage} {
		set _page $_lastPage
		refreshData
	}
}

body TableWin::firstRows {} {
	if {$_page > 0} {
		set _page 0
		refreshData
	}
}

body TableWin::exportTable {} {
	catch {destroy .exportTable}
	set dialog [ExportDialog .exportTable -showdb true -showtable true -title [mc {Export table}] -db $_db -table $_table -readonly true -type table]
	$dialog exec
}

body TableWin::importTable {} {
	catch {destroy .importTable}
	set dialog [ImportDialog .importTable -title [mc {Import data}] -db $_db -existingtable $_table]
	$dialog exec
}

body TableWin::getSessionString {} {
	updateGeometry
	return [list TABLE_WINDOW [$_db getName] $_table $mdimode [list $qx $qy $qw $qh]]
}

body TableWin::restoreSession {sessionString} {
	lassign $sessionString type dbName table mdimode coords
	if {$type != "TABLE_WINDOW"} {
		return 0
	}

	set db [DBTREE getDBByName $dbName]
	if {$db != ""} {
		if {![$db isOpen]} {
			$db open
			DBTREE refreshSchemaForDb $db
		}
		set win [DBTREE openTableWindow $db $table]
		if {$mdimode == "NORMAL"} {
			lassign $coords x y w h
			$win setGeoms $x $y $w $h
		}
	}
	return 1
}

body TableWin::updateShortcuts {} {
	set colsGrid [$_colsGrid getWidget]
	set dataGrid [$_dataGrid getWidget]
	set consGrid [$_consGrid getWidget]
	set idxGrid [$_idxGrid getWidget]
	set trigGrid [$_trigGrid getWidget]
	set sqlEdit [$_sqlEditor getWidget]
	set form [$_dataForm getFrame]

	bind [$_cols.grid getWidget] <${::Shortcuts::refresh}> "$this refreshColumns"
	bind [$_dataGridTab.grid getWidget] <${::Shortcuts::refresh}> "$this refreshData"
	bind [$_trig.grid getWidget] <${::Shortcuts::refresh}> "$this refreshTriggers"
	bind [$_sql.edit getWidget] <${::Shortcuts::refresh}> "$this refreshColumns"

	bind $colsGrid <${::Shortcuts::nextTab}> "$_tabs select 1"

	bind $dataGrid <${::Shortcuts::prevTab}> "$_tabs select 0"
	bind $dataGrid <${::Shortcuts::nextTab}> "$_tabs select 2"
	bind $form <${::Shortcuts::prevTab}> "$_tabs select 0"
	bind $form <${::Shortcuts::nextTab}> "$_tabs select 2"

	#bind $consGrid <${::Shortcuts::prevTab}> "$_tabs select 1"
	#bind $consGrid <${::Shortcuts::nextTab}> "$_tabs select 3"

	bind $idxGrid <${::Shortcuts::prevTab}> "$_tabs select 1"
	bind $idxGrid <${::Shortcuts::nextTab}> "$_tabs select 3"

	bind $trigGrid <${::Shortcuts::prevTab}> "$_tabs select 2"
	bind $trigGrid <${::Shortcuts::nextTab}> "$_tabs select 4"

	bind $sqlEdit <${::Shortcuts::prevTab}> "$_tabs select 3"

	bind $dataGrid <${::Shortcuts::nextSubTab}> "$_dataTabs select $_dataFormTab"
	bind $form <${::Shortcuts::prevSubTab}> "$_dataTabs select $_dataGridTab"

	bind $idxGrid <${::Shortcuts::insertRow}> "$this newIndex"
	bind $idxGrid <Return> "$this editIndex"
	bind $idxGrid <${::Shortcuts::deleteRow}> "$this delIndex"
	bind $trigGrid <${::Shortcuts::insertRow}> "$this newTrigger"
	bind $trigGrid <Return> "$this editTrigger"
	bind $trigGrid <${::Shortcuts::deleteRow}> "$this delTrigger"

	bind $dataGrid <${::Shortcuts::commitFormView}> "$this commitGrid"
	bind $dataGrid <${::Shortcuts::rollbackFormView}> "$this rollbackGrid"
}

body TableWin::clearShortcuts {} {
	set colsGrid [$_colsGrid getWidget]
	set dataGrid [$_dataGrid getWidget]
	set consGrid [$_consGrid getWidget]
	set idxGrid [$_idxGrid getWidget]
	set trigGrid [$_trigGrid getWidget]
	set sqlEdit [$_sqlEditor getWidget]
	set form [$_dataForm getFrame]

	bind $_cols.grid <${::Shortcuts::refresh}> ""
	bind $_dataGridTab.grid <${::Shortcuts::refresh}> ""
	bind $_trig.grid <${::Shortcuts::refresh}> ""
	bind $_sql.edit <${::Shortcuts::refresh}> ""

	bind $colsGrid <${::Shortcuts::nextTab}> ""

	bind $dataGrid <${::Shortcuts::prevTab}> ""
	bind $dataGrid <${::Shortcuts::nextTab}> ""
	bind $form <${::Shortcuts::prevTab}> ""
	bind $form <${::Shortcuts::nextTab}> ""

	bind $consGrid <${::Shortcuts::prevTab}> ""
	bind $consGrid <${::Shortcuts::nextTab}> ""

	bind $idxGrid <${::Shortcuts::prevTab}> ""
	bind $idxGrid <${::Shortcuts::nextTab}> ""

	bind $trigGrid <${::Shortcuts::prevTab}> ""
	bind $trigGrid <${::Shortcuts::nextTab}> ""

	bind $sqlEdit <${::Shortcuts::prevTab}> ""

	bind $dataGrid <${::Shortcuts::nextSubTab}> ""
	bind $form <${::Shortcuts::prevSubTab}> ""

	bind $idxGrid <${::Shortcuts::insertRow}> ""
	bind $idxGrid <${::Shortcuts::deleteRow}> ""
	bind $trigGrid <${::Shortcuts::insertRow}> ""
	bind $trigGrid <${::Shortcuts::deleteRow}> ""

	bind $dataGrid <${::Shortcuts::commitFormView}> ""
	bind $dataGrid <${::Shortcuts::rollbackFormView}> ""
}

body TableWin::sortingChanged {columnName order} {
	set _dataSorting [list $columnName $order]
	refreshData
}

body TableWin::populateTable {} {
	set dialog [PopulateTableDialog .populateTable -db $_db -table $_table -title [mc {Populate table}]]
	$dialog exec
}

body TableWin::clearFilter {} {
	set filterPhrase ""
	refreshData
}

body TableWin::changeTable {newTable} {
	set _table $newTable
	$_dataGrid setTable $newTable
}

body TableWin::selectionChanged {type it col} {
	switch -- $type {
		"index" {
			if {$it == ""} {
				$_tb(idx) setActive false $_tbt(idx:del)
				$_tb(idx) setActive false $_tbt(idx:edit)
			} else {
				$_tb(idx) setActive true $_tbt(idx:del)
				$_tb(idx) setActive true $_tbt(idx:edit)
			}
		}
		"trigger" {
			if {$it == ""} {
				$_tb(trig) setActive false $_tbt(trig:del)
				$_tb(trig) setActive false $_tbt(trig:edit)
			} else {
				$_tb(trig) setActive true $_tbt(trig:del)
				$_tb(trig) setActive true $_tbt(trig:edit)
			}
		}
	}
}

body TableWin::updateEditorToolbar {} {
	set toCommitCnt [llength [$_dataGrid getCellsToCommit]]
	if {$toCommitCnt > 0 || [$_dataGrid isEditCellModified] || [$_dataGrid isEditing]} {
		enableRowNavBtn [list commitnew rollbacknew]
	} else {
		disableRowNavBtn [list commitnew rollbacknew]
	}
}

body TableWin::updateUISettings {} {
	MDIWin::updateUISettings
	reformatDdl

	if {$rowIdsByDefault} {
		$_dataGrid switchTo rowid
	} else {
		$_dataGrid switchTo rownum
	}
}

body TableWin::getGridObject {} {
	return $_dataGrid
}

body TableWin::getFormFrame {} {
	return $_dataForm
}

body TableWin::getDataTabs {} {
	return $_dataTabs
}

body TableWin::canDestroy {} {
	return [DataEditor::canDestroy]
}

body TableWin::getSelectedRowDataWithNull {{limited true}} {
	set colList [list]
	foreach c $_columns {
		lassign $c name type pk notnull def
		set wrappedName [wrapObjName $name [$_db getDialect]]
		if {$limited} {
			set wrappedName "substr($wrappedName, 1, $::QueryExecutor::visibleDataLimit) AS $wrappedName"
		}
		lappend colList $wrappedName
		lappend colNames $name
	}
	set cols [join $colList {, }]

	lassign [$_dataGrid getSelectedCell] it col
	if {$it == ""} {
		return [list]
	}
	if {[$_dataGrid isRowNew $it]} {
		return [$_dataGrid getSelectedRowDataWithNull]
	}

	set rowid [$_dataGrid getRowId $it $col]

	set firstCol [$_dataGrid getColumnIdByIndex 0]
	set rowNum [$_dataGrid getCellData $it $firstCol]

	set data [list [list $rowNum 0]]
	$_db eval "SELECT $cols FROM [wrapObjName $_table [$_db getDialect]] WHERE ROWID = $rowid LIMIT 1" R {
		foreach id $R(*) {
			lappend data [list $R($id) [$_db isNull $R($id)]]
		}
		break ;# just for sure
	}
	return $data
}

body TableWin::getDb {} {
	return $_db
}

body TableWin::getTable {} {
	return $_table
}
