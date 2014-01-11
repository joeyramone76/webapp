use src/common/common.tcl
use src/common/window.tcl

class Modal {
	inherit Window

	constructor {args} {}
	destructor {}

	protected {
		variable wd_algo "reqwidth"
		variable hg_algo "reqheight"
		variable _expandContainer 0
		variable grabbed ""
		variable retval ""
		variable _root ""
		variable modal 1
		variable _parent "."
		variable _resizable 0
		variable _allowReturn 0
		variable _skipMacBottomFrame 0
		variable title ""
		variable closeWhenOkClicked 1
		variable _initScript ""

		method center {}
		method destroyed {}
		method cancelClicked {}
		method preventClosing {}
		method allowClosing {}
		#>
		# @method getSize
		# Results of this method are used to center window.
		# @return List of two elements: width and height of the window.
		#<
		method getSize {}
		abstract method okClicked {}
		abstract method grabWidget {}
	}

	public {
		method exec {}
		method setGrab {widget}
		method releaseGrab {widget}
		method clicked {btn}
		method windowDestroyed {}
		method setTitle {title}
		method refreshGrab {}
	}
}

body Modal::constructor {args} {
	wm protocol $path WM_DELETE_WINDOW "#"
	parseArgs {
		-modal {set modal $value}
		-command {set command $value}
		-title {set title $value}
		-parent {set _parent $value}
		-resizable {set _resizable $value}
		-expandcontainer {set _expandContainer $value}
		-allowreturn {set _allowReturn $value}
		-skipmacbottomframe {set _skipMacBottomFrame $value}
	}

	set _root [ttk::frame $path.f]

	pack $_root -side top -fill both -expand $_expandContainer

	if {[tk windowingsystem] == "aqua" && !$_skipMacBottomFrame} {
		ttk::frame $path.mac_bottom
		ttk::label $path.mac_bottom.l -text " "
		pack $path.mac_bottom.l -side top
		pack $path.mac_bottom -side bottom -fill x
	}

	setTitle $title
	wm withdraw $path
	if {[os] != "win32"} {
		# Not for windows, because it breaks behaviour
		# of "Show desktop" with modal window on top.
		wm transient $path $_parent
	}
}

body Modal::destructor {} {
	wm protocol $path WM_DELETE_WINDOW ""
	if {$grabbed != ""} {
		releaseGrab $grabbed
	}
}

body Modal::preventClosing {} {
	wm protocol $path WM_DELETE_WINDOW "#"
}

body Modal::allowClosing {} {
	wm protocol $path WM_DELETE_WINDOW "$this windowDestroyed"
}

body Modal::center {} {
	update idletasks
	set pWd [winfo width $_parent]
	set pHt [winfo height $_parent]
	set px [winfo x $_parent]
	set py [winfo y $_parent]
	lassign [getSize] wd ht
	set x [expr {$px+($pWd-$wd)/2}]
	set y [expr {$py+($pHt-$ht)/2}]
	wm geometry $path +$x+$y
}

body Modal::getSize {} {
	update idletasks
	return [list [winfo $wd_algo $path] [winfo $hg_algo $path]]
}

body Modal::exec {} {
	set minSize [getSize]
	wm minsize $path {*}$minSize
	$this center
	if {!$_resizable} {
		wm resizable $path 0 0
	}
	update
	wm deiconify $path
	raise $path
	if {$modal} {
		# Necessery before focus and raise.
		# It's required when editing column from table editing dialog
		# under windows, so the column dialog doesn't loose its focus.
		setGrab $path ;#[grabWidget]
	}
	focus [grabWidget]
	if {!$_allowReturn} {
		bind $path <Return> "$this clicked ok"
	}
	bind $path <Escape> "$this clicked cancel"
	wm protocol $path WM_DELETE_WINDOW "$this windowDestroyed"
	if {$modal} {
		if {$_initScript != ""} {
			uplevel #0 $_initScript
		}
		tkwait window $path
		return $retval
	}
	return ""
}

body Modal::setGrab {widget} {
	::tk::SetFocusGrab $path $widget
	set grabbed $widget
}

body Modal::releaseGrab {widget} {
	::tk::RestoreFocusGrab $path $widget
}

body Modal::cancelClicked {} {
	return ""
}

body Modal::clicked {bt} {
	set okBtn 0
	switch -- $bt {
		"cancel" {
			set retval [cancelClicked]
		}
		default {
			set okBtn 1
			set retval [okClicked]
		}
	}
	if {$closeWhenOkClicked && $okBtn || !$okBtn} {
		catch {bind $path <Destroy> ""}
		catch {destroy $path}
	}
}

body Modal::windowDestroyed {} {
	set retval [destroyed]
	catch {destroy $path}
}

body Modal::destroyed {} {
	return ""
}

body Modal::setTitle {title} {
	wm title $path $title
}

body Modal::refreshGrab {} {
	setGrab $path ;#[grabWidget]
}
