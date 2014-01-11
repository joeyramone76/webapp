use src/trees/browser_tree.tcl

#>
# @class HintWinTree
# It uses advanced routines from {@class BrowserTree} but differs in look - main label is bold
# and additional label on right with different color and it's not bold.
#<
class HintWinTree {
	inherit BrowserTree

# 	opt clicked ""
# 	opt doubleclicked ""
#
# 	#>
# 	# @var alternative_color
# 	# Alternative color used for number suffixes.
# 	#<
# 	common alternative_color "blue"

	#>
	# @var bold_font
	# Alternative font used for additional info suffixes.
	#<
	common bold_font "TreeFontBold"

	#>
	# @method constructor
	# @param args Arguments passed to {@method Tree::constructor}.
	# Default constructor.
	#<
	constructor {args} {}

	protected {
# 		#>
# 		# @var _clickedCode
# 		# Code to be evaluated on click event. Can use \\\$item variable as clicked item.
# 		#<
# 		variable _clickedCode ""
#
# 		#>
# 		# @var _doubleClickedCode
# 		# Code to be evaluated on double-click event. Can use \\\$item variable as clicked item.
# 		#<
# 		variable _doubleClickedCode ""
	}

	public {
		#>
		# @method setElementAddInfo
		# @param it Tree node item to set additional info for.
		# @param lab Label to set.
		# Sets new label to be displayed next to the given node.
		#<
		method setElementAddInfo {it num}

# 		#>
# 		# @method incrElementLabelNumber
# 		# @param it Tree node item to increment number for.
# 		# Increments number that is displayed next to the given node.
# 		# It works only if label is set to empty string or a number.
# 		#<
# 		method incrElementLabelNumber {it}

		#>
		# @method addItem
		# @overloaded Tree
		#<
		method addItem {parent img text button label}

		#>
		# @method updateUISettings
		# @overloaded UI
		#<
		method updateUISettings {}
		
		method goto {where}

		#>
		# @method clicked
		# @param x X-coordinate of click event.
		# @param y Y-coordinate of click event.
		# Usually called by <i>Button-1</i> event on tree.
		#<
# 		method clicked {x y}

		#>
		# @method doubleClicked
		# @param x X-coordinate of double-click event.
		# @param y Y-coordinate of double-click event.
		# Opens window related to node that is double-clicked, opens database
		# (in case when the node represents closed database),
		# or expands/collapses double-clicked node.
		#<
# 		method doubleClicked {x y}
	}
}

body HintWinTree::constructor {args} {
	$_tree element create e_addInfoElemsTxt text -font "{$::Tree::font}"
	$_tree element configure e_addInfoElemsTxt -fill [list \
		${::Tree::selected_foreground_color} {selected} \
		${::BrowserTree::alternative_color} {!selected} \
	]
	$_tree element configure e_txt -font "{$bold_font}"

	$_tree style elements	s_item [list e_img e_sel_rect e_txt e_addInfoElemsTxt]
	$_tree style layout		s_item e_txt -expand "" -pady 2
	$_tree style layout		s_item e_addInfoElemsTxt -expand ens -pady 2 -padx 5

	bind $_tree <Home> "$this goto top; break"
	bind $_tree <End> "$this goto bottom; break"
	bind $_tree <Next> "$this goto pageDown; break"
	bind $_tree <Prior> "$this goto pageUp; break"
}

body HintWinTree::setElementAddInfo {it lab} {
}

body HintWinTree::addItem {parent img text button label} {
	set it [Tree::addItem $parent $img $text $button]
	if {$label == ""} {
		$_tree item element configure $it 0 e_addInfoElemsTxt -text ""
	} else {
		$_tree item element configure $it 0 e_addInfoElemsTxt -text "($label)"
	}
# 	$_tree item element configure $it 0 e_addInfoElemsTxt -text ""
	return $it
}

body HintWinTree::updateUISettings {} {
	Tree::updateUISettings
	$_tree element configure e_subElemsTxt -fill [list \
		${::Tree::selected_foreground_color} {selected} \
		$alternative_color {!selected} \
	]
	$_tree element configure e_subElemsTxt -font "{$numbers_font}"
}

# body HintWinTree::clicked {x y} {
# 	set item [$_tree identify $x $y]
# 	eval $_clickedCode
# }
#
# body HintWinTree::doubleClicked {x y} {
# 	set item [$_tree identify $x $y]
# 	eval $_doubleClickedCode
# }

body HintWinTree::goto {where} {
	switch -- $where {
		"top" {
			set idx "first visible"
		}
		"bottom" {
			set idx "last visible"
		}
		"pageUp" {
			set treeHg [$_tree cget -height]
			set itemHg [$_tree cget -itemheight]
			set items [expr {int(ceil(double($treeHg) / double($itemHg))) - 1}]
			set idx [$_tree item id "active"]
			for {set i 0} {$i < $items} {incr i} {
				set idx [$_tree item id "$idx prev visible"]
				if {$idx == ""} {
					set idx "first visible"
					break
				}
			}
		}
		"pageDown" {
			set treeHg [$_tree cget -height]
			set itemHg [$_tree cget -itemheight]
			set items [expr {int(ceil(double($treeHg) / double($itemHg))) - 1}]
			set idx [$_tree item id "active"]
			for {set i 0} {$i < $items} {incr i} {
				set idx [$_tree item id "$idx next visible"]
				if {$idx == ""} {
					set idx "last visible"
					break
				}
			}
		}
		default {
			return
		}
	}
	$_tree selection clear
	$_tree activate $idx
	$_tree see $idx
	$_tree selection add $idx
}
