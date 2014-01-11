package require platform

# win32
# macosx
# freebsd
# solaris
# linux
proc os {} {
	return [lindex [split [platform::generic] -] 0]
}

proc isCommonUnix {} {
	expr {[os] in [list "linux" "solaris" "freebsd"]}
}

# win32-ix86			win32-ix86_64
# macosx-ix86			macosx10.6-ix86
# freebsd-ix86			freebsd-amd64
# solaris-ix86			solaris2.10-ix86
# linux-x86_64			linux-glibc2.11-x86_64
# linux-ix86			linux-glibc2.11-ix86

proc osDetails {} {
	lassign [split [platform::generic] -] os arch
	lassign [split [platform::identify] -] fullOs arch2

	set details [dict create os $os version 0 arch 32]
	switch -- $os {
		"linux" - "freebsd" {
			dict set details version [regexp -inline -- {[\d\.]+} $::tcl_platform(osVersion)]
		}
		"solaris" - "macosx" {
			dict set details version [regexp -inline -- {[\d\.]+} $fullOs]
		}
		"win32" {
			switch -- $::tcl_platform(osVersion) {
				"6.1" {
					# Windows 7
					dict set details version "7"
				}
				"6.0" {
					# Vista
					dict set details version "vista"
				}
				"5.2" {
					# 2003
					dict set details version "2003"
				}
				"5.1" {
					# XP
					dict set details version "xp"
				}
				"5.0" {
					# 2000
					dict set details version "2000"
				}
				default {
					# Other
					switch -- $::tcl_platform(os) {
						"Windows NT" {
							dict set details version "nt"
						}
						default {
							dict set details version "9x"
						}
					}
					
				}
			}
		}
	}

	if {[string match "*64" $arch]} {
		dict set details arch 64
	}

	return $details
}

####################################################################

if {[os] == "win32"} {
	proc win_wheelEvent {x y delta} {
		set widget [winfo containing $x $y]
		if {$widget != ""} {
			if {$delta > 0} {
				event generate $widget <Button-4>
			} elseif {$delta < 0} {
				event generate $widget <Button-5>
			}
		}
	}
	bind all <MouseWheel> "+win_wheelEvent %X %Y %D"

#	event add <<Copy>> <Command-Key-Cyrillic_tse>
# 	event add <<Copy>> <Command-Key->
}

# Fix for shift-backspace asteriks:
# http://forum.sqlitestudio.pl/viewtopic.php?f=2&t=4106
if {[isCommonUnix]} {
	bind Text <Terminate_Server> "break"
	bind Entry <Terminate_Server> "break"
	bind Spinbox <Terminate_Server> "break"
	bind TEntry <Terminate_Server> "break"
	bind TSpinbox <Terminate_Server> "break"
}

# Unify right and middle buttons - OSX does it differently
if {[tk windowingsystem] == "aqua"} {
	set ::RIGHT_BUTTON 2
	set ::MIDDLE_BUTTON 3
} else {
	set ::RIGHT_BUTTON 3
	set ::MIDDLE_BUTTON 2
}

# Cursors
if {[os] == "win32"} {
	set ::CURSOR(link) hand2
} else {
	set ::CURSOR(link) hand1
}

# Reading *.lnk Windows files
proc readlnk {lnk} {
	set res ""
	set fp [open $lnk]
	foreach snip [split [read $fp] \x00] {
		if {[regexp {[A-Z]:\\} $snip] && [file exists $snip]} {
			set res $snip
			break
		}
	}
	close $fp
	return $res
}

# Pseudo shadows for windows
proc initHintShadow {t} {
	toplevel $t.shadow1 -background black -class Tooltip -takefocus 0
	wm overrideredirect $t.shadow1 1
	wm withdraw $t.shadow1
	wm attributes $t.shadow1 -alpha 0.4

	toplevel $t.shadow2 -background black -class Tooltip -takefocus 0
	wm overrideredirect $t.shadow2 1
	wm withdraw $t.shadow2
	wm attributes $t.shadow2 -alpha 0.2

	bind $t <Unmap> "
		wm withdraw $t.shadow1
		wm withdraw $t.shadow2
	"
}

proc raiseHintShadow {t x y w h} {
	incr x +2
	incr y +2
	wm geometry $t.shadow1 ${w}x${h}+$x\+$y
	incr x -1
	incr y -1
	incr w +2
	incr h +2
	wm geometry $t.shadow2 ${w}x${h}+$x\+$y

	wm deiconify $t.shadow1
	wm deiconify $t.shadow2
	lower $t.shadow1 $t
	lower $t.shadow2 $t.shadow1
}
