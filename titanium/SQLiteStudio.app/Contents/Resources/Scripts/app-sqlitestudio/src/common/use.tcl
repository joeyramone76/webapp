# [use] procedure
if {![info exists USED]} {
	set USED [list]
}

proc use {script} {
    set script [string tolower $script]
    set short [string range $script 0 end-4]
	if {$short ni $::USED} {
		lappend ::USED $short
		source -encoding utf-8 $script
	}
}
