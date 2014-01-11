# This procedure comes from original code of pdf4tcl,
# but a little modified for SQLiteStudio purpose.
proc pdf_getTextBoxHeight {pdf fontSize width txt} {
	$pdf Trans  0 0 x y
	$pdf TransR $width 0 width height

	# pre-calculate some values
	set fontSize [::pdf4tcl::getPoints $fontSize]
	set font_height [expr {$fontSize * [$pdf getLineSpacing]}]
	set bboxb [$pdf getFontMetric bboxb 1]
	set len [string length $txt]

	# run through chars until we exceed width or reach end
	set start 0
	set pos 0
	set cwidth 0
	set lastbp 0
	set done false
	set req_height [expr {$font_height + $bboxb}]

	while {! $done} {
		set ch [string index $txt $pos]
		# test for breakable character
		if {[regexp "\[ \t\r\n-\]" $ch]} {
			set lastbp $pos
		}
		set w [$pdf getCharWidth $ch 1]
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
				set req_height [expr {$req_height + $font_height}]
			}
			set start $pos
			incr start
			set cwidth 0
			set lastbp $start
		} else {
			set cwidth [expr {$cwidth + $w}]
		}
		incr pos
	}
	return $req_height
}
