use src/grids/dbgrid.tcl

class TrigGrid {
	inherit DBGrid

	constructor {args} {
		DBGrid::constructor {*}$args -readonly 0 -multicell 0
	} {}

	public {
		method edit {item}
	}
}

body TrigGrid::edit {item} {
	set dialog [TriggerDialog .editTrig -title [mc {Edit trigger}] -db $_db -trigger \
		[$_tree item element cget [lindex $item 0] 1 e_text -text] \
	]
	$dialog exec
}
