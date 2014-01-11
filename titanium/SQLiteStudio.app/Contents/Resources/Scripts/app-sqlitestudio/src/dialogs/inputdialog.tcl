use src/common/modal.tcl

class InputDialog {
	inherit Modal

	constructor {args} {
		Modal::constructor {*}$args
	} {}

	public {
		method okClicked {}
		method grabWidget {}
	}
}

body InputDialog::constructor {args} {
	set message ""
	set default 0

	parseArgs {
		-message {set message $value}
		-default {set default $value}
	}

	ttk::frame $_root.u
	pack $_root.u -side top -fill both
	ttk::label $_root.u.l -text "" -justify left
	pack $_root.u.l -side top -fill x -pady 2 -padx 0.2c
	ttk::entry $_root.u.e
	pack $_root.u.e -side top -fill x -pady 0.1c -padx 0.2c
	ttk::frame $_root.d
	pack $_root.d -side bottom -fill x
	ttk::frame $_root.d.f
	pack $_root.d.f -side bottom

	ttk::button $_root.d.f.ok -text [mc "Ok"] -command "$this clicked ok" -compound left -image img_ok
	pack $_root.d.f.ok -side left -pady 3
	ttk::button $_root.d.f.cancel -text [mc "Cancel"] -command "$this clicked cancel" -compound left -image img_cancel
	pack $_root.d.f.cancel -side left -pady 3

	$_root.u.l configure -text $message

	$_root.u.e insert end $default
	$_root.u.e selection range 0 end
}

body InputDialog::okClicked {} {
	return [$_root.u.e get]
}

body InputDialog::grabWidget {} {
	return $_root.u.e
}
