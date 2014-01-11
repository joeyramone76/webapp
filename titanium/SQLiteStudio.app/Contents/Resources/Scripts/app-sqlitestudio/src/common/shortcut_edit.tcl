use src/common/panel.tcl

class ShortcutEdit {
	inherit Panel

	opt label
	opt variable
	opt hint
	opt modifycmd

	constructor {args} {
		eval Panel::constructor $args
	} {}

	private {
		variable _entry ""
		variable _var ""
		variable _btn ""
		variable _state
		variable _hint ""
		variable _modifycmd ""
	}

	public {
		method change {}
		method keyPressed {k}
		method keyReleased {k}
	}
}

body ShortcutEdit::constructor {args} {
	set w [ttk::frame $path.f -relief groove -borderwidth 1]
	pack $w -side top -fill x

	set _btn [ttk::button $w.btn -text [mc {Change}] -command "$this change"]
	set _entry [ttk::entry $w.entry]
	ttk::label $w.lab -text ""
	pack $_btn -side right
	pack $_entry -side right -padx 1
	pack $w.lab -side left

	eval itk_initialize $args
	set _var $itk_option(-variable)
	set _hint $itk_option(-hint)
	set _modifycmd $itk_option(-modifycmd)

	set shc [set $_var]
	$w.lab configure -text $itk_option(-label)
	$_entry insert end $shc
	$_entry configure -width 16 -state disabled

	if {$_hint != ""} {
		foreach w [list $_btn $_entry $w.lab $w] {
			helpHint $w $_hint
		}
	}

	# Widget for validating bindings
	frame $path.test
}

body ShortcutEdit::change {} {
	set _state(shift:L) 0
	set _state(shift:R) 0
	set _state(alt:L) 0
	set _state(alt:R) 0
	set _state(control:L) 0
	set _state(control:R) 0

	bind $_entry <Any-KeyPress> "$this keyPressed %K; break"
	bind $_entry <Any-KeyRelease> "$this keyReleased %K; break"
	$_entry configure -state !disabled
	grab set -global $_entry
	focus $_entry
}

body ShortcutEdit::keyPressed {k} {
	switch -glob -- $k {
		"Alt_*" {
			set side [lindex [split $k _] 1]
			set _state(alt:$side) 1
		}
		"Control_*" {
			set side [lindex [split $k _] 1]
			set _state(control:$side) 1
		}
		"Shift_*" {
			set side [lindex [split $k _] 1]
			set _state(shift:$side) 1
		}
		"Escape" {
			$_entry configure -state disabled
			grab release $_entry
			focus $_btn
		}
		default {
			set prefix ""
			foreach mod [list control alt shift] {
				if {$_state($mod:L) || $_state($mod:R)} {
					append prefix "[string totitle ${mod}]-"
				}
			}
			set str "$prefix$k"

			if {[catch {bind $path.test <$str> "puts test"}]} {
				Warning [mc {Forbidden shortcut key combination: %s} $str]
			} else {
				set $_var $str
				$_entry delete 0 end
				$_entry insert end $str
				if {$_modifycmd != ""} {
					eval $_modifycmd
				}
			}
			$_entry configure -state disabled
			grab release $_entry
			focus $_btn
		}
	}
}

body ShortcutEdit::keyReleased {k} {
	switch -glob -- $k {
		"Alt_*" {
			set side [lindex [split $k _] 1]
			set _state(alt:$side) 0
		}
		"Control_*" {
			set side [lindex [split $k _] 1]
			set _state(control:$side) 0
		}
		"Shift_*" {
			set side [lindex [split $k _] 1]
			set _state(shift:$side) 0
		}
	}
}
