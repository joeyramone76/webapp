# type		- type of tree item.
# opened	- if db is opened or not. 0=don't care, 1=disable entry if not opened, -1=enable entry if not opened, 2=do not show if not opened
# args		- menu command to evaluate
proc cmenu {type p_open args} {
	upvar CMENU cmenu

	if {$type != "" && $type != "ALL" && $type != $cmenu(type)} return
	if {$cmenu(db) != ""} {
		set open [$cmenu(db) isOpen]
	} else {
		set open 0
	}
	if {!$open && $p_open == 2} return
	set menu [lindex $args 0]
	eval $args
	if {$p_open == -1 && $open || $p_open == 1 && !$open} {
		$menu entryconfigure end -state disabled
	}
}
