#!/usr/bin/env tclsh

if {$::DISTRIBUTION == "binary"} {
	set dir "../../../../lang"
} else {
	set dir "../lang"
}

set ::sources [list]
set ::translated [list]

set exceptions {                                                                                                                                                                    
	{ok}
	{sql}
	{url}
	{on update}
	{on delete}
	{match}
	{uri:}
}                                                                                                                                                                                   
                                                                                                                                                                                    
set locExc(pl_pl) {                                                                                                                                                                 
	{\t (tab)}
	{separator:}
	{login:}
}

if {$argc != 1} {
	puts "$argv0 <lang>"
	exit 1
}

proc win {msg} {
	package require Tk
	text .text -background white -yscrollcommand ".s set" -borderwidth 1
	ttk::scrollbar .s -command ".text yview"
	pack .text -side left -fill both -expand 1
	pack .s -side right -fill y
	.text insert end $msg
	.text configure -state disabled
	tkwait window .
}

set lang [lindex $argv 0]

if {![file readable $::dir/$lang.msg]} {
	if {$::DISTRIBUTION == "binary"} {
		set dir "../lang"
		if {![file readable $::dir/$lang.msg]} {
			puts "Cannot read $::dir/$lang.msg"
			exit 1
		}
	} else {
		puts "Cannot read $::dir/$lang.msg"
		exit 1
	}
}

proc mcset {locale src dst} {
	lappend ::sources $src
	if {![string equal $src $dst]} {
		lappend ::translated $src
	}
}

foreach f [glob -directory $::dir $lang.msg] {
	source $f
}

if {[llength $::sources] == [llength $::translated]} {
	puts "Everything is translated for $lang."
	exit 0
}

if {$tcl_platform(platform) == "windows"} {
	set text "Messages possibly not translated for $lang:\n"
	set i 1
	foreach msg $::sources {
		if {$msg ni $::translated && !([string tolower $msg] in $::exceptions \
				|| [info exists locExc($lang)] && [string tolower $msg] in $locExc($lang))} {
			append text "$i) $msg\n"
			incr i
		}
	}
	win $text
} else {
	puts "Messages possibly not translated for $lang:"
	set i 1
	foreach msg $::sources {
		if {$msg ni $::translated && !([string tolower $msg] in $::exceptions \
				|| [info exists locExc($lang)] && [string tolower $msg] in $locExc($lang))} {
			puts "$i) $msg"
			incr i
		}
	}
}
