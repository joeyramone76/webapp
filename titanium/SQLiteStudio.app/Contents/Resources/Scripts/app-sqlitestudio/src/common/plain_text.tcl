proc formatPlainText {db baseRowNum dataCols dataRows maxPlainTextColumnWidth nullPlainTextRepresentation} {
	set plainText ""
	array set columnMinSize {}
	set addedColumns [list]

	# Determinating minimum sizes of columns
	set rowNum $baseRowNum
	foreach dataRow $dataRows {
		set colNum 0
		foreach colValue [concat [list $rowNum] [lindex $dataRow 0]] {
			if {[$db isNull $colValue]} {
				set size [string length $nullPlainTextRepresentation]
			} else {
				set size [string length $colValue]
			}
			if {$size > $maxPlainTextColumnWidth} {
				set size $maxPlainTextColumnWidth
			}
			if {![info exists columnMinSize($colNum)] || $size > $columnMinSize($colNum)} {
				set columnMinSize($colNum) $size
			}
			incr colNum
		}
		incr rowNum
	}

	# Adding column labels
	set rowToAdd [list]
	set colNum 0
	foreach dataCol [concat [list [list [dict create database "" table "" column "#"] ""]] $dataCols] {
		lassign $dataCol colDict rowid
		set title [dict get $colDict column]
		if {$title in $addedColumns} {
			set title "[dict get $colDict table].$title"
		}
		lappend addedColumns $title

		# Making sure of column width
		set size [string length $title]
		if {![info exists columnMinSize($colNum)] || $size > $columnMinSize($colNum)} {
			set columnMinSize($colNum) $size
		}

		lappend rowToAdd [pad $columnMinSize($colNum) " " $title]
		incr colNum
	}
	append plainText [join $rowToAdd "|"]
	append plainText "\n"

	# Adding header separator
	set rowToAdd [list]
	set colNum 0
	foreach dataCol [concat [list [list]] $dataCols] {
		lappend rowToAdd [pad $columnMinSize($colNum) "-" ""]
		incr colNum
	}
	append plainText [join $rowToAdd "+"]
	append plainText "\n"

	# Adding rows
	set rowNum $baseRowNum
	foreach dataRow $dataRows {
		set rowToAdd [list]
		set colNum 0
		foreach colValue [concat [list $rowNum] [lindex $dataRow 0]] {
			if {[$db isNull $colValue]} {
				set value [string range $nullPlainTextRepresentation 0 [expr {$columnMinSize($colNum)-1}]]
			} else {
				set value [string range $colValue 0 [expr {$columnMinSize($colNum)-1}]]
			}
			lappend rowToAdd [pad $columnMinSize($colNum) " " $value]
			incr colNum
		}
		append plainText [join $rowToAdd "|"]
		append plainText "\n"
		incr rowNum
	}
	return $plainText
}
