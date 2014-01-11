use src/grids/grid.tcl

class RichGrid {
	inherit Grid

	common linkFont "GridFontUnderline"
	common linkBoldFont "GridFontBoldUnderline"

	constructor {args} {
		Grid::constructor {*}$args
	} {}

# 	protected {
# 		variable _colType
# 	}

	public {
		method addColumn {title {type "text"}}
		method addRow {data}
		method handleClick {x y}
		method handleMotion {x y}
	}
}

body RichGrid::constructor {args} {
	$_tree element create e_link text -wrap none -lines 1 -font [list $linkFont] -fill blue

	$_tree style create s_link
	$_tree style elements s_link [list e_border e_link]
	$_tree style layout s_link e_border -detach yes -iexpand xy
	$_tree style layout s_link e_link -ipadx 3 -ipady 3 -maxwidth $maxColumnWidth -padx 1 -pady 1

	bind $_tree <Motion> "$this handleMotion %x %y"

	eval itk_initialize $args
}

body RichGrid::addColumn {title {type "text"}} {
	switch -- $type {
		"rownum" {
			 lappend _cols [$_tree column create -text "$title" -borderwidth 1 -maxwidth 400 -button no -justify right -itembackground gray]
		}
		"numeric" - "real" - "integer" {
			lappend _cols [$_tree column create -text "$title" -borderwidth 1 -maxwidth 400 -button no -justify right]
		}
		"text" {
			lappend _cols [$_tree column create -text "$title" -borderwidth 1 -maxwidth 400 -button no]
		}
		"link" {
			lappend _cols [$_tree column create -text "$title" -borderwidth 1 -maxwidth 400 -button no]
		}
		"window" {
			 lappend _cols [$_tree column create -text "$title" -borderwidth 1 -maxwidth 400 -button no -justify center]
		}
		"image" {
			 lappend _cols [$_tree column create -text "$title" -borderwidth 1 -maxwidth 400 -button no -justify center]
		}
		default {
			error "Unknown column type '$type' passed to RichGrid::addColumn."
		}
	}
	set c [lindex $_cols end]
	set _colName($c) $title
	set _colType($c) $type
	refreshWidth
	return $c
}

body RichGrid::addRow {data} {
	set it [Grid::addRow $data]
	foreach w [concat $_rowNum $data] c $_cols {
		switch -- $_colType($c) {
			"link" {
				lassign $w url label
				$_tree item style set $it $c s_link
				$_tree item element configure $it $c e_link -text "$label" -data $url
			}
		}
	}
	return $it
}

body RichGrid::handleClick {x y} {
	set item [dict create {*}[$_tree identify $x $y]]
	if {![dict exists $item elem]} return

	set elem [dict get $item elem]
	if {$elem == "e_link"} {
		set it [dict get $item item]
		set col [dict get $item column]
		set url [$_tree item element cget $it $col e_link -data]
		MAIN openWebBrowser $url
	}
}

body RichGrid::handleMotion {x y} {
	if {[catch {dict create {*}[$_tree identify $x $y]} item]} return
	if {![dict exists $item item] || ![dict exists $item column]} return

	set it [dict get $item item]
	set col [dict get $item column]
	if {![dict exists $item elem]} {
		$_tree configure -cursor ""
		return
	}

	set elem [dict get $item elem]
	if {$elem == "e_link"} {
		$_tree configure -cursor $::CURSOR(link)
	} else {
		$_tree configure -cursor ""
	}
}
