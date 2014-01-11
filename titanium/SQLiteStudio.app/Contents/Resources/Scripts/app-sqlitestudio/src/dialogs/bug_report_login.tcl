use src/common/modal.tcl

class BugReportLoginDialog {
	inherit Modal

	constructor {args} {
		Modal::constructor {*}$args -resizable 0 -allowreturn 1 -expandcontainer 1
	} {}

	protected {
		method getSize {}
	}

	public {
		variable uiVar

		method okClicked {}
		method grabWidget {}
		method validate {}
		method modified {op}
	}
}

body BugReportLoginDialog::constructor {args} {
	ttk::frame $_root.u
	pack $_root.u -side top -fill both -expand 1
	ttk::frame $_root.d
	pack $_root.d -side bottom -fill x -padx 2 -pady 2
	
	set w $_root.u.desc
	ttk::frame $w
	set wrap [expr {[lindex [getSize] 0]-10}]
	ttk::label $w.l -wraplength $wrap -text [mc {Please type username and password to use for reporting bugs and feature requests. If you don't have one, you can set it up at the URL below. Reporting with your own user name will let you track your reports easier. The password will be stored in encrypted format.}]
	pack $w.l -side left -fill x
	pack $w -side top -fill x -padx 2

	set w $_root.u.url
	ttk::frame $w
	ttk::label $w.l -text $::MainWindow::bugReportLink -foreground blue -font TkDefaultFontUnderline -cursor $::CURSOR(link)
	pack $w.l -side top
	pack $w -side top -fill x -pady 5
	bind $w.l <Button-1> [list MAIN openWebBrowser $::MainWindow::bugReportLink]

	set w $_root.u.login
	ttk::labelframe $w -text [mc {Login:}]
	set uiVar(login) $::BugReportDialog::bugTrackerUser
	ttk::entry $w.e -textvariable [scope uiVar(login)] -validatecommand [list $this modified %d] -validate all
	pack $w.e -side top -fill x -padx 2 -pady 2
	pack $w -side top -fill x -padx 2 -pady 5
	bind $w.e <Return> [list $this validate]

	set w $_root.u.pass
	ttk::labelframe $w -text [mc {Password:}]
	set uiVar(pass) $::BugReportDialog::bugTrackerPassword
	ttk::entry $w.e -show "*" -textvariable [scope uiVar(pass)] -validatecommand [list $this modified %d] -validate all
	pack $w.e -side top -fill x -padx 2 -pady 2
	pack $w -side top -fill x -padx 2 -pady 5
	bind $w.e <Return> [list $this validate]
	
	set w $_root.u.validate
	ttk::frame $w
	ttk::button $w.b -text [mc {Validate}] -command [list $this validate]
	pack $w.b -side top
	pack $w -side top -fill both -pady 10

	set w $_root.u.status
	ttk::labelframe $w -text [mc {Validation result}]
	ttk::label $w.l -text [mc {Not validated yet}]
	pack $w.l -side top -expand 1
	pack $w -side top -fill both -pady 5 -expand 1 -padx 2

	set bottom $_root.d
	ttk::button $bottom.ok -text [mc {Ok}] -command "$this clicked ok" -compound left -image img_ok -state disabled
	pack $bottom.ok -side left
	ttk::button $bottom.cancel -text [mc {Cancel}] -command "$this clicked cancel" -compound left -image img_cancel
	pack $bottom.cancel -side right
}

body BugReportLoginDialog::okClicked {} {
	set ::BugReportDialog::bugTrackerUser $uiVar(login)
	set ::BugReportDialog::bugTrackerPassword $uiVar(pass)
	return 1
}

body BugReportLoginDialog::grabWidget {} {
	return $_root.u.login.e
}

body BugReportLoginDialog::getSize {} {
	return [list 440 400]
}

body BugReportLoginDialog::validate {} {
# 	if {[$_root.d.ok cget -state] == "normal"} {
# 		after idle [list $this clicked ok]
# 		return
# 	}

	set query [http::formatQuery validateUser $uiVar(login) password $uiVar(pass)]

	BusyDialog::show [mc {Validating...}] [mc {Validating login and password...}] 0 20 0
	BusyDialog::autoProgress 500

	set tid [thread::create {thread::wait}]

	thread::send $tid [list set ::httpUserAgent $::httpUserAgent]
	thread::send $tid [list set ::MAIN_THREAD $::MAIN_THREAD]
	thread::send $tid [list set ::sqliteStudioBugService $::MainWindow::sqliteStudioBugService]
	thread::send $tid [list set ::query $query]

	thread::send -async $tid {
		package require http 2.7
		http::config -useragent $::httpUserAgent
		if {[catch {
			http::geturl $::sqliteStudioBugService -timeout 10000 -query $::query
		} result]} {
			return [string trim $result]
		} else {
			upvar #0 $result data
			return [string trim $data(body)]
		}
	} ::bugReportLoginDialogResult

	vwait ::bugReportLoginDialogResult
	thread::release $tid

	BusyDialog::hide

	if {$::bugReportLoginDialogResult != "OK"} {
		$_root.u.status.l configure -text [mc {Invalid login or password.}] -foreground #AA0000
		$_root.d.ok configure -state disabled
	} else {
		$_root.u.status.l configure -text [mc {Login and password are correct.}] -foreground #000000
		$_root.d.ok configure -state normal
	}

	# -force, because nothing else seem to work here,
	# but this is pretty okay to use it here.
	focus -force $_root.u.pass.e
}

body BugReportLoginDialog::modified {op} {
	if {$op < 0} {return true}
	$_root.d.ok configure -state disabled
	$_root.u.status.l configure -text [mc {Not validated yet}] -foreground #000000
	return true
}
