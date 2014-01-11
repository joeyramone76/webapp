use src/trees/tree.tcl

#>
# @class BrowserTree
# More advanced kind of tree, based on regular {@class Tree} widget.
# Provides additional suffixes for every node with numbers in it,
# so it can be used as some kind of browser with counting of items in every node.
#<
class BrowserTree {
	inherit Tree

	opt clicked ""
	opt doubleclicked ""

	#>
	# @var alternative_color
	# Alternative color used for number suffixes.
	#<
	common alternative_color "blue"

	#>
	# @var numbers_font
	# Alternative font used for number suffixes.
	#<
	common numbers_font "TreeLabelFont"

	#>
	# @method constructor
	# @param args Arguments passed to {@method Tree::constructor}.
	# Default constructor.
	#<
	constructor {args} {}

	protected {
		#>
		# @var _clickedCode
		# Code to be evaluated on click event. Can use \\\$item variable as clicked item.
		#<
		variable _clickedCode ""

		#>
		# @var _doubleClickedCode
		# Code to be evaluated on double-click event. Can use \\\$item variable as clicked item.
		#<
		variable _doubleClickedCode ""
	}

	public {
		#>
		# @method setElementLabel
		# @param it Tree node item to set number for.
		# @param lab Label to set.
		# Sets new label to be displayed next to the given node.
		#<
		method setElementLabel {it num}

		#>
		# @method incrElementLabelNumber
		# @param it Tree node item to increment number for.
		# Increments number that is displayed next to the given node.
		# It works only if label is set to empty string or a number.
		#<
		method incrElementLabelNumber {it}

		#>
		# @method addItem
		# @overloaded Tree
		#<
		method addItem {parent img text button}

		#>
		# @method updateUISettings
		# @overloaded UI
		#<
		method updateUISettings {}

		#>
		# @method clicked
		# @param x X-coordinate of click event.
		# @param y Y-coordinate of click event.
		# Usually called by <i>Button-1</i> event on tree.
		#<
		method clicked {x y}

		#>
		# @method doubleClicked
		# @param x X-coordinate of double-click event.
		# @param y Y-coordinate of double-click event.
		# Opens window related to node that is double-clicked, opens database
		# (in case when the node represents closed database),
		# or expands/collapses double-clicked node.
		#<
		method doubleClicked {x y}
	}
}

body BrowserTree::constructor {args} {
	$_tree element create e_subElemsTxt text -fill [list \
		${::Tree::selected_foreground_color} {selected} \
		$alternative_color {!selected} \
	]
	$_tree element configure e_subElemsTxt -font "{$numbers_font}"

	$_tree style elements	s_item [list e_img e_sel_rect e_txt e_subElemsTxt]
	$_tree style layout		s_item e_txt -expand "" -pady 2
	$_tree style layout		s_item e_subElemsTxt -expand ens -pady 2 -padx 5

	bind $_tree <ButtonRelease-1> [list after 10 [list catch [list $this clicked %x %y]]]
	bind $_tree <Double-Button-1> [list $this doubleClicked %x %y]

	eval itk_initialize $args
	set _clickedCode $itk_option(-clicked)
	set _doubleClickedCode $itk_option(-doubleclicked)
}

body BrowserTree::setElementLabel {it lab} {
	if {$lab == ""} {
		$_tree item element configure $it 0 e_subElemsTxt -text ""
	} else {
		$_tree item element configure $it 0 e_subElemsTxt -text "($lab)"
	}
}

body BrowserTree::incrElementLabelNumber {it} {
	set num [$_tree item element cget $it 0 e_subElemsTxt -text]
	if {$num == ""} {
		set num 1
	} elseif {[regexp -- {^\(\d+\)$} $num]} {
		set num [string trimright [string trimleft $num "("] ")"]
		incr num
	}
	$_tree item element configure $it 0 e_subElemsTxt -text "($num)"
}

body BrowserTree::addItem {parent img text button} {
	set it [Tree::addItem $parent $img $text $button]
	$_tree item element configure $it 0 e_subElemsTxt -text ""
	return $it
}

body BrowserTree::updateUISettings {} {
	Tree::updateUISettings
	$_tree element configure e_subElemsTxt -fill [list \
		${::Tree::selected_foreground_color} {selected} \
		$alternative_color {!selected} \
	]
	$_tree element configure e_subElemsTxt -font "{$numbers_font}"
}

body BrowserTree::clicked {x y} {
	set item [$_tree identify $x $y]
	eval $_clickedCode
}

body BrowserTree::doubleClicked {x y} {
	set item [$_tree identify $x $y]
	eval $_doubleClickedCode
}
