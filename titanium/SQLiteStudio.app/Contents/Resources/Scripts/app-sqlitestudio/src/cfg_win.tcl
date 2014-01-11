use src/common/modal.tcl
use src/common/ui.tcl
use src/common/ui_state_handler.tcl

#>
# @class CfgWin
# This class implements Configuration Window and takes care of
# saving everything in configuration file (which is SQLite database).<br>
# Pushing 'Apply' button in the window calls {@method UI::updateUI}.
#<
class CfgWin {
	inherit Modal UI UiStateHandler

	#>
	# @method constructor
	# @param args Options for a window.
	# Creates window, but doesn't show it - to do so, call to {@method Modal::exec} method is required.<br>
	# Created window is modal-less. For list of available options see {@method Modal::constructor}.
	#<
	constructor {args} {
		eval Modal::constructor $args -modal 0
	} {}

	#>
	# @var theme
	# Currently set theme, <b>it's not</b> the same as selected in configuration window.
	# This variable keeps theme to restore it if user tries other theme from configuration window
	# and finally pushes 'Cancel' button, without applying new theme.
	#<
	common theme ""

	#>
	# @var sessionRestore
	# Boolean variable. If <code>true</code> then restores session saved in configuration.
	# If <code>false</code> then application does nothing. It's configurable on 'Misc' configuration tab.
	#<
	common sessionRestore 1

	#>
	# @var historyLength
	# Keeps number of maximum allowed entries stored in SQL queries history.
	#<
	common historyLength 150
	
	#>
	# @var insCurSpeed
	# Keeps number of milliseconds that insertion cursor blinks with.
	#<
	common insCurSpeed 600

	#>
	# @var unixWebBrowser
	# This variable is used only for Unix systems. It contains choosen web browser.
	#<
	common unixWebBrowser ""

	#>
	# @var language
	# Current interface language used for <code>mclocale</code> from <b>msgcat</b> package.
	#<
	common language ""

	private {
		#>
		# @var _tabs
		# Tabs widget object.
		#<
		variable _tabs ""

		#>
		# @var _colors
		# Colors frame. It's placed on 'Colors' tab.
		#<
		variable _colors ""

		#>
		# @var _fonts
		# Fonts frame. It's placed on 'Fonts' tab.
		#<
		variable _fonts ""

		#>
		# @var _themes
		# Themes frame. It's placed on 'Themes' tab.
		#<
		variable _themes ""

		#>
		# @var _shortcuts
		# Shortcuts frame. It's placed on 'Shortcut' tab.
		#<
		variable _shortcuts ""

		#>
		# @var _misc
		# Miscellaneous frame. It's placed on 'Miscellaneous' tab.
		#<
		variable _misc ""

		#>
		# @var _destTheme
		# Selected theme in themes configuration list.
		#<
		variable _destTheme ""

		#>
		# @arr _widget
		# Contains references to widgets that need to be accessed globally in this class.
		#<
		variable _widget

		#>
		# @arr checkState
		# Variable accessible by widgets to bind values with widget variables.
		#<
		variable checkState

		variable _modified 0

		#>
		# @method makeScrollable
		# @param w Widget to be made scrollable, must be placed inside of canvas.
		# @param canv Canvas that handles scrolling.
		# Binds mouse-roller events for given widgets and all it's children widgets
		#<
		method makeScrollable {w canv}

		#>
		# @method createColorsTab
		# Creates all contents for 'Colors' tab.
		#<
		method createColorsTab {}

		#>
		# @method createFontsTab
		# Creates all contents for 'Fonts' tab.
		#<
		method createFontsTab {}

		#>
		# @method createMiscTab
		# Creates all contents for 'Miscellaneous' tab.
		#<
		method createMiscTab {}

		#>
		# @method createShortcutsTab
		# Creates all contents for 'Shortcuts' tab.
		#<
		method createShortcutsTab {}

		#>
		# @method createThemesTab
		# Creates all contents of 'Themes' tab.
		#<
		method createThemesTab {}

		method createPluginsTab {}

		#>
		# @method getSize
		# @overloaded Modal
		#<
		method getSize {}

		proc openDb {name}
	}

	public {
		#>
		# @arr value
		# Keeps temporary values for all settings variables
		# configured by the window. When 'Apply' or 'Ok' button is pressed,
		# then all values from this array are copied to their parallel
		# variables that are used by application.<br>
		# This array simply allows to close Configuration Window without
		# applying any changes.
		#<
		variable value
		variable cfgFont

		#>
		# @method okClicked
		# @overloaded Modal::okClicked
		#<
		method okClicked {}

		#>
		# @method cancelClicked
		# @overloaded Modal::cancelClicked
		#<
		method cancelClicked {}

		#>
		# @method destroyed
		# @overloaded Modal::destroyed
		#<
		method destroyed {}

		#>
		# @method grabWidget
		# @overloaded Modal::grabWidget
		#<
		method grabWidget {}

		#>
		# @method configCurrentFormatterPlugin
		# Invokes configuration window for currently selected formatter plugin.
		#<
		method configCurrentFormatterPlugin {}

		#>
		# @method updateState
		# @param mode Mode of updating. It describes which part of dialog to update.
		# Updates widget statuses, etc.
		#<
		method updateState {mode}
		
		method langChanged {w arrIdx langDict}

		#>
		# @method apply
		# Applies all changes made in the window and saves them in configuration file.
		#<
		method apply {}

		#>
		# @method updateUISettings
		# @overloaded UI
		#<
		method updateUISettings {}
		method updateUiState {}
		method modifiedFlagProxy {args}

		proc saveFonts {list}
		
		#>
		# @method save
		# @param varList List of variable names and their values, like this: <code>{var1 value1 var2 value2 var3 value3}</code>.
		# Saves given values using given variable names. They are restored later by {@method load}. Variable names have to
		# be absolute, which means any namespace prefixes have to be included.
		#<
		proc save {varList}

		#>
		# @method load
		# Loads variables values from configuration file.
		#<
		proc load {}

		#>
		# @method store
		# @param group Group of keys, kind of namespace to aviod conflicts in key names.
		# @param key Key to store value under.
		# @param value Value to store.
		# This method allows custom value paired with given key to be stored in configuration database file easly.
		#<
		proc store {group key value}

		#>
		# @method get
		# @param group Group of keys to read key from.
		# @param key Key of value to read.
		# Looks for given key in configuration database.
		# @return Value stored in configuration database or empty string if no entry was found.
		#<
		proc get {group key}

		proc putBindHistory {key values}
		proc getBindHistory {key}

		#>
		# @method getDBList
		# @return List of configured databases stored in configuration file.
		#<
		proc getDBList {}

		#>
		# @method saveDBList
		# @param list List of {@class DB} objects.
		# Saves databases objects into configuration file.
		#<
		proc saveDBList {list}

		#>
		# @method getHistory
		# Gets history entries list. Each element of the list is a sublist with following elements:<br>
		# <code>{Database name} {execution date} {execution time} {affected rows} {executed SQL}</code>
		# @return History entries list.
		#<
		proc getHistory {}

		#>
		# @method addToHistory
		# @param dbname Database name.
		# @param execDate Execution date.
		# @param execTime Execution time.
		# @param rows Affected rows.
		# @param query Executed SQL query.
		# Appends new entry to the history. If history entries limit has been exceed, then
		# oldest entries are deleted to fit the limit.
		#<
		proc addToHistory {dbname execDate execTime rows query}

		#>
		# @method clearHistory
		# Deletes <b>all</b> history entries.
		#<
		proc clearHistory {}
		proc delHistoryEntry {date time rows}

		#>
		# @method addSearchDlgHistory
		# @param editPath Path of edit widget (it's symbolic path, not a real one) to assign this entry to given widget.
		# @param type Type must be one of <code>SEARCH</code> or <code>REPLACE</code> to determinate if history entry applies to searching fraze or replaceing fraze.
		# @param value History entry value.
		# Adds new search and/or replace history entry to history database.
		#<
		proc addSearchDlgHistory {editPath type value}

		#>
		# @method getSearchDlgHistory {editPath type}
		# @param editPath Path of edit widget to get history for.
		# @param type Type must be one of <code>SEARCH</code> or <code>REPLACE</code> to determinate if history entry applies to searching fraze or replaceing fraze.
		# Reads history entries of given type, for given widget.
		# @return List of history values. Length of the list is determinated by configurable value of variable {@var SearchDialog::historyLength} .
		#<
		proc getSearchDlgHistory {editPath type}

		#>
		# @method saveFunction
		# @param name Name of function.
		# @param type Type of function (<code>SQL</code>/<code>Tcl</code>).
		# @param code Implementation code.
		# Saves function in configuration so it will be returned by {@method getFunctions}.
		# If function with given name already exists it will be overwritten.
		#<
		proc saveFunction {name type code}

		#>
		# @method getFunctions
		# @return List of existing function entries, where each entry contains 3 elements: name, type and code.
		#<
		proc getFunctions {}

		#>
		# @method clearFunctions
		# Erases all functions from configuration.
		#<
		proc clearFunctions {}

		#>
		# @method convert
		# Converts configuration database to lastest structure if needed. Called from {@method load} method.
		#<
		proc convert {}

		#>
		# @method addReportedBug
		# @param brief Brief of reported bug. Just for quick user information latar on.
		# @param url URL to put into web browser so user can see bug discussion.
		# @param type Type: <code>URL</code> or <code>FEATURE</code>.
		#<
		proc addReportedBug {brief url type}

		#>
		# @method getReportedBugs
		# @return List of elements, where each element has 4 subelements: time of occurance (in unixtime), brief, URL and type.
		#<
		proc getReportedBugs {}

		#>
		# @method clearReportedBugs
		# Clears list of reported bugs.
		#<
		proc clearReportedBugs {}
	}
}

body CfgWin::constructor {args} {
	ttk::frame $path.top
	ttk::frame $path.bottom
	pack $path.top -side top -fill both -expand 1
	pack $path.bottom -side bottom -fill x -padx 3

	set _tabs [ttk::notebook $path.top.tabs]
	pack $_tabs -side top -fill both -expand 1

	createColorsTab
	createFontsTab
	createThemesTab
	createShortcutsTab
	createPluginsTab
	createMiscTab

	### Bottom
	ttk::button $path.bottom.ok -text [mc {Ok}] -command "$this clicked ok" -image img_ok -compound left
	ttk::button $path.bottom.apply -text [mc {Apply}] -command "$this apply" -image img_apply -compound left -state disabled
	ttk::button $path.bottom.cancel -text [mc {Cancel}] -command "$this clicked cancel" -image img_cancel -compound left
	ttk::frame $path.bottom.sep1
	ttk::frame $path.bottom.sep2
	pack $path.bottom.ok -side left -padx 2 -pady 2
	pack $path.bottom.sep1 -side left -padx 10 -pady 2
	pack $path.bottom.apply -side left -padx 2 -pady 2
	pack $path.bottom.sep2 -side left -padx 20 -pady 2
	pack $path.bottom.cancel -side right -padx 2 -pady 2

	#set wd_algo "width"
	#set hg_algo "height"

	#wm geometry $path 460x360
	#wm minsize $path {*}[getSize]

	trace add variable value write [list $this modifiedFlagProxy]
	trace add variable cfgFont write [list $this modifiedFlagProxy]
}

body CfgWin::updateUiState {} {
	$path.bottom.apply configure -state [expr {$_modified ? "normal" : "disabled"}]
}

body CfgWin::modifiedFlagProxy {args} {
	set _modified 1
	updateUiState
}

body CfgWin::getSize {} {
	return [list 600 500]
}

body CfgWin::createThemesTab {} {
	### Themes tab
	set _themes [ttk::frame $_tabs.themes]
	$_tabs add $_themes -text [mc {Theme}] -compound left -image img_theme

	# List
	set ff [ttk::frame $_themes.l]
	pack $ff -side left -pady 20 -padx 10

	ttk::label $ff.lab -text [mc {Select theme to use:}]
	listbox $ff.l -height 22 -width 20 -borderwidth 1 -relief solid -highlightthickness 0 \
		-background ${::Tree::background_color} -foreground ${::Tree::foreground_color} -selectborderwidth 0 \
		-selectbackground ${::Tree::selected_background_color} -selectforeground ${::Tree::selected_foreground_color}
	pack $ff.lab $ff.l -side top

	# Details
	set fr [ttk::frame $_themes.r]
	pack $fr -side right -pady 20 -padx 30 -fill x -expand 1

	pack [ttk::frame $fr.ver] -side top -fill x -pady 6
	ttk::label $fr.ver.lab -text [mc {Theme version:}]
	ttk::label $fr.ver.ver -text "?"
	pack $fr.ver.lab -side left
	pack $fr.ver.ver -side right

	# Filling data
	set availableTileThemes [array names ::THEME_VERSION]
	set themes [lsort -unique -dictionary $availableTileThemes]
	foreach t $themes {
		$ff.l insert end " $t"
	}
	$ff.l selection set [lsearch -exact $themes ${::ttk::currentTheme}]
	$fr.ver.ver configure -text $::THEME_VERSION(${::ttk::currentTheme})
	set _destTheme ${::ttk::currentTheme}
	bind $ff.l <ButtonRelease-1> "
		after 10 {
			set ver \[string trim \[$ff.l get active]]
			$fr.ver.ver configure -text \$::THEME_VERSION(\$ver)
			ttk::setTheme \$ver
			UI::updateUI
			$this modifiedFlagProxy
		}
	"
}

body CfgWin::createShortcutsTab {} {
	set _shortcuts [ttk::frame $_tabs.shortcuts]
	$_tabs add $_shortcuts -text [mc {Shortcuts}] -sticky nswe -compound left -image img_shortcuts

	ScrolledFrame $_shortcuts.sf
	set fr [$_shortcuts.sf getFrame]
	pack $_shortcuts.sf -side top -fill both -expand 1

	# Global shortcuts
	set global [ttk::labelframe $fr.f1 -text [mc {Global shortcuts}]]
	pack $global -side top -fill x -padx 3 -pady 8

	foreach {w var text hint} [list \
		openEdit		::Shortcuts::openEditor			[mc {Open SQL editor}]				[mc {Opens SQL editor window.}] \
		closeSelTask	::Shortcuts::closeSelectedTask	[mc {Close selected task}]			[mc {Closes active MDI window.}] \
		restoreWin		::Shortcuts::restoreLastWindow	[mc {Restore last closed task}]		[mc {Restores last closed MDI window.}] \
		openSettings	::Shortcuts::openSettings		[mc {Open settings}]				[mc {Opens SQLiteStudio settings window.}] \
		nextTask		::Shortcuts::nextTask			[mc {Next task}]					[mc {Switches task (window) to next, placed on the right from active task on taskbar.}] \
		nextTaskAlt		::Shortcuts::nextTaskAlt		[mc {Next task (alternative)}]		[mc "Switches task (window) to next, placed on the right from active task on taskbar.\nThis is alternative shortcut. Does the same thing as one above."] \
		prevTask		::Shortcuts::prevTask			[mc {Previous task}]				[mc {Switches task (window) to previous, placed on the left from active task on taskbar.}] \
		prevTaskAlt		::Shortcuts::prevTaskAlt		[mc {Previous task (alternative)}]	[mc "Switches task (window) to previous, placed on the left from active task on taskbar.\nThis is alternative shortcut. Does the same thing as one above."] \
	] {
		set value($var) [set $var]
		ShortcutEdit $global.$w -label $text -variable [scope value($var)] -hint $hint
		pack $global.$w -side top -fill x -pady 1 -padx 10
	}

	# Table and editor shortcuts
	set global [ttk::labelframe $fr.f2 -text [mc {Editor and table window shortcuts}]]
	pack $global -side top -fill x -padx 3 -pady 8

	foreach {w var text hint} [list \
		editorComplete		::Shortcuts::editorComplete		[mc {SQL editor completion}]				[mc {Invokes SQL completion in editor window.}] \
		executeSql			::Shortcuts::executeSql			[mc {Execute SQL query}]					[mc {Executes SQL query typed in editor.}] \
		explainSql			::Shortcuts::explainSql			[mc {Explain SQL query}]					[mc {Calls EXPLAIN on SQL query typed in editor.}] \
		formatSql			::Shortcuts::formatSql			[mc {Format SQL code}]						[mc {Formats SQL code typed in editor.}] \
		loadFile			::Shortcuts::loadSqlFile		[mc {Load SQL from file}]					[mc {Loads SQL from file to the editor.}] \
		saveFile			::Shortcuts::saveSqlFile		[mc {Save SQL to file}]						[mc {Saves contents of the editor into a file.}] \
		execFromFile		::Shortcuts::execFromFile		[mc {Execute SQL from file}]				[mc {Executes SQL directly from file, without loading it to the editor.}] \
		nextTab				::Shortcuts::nextTab			[mc {Next tab}]								[mc {Switches to next tab of editor window (result or history).}] \
		prevTab				::Shortcuts::prevTab			[mc {Previous tab}]							[mc {Switches to previous tab of editor window (query or result).}] \
		nextSubTab			::Shortcuts::nextSubTab			[mc {Next subtab}]							[mc {Switches to next subtab (form view in results tab).}] \
		prevSubTab			::Shortcuts::prevSubTab			[mc {Previous subtab}]						[mc {Switches to previous subtab (grid view in results tab).}] \
		refresh				::Shortcuts::refresh			[mc {Refresh}]								[mc {Re-executes SQL query so results data is refreshed.}] \
		deleteRow			::Shortcuts::deleteRow			[mc {Delete selected row}]					[mc {Deletes selected row.}] \
		insertRow			::Shortcuts::insertRow			[mc {Add new row}]							[mc {Adds new empty row without commiting it.}] \
		editInEditor		::Shortcuts::editInBlobEditor	[mc {Edit cell in BLOB editor}]				[mc {Opens BLOB editor dialog for selected cell.}] \
		eraseRow			::Shortcuts::eraseRow			[mc {Erase cells data}]						[mc {Erases data of selected cells.}] \
		nextDatabase		::Shortcuts::nextDatabase		[mc {Next editor database in list}]			[mc "Switches database to next in editor context databases list\n(it's drop-down list on top of the editor window)"] \
		prevDatabase		::Shortcuts::prevDatabase		[mc {Previous editor database in list}]		[mc "Switches database to previous in editor context databases list\n(it's drop-down list on top of the editor window)"] \
		commitFormView		::Shortcuts::commitFormView		[mc {Commit edition in Form View}]			[mc {Commits edition in Form View of query results or table data preview.}] \
		rollbackFormView	::Shortcuts::rollbackFormView	[mc {Rollback edition in Form View}]		[mc {Rolls back edition in Form View of query results or table data preview.}] \
		formViewFirstRow	::Shortcuts::formViewFirstRow	[mc {Jump to first row in Form View}]		[mc "Jumps to first row of query results grid\nor table data preview grid in Form View."] \
		formViewPrevRow		::Shortcuts::formViewPrevRow	[mc {Go to previous row in Form View}]		[mc "Goes to previous row of query results grid\nor table data preview grid row in Form View."] \
		formViewNextRow		::Shortcuts::formViewNextRow	[mc {Go to next row in Form View}]			[mc "Goes to next row of query results grid\nor table data preview grid row in Form View."] \
		formViewLastRow		::Shortcuts::formViewLastRow	[mc {Jump to last row in Form View}]		[mc "Jumps to last row of query results grid\nor table data preview grid in Form View."] \
		setNullInForm		::Shortcuts::setNullInForm		[mc {Switch NULL value in form edit field}]	[mc "Sets or unsets NULL value in currently selected\ncolumn in form view data edit mode."]
	] {
		set value($var) [set $var]
		ShortcutEdit $global.$w -label $text -variable [scope value($var)] -hint $hint
		pack $global.$w -side top -fill x -pady 1 -padx 10
	}
	$_shortcuts.sf makeChildsScrollable
}

body CfgWin::createPluginsTab {} {
	set _plug [ttk::frame $_tabs.plugins]
	$_tabs add $_plug -text [mc {Plugins}] -compound left -image img_plugin

	ScrolledFrame $_plug.sf
	set fr [$_plug.sf getFrame]
	pack $_plug.sf -side top -fill both -expand 1

	# SQL formatter plugin
	ttk::labelframe $fr.f -text [mc {SQL formatter plugins}]
	pack $fr.f -side top -fill x -pady 5 -padx 6

	# SQL formatter plugin list
	array set hndClass {}
	foreach hnd $SqlFormattingPlugin::handlers {
		set name [${hnd}::getName]
		set hndClass($name) $hnd
	}

	ttk::frame $fr.f.formatHnd
	pack $fr.f.formatHnd -side top -fill x -pady 2
	set value(::SqlFormattingPlugin::defaultHandler) ${::SqlFormattingPlugin::defaultHandler}
	ttk::label $fr.f.formatHnd.l -text [mc {Use following SQL formatter plugin:}]
	pack $fr.f.formatHnd.l -side left
	ttk::combobox $fr.f.formatHnd.e -values [lsort [array names hndClass]] -textvariable [scope value(::SqlFormattingPlugin::defaultHandler)] -state readonly
	set formatHnd ""
	if {$::SqlFormattingPlugin::defaultHandler != "" && [info exists hndClass($::SqlFormattingPlugin::defaultHandler)]} {
		$fr.f.formatHnd.e set ${::SqlFormattingPlugin::defaultHandler}
		set formatHnd $hndClass(${::SqlFormattingPlugin::defaultHandler})
	} else {
		set formatHnd [lindex ${::SqlFormattingPlugin::handlers} 0]
		set ::SqlFormattingPlugin::defaultHandler ${::SqlFormattingPlugin::defaultHandler}
		$fr.f.formatHnd.e set ${::SqlFormattingPlugin::defaultHandler}
	}
	pack $fr.f.formatHnd.e -side right -padx 5
	bind $fr.f.formatHnd.e <<ComboboxSelected>> "$this updateState formatConfig"

	# SQL formatter plugin config
	ttk::frame $fr.f.formatConfig
	ttk::label $fr.f.formatConfig.lab -text [mc {Configure formatter plugin}]
	set _widget(formatConfig) $fr.f.formatConfig.btn
	ttk::button $_widget(formatConfig) -text [mc {Configure}] -command "$this configCurrentFormatterPlugin" -state disabled
	pack $fr.f.formatConfig.lab -side left
	pack $fr.f.formatConfig.btn -side right -pady 2 -padx 5
	pack $fr.f.formatConfig -side top -fill x
	if {$formatHnd != "" && [${formatHnd}::configurable]} {
		$_widget(formatConfig) configure -state normal
	}

	# Default populating engine
	set iFrame [ttk::labelframe $fr.popFrame -text [mc {Populating plugins}]]
	pack $iFrame -side top -fill x -pady 5 -padx 6

	array unset hndClass
	array set hndClass {}
	foreach hnd $PopulatingPlugin::handlers {
		set name [${hnd}::getName]
		set hndClass($name) $hnd
	}

	ttk::frame $iFrame.popHnd
	pack $iFrame.popHnd -side top -fill x -pady 5
	set value(::PopulatingPlugin::defaultHandler) ${::PopulatingPlugin::defaultHandler}
	ttk::label $iFrame.popHnd.l -text [mc {Default table populating plugin:}]
	pack $iFrame.popHnd.l -side left
	ttk::combobox $iFrame.popHnd.e -values [lsort [array names hndClass]] -textvariable [scope value(::PopulatingPlugin::defaultHandler)] -state readonly
	if {$::PopulatingPlugin::defaultHandler != "" && [info commands $::PopulatingPlugin::defaultHandler] != ""} {
		$iFrame.popHnd.e set [${::PopulatingPlugin::defaultHandler}::getName]
	}
	pack $iFrame.popHnd.e -side right -padx 5
}

body CfgWin::createMiscTab {} {
	set _misc [ttk::frame $_tabs.misc]
	$_tabs add $_misc -text [mc {Miscellaneous}] -compound left -image img_misc_tab

	ScrolledFrame $_misc.sf
	set fr [$_misc.sf getFrame]
	pack $_misc.sf -side top -fill both -expand 1

	foreach {wName varName label hint} [list \
		sess ::CfgWin::sessionRestore [mc {Restore session after next start}] [mc "All windows and their contents (such as SQL code)\nwill be restored while next application startup."] \
		linnum ::EditorWin::showLineNumbers [mc {Show line numbers in SQL editor}] [mc {All SQL editor windows will contain line numbers on the left side of window.}] \
		err_underline ::SQLEditor::error_underline [mc {Underline syntax errors in SQL editor}] [mc "Makes errors to be marked with underline.\nYou can also define foreground and background color for errors."] \
		sqlitetables ::DBTree::showSqliteSystemTables [mc {Show SQLite system tables and indexes in databases tree}] [mc "If enabled then SQLite system tables (matching 'sqlite_*')\nand indexes (matching '(*autoindex*)') are displayed in databases tree."] \
		singleclick ::DBTree::singleClick [mc {Open items with single mouse click in databases tree}] [mc "Items in database tree are open by double click by default.\nThis option switches it to single click."] \
		rowIdsByDefault ::TableWin::rowIdsByDefault [mc {Show ROWID as default instead of row order number in table data view}] [mc "This option affects first column from the left on the data tab of the table window."] \
		tips ::TipsDialog::hide [mc {Do not show 'did you know that...' dialog at startup.}] [mc {Uncheck this option to show the dialog.}] \
		updates ::NewVersionDialog::checkAtStartup [mc {Check for updates at startup.}] [mc "If enabled, application will will check\nfor new version available at startup."] \
		func_sort ::FunctionsDialog::sortByName [mc {Sort custom SQL functions list by name}] [mc {This list is placed in Custom SQL funcions dialog.}] \
		select_grid_edit ::Grid::selectAllOnEdit [mc {Select all contents when editing the table cell}] [mc "If this is enabled, then every time you edit the table cell\nthe contents of that cell will be selected by default."] \
		big_clipboard_cut ::Grid::askIfCutBigClipboard [mc {Ask if clipboard contents should be cut}] [mc "If checked then application will ask user if he wants\nto cut off clipboard contents while pasting,\nin case when they don't fit into the grid.\nIf it's not checked, then application will cut\ncontents without asking."] \
	] {
		set w $fr.$wName
		set value($varName) [set $varName]
		ttk::checkbutton $w -text $label -variable [scope value($varName)]
		pack $w -side top -fill x -padx 6 -pady 5
		if {$hint != ""} {
			helpHint $w $hint
		}
	}

	# Max results per page
	set w $fr.resPerPage
	ttk::frame $w
	pack $w -side top -fill x -pady 5 -padx 6
	set value(::TableWin::resultsPerPage) ${::TableWin::resultsPerPage}
	ttk::label $w.l -text [mc {Rows per page in Table Window and Editor Results:}]
	pack $w.l -side left
	ttk::spinbox $w.e -textvariable [scope value(::TableWin::resultsPerPage)] -from 1 -to 9999999 -increment 10 -width 8 \
		-validate all -validatecommand {validatePositiveInt %P}
	pack $w.e -side right -padx 5
	foreach wid [list $w $w.l $w.e] {
		helpHint $wid [mc {More results per page causes slower loading of single data page. Value 1000 should be right.}]
	}
	
	# Grid column max width
	set w $fr.maxColWidth
	set v "::Grid::maxColumnWidth"
	set value($v) [set $v]
	ttk::frame $w
	ttk::label $w.l -text [mc {Maximum column width in data grids (pixels):}]
	ttk::spinbox $w.e -textvariable [scope value($v)] -from 10 -to 1000 -increment 1 -width 5 \
		 -validate all -validatecommand "validateInt %P"
	foreach wid [list $w $w.l $w.e] {
		helpHint $wid [mc "When there are long values in data grid\ncolumns will be no wider than number\nof pixels typed here."]
	}
	pack $w.l  -side left -padx 3
	pack $w.e  -side right -padx 3
	pack $w -side top -fill x -padx 6 -pady 5

	# History length
	set w $fr.histLgt
	set v ::CfgWin::historyLength
	ttk::frame $w
	pack $w -side top -fill x -pady 5 -padx 6
	set value($v) [set $v]
	ttk::label $w.l -text [mc {History entries limit:}]
	pack $w.l -side left
	ttk::spinbox $w.e -textvariable [scope value($v)] -from 1 -to 9999999 -increment 1 -width 8 \
		-validate all -validatecommand "validatePositiveInt %P"
	pack $w.e -side right -padx 5
	foreach wid [list $w $w.l $w.e] {
		helpHint $wid [mc {Number of rows to remember in SQL editor history.}]
	}

	# Insertion cursor blinking speed
	set w $fr.insCurSpeed
	set v ::CfgWin::insCurSpeed
	ttk::frame $w
	pack $w -side top -fill x -pady 5 -padx 6
	set value($v) [set $v]
	ttk::label $w.l -text [mc {Insertion cursor blinking period (milliseconds):}]
	pack $w.l -side left
	ttk::spinbox $w.e -textvariable [scope value($v)] -from 0 -to 3000 -increment 100 -width 8 \
		-validate all -validatecommand "validatePositiveOrZeroInt %P"
	pack $w.e -side right -padx 5
	foreach wid [list $w $w.l $w.e] {
		helpHint $wid [mc {Number of milliseconds that it takes to blink insertion cursor in SQL editor. Set to 0 to disable blinking.}]
	}

	# Unix Web Browser
	if {[isCommonUnix]} {
		set w $fr.webbr
		set v "::CfgWin::unixWebBrowser"
		ttk::frame $w
		pack $w -side top -fill x -pady 5 -padx 6
		set value($v) [set $v]
		ttk::label $w.l -text [mc {Web browser:}]
		pack $w.l -side left
		ttk::combobox $w.e -values ${::MainWindow::unixWebBrowsers} -textvariable [scope value($v)]
		pack $w.e -side right -padx 5
		foreach wid [list $w $w.l $w.e] {
			helpHint $wid [mc "You can type your own webbrowser command here. It has to be in PATH variable.\nAddress to open will be simply passed as an argument to this command."]
		}
	}

	# Language
	set langDict [getLangLabels true]
	set langs [lsort -dictionary [dict values $langDict]]
	set w $fr.lang
	ttk::frame $w
	pack $w -side top -fill x -pady 5 -padx 6
	set v "::CfgWin::language"
	set value($v) [set $v]
	ttk::label $w.l -text [mc {Language:}]
	pack $w.l -side left
	ttk::combobox $w.e -values $langs -textvariable [scope value($v:labeled)] -state readonly
	bind $w.e <<ComboboxSelected>> [list $this langChanged $w.e $v $langDict]
	if {[dict exists $langDict [mclocale]]} {
		$w.e set [dict get $langDict [mclocale]]
	} else {
		$w.e set [dict get $langDict en]
	}
	pack $w.e -side right -padx 5

	foreach {w v val1 val2 frameLabel radio1Label radio2Label hintText} [list \
		$fr.tableWinTab "::TableWin::openTabOnCreate" 0 1 \
		[mc {Tab in table window on open:}] [mc {Table structure}] [mc {Table data}] \
		[mc "Select which tab should be opened for start in table window,\nwhen you just opened that window."] \
		\
		$fr.viewOpenMode "::DBTree::viewOpenMode" "dialog" "data" \
		[mc {View default display mode:}] [mc {Edition dialog}] [mc {Data view}] \
		[mc {Defines what is displayed by default when user opens a view.}] \
		\
		$fr.editorResultsOrient "::EditorWin::defaultResultsOrientation" tabs paned \
		[mc {Editor window results layout}] [mc {Show results in separated tab}] [mc {Show results in frame below query}] \
		{} \
	] {
		set value($v) [set $v]
		ttk::labelframe $w -text $frameLabel
		ttk::frame $w.opt1
		ttk::radiobutton $w.opt1.r -text $radio1Label -variable [scope value($v)] -value $val1
		ttk::frame $w.opt2
		ttk::radiobutton $w.opt2.r -text $radio2Label -variable [scope value($v)] -value $val2
		pack $w.opt1.r -side left -padx 3
		pack $w.opt2.r -side left -padx 3
		pack $w.opt1 $w.opt2 -side top -fill x
		pack $w -side top -fill x -padx 6 -pady 5
		if {$hintText != ""} {
			helpHint $w $hintText
		}
	}
# 		$fr.dbTreeDispMode "::DBTree::displayMode" "objectsUnderTable" "flat" \
# 		[mc {Database tree display mode}] [mc {Show indexes and triggers linked under referenced table.}] [mc {Show indexes and triggers in their own groups.}] \
# 		{}

	# Objects under table
	set v ::DBTree::displayMode
	set w $fr.dbTreeDispMode
	set value($v) [set $v]
	set value(::DBTree::showColumnsUnderTable) $::DBTree::showColumnsUnderTable
	ttk::labelframe $w -text [mc {Database tree display mode}]
	ttk::frame $w.opt1
	ttk::radiobutton $w.opt1.r -text [mc {Show indexes and triggers linked under referenced table.}] -variable [scope value($v)] -value "objectsUnderTable"
	ttk::frame $w.opt2
	ttk::radiobutton $w.opt2.r -text [mc {Show indexes and triggers in their own groups.}] -variable [scope value($v)] -value "flat"
	ttk::separator $w.sep
	ttk::frame $w.cols
	ttk::checkbutton $w.cols.c -text [mc {Show column names linked under the table.}] -variable [scope value(::DBTree::showColumnsUnderTable)]
	pack $w.opt1.r -side left -padx 3
	pack $w.opt2.r -side left -padx 3
	pack $w.opt1 $w.opt2 -side top -fill x
	pack $w.sep -side top -fill x -pady 3 -padx 3
	pack $w.cols.c -side left -fill x
	pack $w.cols -side top -fill x
	pack $w -side top -fill x -padx 6 -pady 5

	# Plain text configuration
	set w $fr.plainText
	set v "::EditorWin::nullPlainTextRepresentation"
	set value($v) [set $v]
	ttk::labelframe $w -text [mc {Plain text results}]
	ttk::frame $w.null
	ttk::label $w.null.l -text [mc {Display NULL values as:}]
	ttk::entry $w.null.e -textvariable [scope value($v)] -cursor xterm
	set v "::EditorWin::maxPlainTextColumnWidth"
	set value($v) [set $v]
	ttk::frame $w.width
	ttk::label $w.width.l -text [mc {Maximum column width:}]
	ttk::spinbox $w.width.e -textvariable [scope value($v)] -from 1 -to 9999999 -increment 1 -width 8 \
		 -validate all -validatecommand "validatePositiveInt %P"
	foreach wid [list $w.width $w.width.l $w.width.e] {
		helpHint $wid [mc "Values longer than specified here will be cut in plain text results."]
	}
	pack $w.null.l -side left -padx 3
	pack $w.width.l  -side left -padx 3
	pack $w.null.e -side right -padx 3
	pack $w.width.e  -side right -padx 3
	pack $w.null $w.width -side top -fill x -pady 3
	pack $w -side top -fill x -padx 6 -pady 5

	$_misc.sf makeChildsScrollable
}

body CfgWin::createColorsTab {} {
	set _colors [ttk::frame $_tabs.colors]
	$_tabs add $_colors -text [mc {Colors}] -compound left -image img_colors

	ScrolledFrame $_colors.sf
 	set fr [$_colors.sf getFrame]
	pack $_colors.sf -side top -fill both -expand 1

	# Global colors
	#
	set glb [ttk::labelframe $fr.glb -text [mc {Global colors}]]

	foreach {w lab} [list \
		borderBackground [mc {MDI windows title bar background color}] \
		borderForeground [mc {MDI windows title bar foreground color}] \
		borderButtonBackground [mc {MDI windows title bar button background color}] \
		borderButtonActiveBackground [mc {MDI windows title bar active button background color}] \
	] {
		ttk::frame $glb.$w
		pack $glb.$w -side top -fill x -pady 2 -padx 10
		set value(::MDIWin::$w) [set ::MDIWin::$w]
		ColorPicker $glb.$w.pick -label $lab -variable [scope value(::MDIWin::$w)] -parent $path
		pack $glb.$w.pick -side left
	}
	pack $glb -side top -fill x -padx 3

	# Editor colors
	set sqledit [ttk::labelframe $fr.e -text [mc {SQL Editor}]]

	foreach {w lab} [list \
		foreground_color [mc {Editor standard font color}] \
		background_color [mc {Editor background}] \
		selected_foreground [mc {Selected foreground color}] \
		selected_background [mc {Selected background color}] \
		disabled_background [mc {Disabled background color}] \
		tables_color [mc {Tables color}] \
		brackets_color [mc {Brackets color}] \
		square_brackets_color [mc {Square brackets color}] \
		keywords_color [mc {Keywords color}] \
		variables_color [mc {Variables color}] \
		strings_color [mc {Strings color}] \
		comments_color [mc {Comments color}] \
		matched_bracket_fgcolor [mc {Matched brackets foreground color}] \
		matched_bracket_bgcolor [mc {Matched brackets background color}] \
		error_foreground [mc {Syntax error color}] \
	] {
		ttk::frame $sqledit.$w
		pack $sqledit.$w -side top -fill x -pady 2 -padx 10
		set value(::SQLEditor::$w) [set ::SQLEditor::$w]
		ColorPicker $sqledit.$w.pick -label $lab -variable [scope value(::SQLEditor::$w)] -parent $path
		pack $sqledit.$w.pick -side left
	}
	pack $sqledit -side top -fill x -padx 3

	# Tcl editor colors
	set tcledit [ttk::labelframe $fr.tcledit -text [mc {Tcl editor}]]

	foreach {w lab} [list \
		foreground_color [mc {Editor standard font color}] \
		background_color [mc {Editor background}] \
		selected_foreground [mc {Selected foreground color}] \
		selected_background [mc {Selected background color}] \
		disabled_background [mc {Disabled background color}] \
		brackets_color [mc {Brackets color}] \
		square_brackets_color [mc {Square brackets color}] \
		keywords_color [mc {Keywords color}] \
		variables_color [mc {Variables color}] \
		strings_color [mc {Strings color}] \
		options_color [mc {Options color}] \
		comments_color [mc {Comments color}] \
		chars_color [mc {Quoted character color}] \
		matched_bracket_bgcolor [mc {Matched brackets background color}] \
		matched_bracket_fgcolor [mc {Matched brackets foreground color}] \
	] {
		ttk::frame $tcledit.$w
		pack $tcledit.$w -side top -fill x -pady 2 -padx 10
		set value(::TclEditor::$w) [set ::TclEditor::$w]
		ColorPicker $tcledit.$w.pick -label $lab -variable [scope value(::TclEditor::$w)] -parent $path
		pack $tcledit.$w.pick -side left
	}
	pack $tcledit -side top -fill x -padx 3

	# Tree colors
	set tr [ttk::labelframe $fr.tr -text [mc {Trees colors}]]

	foreach {w lab} [list \
		background_color [mc {Tree background}] \
		foreground_color [mc {Tree standard font color}] \
		selected_background_color [mc {Tree selected background color}] \
		selected_foreground_color [mc {Tree selected foreground color}] \
	] {
		ttk::frame $tr.$w
		pack $tr.$w -side top -fill x -pady 2 -padx 10
		set value(::Tree::$w) [set ::Tree::$w]
		ColorPicker $tr.$w.pick -label $lab -variable [scope value(::Tree::$w)] -parent $path
		pack $tr.$w.pick -side left
	}
	foreach {w lab} [list \
		alternative_color [mc {Color for number of objects in tree branch}] \
	] {
		ttk::frame $tr.$w
		pack $tr.$w -side top -fill x -pady 2 -padx 10
		set value(::BrowserTree::$w) [set ::BrowserTree::$w]
		ColorPicker $tr.$w.pick -label $lab -variable [scope value(::BrowserTree::$w)] -parent $path
		pack $tr.$w.pick -side left
	}
	pack $tr -side top -fill x -padx 3

	# Grid colors
	set tg [ttk::labelframe $fr.tg -text [mc {Grids colors}]]

	foreach {w lab} [list \
		background_color [mc {Grid background}] \
		foreground_color [mc {Grid standard font color}] \
		selected_background_color [mc {Grid selected background color}] \
		selected_foreground_color [mc {Grid selected foreground color}] \
		base_col_background_color [mc {Grid base column background color}] \
		null_foreground_color [mc {Foreground color for cells with NULL value}] \
	] {
		ttk::frame $tg.$w
		pack $tg.$w -side top -fill x -pady 2 -padx 10
		set value(::Grid::$w) [set ::Grid::$w]
		ColorPicker $tg.$w.pick -label $lab -variable [scope value(::Grid::$w)] -parent $path
		pack $tg.$w.pick -side left
	}
	pack $tg -side top -fill x -padx 3

	# Status field colors
	set sf [ttk::labelframe $fr.sf -text [mc {Status fields colors}]]

	foreach {w lab} [list \
		background_color [mc {Background color}] \
		foreground_color [mc {Foreground color}] \
		error_color [mc {Error foreground color}] \
		info_color [mc {Information foreground color}] \
		info2_color [mc {Information (second kind) foreground color}] \
	] {
		ttk::frame $sf.$w
		pack $sf.$w -side top -fill x -pady 2 -padx 10
		set value(::StatusField::$w) [set ::StatusField::$w]
		ColorPicker $sf.$w.pick -label $lab -variable [scope value(::StatusField::$w)] -parent $path
		pack $sf.$w.pick -side left
	}
	pack $sf -side top -fill x -padx 3

	# Miscellaneous colors
	set misc [ttk::labelframe $fr.misc -text [mc {Miscellaneous colors}]]

	foreach {w var lab} [list \
		hint_bg ::HINT_BG [mc {Context hints background color}] \
		hint_fg ::HINT_FG [mc {Context hints foreground color}] \
	] {
		ttk::frame $misc.$w
		pack $misc.$w -side top -fill x -pady 2 -padx 10
		set value($var) [set $var]
		ColorPicker $misc.$w.pick -label $lab -variable [scope value($var)] -parent $path
		pack $misc.$w.pick -side left
	}
	pack $misc -side top -fill x -padx 3

	$_colors.sf makeChildsScrollable
}

body CfgWin::createFontsTab {} {
	set _fonts [ttk::frame $_tabs.fonts]
	$_tabs add $_fonts -text [mc {Fonts}] -compound left -image img_font

	ScrolledFrame $_fonts.sf
 	set ff [$_fonts.sf getFrame]
	pack $_fonts.sf -side top -fill both -expand 1

	pack [ttk::frame $ff.top_sep] -side top -fill x -pady 3

	foreach {wdg vname lab} [list \
		edit	::SQLEditor::font		[mc {SQL editor font}] \
		sf		::StatusField::font		[mc {Status fields font}] \
		grid	::Grid::font			[mc {Grid font}] \
		tree	::Tree::font			[mc {Tree font}] \
		treealt	::BrowserTree::numbers_font	[mc {Tree additional labels font}] \
		hint	::HINT_FONT				[mc {Context hints font}] \
	] {
		set w [ttk::frame $ff.$wdg]
		set v $vname
		pack $w -side top -fill x -padx 3 -pady 2
		set cfgFont($v) [set $v]
		FontPicker $w.pick -label $lab -variable [scope cfgFont($v)]
		pack $w.pick -side top -fill x
	}

	# Other font options
	pack [ttk::labelframe $ff.opts -text [mc {Font options}]] -fill x -side top -pady 10 -padx 3
	
	# Bold keywords
	set w [ttk::frame $ff.opts.boldKeywords]
	set v "::SQLEditor::useBoldFontForKeywords"
	pack $w -side top -fill x -padx 3 -pady 2
	set value($v) [set $v]
	ttk::checkbutton $w.c -text [mc {Use bold font for keywords in SQL editor}] -variable [scope value($v)]
	pack $w.c -side top -fill x

	$_fonts.sf makeChildsScrollable
}


body CfgWin::apply {} {
	preventClosing
	set refreshSchema 0

	if {${::CfgWin::language} != "" && ${::CfgWin::language} != $value(::CfgWin::language)} {
		Info [mc {Changed language needs application to be restarted.}]
	}

	if {${::DBTree::showSqliteSystemTables} != $value(::DBTree::showSqliteSystemTables)} {
		set refreshSchema 1
	}

	Shortcuts::clearAllShortcuts
	set list [list]
	foreach v [array names value] {
		lappend list $v $value($v)
		set $v $value($v)
	}
	
	# Fonts
	foreach fontVar [array names cfgFont] {
		set font [set $fontVar]
		font configure $font {*}[font actual $cfgFont($fontVar)]
	}
	updateFonts
	
	set fontList [list]
	foreach font [font names] {
		lappend fontList [list $font [font actual $font]]
	}
	saveFonts $fontList

	# Unix vars
	if {[isCommonUnix]} {
		foreach v {
			::CfgWin::unixWebBrowser
		} {
			lappend list $v $value($v)
			set $v $value($v)
		}
	}

	set _destTheme ${::ttk::currentTheme}
	lappend list ::CfgWin::theme $_destTheme
	lappend list ::CfgWin::sessionRestore ${::CfgWin::sessionRestore}

	# SQL formatter plugin
	catch {delete object ${::Formatter::formatter}}
	catch {array unset hndClass}
	array set hndClass {}
	foreach hnd $SqlFormattingPlugin::handlers {
		set name [${hnd}::getName]
		set hndClass($name) $hnd
	}
	set ::Formatter::formatter [$hndClass(${::SqlFormattingPlugin::defaultHandler}) ::#auto]

	save $list
	set _modified 0

	mclocale $language
	updateUiState
	UI::updateUI
	Shortcuts::updateAllShortcuts
	DBTREE signal DBTree [list REFRESH]
	TASKBAR signal EditorWin [list UPDATE_LINNUMS ${::EditorWin::showLineNumbers}]

	allowClosing
}

body CfgWin::openDb {name} {
	if {[catch {sqlite3 $name $::CFG_DIR/settings}]} {
		Error [mc {Problem occured while tried to open settings file: %s. Seems like %s directory was deleted or renamed. The SQLiteStudio settings won't be saved.} $::CFG_DIR/settings $::CFG_DIR]
		return 1
	}
	return 0
}

body CfgWin::saveFonts {list} {
	if {[openDb cfg]} return

	catch {
		cfg eval {BEGIN}
	}
	foreach f $list {
		lassign $f font cfg
		if {[catch {
			cfg eval {INSERT OR REPLACE INTO fonts (font, configuration) VALUES ($font, $cfg)}
		} err]} {
			debug "Problem while saving font $font: $err"
		}
	}
	catch {
		cfg eval {COMMIT}
		cfg close
	}
}

body CfgWin::save {varList} {
	if {[openDb cfg]} return

	catch {
		cfg eval {BEGIN}
	}
	foreach {var val} $varList {
		if {[catch {
			cfg eval {INSERT OR REPLACE INTO settings (varname, value) VALUES ($var, $val)}
		}]} {
			if {[file exists $::CFG_DIR/settings]} {
				catch {
					file delete -force $::CFG_DIR/settings
					cfg eval {INSERT OR REPLACE INTO settings (varname, value) VALUES ($var, $val)}
				}
			} else {
				break
			}
		}
	}
	catch {
		cfg eval {COMMIT}
		cfg close
	}
}

body CfgWin::load {} {
	if {[openDb cfg]} return

	set tab(bugs) 0
	set tab(dblist) 0
	set tab(settings) 0
	set tab(fonts) 0
	set tab(custom_cfg) 0
	set tab(bind_history) 0
	set tab(history) 0
	set tab(search_dlg_hist) 0
	set tab(functions) 0
	if {[catch {
		cfg eval {SELECT * FROM sqlite_master WHERE type = 'table'} r {
			set tab($r(name)) 1
		}
	}]} {
		cfg close
		return
	}
	if {!$tab(dblist)} {
		cfg eval {CREATE TABLE dblist (path TEXT UNIQUE, name TEXT UNIQUE)}
	}
	if {!$tab(settings)} {
		cfg eval {CREATE TABLE settings (varname TEXT UNIQUE, value TEXT)}
	}
	if {!$tab(fonts)} {
		cfg eval {CREATE TABLE fonts (font TEXT UNIQUE, configuration TEXT)}
	}
	if {!$tab(custom_cfg)} {
		cfg eval {CREATE TABLE custom_cfg (grp TEXT, key TEXT, value TEXT, UNIQUE (grp, key))}
	}
	if {!$tab(bind_history)} {
		cfg eval {CREATE TABLE bind_history (key TEXT PRIMARY KEY, [values] TEXT, unixtime INTEGER)}
	}
	if {!$tab(history)} {
		cfg eval {CREATE TABLE history (dbname TEXT, date TEXT, time REAL, rows INTEGER, sql BLOB)}
	}
	if {!$tab(search_dlg_hist)} {
		cfg eval {CREATE TABLE search_dlg_hist (id INTEGER PRIMARY KEY AUTOINCREMENT, editpath TEXT, type TEXT, value TEXT)}
	}
	if {!$tab(functions)} {
		cfg eval {CREATE TABLE functions (name TEXT PRIMARY KEY, type TEXT, code TEXT)}
	}
	if {!$tab(bugs)} {
		cfg eval {
			CREATE TABLE [bugs]
			(
				[id] INTEGER PRIMARY KEY AUTOINCREMENT,
				[created_on] INTEGER NOT NULL,
				[brief] TEXT,
				[url] TEXT NOT NULL,
				[type] TEXT NOT NULL CHECK
				(
					type IN
					(
						'BUG',
						'FEATURE'
					)
				)
			)
		}
	}

	set toDel [list]
	set toSave [list]
	cfg eval {SELECT * FROM settings} r {
		if {![info exists $r(varname)]} {
			lappend toDel [list $r(varname) $r(value)]
			continue
		}
		if {[checkForFontMigration $r(varname) $r(value)]} {
			lappend toSave $r(varname)
			continue
		}

		catch {set $r(varname) $r(value)}
	}
	
	foreach del $toDel {
		lassign $del varname value
		cfg eval {DELETE FROM settings WHERE varname = $varname AND value = $value}
	}
	
	foreach varname $toSave {
		set value [set $varname]
		cfg eval {UPDATE settings SET value = $value WHERE varname = $varname}
	}
	
	# Load font configurations
	array unset r
	cfg eval {SELECT * FROM fonts} r {
		if {$r(font) ni [font names]} {
			continue
		}
		font configure $r(font) {*}$r(configuration)
		lappend fonts $r(font)
	}
	updateFonts

	catch {
		cfg close
	}

	convert
}

body CfgWin::getDBList {} {
	if {[openDb listdb]} return
	set ret [list]
	catch {
		listdb eval {SELECT * FROM dblist} r {
			lappend ret [list $r(name) $r(path)]
		}
	}
	listdb close
	return $ret
}

body CfgWin::saveDBList {list} {
	if {[openDb listdb]} return
	if {[catch {
		catch {
			listdb eval {BEGIN}
		}
		listdb eval {DELETE FROM dblist}
		foreach db $list {
			if {[$db isTemp]} continue
			set path [$db getPath]
			set name [$db getName]
			if {[catch {
				listdb eval {INSERT INTO dblist (path, name) VALUES ($path, $name)}
			}]} {
				if {[file exists $::CFG_DIR/settings]} {
					catch {
						file delete -force $::CFG_DIR/settings
						listdb eval {INSERT INTO dblist (path, name) VALUES ($path, $name)}
					}
				} else {
					break
				}
			}
		}
		catch {
			listdb eval {COMMIT}
		}
		listdb close
	} err]} {
		Error [mc {Could not save configuration file. Some settings might get lost. Please check if file '%s' is writable.} $::CFG_DIR/settings]
	}
}

body CfgWin::getHistory {} {
	if {[openDb hist]} return
	set ret [list]
	catch {
		hist eval {SELECT * FROM history} r {
			lappend ret [list $r(dbname) $r(date) $r(time) $r(rows) $r(sql)]
		}
	}
	hist close
	return $ret
}

body CfgWin::addToHistory {dbname execDate execTime rows query} {
	if {[openDb hist]} return
	catch {
		hist eval {INSERT INTO history (dbname, date, time, rows, sql) VALUES ($dbname, $execDate, $execTime, $rows, $query)}

		set lgt [hist onecolumn {SELECT COUNT(*) FROM history}]
		if {$lgt > $historyLength} {
			set date [hist onecolumn "SELECT date FROM history ORDER BY date DESC LIMIT 1 OFFSET $historyLength"]
			if {$date != ""} {
				hist eval {DELETE FROM history WHERE date <= $date}
			}
		}
	}
	hist close
}

body CfgWin::clearHistory {} {
	if {[openDb hist]} return
	catch {
		hist eval {DELETE FROM history}
	}
	hist close
}

body CfgWin::delHistoryEntry {date time rows} {
	if {[openDb hist]} return
	catch {
		hist eval "DELETE FROM history WHERE date = '$date' AND time = '$time' AND rows = $rows"
	}
	hist close
}

body CfgWin::makeScrollable {w canv} {
	#if {[winfo children $w] == ""} {puts "$w"}
	foreach wid [winfo children $w] {
		bind $wid <Button-4> "
			$canv yview scroll -1 units
			break
		"
		bind $wid <Button-5> "
			$canv yview scroll 1 units
			break
		"
		makeScrollable $wid $canv
	}
}

body CfgWin::grabWidget {} {
	return $_tabs
}

body CfgWin::okClicked {} {
	preventClosing
	apply
	allowClosing
}

body CfgWin::cancelClicked {} {
	if {$_destTheme != ${::ttk::currentTheme}} {
		ttk::setTheme $_destTheme
		UI::updateUI
	}
	return ""
}

body CfgWin::destroyed {} {
	cancelClicked
}

body CfgWin::updateUISettings {} {
}

body CfgWin::putBindHistory {key values} {
	if {[openDb cfg]} return
	cfg eval {INSERT OR REPLACE INTO bind_history (key, [values], unixtime) VALUES ($key, $values, strftime('%s','now'))}
	if {[cfg onecolumn {SELECT count(*) FROM bind_history}] > 100} {
		set timeLimit [cfg onecolumn {SELECT unixtime FROM bind_history ORDER BY unixtime DESC LIMIT 901}]
		cfg eval {DELETE FROM bind_history WHERE unixtime < $timeLimit}
	}
	cfg close
}

body CfgWin::getBindHistory {key} {
	if {[openDb cfg]} {
		return ""
	}
	set res ""
	catch {
		set res [cfg onecolumn {SELECT [values] FROM bind_history WHERE key = $key LIMIT 1}]
	}
	cfg close
	return $res
}


body CfgWin::store {group key value} {
	if {[openDb cfg]} return
# 	if {[catch {
		cfg eval {INSERT OR REPLACE INTO custom_cfg (grp, key, value) VALUES ($group, $key, $value)}
# 	}]} {
# 		if {[file exists $::CFG_DIR/settings]} {
# 			catch {
# 				file delete -force $::CFG_DIR/settings
# 				cfg eval {INSERT OR REPLACE INTO custom_cfg (grp, key, value) VALUES ($group, $key, $value)}
# 			}
# 		} else {
# 			break
# 		}
# 	}
	cfg close
}

body CfgWin::get {group key} {
	if {[openDb cfg]} {
		return ""
	}
	set res ""
	catch {
		set res [cfg onecolumn {SELECT value FROM custom_cfg WHERE grp = $group AND key = $key LIMIT 1}]
	}
	cfg close
	return $res
}

body CfgWin::addSearchDlgHistory {editPath type value} {
	if {[openDb cfg]} return
	#if {[catch {
		cfg eval {INSERT INTO search_dlg_hist (editpath, type, value) VALUES ($editPath, $type, $value)}
	#}]} {
	#	if {[file exists $::CFG_DIR/settings]} {
	#		catch {
	#			file delete -force $::CFG_DIR/settings
	#			cfg eval {INSERT INTO search_dlg_hist (editpath, type, value) VALUES ($editPath, $type, $value)}
	#		}
	#	} else {
	#		break
	#	}
	#}
	set offset $::SearchDialog::historyLength
	cfg eval {DELETE FROM search_dlg_hist WHERE type = $type AND editpath = $editPath AND rowid <= (SELECT rowid FROM search_dlg_hist WHERE type = $type AND editpath = $editPath ORDER BY rowid DESC LIMIT 1 OFFSET $offset)}
	cfg close
}

body CfgWin::getSearchDlgHistory {editPath type} {
	if {[openDb cfg]} return
	set res [cfg eval {SELECT value FROM search_dlg_hist WHERE type = $type AND editpath = $editPath ORDER BY id DESC}]
	cfg close
	return $res
}

body CfgWin::convert {} {
	set updatedTo [get update last_cfg_update_to]
	if {$updatedTo != ""} {
		if {$updatedTo == $::version} return

		set cfgVer [versionToInt $updatedTo]
		set myVer [versionToInt $::version]
		if {$cfgVer >= $myVer} {
			return
		}
	}

	switch -- "$updatedTo -> $::version" {
		"1.0.0 -> 1.1.0" - " -> 1.1.0" {
			set ::Shortcuts::formatSql "Control-Shift-F"
			save [list ::Shortcuts::formatSql $::Shortcuts::formatSql]
			Shortcuts::updateAllShortcuts
		}
	}

	store update last_cfg_update_to $::version
}

body CfgWin::clearFunctions {} {
	if {[openDb cfg]} return
	catch {cfg eval {DELETE FROM functions}}
	cfg close
}

body CfgWin::saveFunction {name type code} {
	if {[openDb cfg]} return
	cfg eval {INSERT OR REPLACE INTO functions (name, type, code) VALUES ($name, $type, $code)}
	cfg close
}

body CfgWin::getFunctions {} {
	set res [list]
	if {[openDb cfg]} return
	cfg eval {SELECT * FROM functions} r {
		lappend res [list $r(name) $r(type) $r(code)]
	}
	cfg close
	return $res
}

body CfgWin::configCurrentFormatterPlugin {} {
	array set hndClass {}
	foreach hnd $SqlFormattingPlugin::handlers {
		set name [${hnd}::getName]
		set hndClass($name) $hnd
	}
	set handler $hndClass($value(::SqlFormattingPlugin::defaultHandler))

	set t $path.formatterConfig
	if {[winfo exists $t]} {
		destroy $t
	}
	toplevel $t
	wm title $t [mc {SQL formatter options}]
	wm withdraw $t
	#wm overrideredirect $t 1
	$t configure -background black
	pack [ttk::frame $t.root] -fill both -expand 1 -padx 1 -pady 1

	# Plugin interface
	set pluginFrame $t.root.top

	bind $path <Return> "${handler}::applyConfig $pluginFrame; destroy $t"
	bind $path <Escape> "destroy $t"

	pack [ttk::frame $t.root.top] -side top -fill both -padx 2 -expand 1
	pack [ttk::frame $t.root.bottom] -side bottom -fill x

	# MacOS X appearance fix
	if {[tk windowingsystem] == "aqua"} {
		ttk::frame $t.mac_bottom
		ttk::label $t.mac_bottom.l -text " "
		pack $t.mac_bottom.l -side top
		pack $t.mac_bottom -side bottom -fill x
	}

	# Bottom buttons
	ttk::button $t.root.bottom.ok -text [mc {Ok}] -command "${handler}::applyConfig $pluginFrame; destroy $t" -image img_ok -compound left
	ttk::button $t.root.bottom.cancel -text [mc {Cancel}] -command "destroy $t" -image img_cancel -compound left
	pack $t.root.bottom.ok -side left -padx 3 -pady 3
	pack $t.root.bottom.cancel -side right -padx 3 -pady 3

	# Creating plugin UI
	${handler}::createConfigUI $pluginFrame

	# Positioning and setting up
	wm transient $t $path
	wcenterby $t $path req
	focus $t
	grab $t
	raise $t
	update idletasks
	wm minsize $t [winfo width $t] [winfo height $t]
}

body CfgWin::updateState {mode} {
	switch -- $mode {
		"formatConfig" {
			array set hndClass {}
			foreach hnd $SqlFormattingPlugin::handlers {
				set name [${hnd}::getName]
				set hndClass($name) $hnd
			}
			set handler $hndClass($value(::SqlFormattingPlugin::defaultHandler))
			if {[info commands $handler] != "" && [${handler}::configurable]} {
				$_widget(formatConfig) configure -state normal
			} else {
				$_widget(formatConfig) configure -state disabled
			}
		}
	}
}

body CfgWin::addReportedBug {brief url type} {
	set now [clock seconds]
	if {[openDb cfg]} return
	catch {
		cfg eval {INSERT INTO bugs (created_on, brief, url, type) VALUES ($now, $brief, $url, $type)}
	}
	cfg close
}

body CfgWin::getReportedBugs {} {
	set bugList [list]
	if {[openDb cfg]} return
	cfg eval {SELECT * FROM bugs} row {
		lappend bugList [list $row(created_on) $row(brief) $row(url) $row(type)]
	}
	cfg close
	return $bugList
}

body CfgWin::clearReportedBugs {} {
	if {[openDb cfg]} return
	catch {cfg eval {DELETE FROM bugs}}
	cfg close
}

body CfgWin::langChanged {w arrIdx langDict} {
	set currValue [$w get]
	set currIdx [lsearch -exact [dict values $langDict] $currValue]
	if {$currIdx == -1} {
		error "No $currValue in langDict: $langDict"
	}
	set currKey [lindex [dict keys $langDict] $currIdx]
	set value($arrIdx) $currKey
}
