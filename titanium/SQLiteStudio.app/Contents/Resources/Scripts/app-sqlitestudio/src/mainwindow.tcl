use src/shortcuts.tcl
use src/common/singleton.tcl

#>
# @class MainWindow
# This class manages main window and actions depended with it,
# menubar and main toolbar.
#<
class MainWindow {
	inherit Shortcuts Singleton UI

	#>
	# @method constructor
	# @param root Should be toplevel window which is to be the application main window.
	# Creates all components (tree on the left, MDI area, taskbar, toolbar, menubar, etc).
	#<
	constructor {root} {}

	#>
	# @var homepage
	# Application home page address.
	#<
	common homepage "http://sqlitestudio.pl"

	#>
	# @var forumPage
	# Discussion forum address.
	#<
	common forumPage "http://forum.sqlitestudio.pl"

	#>
	# @var downloadPage
	# Application download page address.
	#<
	common downloadPage "http://sqlitestudio.pl/index.rvt?act=download"

	#>
	# @var donatePage
	# Donation page address.
	#<
	common donatePage "http://sqlitestudio.pl/index.rvt?act=donate"

	#>
	# @var bugReportLink
	# Online bugs reporting page address.
	#<
	common bugReportLink "http://bugs.sqlitestudio.pl"

	#>
	# @var sqliteDocsLink
	# Link to online SQLite documentation.
	#<
	common sqliteDocsLink "http://www.sqlite.org/lang.html"

	#>
	# @var sqliteStudioDocsOnlineLink
	# Link to online SQLiteStudio manual.
	#<
	common sqliteStudioDocsOnlineLink "http://sqlitestudio.pl/docs/html/manual.html"

	#>
	# @var sqliteDocsLink
	# Link to online SQLiteStudio bug reporting service.
	#<
	common sqliteStudioBugService "http://sqlitestudio.pl/report_bug.rvt"

	#>
	# @var unixWebBrowsers
	# List of Unix web browsers that were found on local system.
	# It's filled only for Unix systems. The list is used in configuration window (on Unix systems).
	#<
	common unixWebBrowsers [list]

	#>
	# @var changeLogFile
	# Absolute path to changelog file. It's different for binary and source distribution.
	#<
	common changeLogFile "[pwd]/ChangeLog"

	#>
	# @var todoFile
	# Absolute path to changelog file. It's different for binary and source distribution.
	#<
	common todoFile "[pwd]/TODO.txt"

	private {
		#>
		# @var winNum
		# Current windows number. Used for MDI windows path generator.
		#<
		variable winNum 0

		#>
		# @var processes
		# List of opened asynchronous processes (such as web browsers, etc).
		# All of them are closed when SQLiteStudio is closed.
		#<
		variable processes [list]

		#>
		# @var _root
		# Main window path. It's the same as parsed to constructor.
		#<
		variable _root ""

		#>
		# @var _sb
		# Contains Database Tree object, that is placed on the left side of window.
		#<
		variable _sb ""

		#>
		# @var _taskbar
		# Contains Task Bar object, that is placed on the bottom of window.
		#<
		variable _taskbar ""

		#>
		# @var _maxBtns
		# Contains frame with buttons that are used when MDI windows are maximized.
		# Buttons actions are: normalize and close.
		#<
		variable _maxBtns ""

		#>
		# @var _mm
		# Menubar that is placed on top of window.
		#<
		variable _mm ""

		#>
		# @var _tb
		# Toolbar object that is placed on top of window, just under menubar.
		#<
		variable _tb ;# Toolbars

		#>
		# @arr _tbt
		# Array of toolbar button objects. Filled by constructor.
		#<
		variable _tbt ;# Toolbar button IDs
		variable _tbState ;# Toolbar state definitions
		
# 		variable _sbtb "" ;# db tree toolbar
# 		variable _sbtbWidgets ;# db tree toolbar
		variable _filterEntry ""
		variable _filterValue ""

		variable _menuEntryState
		variable _menuEntryShortcut

		#>
		# @method reportBugToLocalFile
		# @param brief Single sentence describing problem.
		# @param contents Full problem description, includeing stack trace.
		# @param os Operating system.
		# @param sqlsVersion SQLiteStudio version.
		# @param featureRequest Boolean determinating if it's a feature request or regular bug report.
		# Reports bug to local file specified with <code>--localbugs</code> startup parameter.
		# This is useful for betatesters that what to collect numerous bugs in one place and then send them manually.
		# This method is called by {@method reportBugViaService} in case of <code>--localbugs</code> option used.
		# @see method reportBugViaService
		#<
		method reportBugToLocalFile {brief contents os sqlsVersion {featureRequest 0}}
		method reportBugViaService {brief contents os sqlsVersion query {featureRequest 0}}

		method fixOldBugsPhase1 {}
		method fixOldBugsPhase2 {}

		method initToolbar {}
		method initMenu {}
		method initMenuRecur {visibilityProfile parentMenu struct}
	}

	public {
		#>
		# @method openSqlEditor
		# @param title Title of new window.
		# @return Created {@class EditorWin} object.
		# Opens new SQL editor (MDI window).
		#<
		method openSqlEditor {{title ""}}

		method updateToolbarVisibility {idx group}

		#>
		# @method updateEditorsDatabases
		# Updates all editor windows databases list so they
		# are up-to-date. Called on new database opened
		# or any is closed.
		#<
		method updateEditorsDatabases {}

		#>
		# @method getNewWin
		# @return Window path.
		# Generates new MDI window path that is free to use (it surely doesn't exist).
		# It uses {@var winNum} variable (increments it).
		#<
		method getNewWin {}

		#>
		# @method openSettings
		# Opens settings window.
		#<
		method openSettings {}

		#>
		# @method saveTBCfg
		# Saves toolbar visibility settings into application configuration database.
		#<
		method saveTBCfg {}

		#>
		# @method getWinAreaSize
		# @return List of two integers that represents width and height of MDI area.
		#<
		method getWinAreaSize {}

		#>
		# @method exportDatabase
		# Opens export dialog in database export mode.
		#<
		method exportDatabase {}

		#>
		# @method exportTable
		# Opens export dialog in table export mode.
		#<
		method exportTable {}

		#>
		# @method importTable
		# Opens import dialog.
		#<
		method importTable {}

		#>
		# @method callOnExit
		# It's called when window manager demands to close the window,
		# which means - when user presses the close button.
		#<
		method callOnExit {}

		#>
		# @method saveMainWinSize
		# Saves main window coordinates.
		#<
		method saveMainWinSize {}

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
		# @method setMaxBtnsVisible
		# @param vis New state of maximized buttons.
		# Shows or hides Maximized buttons. Maximized buttons are used
		# when MDI windows are maximized.
		#<
		method setMaxBtnsVisible {vis}

		#>
		# @method openWebBrowser
		# @param url
		# Opens webbrowser with given url.
		#<
		method openWebBrowser {url}

		#>
		# @method todo
		# Shows Roadmap dialog. It's formatted TODO file contents.
		#<
		method todo {}

		#>
		# @method sqliteDocs
		# Opens webbrowser with online SQLite documentation.
		#<
		method sqliteDocs {}

		method openForum {}

		#>
		# @method sqliteStudioDocsOnline
		# Opens webbrowser with online SQLiteStudio manual.
		#<
		method sqliteStudioDocsOnline {}

		#>
		# @method about
		# Shows About dialog.
		#<
		method about {}

		#>
		# @method changelog
		# Shows ChangeLog dialog.
		#<
		method changelog {}

		#>
		# @method reportBug
		# @param title Brief description to initialize bug report form with.
		# @param desc Full bug description to initialize bug report form with.
		# Opens bug report dialog.
		#<
		method reportBug {title desc}

		#>
		# @method setSubTitle
		# @param txt New subtitle to set or empty string to reset title.
		# Application window title is set to 'SQLite Studio (v1.0.0)' or something like that,
		# but this function lets to set a subtitle in form: 'SQLite Studio (v1.0.0) (subtitle string)'.
		#<
		method setSubTitle {{txt ""}}

		#>
		# @method showTipsWindow
		# Shows Tips&Tricks window.
		#<
		method showTipsWindow {}

		#>
		# @method updateUISettings
		# @overloaded UI
		#<
		method updateUISettings {}

		#>
		# @method functionsEditor
		# Opens functions editor.
		#<
		method functionsEditor {}

		#>
		# @method checkVersion
		# @param noticeAboutNoUpdates If <code>true</code> then no new version message will also be displayed in dialog.
		# Checks for new version.
		#<
		method checkVersion {{noticeAboutNoUpdates false}}

		#>
		# @method reportCustomBug
		# Opens dialog for reporting custom bugs.
		#<
		method reportCustomBug {}

		#>
		# @method reportFeatureRequest
		# Opens dialog for reporting feature request.
		#<
		method reportFeatureRequest {}

		#>
		# @method showBugHistory
		# Opens dialog with bug reports history.
		#<
		method showBugHistory {}

		#>
		# @method reportBugViaService
		# @param brief Single sentence describing problem.
		# @param contents Full problem description, includeing stack trace.
		# @param os Operating system.
		# @param sqlsVersion SQLiteStudio version.
		# @param featureRequest Boolean determinating if it's a feature request or regular bug report.
		# Reports bug to SQLiteStudio bugs database using Tcl http implementation (not from system),
		# which allows to POST as long data as needed.
		#<
		method reportBugViaServiceWithUser {brief contents os sqlsVersion user password {featureRequest 0}}
		method reportBugViaServiceWithEmail {brief contents os sqlsVersion byEmail {featureRequest 0}}

		method getInstalledPackages {}
		method getInstalledPlugins {}
		method updateApplication {version}
		method cancelUpdate {fd file token}
		method finishUpdate {fd file token}
		method updateProgress {progress token total current}
		method getPlatformForUpdate {}
		method sqliteStudioHomePage {}
		method restoreGeometry {}
		method donate {}
		method clearTreeFilter {}
		method updateTreeFilter {}
		method fireTreeFilter {}
		method registerDropTarget {}
		method handleFileDrop {paths}
		method updateMenuAndToolbar {}
	}
}

body MainWindow::constructor {root} {
	set _root $root
	ttk::frame $_root

	# Fixing bugs phase 1
	fixOldBugsPhase1

	# Icon fix
	wm iconphoto . -default img_sqlitestudio

	# Toolbar
	initToolbar

	# Maximized MDI buttons
	set _maxBtns [ttk::frame [$_tb getSpace].maxbtns -style Toolbutton]
	ttk::button $_maxBtns.min -style Toolbutton -image img_win_min_small -command "MDIWin::maximizedMinButtonPressed"
	ttk::button $_maxBtns.close -style Toolbutton -image img_win_close_small -command "MDIWin::maximizedCloseButtonPressed"
	pack $_maxBtns.min -side left -ipadx 1 -ipady 0 -padx 2
	pack $_maxBtns.close -side left -ipadx 1 -ipady 0 -padx 2

	# Taskbar
	set _taskbar $_root.taskbar
	TaskBar ::TASKBAR $_taskbar
	pack $_taskbar -side bottom -fill x

	# Two main parts of window
	pack [ttk::panedwindow $_root.d -orient horizontal] -side bottom -fill both -expand 1

	ttk::frame $_root.d.l
	frame $_root.d.r -background #888888 -relief sunken -borderwidth 0
	$_root.d add $_root.d.l -weight 1
	$_root.d add $_root.d.r -weight 6
	pack propagate $_root.d.r 0

	# DB Tree
	set _sb [DBTree $_root.d.l.sb]
	pack $_sb -side bottom -fill both -expand 1
	interp alias {} ::DBTREE {} $_sb

	# DB Tree filter
	ttk::frame $_root.d.l.filter
	pack $_root.d.l.filter -side top -fill x

	set _filterEntry [ttk::entry $_root.d.l.filter.e -textvariable [scope _filterValue] -width 3]
	ttk::button $_root.d.l.filter.erase -image img_clear_filter -style Toolbutton -command [list $this clearTreeFilter]
	helpHint $_root.d.l.filter.erase [mc {Clear objects filter}]
	helpHint $_filterEntry [mc {Enter object name you want to look for}]
	pack $_filterEntry -side left -fill x -expand 1 -padx 1
	pack $_root.d.l.filter.erase -side right

	bind $_filterEntry <Any-Key> "$this updateTreeFilter"

	# Menu
	initMenu

	# Useful bindings
	Shortcuts::updateAllShortcuts

	# Other bindings
	wm protocol . WM_DELETE_WINDOW "
		$this callOnExit
	"

	registerDropTarget

	# First start? Check available browser for Unix systems
	foreach app {
		firefox
		opera
		chrome
		mozilla
		netscape
		konqueror
		galeon
		dillo
	} {
		if {![catch {exec which $app} res]} {
			lappend unixWebBrowsers $app
		}
	}
	if {${::CfgWin::unixWebBrowser} == ""} {
		set ::CfgWin::unixWebBrowser [lindex $unixWebBrowsers 0]
		CfgWin::save [list ::CfgWin::unixWebBrowser ${::CfgWin::unixWebBrowser}]
	}

	# Restoring settings and finishing startup
	restoreGeometry

	update
	DBTREE loadDatabases

	setSubTitle
	updateUISettings
	updateMenuAndToolbar

	# F10 shortcut workaround (which causes error)
	bind . <F10> "break"

	# Tips&Tricks dialog
	TipsDialog::createTipsList

	update idletasks
	TASKBAR callForAll callOnWinObj refreshWindowPlacement

	if {${::CfgWin::sessionRestore}} {
		update idletasks
		if {[catch {Session::recreate} err]} {
			puts "Error recreating session:\n$::errorInfo"
		}
	}

	if {!$::TipsDialog::hide} {
		showTipsWindow
	}

	update idletasks
	checkVersion

	# Fixing bugs phase 2
	fixOldBugsPhase2
}

body MainWindow::initToolbar {} {
	set structure [TOOLBAR_STRUCTURE]
	rename TOOLBAR_STRUCTURE {}

	set _tb [Toolbar $_root.db]
	pack $_tb -side top -fill x

	foreach {type struct} $structure {
		# type for now is always a group
		set grp [dict get $struct name]
		$_tb addGroup $grp
		set i 0
		foreach widget [dict get $struct widgets] {
			switch -- [dict get $widget type] {
				"button" {
					set _tbt($grp:$i) [$_tb addButton [dict get $widget image] [dict get $widget label] [dict get $widget command]]
					set _tbState($grp:$i) [dict get $widget states]
				}
				"separator" {
					set _tbt($grp:$i) [$_tb addSeparator]
				}
				default {
					error "invalid widget type: [dict get $widget type]"
				}
			}
			incr i
		}
	}

	$_tb setConfigVar ::MainToolbarOrder
	foreach {idx grp} {
		main_toolbar db
		struct_toolbar tree
		wins_toolbar wins
		tools_toolbar tools
		config_toolbar config
	} {
		updateToolbarVisibility $idx $grp
	}
}

body MainWindow::initMenu {} {
	set structure [MENU_STRUCTURE]
	rename MENU_STRUCTURE {}

	set visibilityProfile [list [os]]

	set _mm [menu .menubar -tearoff 0 -type menubar -borderwidth 0 -activeborderwidth 0 -activebackground #DDDDDD]
	initMenuRecur $visibilityProfile $_mm $structure
	. configure -menu $_mm
}

body MainWindow::initMenuRecur {visibilityProfile parentMenu structure} {
	set i 0
	foreach struct $structure {
		set visible 1
		if {[dict exists $struct visibility]} {
			dict for {key vis} [dict get $struct visibility] {
				if {$key in $visibilityProfile} {
					set visible $vis
				}
			}
		}
		if {!$visible} {
			continue
		}

		switch -- [dict get $struct type] {
			"menu" {
				set m [menu $parentMenu.w$i -tearoff 0 -borderwidth 1 -activeborderwidth 1]
				$parentMenu add cascade -label [dict get $struct label] -menu $m
				initMenuRecur $visibilityProfile $m [dict get $struct widgets]
				set _menuEntryState($parentMenu:$i) [dict get $struct states]
			}
			"command" {
				$parentMenu add command -compound left -image [dict get $struct image] \
					-label [dict get $struct label] -command [dict get $struct command]
				set _menuEntryState($parentMenu:$i) [dict get $struct states]
			}
			"checkbutton" {
				$parentMenu add checkbutton -variable [dict get $struct variable] \
					-label [dict get $struct label] -command [dict get $struct command]
				set _menuEntryState($parentMenu:$i) [dict get $struct states]
			}
			"separator" {
				$parentMenu add separator
			}
			default {
				error "invalid widget type: [dict get $widget type]"
			}
		}
		if {[dict exists $struct shortcut]} {
			set _menuEntryShortcut($parentMenu:$i) [dict get $struct shortcut]
		}
		incr i
	}
}

body MainWindow::updateToolbarVisibility {idx group} {
	if {$::VIEW($idx)} {
		$_tb show $group
	} else {
		$_tb hide $group
	}
	saveTBCfg
}

body MainWindow::restoreGeometry {} {
	set useStored 0
	if {[info exists ::WIN_GEOM] && $::WIN_GEOM != ""} {
		lassign [split $::WIN_GEOM +] wh x y
		lassign [split $wh x] w h

		if {[info exists ::WIN_GEOM_ZOOMED]} {
			if {$::WIN_GEOM_ZOOMED} {
				set useStored 1
			} elseif {[isMostlyVisible . $x $y $w $h]} {
				set useStored 1
			}
		} elseif {[isMostlyVisible . $x $y $w $h]} {
			set useStored 1
		}
	}

	if {$useStored} {
		wm geometry . $::WIN_GEOM
	}

	if {[info exists ::WIN_GEOM_ZOOMED] && $::WIN_GEOM_ZOOMED || !$useStored} {
		switch -- [os] {
			"win32" - "macosx" {
				wm state . zoomed
			}
			"linux" - "solarix" - "freebsd" {
				wm attributes . -zoomed 1
			}
			default {
				wm geometry . [winfo screenwidth .]x[winfo screenheight .]+0+0
			}
		}
	}
}

body MainWindow::showTipsWindow {} {
	if {[winfo exists .tips]} {
		delete object .tips
	}
	TipsDialog .tips -title [mc {Did you know that...}]
	.tips exec
}

body MainWindow::callOnExit {} {
	set ::QUITTING 1
	catch {::Session::save}
	saveMainWinSize
	foreach p $processes {
		catch {close $p}
	}
	
	# Close Tk
	destroy .

	# Quit
	exit
}

body MainWindow::saveMainWinSize {} {
	switch -- [os] {
		"solaris" - "linux" - "freebsd" {
			if {[wm attributes . -zoomed]} {
				CfgWin::save [list ::WIN_GEOM_ZOOMED 1]
			} else {
				CfgWin::save [list ::WIN_GEOM_ZOOMED 0]
				CfgWin::save [list ::WIN_GEOM [wm geometry .]]
			}
		}
		"win32" - "macosx" {
			if {[wm state .] == "zoomed"} {
				CfgWin::save [list ::WIN_GEOM_ZOOMED 1]
			} else {
				CfgWin::save [list ::WIN_GEOM_ZOOMED 0]
				CfgWin::save [list ::WIN_GEOM [wm geometry .]]
			}
		}
		default {
			CfgWin::save [list ::WIN_GEOM [wm geometry .]]
		}
	}
}

body MainWindow::openSqlEditor {{title ""}} {
	if {$title == ""} {
		while {$title == "" || [TASKBAR taskExists $title]} { ;# title == "" condition for first iteration to be true
			set edWinNum [EditorWin::getWinNum]
			set title [mc {Editor %s} $edWinNum]
		}
	}
	set e [TASKBAR createTask EditorWin $title]
	if {$e == ""} {
		incr EditorWin::winNum -1
	}
	return $e
}

body MainWindow::updateMenuAndToolbar {} {
	# Going from the end, cause the most precise elements are at the end.
	set profile [lreverse [DBTREE getSelectionProfile]]

	#
	# First toolbar
	#
	foreach idx [array names _tbState] {
		set stateDict $_tbState($idx)
		set w $_tbt($idx)
		set enabled 0
		foreach profileItem $profile {
			if {[dict exists $stateDict $profileItem]} {
				set enabled [dict get $stateDict $profileItem]
				break
			}
		}
		$_tb setActive $enabled $w
	}

	#
	# Then menu
	#
	foreach idx [array names _menuEntryState] {
		set stateDict $_menuEntryState($idx)
		lassign [split $idx :] menu entryIdx
		set enabled 0
		foreach profileItem $profile {
			if {[dict exists $stateDict $profileItem]} {
				set enabled [dict get $stateDict $profileItem]
				break
			}
		}
		$menu entryconfigure $entryIdx -state [expr {$enabled ? "normal" : "disabled"}]
	}
}

body MainWindow::updateEditorsDatabases {} {
	set dblist [DBTREE getActiveDatabases]
	foreach obj [find objects * -class EditorWin] {
		$obj setDatabases $dblist
	}
}

body MainWindow::getNewWin {} {
	incr winNum
	return $_root.d.r.win$winNum
}

body MainWindow::getWinAreaSize {} {
	return [list [winfo width $_root.d.r] [winfo height $_root.d.r]]
}

body MainWindow::openSettings {} {
	if {[winfo exists $_root.cfgwin]} {
		raise $_root.cfgwin
		focus $_root.cfgwin
		return
	}
	CfgWin $_root.cfgwin -title [mc {Settings}] -resizable true
	$_root.cfgwin exec
}

body MainWindow::saveTBCfg {} {
	foreach tb {
		main_toolbar
		struct_toolbar
		wins_toolbar
		tools_toolbar
		config_toolbar
	} {
		CfgWin::save [list ::VIEW($tb) $::VIEW($tb)]
	}
}

body MainWindow::todo {} {
	if {[winfo exists .txtDialog]} {
		delete object .txtDialog
	}
	set fd [open $todoFile r]
	set data [read $fd]
	close $fd

	TextBrowseDialog .txtDialog -title [mc {SQLiteStudio roadmap}]
	.txtDialog setText $data
	set t [.txtDialog textWidget]

	set font [$t cget -font]
	if {[llength $font] == 1} {
		set act [font actual $font]
		set font [list [dict get $act -family] [dict get $act -size]]
	}
	$t tag configure bold -font "$font bold"

	set startIdx 1.0
	set was [list]
	set re {[\*\-]{3}\s[^\n]+}
	while {[set idx [$t search -forwards -regexp -- $re $startIdx]] != ""} {
		if {[lsearch -exact $was $idx] != -1} {
			break
		}
		$t tag add bold $idx [$t index "$idx lineend"]
		lappend was $idx
		set startIdx [$t index "$idx +1 chars"]
	}

	.txtDialog exec
}

body MainWindow::updateShortcuts {} {
	bind . <${::Shortcuts::openEditor}> "$this openSqlEditor; break"
	bind . <${::Shortcuts::closeSelectedTask}> "TASKBAR closeSelectedTask; break"
	bind . <${::Shortcuts::nextTask}> "TASKBAR nextTask; break"
	bind . <${::Shortcuts::nextTaskAlt}> "TASKBAR nextTask; break"
	bind . <${::Shortcuts::prevTask}> "TASKBAR prevTask; break"
	bind . <${::Shortcuts::prevTaskAlt}> "TASKBAR prevTask; break"
	bind . <${::Shortcuts::openSettings}> "$this openSettings; break"
	bind . <${::Shortcuts::restoreLastWindow}> "::MDIWin::restoreLastClosedWindow"

	foreach idx [array names _menuEntryShortcut] {
		lassign [split $idx :] menu entryIdx
		$menu entryconfigure $entryIdx -accelerator [set $_menuEntryShortcut($idx)]
	}
}

body MainWindow::clearShortcuts {} {
	bind . <${::Shortcuts::openEditor}> ""
	bind . <${::Shortcuts::closeSelectedTask}> ""
	bind . <${::Shortcuts::nextTask}> ""
	bind . <${::Shortcuts::nextTaskAlt}> ""
	bind . <${::Shortcuts::prevTask}> ""
	bind . <${::Shortcuts::prevTaskAlt}> ""
	bind . <${::Shortcuts::openSettings}> ""
	bind . <${::Shortcuts::restoreLastWindow}> ""
}

body MainWindow::setMaxBtnsVisible {vis} {
	if {$vis} {
		pack $_maxBtns -side right
	} else {
		pack forget $_maxBtns
	}
}

body MainWindow::sqliteDocs {} {
	openWebBrowser $sqliteDocsLink
}

body MainWindow::openForum {} {
	openWebBrowser $forumPage
}

body MainWindow::sqliteStudioDocsOnline {} {
	openWebBrowser $sqliteStudioDocsOnlineLink
}

body MainWindow::sqliteStudioHomePage {} {
	openWebBrowser $homepage
}

body MainWindow::openWebBrowser {url} {
	switch -- [os] {
		"win32" {
			if {[catch {open "|[auto_execok start] $url" r} res]} {
				Error [mc "Can't start web browser, because:\n%s" $res]
				return
			}
			fconfigure $res -blocking 0
			lappend processes $res
		}
		"macosx" {
			if {[catch {open "|open $url" r} res]} {
				Error [mc "Can't start web browser, because:\n%s" $res]
				return
			}
		}
		"linux" - "freebsd" - "solaris" {
			if {[catch {exec which ${::CfgWin::unixWebBrowser}} br]} {
				Error [mc "Can't start %s web browser, because:\n%s" ${::CfgWin::unixWebBrowser} $br]
				return
			}
			if {[catch {open "|$br $url" r} res]} {
				Error [mc "Can't start %s web browser, because:\n%s" ${::CfgWin::unixWebBrowser} $res]
				return
			}
			fconfigure $res -blocking 0
			lappend processes $res
		}
		default {
			error "Unsupported webbrowser under this operating system."
		}
	}
}

body MainWindow::about {} {
	if {[winfo exists .aboutDialog]} return ;# Fix for MacOS X menu
	[AboutDialog .aboutDialog -title [mc {About SQLiteStudio}]] exec
}

body MainWindow::donate {} {
	openWebBrowser $donatePage
}

body MainWindow::changelog {} {
	if {[winfo exists .changeLogDialog]} {
		delete object .changeLogDialog
	}
	set fd [open $changeLogFile r]
	set data [read $fd]
	close $fd
	set data [string map [list \t ""] $data]

	TextBrowseDialog .changeLogDialog -title [mc {SQLiteStudio ChangeLog}]
	.changeLogDialog setText $data
	set t [.changeLogDialog textWidget]
	$t configure -spacing1 10 -spacing2 0 -height 16

	set font [$t cget -font]
	if {[llength $font] == 1} {
		set act [font actual $font]
		set font [list [dict get $act -family] [dict get $act -size]]
	}
	$t tag configure bold -font "$font bold"
	$t tag configure type -foreground #0000FF

	# Bold
	set startIdx 1.0
	set was [list]
	set re {\[\d+\.\d+\.\d+(-\w+)?\]}
	while {[set idx [$t search -forwards -regexp -- $re $startIdx]] != ""} {
		if {[lsearch -exact $was $idx] != -1} {
			break
		}
		$t tag add bold $idx [$t index "$idx lineend"]
		lappend was $idx
		set startIdx [$t index "$idx +1 chars"]
	}

	# Blue
	set startIdx 1.0
	set was [list]
	set re {\*\s+\[[^\]]+\]\:}
	while {[set idx [$t search -forwards -regexp -- $re $startIdx]] != ""} {
		if {[lsearch -exact $was $idx] != -1} {
			break
		}
		set str [$t get $idx end]
		set lgt [string length [lindex [regexp -inline -- $re $str] 0]]
		$t tag add type $idx "$idx +$lgt chars"
		lappend was $idx
		set startIdx [$t index "$idx +[expr {$lgt+1}] chars"]
	}

	.changeLogDialog exec
}

body MainWindow::setSubTitle {{txt ""}} {
	if {$txt == ""} {
		wm title . "SQLiteStudio (v$::version)"
	} else {
		wm title . "SQLiteStudio (v$::version) \[$txt]"
	}
}

body MainWindow::updateUISettings {} {
	set themedTb [getThemeSetting ${::ttk::currentTheme} toolbar use_themed_background]
	if {$themedTb} {
		$_maxBtns configure -style Toolbutton
	} else {
		$_maxBtns configure -style TFrame
	}

	# Check if windows size is not greater than screen size.
# 	set screenW [winfo screenwidth .]
# 	set screenH [winfo screenheight .]
#
# 	update
# 	set winW [winfo width .]
}

body MainWindow::functionsEditor {} {
	if {[winfo exists .functionsEditor]} return ;# Fix for MacOS X menu
	FunctionsDialog .functionsEditor -title [mc {Custom SQL functions}]
	.functionsEditor exec
}

body MainWindow::checkVersion {{noticeAboutNoUpdates false}} {
	if {[winfo exists .newVersion]} return ;# Fix for MacOS X menu
	if {!$::NewVersionDialog::checkAtStartup} return

	set platDict [getPlatformForUpdate]
	if {$platDict == ""} {
		set os ""
	} else {
		set os [dict get $platDict os]
	}

	tsv::set ::checkVersionVar MAIN_THREAD $::MAIN_THREAD
	tsv::set ::checkVersionVar httpUserAgent $::httpUserAgent
	tsv::set ::checkVersionVar downloadPage $downloadPage
	tsv::set ::checkVersionVar noticeAboutNoUpdates $noticeAboutNoUpdates
	tsv::set ::checkVersionVar os $os
	tsv::set ::checkVersionVar sqliteStudioVersion $::version
	if {$::DEBUG(use_update2)} {
		tsv::set ::checkVersionVar updatesFile "updates2.rvt"
	} else {
		tsv::set ::checkVersionVar updatesFile "updates.rvt"
	}

	thread::create {
		package require http 2.7
		http::config -useragent [tsv::get ::checkVersionVar httpUserAgent]
		set os [tsv::get ::checkVersionVar os]
		set updatesFile [tsv::get ::checkVersionVar updatesFile]
		set sqliteStudioVersion [tsv::get ::checkVersionVar sqliteStudioVersion]
		set query "http://sqlitestudio.pl/${updatesFile}?platform=$os"
		if {[catch {http::geturl $query -timeout 10000} result]} {
			tsv::set ::checkVersionVar result $result
			thread::send [tsv::get ::checkVersionVar MAIN_THREAD] {
				debug "Error while checking updates: [tsv::get ::checkVersionVar result]"
			}
		} else {
			upvar #0 $result data
			set version [string trim $data(body)]
			if {![regexp {\d+\.\d+\.\d+} $version]} {
				if {[tsv::get ::checkVersionVar noticeAboutNoUpdates]} {
					thread::send [tsv::get ::checkVersionVar MAIN_THREAD] {
						Info [mc {There is no new version available.}]
					}
				}
				return
			}

			lassign [split $version .] major minor patch
			set availVersionInt [expr {10000*$major+100*$minor+$patch}]
			set availVersion "$major.$minor.$patch"
			lassign [split $sqliteStudioVersion .] major minor patch
			set currentVersionInt [expr {10000*$major+100*$minor+$patch}]
			if {$currentVersionInt >= $availVersionInt} {
				if {[tsv::get ::checkVersionVar noticeAboutNoUpdates]} {
					thread::send [tsv::get ::checkVersionVar MAIN_THREAD] {
						Info [mc {There is no new version available.}]
					}
				}
				return
			}

			tsv::set ::checkVersionVar availVersion $availVersion
			thread::send [tsv::get ::checkVersionVar MAIN_THREAD] {
				NewVersionDialog .newVersion -url [tsv::get ::checkVersionVar downloadPage] \
					-version [tsv::get ::checkVersionVar availVersion] -title [mc {New version}]
				.newVersion exec
				CfgWin::save [list ::NewVersionDialog::checkAtStartup $::NewVersionDialog::checkAtStartup]
			}
		}
		catch {::http::cleanup $result}
	}
}

body MainWindow::reportCustomBug {} {
	if {[winfo exists .bugReport]} return ;# Fix for MacOS X menu
	BugReportDialog .bugReport -title [mc {Report bug}]
	.bugReport exec
}

body MainWindow::reportFeatureRequest {} {
	if {[winfo exists .wishReport]} return ;# Fix for MacOS X menu
	BugReportDialog .wishReport -title [mc {Feature request}] -featurerequest 1
	.wishReport exec
}

body MainWindow::reportBug {title desc} {
	if {[winfo exists .bugReport]} return ;# Fix for MacOS X menu
	BugReportDialog .bugReport -title [mc {Report bug}] -brief $title -description "\n\n$desc" -focushowto 1
	.bugReport exec
}

body MainWindow::showBugHistory {} {
	if {[winfo exists .bugHistory]} return ;# Fix for MacOS X menu
	BugHistoryDialog .bugHistory -title [mc {Reports history}]
	.bugHistory exec
}

body MainWindow::reportBugViaServiceWithUser {brief contents os sqlsVersion user password {featureRequest 0}} {
	set query [http::formatQuery brief $brief os $os contents $contents version $sqlsVersion byUser $user password $password featureRequest $featureRequest]
	reportBugViaService $brief $contents $os $sqlsVersion $query $featureRequest
}

body MainWindow::reportBugViaServiceWithEmail {brief contents os sqlsVersion byEmail {featureRequest 0}} {
	set query [http::formatQuery brief $brief os $os contents $contents version $sqlsVersion byEmail $byEmail featureRequest $featureRequest]
	reportBugViaService $brief $contents $os $sqlsVersion $query $featureRequest
}

body MainWindow::reportBugViaService {brief contents os sqlsVersion query {featureRequest 0}} {
	if {$::localBugReports != ""} {
		if {[catch {reportBugToLocalFile $brief $contents $os $sqlsVersion $featureRequest} res]} {
			debug "Error reporting bug to file $::localBugReports\:\n$res"
		}
		return
	}

	BusyDialog::show [mc {Reporting bug}] [mc {Reporting bug to SQLiteStudio bugs database...}] 0 20 0
	BusyDialog::autoProgress 500

	tsv::set ::bugReportVar httpUserAgent $::httpUserAgent
	tsv::set ::bugReportVar MAIN_THREAD $::MAIN_THREAD
	tsv::set ::bugReportVar sqliteStudioBugService $sqliteStudioBugService
	tsv::set ::bugReportVar query $query
	tsv::set ::bugReportVar brief $brief
	tsv::set ::bugReportVar featureRequest $featureRequest

	thread::create {
		package require http 2.7
		http::config -useragent [tsv::get ::bugReportVar httpUserAgent]
		if {[catch {
			http::geturl [tsv::get ::bugReportVar sqliteStudioBugService] -timeout 10000 -query [tsv::get ::bugReportVar query]
		} result]} {
			tsv::set ::bugReportVar result $result
			thread::send [tsv::get ::bugReportVar MAIN_THREAD] {
				debug "Error while reporting bug: [tsv::get ::bugReportVar result]"
				BusyDialog::hide
				Info [mc {Problem occurred while reporting bug. You can ignore it and get back to your work.}] [mc {Ignore}]
			}
		} else {
			upvar #0 $result data

			tsv::set ::bugReportVar body [string map [list \" \\\"] $data(body)]
			thread::send [tsv::get ::bugReportVar MAIN_THREAD] {
				set body [tsv::get ::bugReportVar body]
				set featureRequest [tsv::get ::bugReportVar featureRequest]
				CfgWin::addReportedBug [tsv::get ::bugReportVar brief] $body [expr {$featureRequest ? "FEATURE" : "BUG"}]
				debug "Bug report sucessful. Result page contents:\n$body"
				BusyDialog::hide
				Info [mc {Bug successfly reported. Thank you! You can always look at discussion about your report using menu SQLiteStudio -> Show bug reports history}]
			}
		}
		catch {::http::cleanup $result}
	}
}

body MainWindow::reportBugToLocalFile {brief contents os sqlsVersion {featureRequest 0}} {
	set time [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}]
	set type [expr {$featureRequest ? "Feature request" : "Bug report"}]

	set fd [open $::localBugReports a+]
	puts $fd "\[$time] $type"
	puts $fd ""
	puts $fd "BRIEF"
	puts $fd "-----------"
	puts $fd $brief
	puts $fd ""
	puts $fd "CONTENTS"
	puts $fd "-----------"
	puts $fd "$contents"
	puts $fd ""
	puts $fd "OS"
	puts $fd "-----------"
	puts $fd "$os"
	puts $fd ""
	puts $fd "VERSION"
	puts $fd "-----------"
	puts $fd "$sqlsVersion"
	puts $fd ""
	puts $fd "===================================================="
	puts $fd ""
	close $fd
}

body MainWindow::exportTable {} {
	if {[winfo exists .exportTable]} return ;# Fix for MacOS X menu
	set dialog [ExportDialog .exportTable -showdb true -showtable true -title [mc {Export}] -type table]
	$dialog exec
}

body MainWindow::importTable {} {
	if {[winfo exists .importTable]} return ;# Fix for MacOS X menu
	set dialog [ImportDialog .importTable -title [mc {Import data}] -newtable ""]
	$dialog exec
}

body MainWindow::exportDatabase {} {
	if {[winfo exists .exportTable]} return ;# Fix for MacOS X menu
	set db [DBTREE getSelectedDb]
	set dialog [ExportDialog .exportTable -showdb true -showtable true -title [mc {Export}] -type database -showtable false -db $db]
	$dialog exec
}

body MainWindow::fixOldBugsPhase1 {} {
	# Forcing "Enterprise" formatter to be default. Version 2 didn't force that and many people don't use it.
	set forced [CfgWin::get "bugfix" "force_enterprise_formatter"]
	if {$forced != 1} {
		set enterprise [::EnterpriseSqlFormattingPlugin::getName]
		if {${::SqlFormattingPlugin::defaultHandler} != $enterprise} {
			set ::SqlFormattingPlugin::defaultHandler $enterprise
			CfgWin::save [list ::SqlFormattingPlugin::defaultHandler $::SqlFormattingPlugin::defaultHandler]
		}
		CfgWin::store "bugfix" "force_enterprise_formatter" 1
	}
}

body MainWindow::fixOldBugsPhase2 {} {
	# Fixing old default binding for formatSql, which was "Control-Shift-f" and it didn't work because of the Shift.
	if {[string equal $::Shortcuts::formatSql "Control-Shift-f"]} {
		set ::Shortcuts::formatSql "Control-Shift-F"
		CfgWin::save [list ::Shortcuts::formatSql $::Shortcuts::formatSql]
		Shortcuts::updateAllShortcuts
	}
}

body MainWindow::getInstalledPackages {} {
	set res [dict create]
	foreach idx [array names ::PKG] {
		dict set res $idx $::PKG($idx)
	}
	return $res
}

body MainWindow::getInstalledPlugins {} {
	return [lsort -dictionary [findClassesBySuperclass "::Plugin"]]
}

body MainWindow::cancelUpdate {fd file token} {
	#catch {close $fd}
	#catch {file delete -force $file}
	http::reset $token
}

body MainWindow::finishUpdate {fd file token} {
	catch {close $fd}
	BusyDialog::hide
	upvar #0 $token state
	set status $state(status)
	http::cleanup $token
	if {$status != "ok" || [file size $file] < 1024*50} {
		catch {file delete -force $file}
		switch -- $status {
			"timeout" {
				Error [mc {A timeout occured while downloading new version. Try again, or download it manually.}]
			}
			default {
				Error [mc {An error occured while downloading new version. Try again, or download it manually.}]
			}
		}
		return
	}

	set dir [string trimright [file dirname [info nameofexecutable]] "/"]
	set boundle 0
	if {[string match "*/SQLiteStudio.app/Contents/MacOS" $dir]} {
		set boundle 1
	}

	set prefix [lindex [regexp -inline -- {(sqlitestudio\-\d+\.\d+\.\d+)\.new(\.\d+)?} $file] 1]

	if {$boundle} {
		set platform "macosx"
	} elseif {$::tcl_platform(platform) == "windows"} {
		set platform "windows"
	} elseif {$::tcl_platform(platform) == "unix"} {
		set platform "unix"
	}

	switch -- $platform {
		"macosx" {
			set exe [file dirname [file dirname $dir]]
		}
		"unix" {
			set exe "$dir/${prefix}.bin"
		}
		"windows" {
			set exe "$dir/${prefix}.exe"
		}
		default {
			error "Error updating application. Unknown platform: $platform"
		}
	}

	if {[catch {
		switch -- $platform {
			"macosx" {
				set topDir [file dirname [file dirname [file dirname $dir]]]
				set zipfile $topDir/$prefix.zip
				file rename -force $file $zipfile
				if {[file exists $exe]} {
					file rename -force $exe $exe.bak
				}
				set pwd [pwd]
				cd $topDir
				exec unzip $zipfile
				cd $pwd
				file delete -force $zipfile
				file attributes $exe/Contents/MacOS/Wish -permissions "+x"
				exec $exe/Contents/MacOS/Wish $exe/Contents/Resources/Scripts/app-sqlitestudio/main.tcl --update-step-2 [file normalize $exe.bak] &
			}
			"windows" {
				if {[file exists $exe]} {
					# This has to be done for each platform separately,
					# because on each platform it could be executed at different moment.
					file rename -force $exe $exe.bak
				}
				file rename -force $file $exe
				exec $exe --update-step-2 [file normalize $exe.bak] &
			}
			"unix" {
				if {[file exists $exe]} {
					file rename -force $exe $exe.bak
				}
				file rename -force $file $exe
				file attributes $exe -permissions "+x"
				exec $exe --update-step-2 [file normalize $exe.bak] &
			}
		}
		exit
	} err]} {
		if {$::DEBUG(global)} {
			puts "Step 1 updating error: $err"
		}
	}
}

body MainWindow::updateProgress {progress token total current} {
	if {$total == 0 || ![winfo exists $progress]} {
		return
	}
	set percents [expr {int(round(double($current) / $total * 100))}]
	$progress setProgress $percents
}

body MainWindow::updateApplication {version} {
	set progress [BusyDialog::show [mc {Downloading...}] [mc {Downloading SQLiteStudio v%s...} $version] true 100 true determinate]
	wm transient $progress .newVersion
	$progress configure -onclose [list $this cancelUpdate "" "" ""]
	$progress setCloseButtonLabel [mc {Cancel}]

	# Determinating file name to download
	set dir [file dirname [file dirname $::argv0]]
	set tmpFile "$dir/sqlitestudio-$version.new"
	set i 1
	while {[file exists $tmpFile]} {
		set tmpFile "$dir/sqlitestudio-$version.new.$i"
		incr $i
	}

	# Determinating URL
	set platDict [getPlatformForUpdate]
	if {$platDict == ""} return
	set os [dict get $platDict os]
	set ext [dict get $platDict ext]

	if {$::DEBUG(use_update2)} {
		set query "http://sqlitestudio.pl/files/free/unstable/$os/sqlitestudio-$version.$ext"
	} else {
		set query "http://sqlitestudio.pl/files/free/stable/$os/sqlitestudio-$version.$ext"
	}

	# Downloading file
	if {[catch {
		set fd [open $tmpFile w+]
	} err]} {
		BusyDialog::hide
		Warning [mc "Problem with saving new SQLiteStudio version to:\n%s\nDetails:\n%s" $tmpFile $err]
		return
	}
	$progress configure -onclose [list $this cancelUpdate $fd $tmpFile ""]
	fconfigure $fd -translation binary -encoding binary
	if {[catch {
		set token [http::geturl $query -progress [list $this updateProgress $progress] -channel $fd \
			-command [list $this finishUpdate $fd $tmpFile]]
	} err]} {
		BusyDialog::hide
		Warning [mc "Problem with getting new SQLiteStudio version\nDetails:\n%s" $err]
		return
	}
	$progress configure -onclose [list $this cancelUpdate $fd $tmpFile $token]
}

body MainWindow::getPlatformForUpdate {} {
	# Determinating URL
	set os ""
	#set bits [expr {$::tcl_platform(wordSize) * 8}]
	set dets [osDetails]
	set bits [dict get $dets arch]
	set detsOs [dict get $dets os]
	switch -- $detsOs {
		"solaris" {
			set os solaris
			set ext "bin"
		}
		"freebsd" {
			set os freebsd$bits
			set ext "bin"
		}
		"linux" {
			set os linux$bits
			set ext "bin"
		}
		"macosx" {
			set os macosx
			set ext "zip"
		}
		"win32" {
			set os windows
			set ext "exe"
		}
		default {
			Info [mc {This is unknown binary distribution. Cannot determinate binary file to download for update.}]
			BysuDialog::hide
			return ""
		}
	}
	return [dict create os $os ext $ext]
}

body MainWindow::clearTreeFilter {} {
	set _filterValue ""
	fireTreeFilter
}

body MainWindow::updateTreeFilter {} {
	after cancel [list $this fireTreeFilter]
	after 500 [list $this fireTreeFilter]
}

body MainWindow::fireTreeFilter {} {
	DBTREE applyFilter $_filterValue
}

body MainWindow::registerDropTarget {} {
	# Drop DB file on the SQLiteStudio
	tkdnd::drop_target register . DND_Files
	bind . <<Drop>> "$this handleFileDrop %D; return copy"
}

body MainWindow::handleFileDrop {paths} {
	foreach path $paths {
		set db [DBTREE getDBByPath $path]
		if {$db == ""} {
			DBEditDialog .dbdialog -mode new -file $path
		} else {
			DBEditDialog .dbdialog -mode edit -db $db
		}
		.dbdialog exec
		update idletasks
	}
}
