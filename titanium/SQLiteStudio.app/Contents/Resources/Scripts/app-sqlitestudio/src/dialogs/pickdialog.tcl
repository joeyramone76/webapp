use src/common/modal.tcl

class PickDialog {
	inherit Modal

	constructor {args} {
		Modal::constructor {*}$args
	} {}

	public {
		method okClicked {}
		method grabWidget {}
	}
}

body PickDialog::constructor {args} {
	set message ""
	set default ""
	set index -1
	set values [list]
	set readonly true
	set cancelbutton true

	parseArgs {
		-message {set message $value}
		-default {set default $value}
		-values {set values $value}
		-index {set index $value}
		-readonly {set readonly $value}
		-cancelbutton {set cancelbutton $value}
	}

	ttk::frame $_root.u
	pack $_root.u -side top -fill both
	ttk::label $_root.u.l -text "" -justify left
	pack $_root.u.l -side top -fill x -pady 2 -padx 0.2c
	ttk::combobox $_root.u.e
	pack $_root.u.e -side top -fill x -pady 0.1c -padx 0.2c
	ttk::frame $_root.d
	pack $_root.d -side bottom -fill x
	ttk::frame $_root.d.f
	pack $_root.d.f -side bottom

	ttk::button $_root.d.f.ok -text [mc "Ok"] -command "$this clicked ok" -compound left -image img_ok
	pack $_root.d.f.ok -side left -pady 3
	if {$cancelbutton} {
		ttk::button $_root.d.f.cancel -text [mc "Cancel"] -command "$this clicked cancel" -compound left -image img_cancel
		pack $_root.d.f.cancel -side left -pady 3
	}

	$_root.u.l configure -text $message
	$_root.u.e configure -values $values
	if {$readonly} {
		$_root.u.e configure -state readonly
	}
	if {$index >= 0} {
		$_root.u.e set [lindex $values $index]
	} else {
		$_root.u.e set $default
	}
}

body PickDialog::okClicked {} {
	return [$_root.u.e get]
}

body PickDialog::grabWidget {} {
	return $_root.u.e
}
