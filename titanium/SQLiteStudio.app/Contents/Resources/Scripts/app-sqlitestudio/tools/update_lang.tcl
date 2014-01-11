#!/usr/bin/env tclsh

# Writes en.msg (or other configured) file with all
# messages used in application externalized for translating.

set dir "../src"				;# Directory to scan recurently
set outDir "../lang"			;# Output directory to write externalized strings

###############################################################################

set ::transList [list]

proc scanDir {d} {
	foreach f [glob -directory $d *] {
		if {[file isdirectory $f]} {
			scanDir $f
		} elseif {[string match "*.tcl" $f]} {
			scanSource $f
		}
	}
}

proc getChar {str} {
	eval return $str
}

proc flushBuf {} {
	uplevel {
		set state "STD"
		if {$buf ni $::transList} {
			lappend ::transList $f $buf
		}
		set buf ""
		incr msgs
	}
}

proc scanSource {f} {
	puts -nonewline "Scanning $f... "
	flush stdout
	set fd [open $f r]
	set data [read $fd]
	close $fd

	set state "STD" ;# STD, MC, MC_QUOTE_BODY, MC_BRACE_BODY
	set squareDepth 0
	set braceDepth 0
	set quote 0
	set buf ""
	set line 1
	set msgs 0

	set lgt [string length $data]
	for {set i 0} {$i < $lgt} {incr i} {
		set c [string index $data $i]
		if {$quote} {
			set char [getChar "\\$c"]
			if {$char in [list "\"" "\\"] && $state == "MC_QUOTE_BODY"} {
				append buf $c
				set quote 0
				continue
			}
			set c $char
			set quote 0
		}
		switch -- $c {
			"\"" {
				if {$state == "MC"} {
					set state "MC_QUOTE_BODY"
				} elseif {$state == "MC_QUOTE_BODY"} {
					flushBuf
				} elseif {$state == "MC_BRACE_BODY"} {
					append buf $c
				}
			}
			"\{" {
				if {$state == "MC"} {
					set state "MC_BRACE_BODY"
				} elseif {$state == "MC_BRACE_BODY"} {
					incr braceDepth
					append buf $c
				}
			}
			"\}" {
				if {$state == "MC"} {
					puts "Unexpected \} in MC state. $f:$line"
					set state "MC"
					set buf ""
				} elseif {$state == "MC_BRACE_BODY"} {
					if {$braceDepth > 0} {
						incr braceDepth -1
						append buf $c
					} else {
						flushBuf
					}
				}
			}
			"\[" {
				set c1 [string index $data [expr {$i+1}]]
				set c2 [string index $data [expr {$i+2}]]
				set c3 [string index $data [expr {$i+3}]]
				if {$state == "MC"} {
					incr squareDepth
				} elseif {$state in [list "MC_BRACE_BODY" "MC_QUOTE_BODY"]} {
					append buf $c
				} elseif {"$c1$c2$c3" == "mc "} {
					set state "MC"
					incr i 3
				}
			}
			"\]" {
				if {$state == "MC"} {
					if {$squareDepth > 0} {
						incr squareDepth -1
					} else {
						set state "STD"
# 						if {[string trim $buf] != ""} {
							flushBuf
# 						} else {
# 							puts "Unexpectd \] in MC state. $f:$line"
# 							set buf ""
# 						}
					}
				} elseif {$state in [list "MC_BRACE_BODY" "MC_QUOTE_BODY"]} {
					incr squareDepth -1
					append buf $c
				}
			}
			"\n" {
				if {$state in [list "MC_QUOTE_BODY" "MC_BRACE_BODY"]} {
					append buf $c
				}
				incr line
			}
			"\\" {
				if {$state == "MC_BRACE_BODY"} {
					append buf $c
				} else {
					set quote 1
				}
			}
			default {
				if {$state in [list "MC_QUOTE_BODY" "MC_BRACE_BODY"]} {
					append buf $c
				}
			}
		}
	}
	puts "($msgs messages)"
}

proc scanLangs {} {
	proc mcset {locale src dst} {
		lappend ::translated($locale) $src
		set ::translation($locale:$src) $dst
	}

	foreach f [glob -directory $::outDir *.msg] {
		source $f
	}

	return [array names ::translated]
}

proc gen {fd locale} {
	set entries(new) 0
	set entries(old) 0
	set entries(unchanged) 0
	if {![info exists ::translated($locale)]} {
		# All
		foreach {file str} $::transList {
# 			set str [string map [list \\n \n \\t \t] $str]
# 			set str [string map [list \\\t \\t \\\n \\n] $str]

			puts $fd ""
			puts $fd "### File: $file"
			puts $fd "mcset $locale [list $str] [list $str]"
			incr entries(new)
		}
	} else {
		# Unchanged
		set first true
		foreach {file str} $::transList {
# 			set str [string map [list \\n \n \\t \t] $str]
# 			set str [string map [list \\\t \\t \\\n \\n] $str]

			set found false
			foreach tr $::translated($locale) {
				#set tr [string map [list \\n \n \\t \t] $tr]

				if {$tr == $str} {
					set found true
					break
				}
			}

			if {$found} {
				if {$first} {
					puts $fd ""
					puts $fd "# Unchanged translations"
					set first false
				}
				puts $fd ""
				puts $fd "### File: $file"
				puts $fd "mcset $locale [list $str] [list $::translation($locale:$str)]"
				incr entries(unchanged)
			}
		}

		# New
		set first true
		foreach {file str} $::transList {
# 			set str [string map [list \\n \n \\t \t] $str]
# 			set str [string map [list \\\t \\t \\\n \\n] $str]
			set found false
			foreach tr $::translated($locale) {
				#set tr [string map [list \\n \n \\t \t] $tr]

				if {$tr == $str} {
					set found true
					break
				}
			}

			if {!$found} {
				#puts "new: [string map {\\ ""} $str]"
				#puts "new: \[lsearch $::translated($locale) $str]"
				#puts "list: |[lsearch -inline -glob $::translated($locale) *(tab)*]|"
				#puts ""
				if {$first} {
					puts $fd ""
					puts $fd "# New entries"
					set first false
				}
				puts $fd ""
				puts $fd "### File: $file"
				puts $fd "mcset $locale [list $str] [list $str]"
				incr entries(new)
			}
		}

		# Old
		set first true
		foreach tr $::translated($locale) {
			#set tr [string map [list \\n \n \\t \t] $tr]

			set notFound true
			foreach {file str} $::transList {
# 				set str [string map [list \\n \n \\t \t] $str]
# 				set str [string map [list \\\t \\t \\\n \\n] $str]
				if {$str == $tr} {
					set notFound false
				}
			}

			if {$notFound} {
				if {$first} {
					puts $fd ""
					puts $fd "# Old, deprecated entries"
					set first false
				}
				puts $fd "mcset $locale [list $tr] [list $::translation($locale:$tr)]"
				incr entries(old)
			}
		}
	}
	puts "For $locale:"
	puts "New entries:       $entries(new)"
	puts "Outdated entries:  $entries(old)"
	puts "Unchanged entries: $entries(unchanged)"
	puts "-----------------------"
}

scanDir $dir
puts "[llength $::transList] messages total.\n"

set langs [scanLangs]

puts "Langs: $langs"

foreach l $langs {
 	set fd [open $outDir/$l.msg w]
 	puts $fd "# SQLiteStudio '$l' localization file"
 	gen $fd $l
 	close $fd
}

if {"en" ni $langs} {
	set l en
	set fd [open $outDir/$l.msg w]
	puts $fd "# SQLiteStudio '$l' localization file"
	gen $fd $l
	close $fd
}
