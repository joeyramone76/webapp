use src/common/modal.tcl

class NewVersionDialog {
	inherit Modal

	opt url
	opt version

	common checkAtStartup 1

	constructor {args} {
		eval Modal::constructor $args
	} {}

	public {
		method okClicked {}
		method grabWidget {}
	}
}

body NewVersionDialog::constructor {args} {
	ttk::frame $_root.u
	pack $_root.u -side top -fill both

	ttk::label $_root.u.l -text "" -justify left -font TkDefaultFontBold
	pack $_root.u.l -side top -fill x -pady 10 -padx 0.2c

	ttk::labelframe $_root.u.f -text [mc {What would you like to do?}]
	ttk::button $_root.u.f.link1 -text [mc {Install it automatically}] -image img_execute_from_file -compound left
	ttk::label $_root.u.f.linkSeparator -justify center -text [mc {or}]
	ttk::button $_root.u.f.link2 -text [mc {Go to download page}] -image img_goto_web -compound left
	if {($::DISTRIBUTION != "binary" && !$::IS_BOUNDLE)} {
		# Sources distribution
		$_root.u.f configure -text [mc {Package download}]
		pack $_root.u.f -side top -fill x -pady 10 -padx 20
		pack $_root.u.f.link2 -side top -pady 0.1c -padx 0.2c
	} elseif {[Privileges::doNeedRootForUpdate]} {
		# Binary but without permissions
		$_root.u.f.link1 configure -state disabled
		helpHint $_root.u.f.link1 [mc {Insufficient privileges to perform automatic update.}]
		pack $_root.u.f -side top -fill x -pady 10 -padx 20
		pack $_root.u.f.link1 -side top -pady 0.1c -padx 0.2c
		pack $_root.u.f.linkSeparator -side top -pady 0.1c -padx 0.2c
		pack $_root.u.f.link2 -side top -pady 0.1c -padx 0.2c
	} else {
		# Binary with permissions
		pack $_root.u.f -side top -fill x -pady 10 -padx 20
		pack $_root.u.f.link1 -side top -pady 0.1c -padx 0.2c
		pack $_root.u.f.linkSeparator -side top -pady 0.1c -padx 0.2c
		pack $_root.u.f.link2 -side top -pady 0.1c -padx 0.2c
	}

	ttk::checkbutton $_root.u.enableChecking -text [mc {Check for updates at startup}] \
		-variable NewVersionDialog::checkAtStartup
	pack $_root.u.enableChecking -side top -pady 0.2c -padx 0.2c

	ttk::frame $_root.d
	pack $_root.d -side bottom -fill x
	ttk::frame $_root.d.f
	pack $_root.d.f -side bottom

	ttk::button $_root.d.f.ok -text [mc {Close}] -command "$this clicked ok" -compound left -image img_ok
	pack $_root.d.f.ok -side left -pady 3

	eval itk_initialize $args
	$_root.u.f.link1 configure -command [list MAIN updateApplication $itk_option(-version)]
	$_root.u.f.link2 configure -command [list MAIN openWebBrowser $itk_option(-url)]

	$_root.u.l configure -text [mc {New version of SQLiteStudio is available: %s} $itk_option(-version)]
}

body NewVersionDialog::okClicked {} {
}

body NewVersionDialog::grabWidget {} {
	return $_root.d.f.ok
}
