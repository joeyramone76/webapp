use src/common/modal.tcl

class YesNoDialog {
	inherit Modal

	constructor {args} {
		eval Modal::constructor $args
	} {}

	private {
		variable _msg ""
		variable _type "NONE"
		variable _firstMsg ""
		variable _firstIcon "img_ok"
		variable _secondMsg ""
		variable _secondIcon "img_cancel"
		variable _thirdMsg ""
		variable _thirdIcon ""
		variable _fourthMsg ""
		variable _fourthIcon ""
		variable _msgFrame ""
		variable _wrapping "false"
		variable _wrapRatio ""
	}

	public {
		method clicked {bt}
		method okClicked {}
		method grabWidget {}
		method destroyed {}
		proc ask {msg}
		proc warning {msg}
		proc err {msg}
		proc information {msg}
	}
}

body YesNoDialog::constructor {args} {
	set _firstMsg [mc "Yes"]
	set _secondMsg [mc "No"]
	set default ""
	parseArgs {
		"-message" {set _msg $value}
		"-first" {set _firstMsg $value}
		"-second" {set _secondMsg $value}
		"-firsticon" {set _firstIcon $value}
		"-secondicon" {set _secondIcon $value}
		"-third" {set _thirdMsg $value}
		"-fourth" {set _fourthMsg $value}
		"-thirdicon" {set _thirdIcon $value}
		"-fourthicon" {set _fourthIcon $value}
		"-type" {set _type $value}
		"-wrapping" {set _wrapping $value}
		"-wrapratio" {set _wrapRatio $value}
	}

	ttk::frame $_root.u
	pack $_root.u -side top -fill both
	# Checking if dialog is the one with icon on the left or not.
	switch -- $_type {
		"error" {
			set mainIcon img_dialog_error
		}
		"warning" {
			set mainIcon img_dialog_warning
		}
		"info" {
			set mainIcon img_dialog_info
		}
		default {
			# No, it's dialog without the icon. Simple label.
			set _msgFrame [ttk::label $_root.u.l -text "" -justify left]
			pack $_root.u.l -side top -fill x -pady 2 -padx 0.2c
		}
	}
	# If it's with icon, then we need to create it
	if {$_type in [list error warning info]} {
		ttk::frame $_root.u.f
		pack $_root.u.f -side top -fill x -pady 2 -padx 0.2c
		ttk::label $_root.u.f.ico -image $mainIcon
		pack $_root.u.f.ico -side left -padx 0.2c
		set _msgFrame [ttk::label $_root.u.f.txt -text "" -justify left]
		pack $_msgFrame -side left -fill x -padx 0.1c
	}

	# Buttons on bottom.
	ttk::frame $_root.d
	pack $_root.d -side bottom -fill x
	ttk::frame $_root.d.f
	pack $_root.d.f -side bottom

	ttk::button $_root.d.f.yes -text $_firstMsg -command "$this clicked yes" -compound left -image $_firstIcon
	pack $_root.d.f.yes -side left -pady 3 -padx 3
	if {$_thirdMsg != ""} {
		ttk::button $_root.d.f.third -text $_thirdMsg -command "$this clicked third" -compound left -image $_thirdIcon
		pack $_root.d.f.third -side left -pady 3 -padx 3
	}
	ttk::button $_root.d.f.no -text $_secondMsg -command "$this clicked no" -compound left -image $_secondIcon
	pack $_root.d.f.no -side left -pady 3 -padx 3
	if {$_fourthMsg != ""} {
		ttk::button $_root.d.f.fourth -text $_fourthMsg -command "$this clicked fourth" -compound left -image $_fourthIcon
		pack $_root.d.f.fourth -side left -pady 3 -padx 3
	}

	$_msgFrame configure -text $_msg

	if {$_wrapping} {
		if {$_wrapRatio != ""} {
			autoWrap $_msgFrame $_msg $_wrapRatio
		} else {
			autoWrap $_msgFrame $_msg
		}
	}
}

body YesNoDialog::grabWidget {} {
	return $_root.d.f.yes
}

body YesNoDialog::okClicked {} {
}

body YesNoDialog::clicked {bt} {
	switch -- $bt {
		"yes" - "ok" {
			set retval 1
		}
		"no" - "cancel" {
			set retval 0
		}
		"third" {
			set retval 2
		}
		"fourth" {
			set retval -1
		}
	}
	destroy $path
}

body YesNoDialog::destroyed {} {
	return 0
}

body YesNoDialog::ask {msg} {
	set obj [local YesNoDialog .#auto -message $msg -wrapping true -title [mc {Question}]]
	return [$obj exec]
}

body YesNoDialog::warning {msg} {
	set obj [local YesNoDialog .#auto -message $msg -type warning -wrapping true -title [mc {Warning}]]
	return [$obj exec]
}

body YesNoDialog::err {msg} {
	set obj [local YesNoDialog .#auto -message $msg -type error -wrapping true -title [mc {Error}]]
	return [$obj exec]
}

body YesNoDialog::information {msg} {
	set obj [local YesNoDialog .#auto -message $msg -type info -wrapping true -title [mc {Information}]]
	return [$obj exec]
}
