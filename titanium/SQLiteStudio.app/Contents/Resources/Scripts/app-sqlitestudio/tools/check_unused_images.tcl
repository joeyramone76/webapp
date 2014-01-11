#!/usr/bin/env tclsh

# Used to get list of images that most likely are not used anymore.

proc get {d ext} {
	set files [list]
	foreach f [glob -nocomplain -directory $d *] {
		if {[file isdirectory $f]} {
			lappend files {*}[get $f $ext]
		} else {
			if {[string match "*.$ext" $f]} {
				lappend files $f
			}
		}
	}
	return $files
}

set tcls [get src tcl]
set pngs [get img png]

set tclData ""
foreach f $tcls {
	set fd [open $f r]
	append tclData [read $fd]
	append tclData "\n"
	close $fd
}

set notFound [list]
foreach png $pngs {
	set img [string range [lindex [file split $png] end] 0 end-4]
	if {[string first img_$img $tclData] == -1} {
		lappend notFound $png
	}
}

puts "Not used:\n[join $notFound \n]"

#foreach f $notFound {
#	file delete $f
#}
