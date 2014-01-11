use src/common/modal.tcl

class MsgDialog {
	inherit Modal

	opt message
	opt messageset
	opt type
	opt buttonlabel ""
	opt wrapping false

	constructor {args} {
		Modal::constructor {*}$args -resizable 1
	} {}

	private {
		variable msgCounter 0
	}
	
	protected {
		method addMsg {txt type}
	}
	
	public {
		method okClicked {}
		method grabWidget {}
		proc show {title message {type info}}
		proc showMulti {title messageList {type info}}
	}
}

body MsgDialog::constructor {args} {
	ttk::frame $_root.u
	pack $_root.u -side top -fill both -expand 1

	pack [ttk::frame $_root.u.l] -side left -fill both -padx 5 -pady 5
	ttk::label $_root.u.l.icon
	pack $_root.u.l.icon -side top

	ttk::frame $_root.u.messages
	pack $_root.u.messages -side right -fill both -pady 0.1c -padx 0.2c -expand 1

	ttk::frame $_root.d
	pack $_root.d -side bottom -fill x
	ttk::frame $_root.d.f
	pack $_root.d.f -side bottom

	ttk::button $_root.d.f.ok -text [mc {Ok}] -command "$this clicked ok" -compound left -image img_ok
	pack $_root.d.f.ok -side left -pady 3

	eval itk_initialize $args

	if {$itk_option(-buttonlabel) != ""} {
		$_root.d.f.ok configure -text $itk_option(-buttonlabel)
	}
	if {$itk_option(-message) != ""} {
		addMsg $itk_option(-message) txt
	} elseif {$itk_option(-messageset) != ""} {
		set totalMsgs [llength $itk_option(-messageset)]
		foreach it $itk_option(-messageset) {
			addMsg {*}$it
		}
	}

	switch -- $itk_option(-type) {
		"error" {
			set icon img_dialog_error
		}
		"warning" {
			set icon img_dialog_warning
		}
		"info" {
			set icon img_dialog_info
		}
		default {
			set icon ""
		}
	}
	$_root.u.l.icon configure -image $icon
}

body MsgDialog::show {title message {type info}} {
	set msg [MsgDialog .#auto -type info -message $message -type $type -wrapping true]
	$msg exec
}

body MsgDialog::showMulti {title messageList {type info}} {
	set msg [MsgDialog .#auto -type info -messageset $messageList -type $type -wrapping true]
	$msg exec
}

body MsgDialog::addMsg {msg type} {
	set w $_root.u.messages.txt$msgCounter
	switch -- $type {
		"txt" {
			ttk::frame $w
			ttk::label $w.e -text $msg
			if {$itk_option(-wrapping)} {
				autoWrap $w.e [join $itk_option(-messageset) \n]
			}
			pack $w.e -side left -fill x
			pack $w -side top -fill x -expand 1 -pady 2
		}
		"link" {
			ttk::label $w -text $msg -foreground blue -font TkDefaultFontUnderline -cursor $::CURSOR(link)
			bind $w <Button-1> [list MAIN openWebBrowser $msg]
			pack $w -side top -fill x -expand 1 -pady 2
		}
		default {
			error "Invalid msg type: $type"
		}
	}
	incr msgCounter
}

body MsgDialog::okClicked {} {
	return ""
}

body MsgDialog::grabWidget {} {
	return $_root.d.f.ok
}
