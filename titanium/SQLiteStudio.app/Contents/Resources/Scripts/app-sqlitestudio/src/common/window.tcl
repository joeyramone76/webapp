#---------------------------------------------------
# Based on orginal Toplevel class from Itk package
# by Michael J. McLennan
#---------------------------------------------------

class Window {
	inherit itk::Archetype

	constructor {args} {}
	destructor {}

	itk_option define -title title Title "" {
		wm title $itk_hull $itk_option(-title)
	}

	protected {
		variable path ""
	}

	private {
		variable itk_hull ""
	}
}

body Window::constructor {args} {
	set itk_hull [namespace tail $this]
	set itk_interior $itk_hull
	set path $itk_hull

	itk_component add hull {
		toplevel $itk_hull -class [namespace tail [info class]]
	} {
		keep -background -cursor -takefocus
	}
	bind itk-delete-$itk_hull <Destroy> [list catch [list itcl::delete object $this]]

	set tags [bindtags $itk_hull]
	bindtags $itk_hull [linsert $tags 0 itk-delete-$itk_hull]

	eval itk_initialize $args
}

body Window::destructor {} {
	if {[winfo exists $itk_hull]} {
		set tags [bindtags $itk_hull]
		set i [lsearch -exact $tags itk-delete-$itk_hull]
		if {$i >= 0} {
			bindtags $itk_hull [lreplace $tags $i $i]
		}
		destroy $itk_hull
	}
	itk_component delete hull

	set components [component]
	foreach component $components {
		set path($component) [component $component]
	}
	foreach component $components {
		if {[winfo exists $path($component)]} {
			destroy $path($component)
		}
	}
}
