use src/grids/grid.tcl

class HistGrid {
	inherit Grid

	constructor {args} {
		Grid::constructor {*}$args -multicell 0
	} {}

	public {
		method delOlderThan {date}
		method scrollToLastRow {}
	}
}

body HistGrid::delOlderThan {date} {
	set item [$_tree item id "first visible"]
	set rowsToDel [list]

	while {$item != ""} {
		set colId [$_tree column id "first next"]	;# database column
		set colId [$_tree column id "$colId next"]	;# execution date column
		set rowNumId [$_tree column id 1]
		set ldate [$_tree item element cget [lindex $item 0] $colId e_text -text]
		if {$ldate <= $date} {
			lappend rowsToDel $item
		}
		set item [$_tree item id "$item next visible"]
	}
	foreach r $rowsToDel {
		$_tree item delete $r
	}
	setSelection
}

body HistGrid::scrollToLastRow {} {
	if {[count] == 0} return
	$_tree see "last visible"
}
