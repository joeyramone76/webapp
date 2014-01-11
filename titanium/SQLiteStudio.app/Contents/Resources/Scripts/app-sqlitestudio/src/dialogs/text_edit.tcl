use src/common/modal.tcl

class TextEdit {
	inherit Modal

	opt message
	opt value
	opt readonly 0

	constructor {args} {
		eval Modal::constructor $args -modal 1
	} {}

	private {
		variable edit ""
	}

	public {
		method okClicked {}
		method cancelClicked {}
		method grabWidget {}
		method returnPushed {}
	}
}

body TextEdit::constructor {args} {
	ttk::frame $_root.u
	pack $_root.u -side top -fill both
	ttk::label $_root.u.l -text "" -justify left
	pack $_root.u.l -side top -fill x -pady 2 -padx 0.2c
	ttk::frame $_root.u.f
	set edit [text $_root.u.f.e -height 16 -width 60 -background white -borderwidth 1 -insertborderwidth 1 -selectbackground #DDDDEE \
		-selectforeground #442222 -insertontime 500 -insertofftime 500 -yscrollcommand "$_root.u.f.s set" -selectborderwidth 0]
	pack $edit -fill both -expand 1 -side left
	ttk::scrollbar $_root.u.f.s -orient vertical -command "$edit yview"
	autoscroll::autoscroll $_root.u.f.s
	pack $_root.u.f.s -side right -fill y
	pack $_root.u.f -side top -fill both -expand 1
	ttk::frame $_root.d
	pack $_root.d -side bottom -fill x
	ttk::frame $_root.d.f
	pack $_root.d.f -side bottom

	eval itk_initialize $args

	if {!$itk_option(-readonly)} {
		ttk::button $_root.d.f.ok -text [mc "Ok"] -command "$this clicked ok" -compound left -image img_ok
		pack $_root.d.f.ok -side left -pady 3
		set btntxt [mc "Cancel"]
	} else {
		set btntxt [mc "Close"]
	}
	ttk::button $_root.d.f.cancel -text $btntxt -command "$this clicked cancel" -compound left -image img_cancel
	pack $_root.d.f.cancel -side left -pady 3

	bind $_root <Return> ""
	bind $_root <Control-Return> "$this returnPushed"
	bind $_root <Shift-Return> "$this returnPushed"

	$_root.u.l configure -text $itk_option(-message)
	$edit insert end $itk_option(-value)

	if {$itk_option(-readonly)} {
		$edit configure -state disabled
	}
}

body TextEdit::returnPushed {} {
	set str [$edit get 1.0 end]
	$edit delete 1.0 end
	$edit insert end [string range $str 0 end-2]
	$this clicked ok
}

body TextEdit::okClicked {} {
	return [$edit get 1.0 "end -1 chars"]
}

body TextEdit::grabWidget {} {
	return $edit
}

body TextEdit::cancelClicked {} {
	error "CANCEL"
}
