use src/common/modal.tcl
use src/common/singleton.tcl

#>
# @class BusyDialog
# Dialog representing that application is busy. It contains some message
# and progressbar that never ends. It can contain also a Cancel button
# but it's optional.<br>
# Currently it's not widely used because threads are required to
# this dialog make sense.
#<
class BusyDialog {
	inherit Modal Singleton

	#>
	# @method constructor
	# @param args Arguments to pass to {@class Modal}.
	#<
	constructor {args} {
		eval Modal::constructor $args -modal 0
	} {}

	opt message
	opt showbutton 0
	opt steps 100
	opt canclose 1
	opt mode "indeterminate"
	opt onclose ""
	opt closelabel ""

	private {
		#>
		# @var progr
		# Progress bar widget.
		#<
		variable progr ""

		#>
		# @var autoProgressTimer
		# Keeps timer id for autoProgress loop.
		#<
		common autoProgressTimer ""
	}

	public {
		#>
		# @method exec
		# @overloaded Modal
		#<
		method exec {}

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
		# @method progress
		# Makes a step on progress bar.
		#<
		method progress {}

		method setProgress {step}
		method setProgressStatic {step}

		#>
		# @method grabWidget
		# @overloaded Modal
		#<
		method grabWidget {}

		method setMessage {msg}
		method setCloseButtonLabel {label}

		#>
		# @method show
		# @param title Dialog title to use.
		# @param msg Message of the dialog.
		# @param btn Should or should not be Cancel button shown (boolean value).
		# @param steps Number of steps to move from left to right.
		# Creates new instance of busy dialog and shows it. It does not check
		# whether it exists or not. You have to check it by yourself with {@method exists}.
		#<
		proc show {title msg {btn 0} {steps 100} {canClose 1} {mode "indeterminate"}}

		#>
		# @method hide
		# Hides and destroys the only busy dialog. If the dialog does not exist, then nothing happens.
		#<
		proc hide {}

		#>
		# @method invoke
		# Makes progress in busy dialog.
		# @return <code>0</code> if everything went ok, <code>-1</code> when dialog does not exist.
		#<
		proc invoke {}

		#>
		# @method exists
		# @return <code>true</code> if busy dialog exists, <code>false</code> otherwise.
		#<
		proc exists {}

		#>
		# @method autoProgress
		# @param milisecs Time in miliseconds.
		# Calls {@method progress} on singleton invoked with {@method show} every miliseconds given in parameter, until {@method hide} is called.
		#<
		proc autoProgress {milisecs}
	}
}

body BusyDialog::constructor {args} {
	ttk::frame $_root.u
	pack $_root.u -side top -fill both
	ttk::label $_root.u.l -text "" -justify left
	pack $_root.u.l -side top -fill x -pady 2 -padx 0.2c

	set progr [ttk::progressbar $_root.prog -orient horizontal -mode indeterminate -length 160]
	pack $progr -side top -fill x -pady 2 -padx 0.2c

	ttk::frame $_root.d
	pack $_root.d -side bottom -fill x

	eval itk_initialize $args
	if {$itk_option(-showbutton)} {
		if {$itk_option(-closelabel) != ""} {
			set title $itk_option(-closelabel)
		} else {
			set title [mc "Close"]
		}
		ttk::button $_root.d.close -text $title -command "$this clicked cancel" -compound left -image img_cancel
		pack $_root.d.close -side bottom -pady 3 -padx 3
	}
	if {!$itk_option(-canclose)} {
		wm protocol [winfo toplevel $_root] WM_DELETE_WINDOW {#}
	}
	$_root.prog configure -maximum $itk_option(-steps) -mode $itk_option(-mode)

	$_root.u.l configure -text $itk_option(-message)
}

body BusyDialog::exec {} {
	update idletasks
	set ret [Modal::exec]
	setGrab [grabWidget]
	return $ret
}

body BusyDialog::okClicked {} {
	return ""
}

body BusyDialog::cancelClicked {} {
	if {$autoProgressTimer != ""} {
		catch {after cancel $autoProgressTimer}
		set autoProgressTimer ""
	}
	if {$itk_option(-onclose) != ""} {
		eval $itk_option(-onclose)
	}
	return ""
}

body BusyDialog::setCloseButtonLabel {label} {
	if {$itk_option(-showbutton)} {
		$_root.d.close configure -text $label
	}
}

body BusyDialog::progress {} {
	$progr step
}

body BusyDialog::setMessage {msg} {
	$_root.u.l configure -text $msg
}

body BusyDialog::show {title msg {btn 0} {steps 100} {canClose 1} {mode "indeterminate"}} {
	if {[winfo exists .busyDialog]} {
		BusyDialog::hide
	}
	set w [BusyDialog .busyDialog -message $msg -title $title -showbutton $btn -steps $steps -canclose $canClose -mode $mode]
	$w exec
	return $w
}

body BusyDialog::hide {} {
	set inst [Singleton::get ::BusyDialog]
	if {$autoProgressTimer != ""} {
		catch {after cancel $autoProgressTimer}
		set autoProgressTimer ""
	}
	if {$inst == ""} {
		return
	}
	$inst clicked ok
}

body BusyDialog::invoke {} {
	set inst [Singleton::get ::BusyDialog]
	if {$inst == ""} {
		return -1
	}
	$inst progress
	update idletasks
	return 0
}

body BusyDialog::setProgress {step} {
	$_root.prog configure -value $step
	update idletasks
}

body BusyDialog::setProgressStatic {step} {
	set inst [Singleton::get ::BusyDialog]
	if {$inst == ""} {
		return -1
	}
	$inst setProgress $step
}

body BusyDialog::exists {} {
	return [Singleton::exists ::BusyDialog]
}

body BusyDialog::autoProgress {milisecs} {
	set autoProgressTimer [after $milisecs [string map [list \$milisecs $milisecs] {
		set inst [Singleton::get ::BusyDialog]
		if {$inst != ""} {
			$inst progress
			BusyDialog::autoProgress $milisecs
		}
	}]]
}

body BusyDialog::grabWidget {} {
	if {$itk_option(-showbutton)} {
		return $_root.d.close
	} else {
		return $_root
	}
}
