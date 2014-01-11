use src/common/modal.tcl

#>
# @class BlobEdit
# Modal dialog with {@class BlobEditPanel} in it.
#<
class BlobEdit {
	inherit Modal

	opt message
	opt readonly 0
	opt value ""

	#>
	# @method constructor
	# @param args Options to pass to {@class Modal}.
	#<
	constructor {args} {
		eval Modal::constructor $args -modal 1
	} {}

	private {
		#>
		# @var edit
		# Contains {@class BlobEditPanel} object.
		#<
		variable edit ""
	}

	public {
		variable nullValue 0

		#>
		# @method okClicked
		# @overloaded Modal
		#<
		method okClicked {}

		#>
		# @method cancelClicked
		# @overloaded Modal
		#<
		method cancelClicked {}

		#>
		# @method grabWidget
		# @overloaded Modal
		#<
		method grabWidget {}

		#>
		# @method returnPushed
		# Called when Return key was pressed on the dialog. Makes dialog to act like Ok button was pressed.
		#<
		method returnPushed {}

		#>
		# @method destroyed
		# @overloaded Modal
		#<
		method destroyed {}

		method updateNullState {}
		method switchNull {}
	}
}

body BlobEdit::constructor {args} {
	# Main frames
	ttk::frame $_root.u
	pack $_root.u -side top -fill both
	#ttk::label $_root.u.l -text "" -justify left
	#pack $_root.u.l -side top -fill x -pady 2 -padx 0.2c
	ttk::frame $_root.u.f
	pack $_root.u.f -side top -fill both -expand 1 -padx 2

	set nullValue 0
	ttk::frame $_root.u.f.nullframe
	pack $_root.u.f.nullframe -side top -fill x -pady 2
	ttk::checkbutton $_root.u.f.nullframe.cb -text [mc {NULL value}] -variable [scope nullValue] \
		-command "$this updateNullState"
	pack $_root.u.f.nullframe.cb -side left
	helpHint $_root.u.f.nullframe.cb [mc {You can use '%s' keyboard shortcut to switch NULL value.} ${::Shortcuts::setNullInForm}]

	# Edit panel
	set opts [list]
	foreach {opt val} $args {
		switch -- $opt {
			"-readonly" {
				lappend opts $opt $val
			}
			"-value" {
				lappend opts $opt [lindex $val 0]
				set nullValue [lindex $val 1]
			}
		}
	}

	set edit [eval BlobEditPanel $_root.u.f.edit $opts]
	pack $edit -side top -fill both -expand 1 -side top

	# Bottom
	ttk::frame $_root.d
	pack $_root.d -side bottom -fill x
	ttk::frame $_root.d.f
	pack $_root.d.f -side bottom

	bind $path <Return> ""
	bind $path <Control-Return> "$this returnPushed"
	bind $path <Shift-Return> "$this returnPushed"
	bind $path <${::Shortcuts::setNullInForm}> "$this switchNull; break"

	# Rest
	eval itk_initialize $args

	if {!$itk_option(-readonly)} {
		ttk::button $_root.d.f.ok -text [mc "Commit"] -command "$this clicked ok" -compound left -image img_ok
		pack $_root.d.f.ok -side left -pady 3
		set btntxt [mc "Cancel"]
	} else {
		set btntxt [mc "Close"]
	}
	ttk::button $_root.d.f.cancel -text $btntxt -command "$this clicked cancel" -compound left -image img_cancel
	pack $_root.d.f.cancel -side left -pady 3 -padx 5

	#$_root.u.l configure -text $itk_option(-message)
	updateNullState
}

body BlobEdit::updateNullState {} {
	$edit setDisabled $nullValue
}

body BlobEdit::switchNull {} {
	set nullValue [expr {!$nullValue}]
	updateNullState
}

body BlobEdit::returnPushed {} {
	$edit clear
	$this clicked ok
}

body BlobEdit::okClicked {} {
	if {$nullValue} {
		return [list 0 [list "" 1]]
	} else {
		return [list 0 [list [$edit get] 0]]
	}
}

body BlobEdit::grabWidget {} {
	return $edit
}

body BlobEdit::cancelClicked {} {
	return [list -1 ""]
}

body BlobEdit::destroyed {} {
	return [list -1 ""]
}
