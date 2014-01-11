use src/common/ui.tcl
use src/common/panel.tcl

#>
# @class Tree
# This is developer-friendly wrapper around TkTreeCtrl so it behaves
# as regular tree widget with icons and labels for each node. It provides
# simple routines to create, delete and manage nodes.
#<
class Tree {
	inherit Panel UI

	#>
	# @method constructor
	# @param args Parameters passed to {@method Panel::constructor}
	# Default constructor.
	#<
	constructor {args} {
		eval Panel::constructor $args
	} {}

	#>
	# @common background_color
	# Background color of the widget.
	#<
	common background_color "white"

	#>
	# @common foreground_color
	# Font color of the widget.
	#<
	common foreground_color "black"

	#>
	# @common selected_background_color
	# Background color of selected node in the widget.
	#<
	common selected_background_color "#000088"

	#>
	# @common selected_foreground_color
	# Font color of selected node in the widget.
	#<
	common selected_foreground_color "white"

	#>
	# @common font
	# Font used in widget. If no font is given, then
	# default TkTreeWidget font is used.
	#<
	common font "TreeFont"

	protected {
		#>
		# @var _root
		# It's root widget for this megawidget. In fact it is the same frame, as {@var Panel::path}.
		#<
		variable _root ""

		#>
		# @var _tree
		# Contains TkTreeCtrl widget used to draw main part of this megawidget.
		#<
		variable _tree ""

		#>
		# @var _col
		# It's identifier of the only column used in this widget. It's column identifier used in TkTreeCtrl widget.
		#<
		variable _col ""

		#>
		# @var _datacol
		# It's invisible column used to keep some additional data related with nodes. Each node can keep some
		# data in this column and it will be not visible for an user.
		#<
		variable _datacol ""
		
		#>
		# @method reportNodeStatus
		# This method calls itself recurently to find open/close status of nodes and reports it back.
		# The return format is: {nodeName status {nodeName status {nodeName status}} {nodeName status} ...}
		#<
		method reportNodeStatus {startNode}
		
		#>
		# @method applyNodeStatus
		# Applies the status returned by {@method reportNodeStatus} to given node, so it can be used to restore the status.
		#<
		method applyNodeStatus {startNode status}
	}

	public {
		#>
		# @method addItem
		# @param parent Parent node identifier, or <code>root</code> to make this node a root node.
		# @param img Image/icon name (existing Tk image object) to be used with this node. Can be empty string to ommit image.
		# @param text Label text for the node.
		# @param button Boolean value to determinate if node should be expandable or not (will contain any childrens or not). It will be automatically set to <code>true</code> for this item when it will be used as parent for other item.
		# Creates new node with given image and label and places it under given parent.
		# @return Created node identifier.
		#<
		method addItem {parent img text {button false}}

		#>
		# @method sort
		# @param it Node item to start sorting at. Optional.
		# Sorts nodes in the tree using standard <code>lsort</code> Tcl command (with <code>-dictionary</code> option passed).
		# It can sort all tree nodes or just ones placed under given node.
		#<
		method sort {{it root}}

		#>
		# @method setData
		# @param node Node item to set data for.
		# @param data New data to assign to the node.
		# Assigns new data to given node. This data can be accessed later with {@method getData}.
		#<
		method setData {node data}

		#>
		# @method getData
		# @param node Node item to get data from.
		# Reads value from data column (see {@var _datacol}) for given node and returns it.
		# @return Data stored for given node.
		#<
		method getData {node}

		#>
		# @method delItem
		# @param node Node item to be deleted. Use 'root' to cleanup the tree.
		# Deletes given node and all it's childrens.
		#<
		method delItem {node}

		#>
		# @method delAll
		# Deletes all nodes.
		#<
		method delAll {}

		#>
		# @method delChilds
		# @param node Node item with childrens to be deleted.
		# Deletes given node childrens.
		#<
		method delChilds {node}

		#>
		# @method expand
		# @param node Node item to be expanded.
		# @param recursive Expand recursivly.
		# Expands given node but only if it's expandable (contains child nodes) and it has any childrens.
		#<
		method expand {node {recursive false}}

		#>
		# @method getText
		# @param node Node item to read text from.
		# Reads label from the given node.
		# @return Node label text.
		#<
		method getText {node}

		#>
		# @method setText
		# @param node Node item to set new text for.
		# @param txt New text to set.
		# Sets new text for the node label.
		#<
		method setText {node txt}

		#>
		# @method updateUISettings
		# @overloaded UI
		#<
		method updateUISettings {}

		#>
		# @method getTree
		# @return {@var _tree} value.
		#<
		method getTree {}
		method getScrollbar {}

		#>
		# @method select
		# @param x X-coordinate.
		# @param y Y-coordinate.
		# Selects node closest to given x-y coordinates. Coordinates are relative to top left corner of the tree.
		#<
		method select {x y}

		#>
		# @method getSelectedItem
		# @return Currently selected node, or empty string if none is selected.
		#<
		method getSelectedItem {}

		#>
		# @method setSelected
		# @param it Tree node to select.
		# @return Sets given node to be selected.
		#<
		method setSelected {it}

		#>
		# @method copyMarked
		# Copies selected node label into clipboard.
		#<
		method copyMarked {}

		method show {it}
		method hide {it}
		method isOpen {node}
		method getNodeByText {text {startNode root}}
		method setNodeForeground {node color}
		method getChilds {it}
		method setButton {node button}
		method findNode {name {parent ""}}
	}
}

body Tree::constructor {args} {
	set _root $path
	set _tree $_root.t
	ttk::scrollbar $_root.s -command "$_tree yview" -orient vertical
	treectrl $_tree -showheader no -border 1 -showroot no -background $background_color -foreground $foreground_color -width 0 \
		-usetheme yes -yscrollcommand "$_root.s set" -font $font

	set _col [$_tree column create -expand 1 -text ""]
	set _datacol [$_tree column create -visible no]
	$_tree configure -treecolumn $_col

	$_tree element create	e_img image
	$_tree element create	e_txt text -fill [list $selected_foreground_color {selected focus} $selected_foreground_color {selected !focus}]
	$_tree element create	e_datatxt text -datatype string
	$_tree element create	e_sel_rect rect -fill [list $selected_background_color {selected focus} $selected_background_color {selected !focus}] -showfocus yes
	$_tree style create		s_item -orient horizontal
	$_tree style elements	s_item [list e_img e_sel_rect e_txt]
	$_tree style layout		s_item e_sel_rect -union [list e_txt] -ipadx 2 -ipady {0 1} -iexpand e -pady 2
	$_tree style layout		s_item e_img -padx 2 -pady 2
	$_tree style layout		s_item e_txt -expand e -pady 2
	$_tree style create		s_dataitem
	$_tree style elements	s_dataitem [list e_datatxt]

	pack $_tree -side left -fill both -expand 1
	pack $_root.s -side right -fill y
	autoscroll $_root.s

	bind $_tree <Button-$::RIGHT_BUTTON> "$this select %x %y"
	bind $_tree <<Copy>> "$this copyMarked"

	eval itk_initialize $args
}

body Tree::select {x y} {
	set it [$_tree item id "nearest $x $y"]
	setSelected $it
}

body Tree::setNodeForeground {node color} {
	$_tree item element configure $node 0 e_txt -fill $color
}

body Tree::setSelected {it} {
	if {$it == ""} return
	$_tree activate $it
	$_tree selection clear
	$_tree selection add $it
}

body Tree::getTree {} {
	return $_tree
}

body Tree::getScrollbar {} {
	return $_root.s
}

body Tree::addItem {parent img text {button false}} {
	set it [$_tree item create -button $button -visible yes -open false]
	$_tree item style set $it 0 s_item
	$_tree item element configure $it 0 e_img -image $img
	$_tree item element configure $it 0 e_txt -text $text
	$_tree item lastchild $parent $it
	$_tree item style set $it 1 s_dataitem
	$_tree item element configure $it 1 e_datatxt -data ""
	if {$parent != "root"} {
		$_tree item configure $parent -button true
	}
	return $it
}

body Tree::setButton {node button} {
	$_tree item configure $node -button $button
}

body Tree::sort {{it root}} {
	$_tree item sort $it -column 0 -element e_txt
}

body Tree::getText {node} {
	return [$_tree item element cget $node 0 e_txt -text]
}

body Tree::setText {node txt} {
	$_tree item element configure $node 0 e_txt -text $txt
}

body Tree::setData {node data} {
	$_tree item element configure $node 1 e_datatxt -data $data
}

body Tree::getData {node} {
	return [$_tree item element cget $node 1 e_datatxt -data]
}

body Tree::isOpen {node} {
	return [$_tree item isopen $node]
}

body Tree::delChilds {node} {
	set childs [$_tree item child $node]
	if {[llength $childs] > 0} {
		$_tree item delete [lindex $childs 0] [lindex $childs end]
	}
	$_tree item configure $node -button false
}

body Tree::delItem {node} {
	if {$node == "root"} {
		delChilds $node
		return
	}
	set parent [$_tree item parent $node]
	$_tree item delete $node
	set childs [$_tree item child $parent]
	if {[llength $childs] == 0} {
		$_tree item configure $parent -button false
	}
}

body Tree::delAll {} {
	$_tree item delete all
}

body Tree::expand {node {recursive false}} {
	if {$recursive} {
		$_tree item expand $node -recurse
	} else {
		$_tree item expand $node
	}
}

body Tree::updateUISettings {} {
	$_tree configure -background $background_color -foreground $foreground_color -font $font
	$_tree element configure e_txt -fill [list $selected_foreground_color {selected focus} $selected_foreground_color {selected !focus}]
	$_tree element configure e_sel_rect -fill [list $selected_background_color {selected focus} $selected_background_color {selected !focus}] -showfocus yes
	$_tree item configure all -height [font metrics TreeFont -linespace]
}

body Tree::getSelectedItem {} {
	set it [$_tree item id active]
	if {$it == "" || $it == 0} return
	return $it
}

body Tree::copyMarked {} {
	set it [getSelectedItem]
	if {$it == ""} return
	setClipboard [getText $it]
}

body Tree::show {it} {
	$_tree item configure $it -visible true
}

body Tree::hide {it} {
	$_tree item configure $it -visible false
}

body Tree::getChilds {it} {
	return [$_tree item children $it]
}

body Tree::reportNodeStatus {startNode} {
	set statusList [list [getText $startNode] [isOpen $startNode]]
	foreach child [getChilds $startNode] {
		lappend statusList [reportNodeStatus $child]
	}
	return $statusList
}

body Tree::applyNodeStatus {startNode status} {
	lassign $status name isopen
	if {[catch {getNodeByText $name $startNode} node]} {
		return
	}
	if {$node != ""} {
		if {$isopen} {
			$_tree item expand $node
		} else {
			$_tree item collapse $node
		}
	}

	foreach subStatus [lrange $status 2 end] {
		applyNodeStatus $node $subStatus
	}
}

body Tree::getNodeByText {text {startNode root}} {
	if {[string equal [getText $startNode] $text]} {
		return $startNode
	}
	foreach it [getChilds $startNode] {
		set node [getNodeByText $text $it]
		if {$node != ""} {
			return $node
		}
	}
	return ""
}

body Tree::findNode {name {parent ""}} {
	if {$parent == ""} {
		set parent root
	}
	set items [$_tree item children $parent]
	foreach it $items {
		if {[getText $it] eq $name} {
			return $it
		}
		set res [findNode $name $it]
		if {$res != ""} {
			return $res
		}
	}
	return ""
}
