use src/grids/dbgrid.tcl

class IdxGrid {
	inherit DBGrid

	constructor {args} {
		DBGrid::constructor {*}$args -readonly 0 -multicell 0
	} {}

	public {
		method edit {item}
	}
}

body IdxGrid::edit {item} {
	set dialog [IndexDialog .editIndex -title [mc {Edit index}] -db $_db -index \
		[$_tree item element cget [lindex $item 0] 1 e_text -text] \
	]
	$dialog exec
}
