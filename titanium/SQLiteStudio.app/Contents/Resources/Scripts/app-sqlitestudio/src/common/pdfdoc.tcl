class PdfDoc {
	inherit_snit_type ::pdf4tcl::pdf4tcl

	constructor {args} {
		snit_type_pdf4tcl::constructor {*}$args
	} {}

	public {
		method getMultiLineStringWidth {str}
		method drawTextBox {x y width height txt args}
	}
}

body PdfDoc::getMultiLineStringWidth {str} {
	set max 0
	foreach line [split $str \n] {
		set max [expr {max($max, [$_pdf getStringWidth $line])}]
	}
	return $max
}

body PdfDoc::drawTextBox {x y width height txt args} {
	# pre-calculate some values
	set font_height [expr {[$super cget -font_size] * [$super cget -line_spacing]}]
	set space_width [$super getCharWidth " " 1]

	set len [string length $txt]

	# run through chars until we exceed width or reach end
	set start 0
	set pos 0
	set cwidth 0
	set lastbp 0
	set done false

	while {!$done} {
		set ch [string index $txt $pos]
		# test for breakable character
		if {[regexp "\[ \t\r\n-\]" $ch]} {
			set lastbp $pos
		}
		set w [$self getCharWidth $ch 1]
		if {($cwidth + $w) > $width || $pos >= $len || $ch == "\n"} {
			if {$pos >= $len} {
				set done true
			} else {
				# backtrack to last breakpoint
				if {$lastbp != $start} {
					set pos $lastbp
				} else {
					# Word longer than line.
					# Back up one char if possible
					if {$pos > $start} {
						incr pos -1
					}
				}
			}
			set sent [string trim [string range $txt $start $pos]]
			$self DrawTextAt $x $y $sent
			# Move y down to next line
			set y [expr {$y-$font_height}]
			incr lines

			set start $pos
			incr start
			set cwidth 0
			set lastbp $start

			# Will another line fit?
			if {($ystart - ($y + $bboxb)) > $height} {
				return [string range $txt $start end]
			}
		} else {
			set cwidth [expr {$cwidth+$w}]
		}
		incr pos
	}
	return ""
}
