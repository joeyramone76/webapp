use src/common/modal.tcl

class BugReportDialog {
	inherit Modal

	opt description ""
	opt brief ""
	opt focushowto 0
	opt featurerequest 0

	common bugTrackerUser ""
	common bugTrackerPassword ""
	
	constructor {args} {
		Modal::constructor {*}$args -resizable 1 -expandcontainer 1 -allowreturn 1
	} {}

	private {
		variable _email ""
		variable _detailPackCmds [list]
		variable _detailUnpackCmds [list]
		variable _detailWidgets [list]
		variable _detailPady 0
		
		method useEmail {}
	}

	public {
		method okClicked {}
		method grabWidget {}
		method privacy {}
		method switchDetails {}
		method logIn {}
		method logOut {}
		method display {emailOrUser}

		variable takeShots 0
	}
}

body BugReportDialog::constructor {args} {
	ttk::frame $_root.u
	pack $_root.u -side top -fill both -expand 1
	ttk::frame $_root.d
	pack $_root.d -side bottom -fill x

	# E-mail
	set w $_root.u.email
	ttk::labelframe $w -text [mc {Your e-mail address or user (both optional)}]
	ttk::entry $w.e
	ttk::button $w.privacy -image img_info -command [list $this privacy] -takefocus 0 -style Toolbutton
	ttk::label $w.or -text [mc {or}]
	ttk::button $w.login -text [mc {Log in}] -command [list $this logIn]
	pack $w.privacy -side left -pady 2 -padx 2
	pack $w.e -side left -fill x -padx 1 -expand 1
	pack $w.login -side right -padx 2 -pady 2
	pack $w.or -side right -padx 5

	# BugTracker user
	set w $_root.u.user
	ttk::labelframe $w -text [mc {Logged in}]
	ttk::label $w.l -text $bugTrackerUser
	ttk::button $w.logout -text [mc {Log out}] -command [list $this logOut]
	pack $w.logout -side right -padx 2 -pady 2
	pack $w.l -side left -pady 3 -padx 10

	# Brief
	set w $_root.u.brief
	ttk::frame $w
	ttk::frame $w.u
	ttk::label $w.u.l -text [mc {Brief description:}]
	ttk::entry $w.e
	pack $w.u -side top -fill x
	pack $w.u.l -side left
	pack $w.e -side top -fill x -padx 1
	pack $w -side top -fill x

	# Mode
	if {[useEmail]} {
		display "email"
	} else {
		display "user"
	}

	# How to invoke
	set w $_root.u.howto
	ttk::frame $w
	ttk::frame $w.u
	ttk::label $w.u.l -text [mc {How to reproduce problem (if possible):}]
	ttk::frame $w.txt
	text $w.txt.t -height 6 -width 60 -highlightthickness 0 -borderwidth 1 -relief solid -yscrollcommand "$w.txt.s set" \
			-background ${::SQLEditor::background_color} -foreground ${::SQLEditor::foreground_color} \
			-selectbackground ${::SQLEditor::selected_background} -selectforeground ${::SQLEditor::selected_foreground} \
			-insertontime 500 -insertofftime 500 -selectborderwidth 0 -wrap word
	ttk::scrollbar $w.txt.s -command "$w.txt.t yview" -orient vertical
	autoscroll $w.txt.s
	pack $w.u.l -side left
	pack $w.u -side top -fill x
	pack $w.txt.t -side left -fill both -expand 1
	pack $w.txt.s -side right -fill y
	pack $w.txt -side top -fill both -expand 1 -padx 1
	pack $w -side top -fill both -expand 1 -pady 8

	bind $w.txt.t <Tab> "focus $_root.u.desc.txt.t; break"

	# Detailed description
	set w $_root.u.desc
	ttk::frame $w
	ttk::frame $w.u
	ttk::label $w.u.l -text [mc {What is the problem:}]
	ttk::frame $w.txt
	text $w.txt.t -height 6 -width 60 -highlightthickness 0 -borderwidth 1 -relief solid -yscrollcommand "$w.txt.s set" \
			-background ${::SQLEditor::background_color} -foreground ${::SQLEditor::foreground_color} \
			-selectbackground ${::SQLEditor::selected_background} -selectforeground ${::SQLEditor::selected_foreground} \
			-insertontime 500 -insertofftime 500 -selectborderwidth 0 -wrap word
	ttk::scrollbar $w.txt.s -command "$w.txt.t yview" -orient vertical
	autoscroll $w.txt.s
	pack $w.u.l -side left
	pack $w.u -side top -fill x
	pack $w.txt.t -side left -fill both -expand 1
	pack $w.txt.s -side right -fill y
	pack $w.txt -side top -fill both -expand 1 -padx 1
	pack $w -side top -fill both -expand 1

	bind $w.txt.t <Tab> "focus $_root.u.pkgs.e; break"

	# Show more / hide
	#
	# Disabled for now:
	# Showing packages and OS to bug reporter is not really important and it obscures the dialog layout.
	# It should be as simple as possible to not scare the reporter.
	#
# 	set w $_root.u.showMore
# 	ttk::frame $w
# 	ttk::button $w.btn -text [mc {Show more (optional)}] -image img_arrow_down -compound right -command [list $this switchDetails]
# 	pack $w.btn -side top
# 	pack $w -side top -fill x -pady 2
	
	# Packages
	set w $_root.u.pkgs
	ttk::frame $w
	ttk::frame $w.u
	ttk::label $w.u.l -text [mc {Used Tcl packages:}]
	ttk::frame $w.txt
	text $w.txt.t -height 3 -width 60 -highlightthickness 0 -borderwidth 1 -relief solid -yscrollcommand "$w.txt.s set" \
			-background ${::SQLEditor::background_color} -foreground ${::SQLEditor::foreground_color} \
			-selectbackground ${::SQLEditor::selected_background} -selectforeground ${::SQLEditor::selected_foreground} \
			-insertontime 500 -insertofftime 500 -selectborderwidth 0 -wrap word
	ttk::scrollbar $w.txt.s -command "$w.txt.t yview" -orient vertical
	autoscroll $w.txt.s
	pack $w.u.l -side left
	pack $w.u -side top -fill x
	pack $w.txt.t -side left -fill both -expand 1
	pack $w.txt.s -side right -fill y
	pack $w.txt -side top -fill both -expand 1 -padx 1
	lappend _detailPackCmds [list pack $w -side top -fill both -expand 1]
	lappend _detailUnpackCmds [list pack forget $w]
	lappend _detailWidgets $w

	bind $w.txt.t <Tab> "focus $_root.u.os.e; break"

	# OS
	set w $_root.u.os
	ttk::frame $w
	ttk::frame $w.u
	ttk::label $w.u.l -text [mc {Operating system:}]
	ttk::entry $w.e
	pack $w.u -side top -fill x
	pack $w.u.l -side left
	pack $w.e -side top -fill x -padx 1
	lappend _detailPackCmds [list pack $w -side top -fill x -pady 8]
	lappend _detailUnpackCmds [list pack forget $w]
	lappend _detailWidgets $w
	incr _detailPady 8

	$w.e insert end "$::tcl_platform(os) ($::tcl_platform(osVersion)), $::tcl_platform(machine)"

	# Take screenshots
# 	set w $_root.u.shots
# 	ttk::frame $w
# 	ttk::checkbutton $w.c -text [mc {Take screenshots of all SQLiteStudio windows and attach them}] -variable [scope takeShots]
# 	pack $w.c -side left
# 	pack $w -side top -fill x -pady 8 -padx 1

	# Bottom buttons
	ttk::button $_root.d.ok -text [mc "Send"] -command "$this clicked ok" -compound left -image img_ok
	pack $_root.d.ok -side left -pady 3 -padx 3
	ttk::button $_root.d.cancel -text [mc "Cancel"] -command "$this clicked cancel" -compound left -image img_cancel
	pack $_root.d.cancel -side right -pady 3 -padx 3

	itk_initialize {*}$args
# 	$_root.u.l configure -text $itk_option(-message)
#
	$_root.u.brief.e insert end $itk_option(-brief)
	$_root.u.desc.txt.t insert end $itk_option(-description)

	set pkgsDict [MAIN getInstalledPackages]
	foreach key [lsort -dictionary [dict keys $pkgsDict]] {
		set value [dict get $pkgsDict $key]
		$_root.u.pkgs.txt.t insert end "[pad 30 {.} $key] $value\n"
	}
	$_root.u.pkgs.txt.t configure -state disabled

	set _email [CfgWin::get BugReport email]

	if {[useEmail]} {
		if {$_email != ""} {
			$_root.u.email.e insert end $_email
			if {$itk_option(-focushowto)} {
				focus $_root.u.howto.txt.t
			}
		} else {
			focus $_root.u.email.e
		}
	} else {
		focus $_root.u.brief
	}
	if {$itk_option(-featurerequest)} {
		pack forget $_root.u.showMore
		catch {pack forget $_root.u.howto}
		catch {pack forget $_root.u.os}
		catch {pack forget $_root.u.pkgs}
		$_root.u.desc.u.l configure -text [mc {Describe your feature request:}]
	}
}

body BugReportDialog::switchDetails {} {
	set w $_root.u.showMore
	set t [winfo toplevel $w]
	set hg 0
	lassign [split [lindex [split [wm geometry [winfo toplevel $_root]] +] 0] x] currW currH
	if {[$w.btn cget -image] == "img_arrow_down"} {
		$w.btn configure -text [mc {Hide}] -image img_arrow_up
		foreach cmd $_detailPackCmds detW $_detailWidgets {
			incr hg [winfo reqheight $detW]
			eval $cmd
		}
		incr currH $hg
		incr currH [expr {$_detailPady * 2}]
	} else {
		$w.btn configure -text [mc {Show more (optional)}] -image img_arrow_down
		foreach cmd $_detailUnpackCmds detW $_detailWidgets {
			incr hg [winfo reqheight $detW]
			eval $cmd
		}
		incr currH -$hg
		incr currH [expr {-$_detailPady * 2}]
	}
	wm geometry [winfo toplevel $_root] ${currW}x${currH}
}

body BugReportDialog::useEmail {} {
	expr {$bugTrackerUser == "" || $bugTrackerPassword == ""}
}

body BugReportDialog::okClicked {} {
	set closeWhenOkClicked 0
	set brief [$_root.u.brief.e get]
	set howto [$_root.u.howto.txt.t get 1.0 end]
	set desc [$_root.u.desc.txt.t get 1.0 end]
	set pkgs [$_root.u.pkgs.txt.t get 1.0 end]
	set os [$_root.u.os.e get]
	if {[useEmail]} {
		set _email [$_root.u.email.e get]
	}
	if {$itk_option(-featurerequest)} {
		set os ""
	}

	if {[string trim $brief] == ""} {
		Warning [mc {Please fill 'Brief' field.}]
		return
	}

	if {[string trim $howto] == "" && [string trim $desc] == ""} {
		Warning [mc {Please fill at least one of 'Description' or 'How to reproduce' fields.}]
		return
	}

	if {[string trim $_email] != "" && ![isEmail $_email]} {
		Warning [mc {Please provide valid e-mail address or leave 'E-mail' empty.}]
		return
	}

	set closeWhenOkClicked 1

	set contents ""
	if {[string trim $howto] != ""} {
		append contents "HOW TO REPRODUCE:\n$howto"
	}
	if {[string trim $desc] != ""} {
		append contents "\n\nDESCRIPTION:\n$desc"
	}
	if {[string trim $os] != ""} {
		append contents "\n\nOPERATING SYSTEM:\n$os"
	}
	append contents "\n\nAPPLICATION VERSION:\n$::version"
	if {[string trim $pkgs] != ""} {
		append contents "\n\nTCL PACKAGES:\n$pkgs"
	}

	CfgWin::store BugReport email $_email

	if {[useEmail]} {
		MAIN reportBugViaServiceWithEmail $brief $contents $os $::version $_email $itk_option(-featurerequest)
	} else {
		MAIN reportBugViaServiceWithUser $brief $contents $os $::version $bugTrackerUser $bugTrackerPassword $itk_option(-featurerequest)
	}
}

body BugReportDialog::grabWidget {} {
	return $_root.u.brief.e
}

body BugReportDialog::privacy {} {
	set msg [MsgDialog .#auto -type info -message \
		[mc "This e-mail will NOT be shared to anyone, neither used for any other\npurpose then described below. It won't be published anywhere.\nIt will be used only by SQLiteStudio developer to eventually contact\nyou if any additional details for this report are necessary.\n\nIt is optional. You can leave it empty."]]
	$msg exec
}

body BugReportDialog::logIn {} {
	set t [winfo toplevel $_root]
	wm withdraw $t

	set logInDialog [BugReportLoginDialog .#auto -title [mc {Log in}]]
	set res [$logInDialog exec]

	wm deiconify $t

	if {$res == 1} {
		display "user"
		CfgWin::save [list ::BugReportDialog::bugTrackerUser $::BugReportDialog::bugTrackerUser \
			::BugReportDialog::bugTrackerPassword $::BugReportDialog::bugTrackerPassword]
	}
	focus [grabWidget]
}

body BugReportDialog::logOut {} {
	set bugTrackerUser ""
	set bugTrackerPassword ""
	display "email"
	focus [grabWidget]
}

body BugReportDialog::display {emailOrUser} {
	if {$emailOrUser == "email"} {
		catch {pack forget $_root.u.user}
		pack $_root.u.email -side top -fill x -padx 2 -pady 3 -before $_root.u.brief
	} else {
		catch {pack forget $_root.u.email}
		$_root.u.user.l configure -text $bugTrackerUser
		pack $_root.u.user -side top -fill x -padx 2 -pady 3 -before $_root.u.brief
	}
}
