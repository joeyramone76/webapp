proc debug {str} {
	if {$::DEBUG(global)} {
		puts $str
	}
}
