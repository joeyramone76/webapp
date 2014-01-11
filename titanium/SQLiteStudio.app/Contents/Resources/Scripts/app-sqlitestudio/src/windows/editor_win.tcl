use src/common/mdi_win.tcl
use src/common/scrolled_frame.tcl
use src/data_editor.tcl
use src/shortcuts.tcl

#>
# @class EditorWin
# SQL queries editor. Just run <b>SQLiteStudio</b> and see it.
#<
class EditorWin {
	inherit MDIWin DataEditor Shortcuts

	#>
	# @var winNum
	# Sequence variable used for editor window title automatic generation.
	# Each new window is numbered with next value of this variable.
	#<
	common winNum 0

	#>
	# @var showLineNumbers
	# It's controled by {@class CfgWin}. It determinates if line numbers are shown
	# in SQL editor widget.
	#<
	common showLineNumbers 1

	common nullPlainTextRepresentation ""
	common maxPlainTextColumnWidth 16
	common defaultResultsOrientation "tabs"

	#>
	# @method constructor
	# @param title Title to use for window.
	# Creates window with given title, all its toolbars and other internal widgets.
	#<
	constructor {title} {
		MDIWin::constructor $title img_edit
	} {}

	#>
	# @method destructor
	# Deletes all internal (but global) objects to clear memory, such as SQL editor widget, results grid, etc.
	#<
	destructor {}

	private {
		#>
		# @var _grid
		# Reference to results grid widget. It's instance of {@class ResultGrid} class.
		#<
		variable _grid ""

		variable _plainText ""

		#>
		# @var _tb
		# Reference to main toolbar widget.
		#<
		variable _tb ""

		#>
		# @var _fvtb
		# Reference to results FormView toolbar widget.
		#<
		variable _fvtb ""

		#>
		# @arr _tbt
		# Array of references to toolbar buttons. Each array index is symbolic name of the button and value is a button object (or other widget).
		#<
		variable _tbt

		#>
		# @var _gtb
		# Reference to results additional toolbar widget.
		#<
		variable _gtb ""

		#>
		# @arr _gtbt
		# Array of references to results additional toolbar buttons. Each array index is symbolic name of the button and value is a button object (or other widget).
		#<
		variable _gtbt

		variable _plainViewToolbar ""
		variable _plainViewToolbarButton

		#>
		# @var _tabs
		# Reference to main tabs widget.
		#<
		variable _tabs ""

		#>
		# @var _restabs
		# Reference to results subtabs (view modes) widget.
		#<
		variable _restabs ""

		#>
		# @arr _resTab
		# Array of frames in results subtabs. Each array index is symbolic name of results subtab and value is frame widget placed in that subtab.
		#<
		variable _resTab

		#>
		# @var _query
		# Reference to frame widget that is placed in <i>query</i> tab. SQL editor is placed in it.
		#<
		variable _query ""

		#>
		# @var _form
		# Reference to frame widget that is placed in <i>form view</i> subtab of <i>results</i> tab.
		#<
		variable _form ""

		#>
		# @var _results
		# Reference to frame widget that is placed in <i>results</i> tab. {@var _restabs} is placed in it.
		#<
		variable _results ""

		#>
		# @var _history
		# Reference to frame widget that is placed in <i>history</i> tab.
		#<
		variable _history ""

		#>
		# @var _historyGrid
		# Reference to history grid widget. Its class is {@class Grid}.
		#<
		variable _historyGrid ""

		#>
		# @var _historyEdit
		# Reference to history SQL editor widget. Selected history entries are displayed in this editor field.
		#<
		variable _historyEdit ""

		#>
		# @arr _historySQL
		# This array contains all history data. It's filled by {@method loadHistory}.<br>
		# Indexes in the array are {@var _historyGrid} row IDs and values are lists of data,
		# where each list has the following elements:<br>
		# <ul>
		# <li> database name (not an object!) - the same name as user sees,
		# <li> date of execution (<code>%Y-%m-%d %H:%M</code>),
		# <li> how much time the execution took,
		# <li> affected rows,
		# <li> called SQL query.
		# </ul>
		#<
		variable _historySQL

		#>
		# @var _statusFrame
		# Reference to frame widget that is placed in {@var _query} frame. It can be hidden or shown by {@method hideStatus} and {@method showStatus}.
		#<
		variable _statusFrame ""

		#>
		# @var _paned
		# Paned window widget. Contains {@var _notebook} and {@var _statusFrame}.
		#<
		variable _paned ""

		#>
		# @var _status
		# Status widget. It's instance of {@class StatusField}. It's placed in {@var _statusFrame}.
		#<
		variable _status ""

		#>
		# @var _sqlEditor
		# SQL editor widget that is placed in <i>query</i> tab. It's instance of {@class SQLEditor}.
		#<
		variable _sqlEditor ""

		#>
		# @var _dblist
		# List of {@class DB} objects that can be choosen in editor window. It also works in opossite way -
		# when user selects database in editor window, then all databases from this list are checked to be
		# equal by name. When database is matched, it's object is used to execute queries.
		#<
		variable _dblist [list]

		#>
		# @var _statusVisible
		# It's a boolean switch to indicate whether {@var _status} is visible or not.
		#<
		variable _statusVisible 0

		#>
		# @var _page
		# When number of results rows is greater than {@var TableWin::resultsPerPage},
		# then they are splitted into serval pages. This variable keeps current page number, counting from 0.
		#<
		variable _page 0

		#>
		# @var _lastPage
		# After query has returned results, total number of pages is calculated and stored in this variable,
		# so user can easly jump to this page.
		#<
		variable _lastPage 0

		#>
		# @var _queryForResults
		# It's temporary variable used by {@method execQueryInternal}. Original query is stored in this variable,
		# then the query is modified to <code>explain</code> SQL that will be executed and then original query
		# is restored from this variable.
		#<
		variable _queryForResults ""
		variable _queryForExport ""

		#>
		# @var _databasesToAttach
		# Used by {@method execQueryInternal}. Keeps list of databases to be attached when reading from database
		# with {@var _queryForResults}.
		#<
		variable _databasesToAttach [list]

		variable _tabsOrder [list]
		variable _resTabsOrder [list]
		variable _queryExecutor ""
		variable _contextMenu ""
		variable _histContextMenu ""
		variable _panedResults ""
		variable _currentResultsOrientation ""

		#>
		# @method hasChoosenDB
		# @return <code>true</code> if user has choosen any database from databases list, <code>false</code> otherwise.
		#<
		method hasChoosenDB {}
	}

	protected {
		method getSelectedRowDataWithNull {{limited true}}
	}

	public {
		#>
		# @method loadHistory
		# Loads history from settings and adds it to history grid.
		#<
		method loadHistory {}

		#>
		# @method useHistory
		# Called when user double-clicks on history row. It copies SQL code from the history row
		# to SQL query editor and switches tab to <i>query</i>, so it's ready to be executed again.
		#<
		method useHistory {}

		#>
		# @method addToHistory
		# @param dbname Name of database (not object, just its name).
		# @param execDate Date of execution.
		# @param execTime How much time the execution took.
		# @param rows Affected rows.
		# @param query Executed SQL query.
		# @param save Should the new row be saved immediately or it's part of bigger history adding and save process should be done later. In the second case the last row added should pass <code>true</code> in this parameter.
		# Adds new history row.
		#<
		method addToHistory {dbname execDate execTime rows query {save 0}}

		#>
		# @method clearHistory
		# Clears all history entries, both in history grid and in settings file.
		#<
		method clearHistory {}
		method delSelectedHistoryEntry {}

		#>
		# @method sortHistory
		# @param 1 History entry.
		# @param 2 History entry.
		# Implementation of comparing function for history sorting. It sorts by date of execution.
		#<
		method sortHistory {1 2}

		#>
		# @method showStatus
		# @param weight Weight of place taken by status frame. It's bigger when query execution returns result as plain text in this frame.
		# Shows {@var _statusFrame} if it wasn't visible already.
		#<
		method showStatus {{weight 1}}

		#>
		# @method hideStatus
		# Hides {@var _statusFrame} if it wasn't hidden already.
		#<
		method hideStatus {}

		#>
		# @method grid
		# @param args Parameters to execute on {@var _grid}.
		# Gives direct access to results grid.
		#<
		method grid {args} {}

		#>
		# @method setDatabases
		# @param list List of new database objects.
		# Sets {@var _dblist} to given list. Also updates list of database names in combobox visible on user interface.
		#<
		method setDatabases {list}

		#>
		# @method execQuery
		# @param plainText If <code>true</code> then results will be stored in status field as plain text.
		# Called when users puches <i>Execute SQL</i> button on toolbar or pushes shortcut related with it.
		# It calls {@method execQueryInternal} to do the main job.
		#<
		method execQuery {{plainText false}}

		#>
		# @method explainQuery
		# Called when users puches <i>Explain SQL</i> button on toolbar or pushes shortcut related with it.
		# It prepends <code>EXPLAIN</code> keyword befor whole query so user will get explanation of the query execution,
		# instead of executing it.
		#<
		method explainQuery {}

		#>
		# @method execQueryInternal
		# @param db Database object to execute query with.
		# @param query SQL query to execute.
		# @param plainText If <code>true</code> then results will be stored in status field as plain text.
		# Executes given query using given database. It takes care about errors in SQL syntax, switching tab to <i>results</i>
		# when any results were returned, counting execution time and adding new row to the history.
		#<
		method execQueryInternal {db query {plainText false}}

		#>
		# @method getDB
		# @return {@class DB} object with name equal to selected by user in database names list.
		#<
		method getDB {{quiet false}}

		#>
		# @method formatSQL
		# Called when users puches <i>Format SQL</i> button on toolbar or pushes shortcut related with it.
		# Uses {@method Formatter::format} to format SQL code in editor and replaces old - unformatted with new - formatted.
		#<
		method formatSQL {}

		#>
		# @method focusTab
		# Makes sure that currently choosen tab has an input focus.
		#<
		method focusTab {}

		#>
		# @method loadSQL
		# Opens file dialog to load SQL code from file and writes that code to the SQL editor widget.
		#<
		method loadSQL {}

		#>
		# @method saveSQL
		# Opens file dialog to save SQL code that is currently in SQL editor widget.
		#<
		method saveSQL {}

		#>
		# @method refreshHighlighting
		# Tells {@var _sqlEditor} to refresh it's highlighting.
		#<
		method refreshHighlighting {}

		#>
		# @method dbChanged
		# Called each time when users changes database in list visible on user interface.
		# It updates list of tables in currently choosen database.<br>
		# Tcl code should not change current database directly. Use {@method setDatabase} to do so.
		#<
		method dbChanged {}

		#>
		# @method setDatabase
		# @param db New database object.
		# Sets current database to be given one.
		#<
		method setDatabase {db}

		#>
		# @method signal
		# @overloaded Signal
		#<
		method signal {receiver data}

		#>
		# @method setSQL
		# @param sql New SQL code.
		# Replaces any code in SQL editor widget with given code.
		#<
		method setSQL {sql}

		#>
		# @method activated
		# @overloaded MDIWin
		#<
		method activated {}

		#>
		# @method busy
		# If busy dialog doesn't exists - this method makes it appear.<br>
		# It the dialog exists, then this method calls the dialog to do some progress.
		#<
		method busy {}

		#>
		# @method exportResults
		# Called when users puches <i>Export results</i> button on toolbar.
		# It opens export dialog window to export current results.
		#<
		method exportResults {}

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
		# @method nextDatabase
		# Changes current database to next in list (if any).
		#<
		method nextDatabase {}

		#>
		# @method prevDatabase
		# Changes current database to previous (if any).
		#<
		method prevDatabase {}

		#>
		# @method enableRowNavBtn
		# @param list List of button symbolic names (used as indexes to {@var _gtbt}) to enable. Pass empty list to enable all of them.
		# Enables results navigation buttons (to switch between results pages).
		#<
		method enableRowNavBtn {{list ""}}

		#>
		# @method disableRowNavBtn
		# @param list List of button symbolic names (used as indexes to {@var _gtbt}) to disable. Pass empty list to disable all of them.
		# Disables results navigation buttons (to switch between results pages).
		#<
		method disableRowNavBtn {{list ""}}

		#>
		# @method nextRows
		# Called by results navigation button. Shows next results page.
		#<
		method nextRows {}

		#>
		# @method prevRows
		# Called by results navigation button. Shows previous results page.
		#<
		method prevRows {}

		#>
		# @method lastRows
		# Called by results navigation button. Shows last results page.
		#<
		method lastRows {}

		#>
		# @method
		# Called by results navigation button. Shows first results page.
		#<
		method firstRows {}

		#>
		# @method updateEditorToolbar
		# Updated results navigation buttons (counts result rows and enables/disabled buttons).
		#<
		method updateEditorToolbar {}

		#>
		# @method reloadData
		# Reexecutes query stored in {@var _queryForResults} with current {@var _page} value,
		# so it can be used both for refreshing results and for switching results pages.
		#<
		method reloadData {}

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

		method refreshData {}
		method clearDb {}
		method setResultEditToolbarButtonsState {enabledBoolean}
		method handleCompletionError {errorMsg}
		method getStatusField {}
		method fillPlainText {db dataCols dataRows}
		method nextTab {}
		method prevTab {}
		method nextResTab {}
		method prevResTab {}
		method getGridObject {}
		method getFormFrame {}
		method getDataTabs {}
		method prevDataTab {}
		method nextDataTab {}
		method updateFormViewToolbar {}
		method enableFormNavBtn {{list ""}}
		method disableFormNavBtn {{list ""}}
		method cancelExecution {}
		method contextMenuPopup {x y}
		method histContextMenuPopup {x y}
		method switchLineNumbers {}
		method handleAttaches {db contents}
		method addRowInFormView {}
		method createViewFromQuery {}
		method handleBindParams {query}
		method createResultsFrame {framePath}
		method switchResultsOrientation {orientation}
		method updateUISettings {}
		method canDestroy {}
		method getQueryForResults {}
		method getQueryForExport {}

		#>
		# @method getWinNum
		# Generates next number for editor window. Works like sequence.
		# @return Next editor window number.
		#<
		proc getWinNum {}
	}
}

body EditorWin::constructor {title} {
	set _paned [ttk::panedwindow $_main.paned]
	set _tabs [ttk::notebook $_paned.tabs]
	set _panedResults [ttk::notebook $_paned.results_pane]
	set _query [ttk::frame $_tabs.query_tab]
	set _results [ttk::frame $_tabs.results_tab]
	set _history [ttk::frame $_tabs.history_tab]
	$_tabs add $_query -text [mc {SQL query}]
	$_tabs add $_results -text [mc {Results}]
	$_tabs add $_history -text [mc {History}]
	set _tabsOrder [list $_query $_results $_history]

	# Editor
	set _sqlEditor [SQLEditor $_query.query -linenumbers $showLineNumbers -selectionascontents 1 -validatesql true]
	pack $_query.query -side top -fill both -expand 1
	$_sqlEditor setCompletionErrorHandler [list $this handleCompletionError]

	# Main toolbar (execute, etc)
	set _tb [Toolbar $_main.tb]
	pack $_tb -side top -fill x

	set _tbt(execute) [$_tb addButton img_execute [mc "Execute query (%s)" ${::Shortcuts::executeSql}] "$this execQuery"]
	#set _tbt(explain) [$_tb addButton img_execute_text [mc "Execute query with plain string results"] "$this execQuery true"] ;# text results are always available
	set _tbt(explain) [$_tb addButton img_explain [mc "Explain query (%s)" ${::Shortcuts::explainSql}] "$this explainQuery"]
	$_tb addSeparator
	set _tbt(format) [$_tb addButton img_format [mc "Format SQL code (%s)" ${::Shortcuts::formatSql}] "$this formatSQL"]
	#set _tbt(refresh) [$_tb addButton img_highlighter [mc "Refresh syntax highlighting (%s)" ${::Shortcuts::refresh}] "$this refreshHighlighting"] ;# ctext should work correctly without this workaround
	set _tbt(clrhist) [$_tb addButton img_history [mc "Clear history"] "$this clearHistory"]
	$_tb addSeparator
	set _tbt(export) [$_tb addButton img_table_export [mc "Export results"] "$this exportResults"]
	set _tbt(createview) [$_tb addButton img_new_view [mc "Create view from query"] "$this createViewFromQuery"]
	$_tb addSeparator
	set _tbt(executefile) [$_tb addButton img_execute_from_file [mc "Execute SQL from file (%s)" ${::Shortcuts::execFromFile}] "DBTREE executeSqlFromFile \[$this getDB]"]
	set _tbt(open) [$_tb addButton img_open [mc "Load SQL from file (%s)" ${::Shortcuts::loadSqlFile}] "$this loadSQL"]
	set _tbt(save) [$_tb addButton img_save [mc "Save SQL to file (%s)" ${::Shortcuts::saveSqlFile}] "$this saveSQL"]
	$_tb addSeparator
	set _tbt(database) [$_tb addComboBox [mc "Default database for SQL executing\n(%s/%s)" ${::Shortcuts::nextDatabase} ${::Shortcuts::prevDatabase}] 1 "" "$this dbChanged"]

	#pack $_tabs -side top -fill both -expand 1
	pack $_paned -side top -fill both -expand 1

	$_paned add $_tabs -weight 12

	# Creating results panel
	switchResultsOrientation $defaultResultsOrientation

	set _statusFrame $_main.status
	set _status [StatusField ::#auto $_statusFrame]

	set edit [$_sqlEditor getWidget]
# 	set grid [$_grid getWidget]
# 	set form [$_form getFrame]

	# Context menu
	set _contextMenu [menu $_sqlEditor.menu -borderwidth 1 -activeborderwidth 1 -tearoff 0]
	bind [$_sqlEditor getWidget] <Button-$::RIGHT_BUTTON> "$this contextMenuPopup %x %y; tk_popup $_contextMenu %X %Y"

	# History
	set pan [ttk::panedwindow $_history.pan -orient vertical]
	pack $pan -side top -fill both -expand 1

	set _historyGrid [HistGrid $pan.grid -clicked "$this loadHistory" -doubleclicked "$this useHistory"]
	set _historyEdit [SQLEditor $pan.edit]
	set hist [$_historyGrid getWidget]
	set histE [$_historyEdit getWidget]
	$histE configure -state disabled
	$_historyGrid addColumn [mc {Database}] "text"
	$_historyGrid addColumn [mc {Execution date}] "text"
	$_historyGrid addColumn [mc {Execution time (s)}] "numeric"
	$_historyGrid addColumn [mc {Rows affected}] "integer"
	$_historyGrid addColumn [mc {SQL}] "blob"
	$_historyGrid columnsEnd

	set _histContextMenu [menu $_historyGrid.menu -borderwidth 1 -activeborderwidth 1 -tearoff 0]
	bind [$_historyGrid getWidget] <Button-$::RIGHT_BUTTON> "$_historyGrid selectItem %x %y; $this histContextMenuPopup %x %y; tk_popup $_histContextMenu %X %Y"

	$pan add $pan.grid -weight 1
	$pan add $pan.edit -weight 1
#
	# Reading history
	set HIST [CfgWin::getHistory]
	set HIST [lsort -command "$this sortHistory" $HIST]
	foreach entry $HIST {
		eval addToHistory $entry
	}

	# Binds
	bind $_tabs <<NotebookTabChanged>> "$this focusTab; break"
	bind $_restabs <<NotebookTabChanged>> "$this focusDataTab; break"
	bind [$_historyGrid getWidget] <Delete> "$this delSelectedHistoryEntry"

	updateShortcuts

	setDatabases [DBTREE getActiveDatabases]
	set activeDb [DBTREE getSelectedDb]
	if {$activeDb != "" && [$activeDb isOpen]} {
		setDatabase $activeDb
	}
}

body EditorWin::destructor {} {
	if {[$_grid getEditItem] != ""} {
		$_grid commitEdit
	}

	delete object $_grid
	delete object $_sqlEditor
	delete object $_status
}

body EditorWin::switchResultsOrientation {orientation} {
	if {$orientation ni [list "tabs" "paned"]} {
		error "Wrong results panel orientation: $orientation"
	}
	set _currentResultsOrientation $orientation
	catch {destroy $_restabs}
	switch -- $orientation {
		"tabs" {
			catch {$_paned forget $_panedResults}
			$_tabs add $_results
			createResultsFrame $_results
		}
		"paned" {
			catch {$_tabs hide $_results}
			$_paned insert end $_panedResults -weight 20
			createResultsFrame $_panedResults
			if {$_statusVisible} {
				# Fix for wrong behaviour of paned add/insert
				hideStatus
				showStatus
			}
		}
	}
}

body EditorWin::createResultsFrame {notebook} {
	# Results
	set _restabs [ttk::notebook $notebook.tabs]
	pack $_restabs -side top -fill both -expand 1
	set _resTab(grid) [ttk::frame $_restabs.t1]
	set _resTab(form) [ttk::frame $_restabs.t2]
	set _resTab(text) [ttk::frame $_restabs.t3]
	$_restabs add $_resTab(grid) -text [mc {Grid view}]
	$_restabs add $_resTab(form) -text [mc {Form view}]
	$_restabs add $_resTab(text) -text [mc {Plain text view}]
	set _resTabsOrder [list $_resTab(grid) $_resTab(form) $_resTab(text)]

	# Grid view - result grid
	set _grid [ResultGrid $_restabs.t1.grid -clicked "$this markToFillForm" -navaction "$this markToFillForm" -modifycmd "$this updateEditorToolbar"]
	$_grid setParent $this
	pack $_restabs.t1.grid -side bottom -fill both -expand 1

	# Plain text view
	set _plainText [Text $_restabs.t3.text]
	$_plainText readonly true

	# Plain text view toolbar
	set _plainViewToolbar [Toolbar $_restabs.t3.toolbar -side top -fill x]
	pack $_plainViewToolbar -side top -fill x
	set _plainViewToolbarButton(first) [$_plainViewToolbar addButton img_db_first [mc "First %s rows" ${::TableWin::resultsPerPage}] "$this firstRows"]
	set _plainViewToolbarButton(prev) [$_plainViewToolbar addButton img_db_previous [mc "Previous %s rows" ${::TableWin::resultsPerPage}] "$this prevRows"]
	set _plainViewToolbarButton(next) [$_plainViewToolbar addButton img_db_next [mc "Next %s rows" ${::TableWin::resultsPerPage}] "$this nextRows"]
	set _plainViewToolbarButton(last) [$_plainViewToolbar addButton img_db_last [mc "Last %s rows" ${::TableWin::resultsPerPage}] "$this lastRows"]
	$_plainViewToolbar addSeparator
	set _plainViewToolbarButton(total_rows) [$_plainViewToolbar addLabel [mc {Total rows: %s} 0] ""]

	foreach idx {
		first
		prev
		next
		last
	} {
		$_plainViewToolbar setActive 0 $_plainViewToolbarButton($idx)
	}

	# Grid view toolbar
	set _gtb [Toolbar $_restabs.t1.toolbar -side top -fill x]
	pack $_gtb -side top -fill x
	set _gtbt(refresh) [$_gtb addButton img_db_refresh [mc "Refresh results (%s)" ${::Shortcuts::refresh}] "$this refreshData"]
	$_gtb addSeparator
	set _gtbt(commit) [$_gtb addButton img_db_post [mc "Commit row (%s)" ${::Shortcuts::commitFormView}] "$this commitGrid"]
	set _gtbt(rollback) [$_gtb addButton img_db_cancel [mc "Rollback row (%s)" ${::Shortcuts::rollbackFormView}] "$this rollbackGrid"]
	$_gtb addSeparator
	set _gtbt(first) [$_gtb addButton img_db_first [mc "First %s rows" ${::TableWin::resultsPerPage}] "$this firstRows"]
	set _gtbt(prev) [$_gtb addButton img_db_previous [mc "Previous %s rows" ${::TableWin::resultsPerPage}] "$this prevRows"]
	set _gtbt(next) [$_gtb addButton img_db_next [mc "Next %s rows" ${::TableWin::resultsPerPage}] "$this nextRows"]
	set _gtbt(last) [$_gtb addButton img_db_last [mc "Last %s rows" ${::TableWin::resultsPerPage}] "$this lastRows"]
	$_gtb addSeparator
	set _gtbt(total_rows) [$_gtb addLabel [mc {Total rows: %s} 0] ""]

	foreach idx {
		first
		prev
		next
		last
	} {
		$_gtb setActive 0 $_gtbt($idx)
	}

	# Form view toolbar
	set _fvtb [Toolbar $_restabs.t2.tb]
	pack $_fvtb -side top -fill x

	set _tbt(dataform:commit) [$_fvtb addButton img_db_post [mc "Commit changes (%s)" ${::Shortcuts::commitFormView}] "$this commitFormEdit"]
	set _tbt(dataform:rollback) [$_fvtb addButton img_db_cancel [mc "Rollback changes (%s)" ${::Shortcuts::rollbackFormView}] "$this rollbackFormEdit"]
	$_fvtb addSeparator
	set _tbt(dataform:first) [$_fvtb addButton img_db_first [mc "First row from data grid (%s)" ${::Shortcuts::formViewFirstRow}] "$this formFirstRow"]
	set _tbt(dataform:prev) [$_fvtb addButton img_db_previous [mc "Previous row from data grid (%s)" ${::Shortcuts::formViewPrevRow}] "$this formPrevRow"]
	set _tbt(dataform:next) [$_fvtb addButton img_db_next [mc "Next row from data grid (%s)" ${::Shortcuts::formViewNextRow}] "$this formNextRow"]
	set _tbt(dataform:last) [$_fvtb addButton img_db_last [mc "Last row from data grid (%s)" ${::Shortcuts::formViewLastRow}] "$this formLastRow"]
	$_fvtb addSeparator
	set _tbt(dataform:tab_switch) [$_fvtb addImageCheckButton img_form_switch_down img_tab \
		[mc "Field switching mode.\n\nClick it to make <Tab> key to insert tab characters."] \
		[mc "Tab inserting mode.\n\nClick it to make <Tab> key switch between form edit fields."] \
		"::DataEditor::useTabToJump" 1 0 {CfgWin::save [list ::DataEditor::useTabToJump $::DataEditor::useTabToJump]}]
	$_fvtb addSeparator
	set _tbt(dataform:total_rows) [$_fvtb addLabel [mc {Total rows: %s} 0] ""]

	set _form [ScrolledFrame $_restabs.t2.form]
	pack $_form -side top -fill both -expand 1

	pack $_plainText -side top -fill both -expand 1
}

body EditorWin::grid {args} {
	eval $_grid $args
}

body EditorWin::contextMenuPopup {x y} {
	$_contextMenu delete 0 end
	$_contextMenu add command -compound left -image img_format -label [mc "Format SQL code (%s)" ${::Shortcuts::formatSql}] -command "$this formatSQL"
	$_contextMenu add command -compound left -image img_execute_from_file -label [mc "Execute SQL from file (%s)" ${::Shortcuts::execFromFile}] -command "DBTREE executeSqlFromFile \[$this getDB]"
	$_contextMenu add command -compound left -image img_open -label [mc "Load SQL from file (%s)" ${::Shortcuts::loadSqlFile}] -command "$this loadSQL"
	$_contextMenu add command -compound left -image img_save -label [mc "Save SQL to file (%s)" ${::Shortcuts::saveSqlFile}] -command "$this saveSQL"
	$_contextMenu add command -compound left -image img_new_view -label [mc "Create view from query"] -command "$this createViewFromQuery"
	$_contextMenu add separator
	$_contextMenu add command -compound left -image img_copy -label [mc {Copy (%s)} "Control-c"] -command stdContextMenu_copy
	$_contextMenu add command -compound left -image img_cut -label [mc {Cut (%s)} "Control-x"] -command stdContextMenu_cut
	$_contextMenu add command -compound left -image img_paste -label [mc {Paste (%s)} "Control-v"] -command "$_sqlEditor paste"
	$_contextMenu add separator
	$_contextMenu add checkbutton -label [mc "Show line numbers"] -variable ::EditorWin::showLineNumbers -command [list $this switchLineNumbers]
}

body EditorWin::histContextMenuPopup {x y} {
	$_histContextMenu delete 0 end
	$_histContextMenu add command -compound left -image img_delete -label [mc "Delete selected history entry (%s)" "Delete"] -command "$this delSelectedHistoryEntry"
}

body EditorWin::switchLineNumbers {} {
	$_sqlEditor configure -linenumbers $showLineNumbers
}

body EditorWin::setDatabases {list} {
	set _dblist $list
	set dblist [list]
	foreach db $_dblist {
		lappend dblist [$db getName]
	}
	$_tbt(database) configure -values $dblist
	if {[llength $dblist] == 0} {
		clearDb
		return
	}
	if {[$_tbt(database) get] == ""} {
		$_tbt(database) set [lindex $dblist 0]
		dbChanged
	} elseif {[$_tbt(database) get] ni $dblist} {
		$_tbt(database) set [lindex $dblist 0]
		dbChanged
	}

	if {[$_grid getDb] != "" && [$_grid getDb] ni $_dblist} {
		clearDb
		dbChanged
	}
}

body EditorWin::clearDb {} {
	$_tbt(database) set ""
	$_grid setDB ""
	$_grid reset
	$_form reset
	updateEditorToolbar
}

body EditorWin::getDB {{quiet false}} {
	set dblist [list]
	foreach db $_dblist {
		lappend dblist [$db getName]
	}
	set idx [lsearch -exact $dblist [$_tbt(database) get]]
	if {$idx == -1} {
		if {!$quiet} {
			Error [mc {Choose the database first.}]
		}
		return ""
	}
	return [lindex $_dblist $idx]
}

body EditorWin::hasChoosenDB {} {
	if {[$_tbt(database) get] == ""} {return 0}
	set dblist [list]
	foreach db $_dblist {
		lappend dblist [$db getName]
	}
	set idx [lsearch -exact $dblist [$_tbt(database) get]]
	if {$idx == -1} {return 0}
	return 1
}

body EditorWin::addToHistory {dbname execDate execTime rows query {save 0}} {
	set r [$_historyGrid addRow [list $dbname $execDate $execTime $rows $query]]
	set _historySQL($r) [list $dbname $execDate $execTime $rows $query]

	if {$save} {
		set date [CfgWin::addToHistory $dbname $execDate $execTime $rows $query]
	}
}

body EditorWin::handleCompletionError {errorMsg} {
	$_status clear
	$_status addMessage [mc {Error while trying to collect completion list: %s} $errorMsg] error 1
	showStatus
	if {$::DEBUG(global)} {
		puts $::errorInfo
	}
}

body EditorWin::showStatus {{weight 1}} {
	if {$_statusVisible} return
	#pack $_statusFrame -side bottom -fill x
	$_paned insert end $_statusFrame -weight $weight
	set _statusVisible 1
}

body EditorWin::hideStatus {} {
	if {!$_statusVisible} return
	#pack forget $_statusFrame
	$_paned forget $_statusFrame
	set _statusVisible 0
}

body EditorWin::formatSQL {} {
	set query [$_sqlEditor getContents true]
	set query [Formatter::format $query [getDB true]]
	$_sqlEditor setContents $query
	$_sqlEditor reHighlight
	$_sqlEditor delayParserRun
}

body EditorWin::focusTab {} {
	if {[catch {
		set edit [$_sqlEditor getWidget]
		set hist [$_historyGrid getWidget]
		set grid [$_grid getWidget]
	}]} {
		# Since focusTab is called by event loop,
		# some of widgets above might not exist at this moment.
		return
	}
	switch -glob -- [$_tabs select] {
		"*results*" {
			after idle [list catch [list $this focusDataTab]]
		}
		"*query*" {
			focus $edit
		}
		"*history*" {
			$_historyGrid scrollToLastRow
			focus $hist
		}
	}
}

body EditorWin::loadSQL {} {
	set f [GetOpenFile -title [mc {Load SQL from file}] -parent .]
	if {$f == ""} return
	if {![file readable $f]} {
		Error [mc {Can't open %s file for reading.} $f]
		return
	}
	set fd [open $f r]
	set data [read $fd]
	close $fd
	$_sqlEditor setContents $data
	refreshHighlighting
}

body EditorWin::saveSQL {} {
	set f [GetSaveFile -title [mc {Save SQL to file}] -parent .]
	if {$f == ""} return
	if {!([file exists $f] && [file writable $f] || ![file exists $f])} {
		Error [mc {Can't open %s file for writting.} $f]
		return
	}
	set data [$_sqlEditor getContents 1]
	set fd [open $f w]
	puts $fd $data
	close $fd
	$_status clear
	$_status addMessage [mc {SQL code saved in %s.} $f]
	showStatus
}

body EditorWin::refreshHighlighting {} {
	$_sqlEditor reHighlight
}

body EditorWin::getWinNum {} {
	return [incr winNum]
}

body EditorWin::loadHistory {} {
	set r [$_historyGrid getSelectedRow]
	if {$r == ""} return
	set e [$_historyEdit getWidget]
	$e configure -state normal
	$e delete 1.0 end
	$e insert end [lindex $_historySQL($r) end]
	$_historyEdit reHighlight
	$e configure -state disabled
}

body EditorWin::useHistory {} {
	set r [$_historyGrid getSelectedRow]
	if {$r == ""} return
	$_sqlEditor setContents [lindex $_historySQL($r) end]
	$_tabs select 0
}

body EditorWin::clearHistory {} {
	set dialog [YesNoDialog .yesno -title [mc {Clear history}] -message [mc {Are you sure you want to clear queries history?}]]
	if {![$dialog exec]} return
	array unset _historySQL
	$_historyGrid delRows
	set e [$_historyEdit getWidget]
	$e configure -state normal
	$e delete 1.0 end
	$e configure -state disabled
	CfgWin::clearHistory
}

body EditorWin::delSelectedHistoryEntry {} {
	update
	set r [$_historyGrid getSelectedRow]
	if {$r == ""} return
	set dialog [YesNoDialog .yesno -title [mc {Delete the history entry}] -message [mc {Are you sure you want to delete selected queries history entry?}]]
	if {![$dialog exec]} return
	
	lassign [$_historyGrid getSelectedRowData] num db date time rows sql

	unset _historySQL($r)
	$_historyGrid delSelected
	set e [$_historyEdit getWidget]
	$e configure -state normal
	$e delete 1.0 end
	$e configure -state disabled
	CfgWin::delHistoryEntry $date $time $rows
	$_historyGrid scrollToLastRow
}

body EditorWin::sortHistory {1 2} {
	if {[catch {
		set time1 [clock scan [lindex $1 1]]
		set time2 [clock scan [lindex $2 1]]
	} err]} {
		error "Error scanning time. Called scans on:\n[lindex $1 1]\nand\n[lindex $2 1]"
	}
	if {$time1 == $time2} {
		return 0
	} elseif {$time1 < $time2} {
		return -1
	} else {
		return 1
	}
}

body EditorWin::dbChanged {} {
	set db [DBTREE getDBByName [$_tbt(database) get]]
	$_sqlEditor setDB $db
	set validTables [$db getTables]
	$_sqlEditor setValidTables $validTables
}

body EditorWin::setDatabase {db} {
	$_tbt(database) set [$db getName]
	dbChanged
}

body EditorWin::setSQL {sql} {
	$_sqlEditor setContents $sql
}

body EditorWin::signal {receiver data} {
	if {[$this isa $receiver]} {
		switch -- [lindex $data 0] {
			"UPDATE_LINNUMS" {
				[$_sqlEditor getCEdit] configure -linemap [lindex $data 1]
			}
			"UPDATE_DB_TABLES" {
				set db [DBTREE getDBByName [$_tbt(database) get]]
				if {[lindex $data 1] == $db} {
					set validTables [$db getTables]
					$_sqlEditor setValidTables $validTables
				}
			}
		}
	}
}

body EditorWin::busy {} {
	if {[BusyDialog::exists]} {
		BusyDialog::invoke
	} else {
		BusyDialog::show [mc {Processing...}] [mc {Processing query...}] 0
	}
}

body EditorWin::activated {} {
	focusTab
}

body EditorWin::exportResults {} {
	if {[$_grid count] == 0} {
		Warning [mc {No results to export.}]
		return
	}
	set db [getDB]
	if {$db == ""} return
	catch {destroy .resultsExportDialog}
	set dialog [ExportDialog .resultsExportDialog -title [mc {Export results}] -query $_queryForExport -type results -db $db -columns [$_grid getColumns]]
	$dialog exec
}

body EditorWin::getSessionString {} {
	updateGeometry
	if {![hasChoosenDB]} {
		return [list EDITOR_WINDOW "" [$_sqlEditor getContents 1] [getTitle] $mdimode [list $qx $qy $qw $qh]]
	} else {
		set db [getDB true]
		return [list EDITOR_WINDOW [$db getName] [$_sqlEditor getContents 1] [getTitle] $mdimode [list $qx $qy $qw $qh]]
	}
}

body EditorWin::restoreSession {sessionString} {
	lassign $sessionString type dbName contents title mdimode coords
	if {$type != "EDITOR_WINDOW"} {
		return 0
	}

	set win [MAIN openSqlEditor $title]
	$win setSQL $contents

	set db [DBTREE getDBByName $dbName]
	if {$db != ""} {
		if {![$db isOpen]} {
			$db open
			DBTREE refreshSchemaForDb $db
			$win setDatabase $db
		}
	}
	if {$mdimode == "NORMAL"} {
		lassign $coords x y w h
		$win setGeoms $x $y $w $h
	}
	return 1
}

body EditorWin::nextDatabase {} {
	set idx [$_tbt(database) current]
	incr idx
	set dblist [$_tbt(database) cget -values]
	set newDb [lindex $dblist $idx]
	if {$newDb != ""} {
		$_tbt(database) set $newDb
		dbChanged
	}
}

body EditorWin::prevDatabase {} {
	set idx [$_tbt(database) current]
	incr idx -1
	set dblist [$_tbt(database) cget -values]
	set newDb [lindex $dblist $idx]
	if {$newDb != ""} {
		$_tbt(database) set $newDb
		dbChanged
	}
}

body EditorWin::nextTab {} {
	set total [llength $_tabsOrder]
	set tab [$_tabs select]
	set idx [lsearch -exact $_tabsOrder $tab]
	incr idx
	if {$idx == $total} {
		return
	}
	$_tabs select [lindex $_tabsOrder $idx]
}


body EditorWin::prevTab {} {
	set tab [$_tabs select]
	set idx [lsearch -exact $_tabsOrder $tab]
	incr idx -1
	if {$idx < 0} {
		return
	}
	$_tabs select [lindex $_tabsOrder $idx]
}

body EditorWin::nextResTab {} {
	set total [llength $_resTabsOrder]
	set tab [$_restabs select]
	set idx [lsearch -exact $_resTabsOrder $tab]
	incr idx
	if {$idx == $total} {
		return
	}
	$_restabs select [lindex $_resTabsOrder $idx]
}

body EditorWin::prevResTab {} {
	set tab [$_restabs select]
	set idx [lsearch -exact $_resTabsOrder $tab]
	incr idx -1
	if {$idx < 0} {
		return
	}
	$_restabs select [lindex $_resTabsOrder $idx]
}

body EditorWin::updateShortcuts {} {
	set edit [$_sqlEditor getWidget]
	set grid [$_grid getWidget]
	set form [$_form getFrame]
	set hist [$_historyGrid getWidget]
	set histEdit [$_historyEdit getWidget]
	set text [$_plainText getEdit]

	bind $edit <Escape> "$this hideStatus"
	bind $grid <Escape> "$this hideStatus"
	bind $form <Escape> "$this hideStatus"
	bind $text <Escape> "$this hideStatus"

	bind $edit <${::Shortcuts::executeSql}> "$this execQuery; break"
	bind $edit <${::Shortcuts::explainSql}> "$this explainQuery; break"
	bind $edit <${::Shortcuts::formatSql}> "$this formatSQL; break"
	bind $edit <${::Shortcuts::loadSqlFile}> "$this loadSQL; break"
	bind $edit <${::Shortcuts::saveSqlFile}> "$this saveSQL; break"
	bind $edit <${::Shortcuts::execFromFile}> "DBTREE executeSqlFromFile \[$this getDB]; break"

	bind $grid <${::Shortcuts::refresh}> "$this refreshData; break"

	bind $edit <${::Shortcuts::nextTab}> "$this nextTab; break"

	bind $grid <${::Shortcuts::prevTab}> "$this prevTab; break"
	bind $grid <${::Shortcuts::nextTab}> "$this nextTab; break"

	bind $form <${::Shortcuts::prevTab}> "$this prevTab; break"
	bind $form <${::Shortcuts::nextTab}> "$this nextTab; break"

	bind $text <${::Shortcuts::nextTab}> "$this nextTab; break"
	bind $text <${::Shortcuts::prevTab}> "$this prevTab; break"

	bind $hist <${::Shortcuts::prevTab}> "$this prevTab; break"
	bind $histEdit <${::Shortcuts::prevTab}> "$this prevTab; break"

	bind $grid <${::Shortcuts::nextSubTab}> "$this nextResTab; break"
	bind $form <${::Shortcuts::prevSubTab}> "$this prevResTab; break"
	bind $form <${::Shortcuts::nextSubTab}> "$this nextResTab; break"
	bind $text <${::Shortcuts::prevSubTab}> "$this prevResTab; break"

	bind $edit <${::Shortcuts::nextDatabase}> "$this nextDatabase; break"
	bind $edit <${::Shortcuts::prevDatabase}> "$this prevDatabase; break"

	bind $grid <${::Shortcuts::commitFormView}> "$this commitGrid"
	bind $grid <${::Shortcuts::rollbackFormView}> "$this rollbackGrid"
}

body EditorWin::clearShortcuts {} {
	set edit [$_sqlEditor getWidget]
	set grid [$_grid getWidget]
	set form [$_form getFrame]
	set hist [$_historyGrid getWidget]
	set histEdit [$_historyEdit getWidget]
	set text $_resTab(text)

	bind $edit <Escape> ""
	bind $grid <Escape> ""
	bind $form <Escape> ""
	bind $text <Escape> ""

	bind $edit <${::Shortcuts::executeSql}> ""
	bind $edit <${::Shortcuts::explainSql}> ""
	bind $edit <${::Shortcuts::formatSql}> ""
	bind $edit <${::Shortcuts::loadSqlFile}> ""
	bind $edit <${::Shortcuts::saveSqlFile}> ""
	bind $edit <${::Shortcuts::execFromFile}> ""

	bind $edit <${::Shortcuts::nextTab}> ""

	bind $grid <${::Shortcuts::nextTab}> ""
	bind $grid <${::Shortcuts::prevTab}> ""

	bind $form <${::Shortcuts::prevTab}> ""
	bind $form <${::Shortcuts::nextTab}> ""

	bind $text <${::Shortcuts::nextTab}> ""
	bind $text <${::Shortcuts::prevTab}> ""

	bind $hist <${::Shortcuts::prevTab}> ""
	bind $histEdit <${::Shortcuts::prevTab}> ""

	bind $grid <${::Shortcuts::nextSubTab}> ""
	bind $form <${::Shortcuts::nextSubTab}> ""
	bind $form <${::Shortcuts::prevSubTab}> ""
	bind $text <${::Shortcuts::prevSubTab}> ""

	bind $edit <${::Shortcuts::nextDatabase}> ""
	bind $edit <${::Shortcuts::prevDatabase}> ""

	bind $grid <${::Shortcuts::commitFormView}> ""
	bind $grid <${::Shortcuts::rollbackFormView}> ""
}

body EditorWin::enableRowNavBtn {{list ""}} {
	if {$list == ""} {
		set list [list first prev next last]
	}
	foreach idx $list {
		if {[info exists _gtbt($idx)]} {
			$_gtb setActive 1 $_gtbt($idx)
		}
		if {[info exists _plainViewToolbarButton($idx)]} {
			$_plainViewToolbar setActive 1 $_plainViewToolbarButton($idx)
		}
	}
}

body EditorWin::disableRowNavBtn {{list ""}} {
	if {$list == ""} {
		set list [list first prev next last]
	}
	foreach idx $list {
		if {[info exists _gtbt($idx)]} {
			$_gtb setActive 0 $_gtbt($idx)
		}
		if {[info exists _plainViewToolbarButton($idx)]} {
			$_plainViewToolbar setActive 0 $_plainViewToolbarButton($idx)
		}
	}
}

body EditorWin::nextRows {} {
	if {$_page < $_lastPage} {
		incr _page
		reloadData
	}
}

body EditorWin::refreshData {} {
	reloadData
}

body EditorWin::prevRows {} {
	if {$_page > 0} {
		incr _page -1
		reloadData
	}
}

body EditorWin::lastRows {} {
	if {$_page < $_lastPage} {
		set _page $_lastPage
		reloadData
	}
}

body EditorWin::firstRows {} {
	if {$_page > 0} {
		set _page 0
		reloadData
	}
}

body EditorWin::updateEditorToolbar {} {
	if {$_queryForResults != ""} {
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
	}

	set toCommitCnt [llength [$_grid getCellsToCommit]]
	if {$toCommitCnt > 0 || [$_grid isEditCellModified] || [$_grid isEditing]} {
		enableRowNavBtn [list commit rollback]
	} else {
		disableRowNavBtn [list commit rollback]
	}
}

body EditorWin::reloadData {} {
	if {$_queryForResults == ""} return
	set db [getDB]
	if {$db == ""} return

	set query $_queryForResults

	# Executing query
	execQueryInternal $db $query

	updateEditorToolbar
	DBTREE refreshSchemaForDb $db
}

body EditorWin::formNextRow {} {
	if {$_formViewModified} {
		transferFormToGrid
	}
	$_grid goToCell next
	markToFillForm
	fillForm false
}

body EditorWin::formPrevRow {} {
	if {$_formViewModified} {
		transferFormToGrid
	}
	$_grid goToCell prev
	markToFillForm
	fillForm false
}

body EditorWin::formLastRow {} {
	if {$_formViewModified} {
		transferFormToGrid
	}
	$_grid goToCell last
	markToFillForm
	fillForm false
}

body EditorWin::formFirstRow {} {
	if {$_formViewModified} {
		transferFormToGrid
	}
	$_grid goToCell first
	markToFillForm
	fillForm false
}

body EditorWin::getStatusField {} {
	return $_status
}

body EditorWin::fillPlainText {db dataCols dataRows} {
	$_plainText readonly false

	set baseRowNum [expr {${::TableWin::resultsPerPage} * $_page + 1}]
	set plainText [$_plainText getEdit]
	$plainText delete 1.0 end
	set text [formatPlainText $db $baseRowNum $dataCols $dataRows $maxPlainTextColumnWidth $nullPlainTextRepresentation]
	$plainText insert end "$text"
	$_plainText readonly true
}

body EditorWin::getGridObject {} {
	return $_grid
}

body EditorWin::getFormFrame {} {
	return $_form
}

body EditorWin::getDataTabs {} {
	return $_restabs
}

body EditorWin::prevDataTab {} {
	prevResTab
}

body EditorWin::nextDataTab {} {
	nextResTab
}

body EditorWin::updateFormViewToolbar {} {
	if {$_formViewModified || [$_grid isSelectedRowPendingForCommit]} {
 		enableFormNavBtn [list commit rollback]
	} else {
 		disableFormNavBtn [list commit rollback]
	}
	set upState [$_grid hasUpAvailable]
	set downState [$_grid hasDownAvailable]
	$_fvtb setActive $upState $_tbt(dataform:prev)
	$_fvtb setActive $upState $_tbt(dataform:first)
	$_fvtb setActive $downState $_tbt(dataform:next)
	$_fvtb setActive $downState $_tbt(dataform:last)
}

body EditorWin::enableFormNavBtn {{list ""}} {
	if {$list == ""} {
		set list [list first prev next last]
	}
	foreach idx $list {
		$_fvtb setActive 1 $_tbt(dataform:$idx)
	}
}

body EditorWin::disableFormNavBtn {{list ""}} {
	if {$list == ""} {
		set list [list first prev next last]
	}
	foreach idx $list {
		$_fvtb setActive 0 $_tbt(dataform:$idx)
	}
}

##########################################################################################
################################ QUERY EXECUTION ROUTINES ################################
##########################################################################################

body EditorWin::execQuery {{plainText false}} {
	set db [getDB]
	if {$db == ""} return

	set query [$_sqlEditor getContents]
	if {[handleAttaches $db $query]} {
		$_status addMessage [mc {Using ATTACH from SQL editor is not allowed. Instead, register the database you want to attach in SQLiteStudio and use it's name visible in databases tree in any SQL statements you need. They will be auto-attached on request.}] warning
		showStatus
		return
	}
	set query [handleBindParams $query]
	if {[string trim $query] == ""} {
		return ;# canceled in handleBindParam
	}

	set _queryForResults ""
	set _page 0
	set _lastPage 0

	execQueryInternal $db $query $plainText
}

body EditorWin::handleAttaches {db contents} {
	set lexer [$_sqlEditor getCurrentLexer]
	set tokenizedStatements [Lexer::splitStatements [dict get [$lexer tokenize $contents] tokens]]
	set treeDbList [list]
	set nativeDbList [list]
	foreach tokens $tokenizedStatements {
		if {[string toupper [lindex $tokens 0 1]] == "ATTACH"} {
			return 1
		}
	}
	return 0
}

body EditorWin::explainQuery {} {
	set db [getDB]
	if {$db == ""} return

	set query [$_sqlEditor getContents]
	set noCommentsQuery [SqlUtils::removeComments $query]
	if {[string trim $noCommentsQuery] == ""} {
		return
	}

	set _queryForResults ""
	set _page 0
	set _lastPage 0

	$_sqlEditor setContents $noCommentsQuery
	if {[catch {
		if {![regexp -- {(?i)EXPLAIN\s.*} $query]} {
			execQueryInternal $db "EXPLAIN $query"
		} else {
			execQueryInternal $db $query
		}
	} err]} {
		$_sqlEditor setContents $query
		error $err
	}
	$_sqlEditor setContents $query
}

body EditorWin::execQueryInternal {db query {plainText false}} {
	set execDate [clock format [clock seconds] -format {%Y-%m-%d %H:%M}]

	if {![validateInt $::TableWin::resultsPerPage]} {
		set ::TableWin::resultsPerPage 1000 ;# just in case
	}

	# Preparing results grid and progress bar
	$_grid reset
	$_grid setDB $db
	update idletasks

	# Showing progress bar
	set progress [BusyDialog::show [mc {Query execution...}] [mc {Executing SQL query...}] true 50 false]
	$progress configure -onclose [list $this cancelExecution]
	$progress setCloseButtonLabel [mc {Cancel}]
	BusyDialog::autoProgress 20

	# Execute the query, using hacks for attaching databases, limit results, etc.
	set _queryExecutor [QueryExecutor ::#auto $db ${::TableWin::resultsPerPage} $_page]
	$_queryExecutor configure -limitedData true ;# truncate huge data volumes in single cells to reasonable length
	if {[SQLEditor::isParserLimitExceeded $query]} {
		$_queryExecutor configure -forceSimpleExecutor true
	}

	set rowsForPlainText [list]
	set colsForPlainText [list]
	set plainTextMaxSizeMinusOne [expr {$maxPlainTextColumnWidth - 1}]

	#
	# Exec and fill grid
	#
	$_grid hide
	if {[catch {
		set rowCnt 0
		set resultDict [$_queryExecutor exec $query row {
			if {$rowCnt == 0} {
				foreach cell $row {
					set colDict [dict create database "" table "" column "" displayName "" type ""]
					foreach key [list database table column displayName type] {
						if {[dict exists $cell $key]} {
							dict set colDict $key [dict get $cell $key]
						}
					}
					$_grid addColumn $colDict "column"
					lappend colsForPlainText [list $colDict ""]
				}
			}

			set dataRow [list]
			set rowIds [list]
			set cellsForPlainText [list]
			foreach cell $row {
				lappend dataRow [dict get $cell value]
				if {[dict exists $cell rowid]} {
					lappend rowIds [dict get $cell rowid]
				} else {
					lappend rowIds ""
				}

				lappend cellsForPlainText [string range [dict get $cell value] 0 $plainTextMaxSizeMinusOne]
			}
			lappend rowsForPlainText [list $cellsForPlainText ""]
			$_grid addRow $dataRow $rowIds false
			incr rowCnt
			if {$rowCnt % 100 == 0} {
				update ;# idletasks seems not to work correctly here, because of same thread used.
			}
		}]
	} err]} {
		$_grid show
		error $::errorInfo
	}

	# Clean
	if {$_queryExecutor != ""} {
		delete object $_queryExecutor
		set _queryExecutor ""
	}

	# Now we can attach other databases while refreshing columns (their types)
	$_grid refreshTableColumns

	# Restore grid
	$_grid show
	$_grid refreshWidth
	$_grid setSelection

	# We can already set base row num
	$_grid setBaseRowNum [expr {${::TableWin::resultsPerPage} * $_page + 1}]

	# Errors first
	set errors [dict get $resultDict errors]
	if {[dict get $resultDict returnCode] != 0} {
		# Hiding progress dialog
		BusyDialog::hide

		if {[dict get $resultDict returnCode] == 3} {
			# Execution canceled
			update
			return
		}

		$_status clear
		if {[llength $errors] > 0} {
			foreach err $errors {
				cutOffStdTclErr err
				$_status addMessage [mc {Error while executing query: %s} $err] error 1
			}
		} else {
			set code [dict get $resultDict returnCode]
			error [mc {Unknown error while query execution. Please report it! ReturnCode=%s. Query for execution was: %s} $code $query]
		}
		showStatus
		return
	}

	# Remember query to switch pages and export
	set _queryForResults [dict get $resultDict queryForResults]
	set _queryForExport $query

	fillPlainText $db $colsForPlainText $rowsForPlainText

	#
	# Rows affected
	#
	set totRows [dict get $resultDict totalRows]
	set affRows [dict get $resultDict affectedRows]
	
	if {[string trim $totRows] == ""} {
		error "Emptry totRows for query: $query"
	}

	set _lastPage [expr { int( floor( double($totRows - 1) / double(${::TableWin::resultsPerPage}) ) ) }]
	$_gtbt(total_rows) configure -text [mc {Total rows: %s} $totRows]
	$_tbt(dataform:total_rows) configure -text [mc {Total rows: %s} $totRows]
	$_plainViewToolbarButton(total_rows) configure -text [mc {Total rows: %s} $totRows]

	if {![dict get $resultDict allowSwitchingPages]} {
		set _lastPage 0
	}

	updateEditorToolbar
	$_status clear

	# Execution time & status
	set secs [dict get $resultDict time]
	if {$secs != 0} {
		catch {hideStatus}
		showStatus
	} else {
		hideStatus
	}
	if {$totRows > 0} {
		$_status addMessage [mc {%s row(s) read in %s second(s).} $totRows $secs] info
	} else {
		$_status addMessage [mc {%s row(s) affected in %s second(s).} $affRows $secs] info
	}

	# Warnings
	foreach warn [dict get $resultDict warnings] {
		$_status addMessage $warn warning
	}

	# Switching to results tab
	if {$rowCnt > 0} {
		markToFillForm
		if {$_currentResultsOrientation == "tabs"} {
			$_tabs select 1
		}
	}

	# History
	addToHistory [$db getName] $execDate $secs $totRows $query true

	# Load extensions if there were loaded any and remember them for later loads
	set extensionsToLoad [dict get $resultDict extensionsToLoad]
	$db addExtensions $extensionsToLoad
	foreach extensionPair $extensionsToLoad {
		set funcArgs [join $extensionPair ", "]
		set sql "SELECT load_extension($funcArgs)"
		if {[catch {
			$db eval $sql
		} err]} {
			debug "Couldn't load extension $extensionPair:\n$err"
		}
	}

	# Hiding progress dialog
	BusyDialog::hide

	DBTREE refreshSchemaForDb $db
}

body EditorWin::cancelExecution {} {
	if {$_queryExecutor != ""} {
		$_queryExecutor interrupt
		delete object $_queryExecutor
		set _queryExecutor ""
	}
}

body EditorWin::addRowInFormView {} {
}

body EditorWin::createViewFromQuery {} {
	set db [getDB]
	if {$db == ""} return
	set contents [$_sqlEditor getContents]
	set lexer [$_sqlEditor getCurrentLexer]
	set tokenizedStatements [Lexer::splitStatements [dict get [$lexer tokenize $contents] tokens]]
	set selects [list]
	foreach tokens $tokenizedStatements {
		if {[string toupper [lindex $tokens 0 1]] == "SELECT"} {
			lappend selects [Lexer::detokenize $tokens]
		}
	}

	set cnt [llength $selects]
	if {$cnt == 0} {
		Info [mc {No SELECT statements found in editor or in selected part of SQL code.}]
		return
	} elseif {$cnt > 1} {
		Info [mc {More than one SELECT statements found. Please select the one you're interested in and then try again.}]
		return
	}
	set select [lindex $selects 0]

	catch {destroy .newView}
	if {$db != "" && [$db isOpen]} {
		set dialog [ViewDialog .newView -title [mc {New view}] -db $db -code $select]
	} else {
		set dialog [ViewDialog .newView -title [mc {New view}] -code $select]
	}
	$dialog exec
}

body EditorWin::handleBindParams {query} {
	set lexer [$_sqlEditor getCurrentLexer]
	set tokenizedStatements [Lexer::splitStatements [dict get [$lexer tokenize $query] tokens]]

	set wasBind 0
	foreach tokens $tokenizedStatements {
		foreach token $tokens {
			if {[lindex $token 0] == "BIND_PARAM"} {
				set wasBind 1
				break
			}
		}
		if {$wasBind} {
			break
		}
	}

	if {$wasBind} {
		set title [mc {Fill query parameters}]
		catch {destroy .bindParamDialog}
		set dialog [BindParamDialog .bindParamDialog -tokens $tokenizedStatements -title $title]
		set tokenizedStatements [$dialog exec]
		return [Lexer::detokenize [join $tokenizedStatements " {OPERATOR ; 0 0} "]]
	} else {
		return $query
	}
}

body EditorWin::updateUISettings {} {
	MDIWin::updateUISettings
	if {$_currentResultsOrientation != $defaultResultsOrientation} {
		switchResultsOrientation $defaultResultsOrientation
	}
}

body EditorWin::canDestroy {} {
	return [DataEditor::canDestroy]
}

body EditorWin::getSelectedRowDataWithNull {{limited true}} {
	lassign [$_grid getSelectedCell] it selCol
	set columns [$_grid getColumns true]
	set db [getDB]

	set data [list]
	foreach colDesc $columns {
		lassign $colDesc col colName colType colTable
		if {[$_grid isEditPossible $it $col]} {
			set rowId [$_grid getRowId $it $col]
			set value [list [$db onecolumn "SELECT [wrapObjName $colName [$db getDialect]] FROM [wrapObjName $colTable [$db getDialect]] WHERE ROWID = $rowId"] 0]
			if {[$db isNull [lindex $value 0]]} {
				set value [list "" 1]
			}
		} else {
			set value [$_grid getCellDataWithNull $it $col]
		}
		lappend data $value
	}

	return $data
}

body EditorWin::getQueryForResults {} {
	return $_queryForResults
}

body EditorWin::getQueryForExport {} {
	return $_queryForExport
}
