use src/common/panel.tcl

class ScrolledFrame {
	inherit Panel

	constructor {args} {
		eval Panel::constructor $args
	} {}

	private {
		variable _frame ""
		method makeWidgetScrollable {w}
	}

	public {
		method reset {}
		method getFrame {}
		method makeChildsScrollable {}
		method getScrolledFrame {}
		method see {widget}
	}
}

body ScrolledFrame::constructor {args} {
	scrolledframe::scrolledframe $path.f -fill x -yscroll "$path.s set"
	if {[os] == "win32"} {
		# There's something wrong with ttk::scrollbar,
		# that causes BUG 1680.
		scrollbar $path.s -command "$path.f yview"
	} else {
		ttk::scrollbar $path.s -command "$path.f yview"
	}
	autoscroll $path.s
	set _frame [ttk::frame $path.f.scrolled.f]
	pack $path.s -side right -fill y
	pack $path.f -side left -fill both -expand 1
	pack $_frame -fill both -expand 1
	grid columnconfigure $path 0 -weight 1

	if {[os] == "win32"} {
		bind $path.f <MouseWheel> "
			$path.f yview scroll \[expr {-(%D/120)}] units
			break
		"
	} else {
		bind $path.f <Button-4> "
			$path.f yview scroll -1 units
			break
		"
		bind $path.f <Button-5> "
			$path.f yview scroll 1 units
			break
		"
	}
}

body ScrolledFrame::reset {} {
	foreach child [winfo child $_frame] {
		destroy $child
	}
}

body ScrolledFrame::getFrame {} {
	return $_frame
}

body ScrolledFrame::getScrolledFrame {} {
	return $path.f
}

body ScrolledFrame::makeChildsScrollable {} {
	foreach w [winfo children $path.f.scrolled] {
		makeWidgetScrollable $w
	}
}

# Runtime optimization - define platform specific implementation,
# instead of checking [os] each time
if {[os] == "win32"} {
	body ScrolledFrame::makeWidgetScrollable {w} {
		bind $w <MouseWheel> "
			$path.f yview scroll \[expr {-(%D/120)}] units
			break
		"

		foreach c [winfo children $w] {
			makeWidgetScrollable $c
		}
	}
} else {
	body ScrolledFrame::makeWidgetScrollable {w} {
		bind $w <Button-4> "
			$path.f yview scroll -1 units
			break
		"
		bind $w <Button-5> "
			$path.f yview scroll 1 units
			break
		"

		foreach c [winfo children $w] {
			makeWidgetScrollable $c
		}
	}
}

body ScrolledFrame::see {widget} {
	set f [getFrame]
	set sf [getScrolledFrame]
	set y [winfo y $widget]
	set h [winfo height $widget]
	set total [winfo height $f]
	set winHg [winfo height $sf]
	incr winHg -30

	lassign [$sf yview] yFrom yTo
	set from [expr {$total * $yFrom}]
	set to [expr {$total * $yTo}]

	if {$y < $from} {
		set y [expr {double($y - 10) / $total}]
		if {$y < 0} {
			set y 0.0
		}
		$sf yview moveto $y
	} elseif {$y+$h > $to} {
		set y [expr {double($y+$h-$winHg) / $total}]
		if {$y > 1} {
			set y 1
		}
		$sf yview moveto $y
	}
}
