use src/common/window.tcl

#>
# @class HintWin
# Implementation of hint window that helps user to choose one option
# from the list. It's used in {@class SQLEditor} to list available
# tables/columns/sql_keywords at the moment context.
# <br>
# TODO: Remove sqlEditor dependency and move it to derived class,
# so HintWin would be clear to use with any text widget.
#<
class HintWin {
	inherit Window

	#>
	# @method constructor
	# @param parent Path to parent widget. It has to be <code>text</code> widget, or widget inheriting from it, or any other widget that implements 2 simple commands from <code>text</code> widget: <code>insert</code> and <code>delete</code>.
	# @param sqlEditor Instance of {@class SQLEditor} that need completion rom hint window.
	# @param completionList Prepared list of elements for completion.
	# @param x X-coordinate of top-left corner of the widget.
	# @param y Y-coordinate of top-left corner of the widget.
	# Creates widget and shows it up at given coordinates.
	#<
	constructor {parent sqlEditor completionList {x ""} {y ""} {delay ""}} {}

	#>
	# @method destructor
	# Hides widget and destroys it, then gives focus back to parent widget.
	#<
	destructor {}

	private {
		common _seq 0

		#>
		# @var _tree
		# Reference to <b>TkTreeCtrl</b> widget that is used to display options list.
		#<
		variable _tree ""

		#>
		# @var _parent
		# Keeps parent given in {@method constructor} to use it in {@method destructor}.
		#<
		variable _parent ""

		#>
		# @var _leave
		# Keeps number of characters to replace with choosen option that are befor insertion cursor.
		# @see method leaveChars
		#<
		variable _leave 0

		#>
		# @var _validKeys
		# List of key-translation pairs that are valid to edit on-the-fly completion expression.
		# User is allowed to type characters like a-zA-Z0-9, underline '_', etc.<br>
		# Each odd value will be translated to its parallel even value.
		#<
		final common _validKeys [list underscore _ minus - comma , period .]

		#>
		# @var _sqlEditor
		# {@var SQLEditor} parent object.
		#<
		variable _sqlEditor ""

		variable _completionList [list]

		variable _busyLabel ""

		#>
		# @method updateHint
		# @param initial Boolean value defining if this is initial dialog creation call.
		# Updates hint window position to current editor insertion cursor position and completion list
		# to current expression in editor.
		#<
		method updateHint {{initial false}}
	}

	public {
		#>
		# @method addRow
		# @param type Row type. Can be one of: <code>table, view, column, keyword, database</code>. Choosen type determinates a way the row is rendered like.
		# @param name Name of the row. It's visible part of row, next to its icon. It's kind of the row label.
		# @param data Any kind of data linked with the row.
		# @param label Additional info label.
		# Adds new row to options list that can be choosen by a user. After user choose the option, liked data will be inserted in parent widget.
		#<
		method addRow {type name data label}

		#>
		# @method choosen
		# It's called whenever user chooses one of options. It does the whole job with inserting choosen option to parent widget and destroying this widget.
		#<
		method choosen {}

		#>
		# @method cancel
		# It's called when the widget loses input focus or user pushes <b>Escape</b> button. It just destroys this widget, nothing more.
		#<
		method cancel {}

		#>
		# @method activateFirst
		# It's called to select first option from the list. It's done by external code, because all options has to be added by {@method addRow}
		# and then this method should be called. It lets user to control options selection by a keyboard input.
		#<
		method activateFirst {}

		#>
		# @method leaveChars
		# @param cnt Number of characters to replace in parent widget.
		# Sets {@var _leave} to a number given in parameter.<br>
		# It's useful when user has typed a couple of characters first, then invokes this widget to help him finish the job.
		# It that case you have to call this method with number of characters that user has typed before, so choosen option will
		# not be appended to old (typed by user) characters, but will replace them.
		#<
		method leaveChars {cnt}

		#>
		# @method keyPressed
		# @param k Character(s) of pressed key.
		# Handler for on-the-fly expression typing, so hint window is updated to new expression (user is able
		# to invoke hint window and then update completion expression to make completion list shorter/longer).
		# <br>
		# TODO: This method should be in derived class. HintWin should be clear for usage with any text widget.
		#<
		method keyPressed {k}

		#>
		# @method clear
		# Clears all entries in completion list.
		#<
		method clear {}
		
		method show {}
		method goto {where}
		method startAnimation {}

		#>
		# @method create
		# @param parent See {@method constructor}.
		# @param sqlEditor Instance of {@class SQLEditor} that need completion rom hint window.
		# @param completionList Prepared list of elements for completion. If it's empty, then "busy" state will be displayed, until [updateList] is called.
		# @param x See {@method constructor}.
		# @param y See {@method constructor}.
		# It's a shortcut to create instances of this class. It simply creates object with given parameters.
		# It lets developer to forget about naming <code>HintWindow</code> object (even with <code>#auto</code>).
		# He has to simply call this method and get result as an object to operate on.<br>
		# It's also a framework for future so something can be done on this level, before/after object is created.
		# @return Created instance of this class.
		#<
		proc create {parent sqlEditor completionList {x ""} {y ""} {delay ""}}

		method updateList {completionList}
	}
}

body HintWin::create {parent sqlEditor completionList {x ""} {y ""} {delay ""}} {
	incr _seq
	HintWin .hint$_seq $parent $sqlEditor $completionList $x $y $delay
	return .hint$_seq
}

body HintWin::constructor {parent sqlEditor completionList {x ""} {y ""} {delay ""}} {
	wm withdraw $path
	set _parent $parent
	set _sqlEditor $sqlEditor
	set _completionList $completionList
	if {[tk windowingsystem] eq "aqua"} {
		::tk::unsupported::MacWindowStyle style $path help none
	} else {
		wm overrideredirect $path 1
	}
	wm positionfrom $path program
	update idletasks

	set _tree [HintWinTree $path.tree]
	[$_tree getTree] configure -width 240 -height 120 -border 0 -showlines 0 -indent 0 -itemheight 20 -highlightthickness 0

	if {$x != "" || $y != ""} {
		if {$x == ""} {
			set x 0
		}
		if {$y == ""} {
			set y 0
		}
		wm geometry $path +$x+$y
	}
	update idletasks

	$path configure -background black
	pack $path.tree -fill both -padx 1 -pady 1

	bind $path <Return> "$this choosen"
	bind $path <Escape> "$this cancel"
	bind $path <Double-Button-1> "$this choosen"
	bind $path.tree.t <FocusOut> "$this cancel"
	bind $path <$::Shortcuts::editorComplete> "break"
	bind $path <Any-Key> "$this keyPressed %K"

	if {[llength $completionList] > 0} {
		show
		updateHint true
	} else {
		if {$delay != ""} {
			after $delay [list catch [list $this show]]
		} else {
			show
		}

		set _busyLabel [label $path.tree.l -image "" -background white]
		place $_busyLabel -x 100 -y 40
		after 300 [list catch [list $this startAnimation]]
	}
}

body HintWin::destructor {} {
	catch {
		focus -force $_parent ;# window manager gets lost if there's no "-force" here
	} ;# catched, because parent window might not exist anymore
}

body HintWin::startAnimation {} {
	playAnim 50 $_busyLabel $::animated(loading)
}

body HintWin::updateList {completionList} {
	set _completionList $completionList
	place forget $_busyLabel
	updateHint true
}

body HintWin::show {} {
	wm deiconify $path
	wm transient $path $_parent
	raise $path
	focus $path.tree.t
}

body HintWin::addRow {type name data label} {
	switch -- $type {
		"table" {
			set img img_table
		}
		"view" {
			set img img_view
		}
		"column" {
			set img img_column
		}
		"keyword" {
			set img img_word
		}
		"function" {
			set img img_function
		}
		"database" {
			set img img_database
		}
		"index" {
			set img img_index
		}
		"trigger" {
			set img img_trigger
		}
		"view" {
			set img img_view
		}
		default {
			error "Unknown row type: $type"
		}
	}

	set it [$_tree addItem root $img $name no $label]
	$_tree setData $it $data
}

body HintWin::choosen {} {
	set data [$_tree getData active]
	$_parent delete "insert -$_leave chars" insert
	$_parent insert insert $data
	$_sqlEditor delayParserRun
	destroy $path
}

body HintWin::cancel {} {
	destroy $path
}

body HintWin::activateFirst {} {
	set first [$path.tree.t index "first visible"]
	if {$first == ""} {
		return
	}
	$path.tree.t selection clear
	$path.tree.t activate $first
	$path.tree.t selection add $first
}

body HintWin::leaveChars {cnt} {
	set _leave $cnt
}

body HintWin::keyPressed {k} {
	set k [string map $_validKeys $k]
	if {[regexp {^[a-zA-Z0-9,\._\-]{1}$} $k]} {
		$_parent insert insert $k
		updateHint
	} else {
		switch -- $k {
			"BackSpace" {
				set c [$_parent get "insert - 1 chars" "insert"]
				$_parent delete "insert - 1 chars" "insert"
				if {[string length [string trim $c]] == 0} {
					cancel
					return
				} else {
					updateHint true
				}
			}
			"space" {
				$_parent insert insert " "
				cancel
			}
			"Right" {
				$_parent mark set insert [$_parent index "insert +1 chars"]
				updateHint
			}
			"Left" {
				$_parent mark set insert [$_parent index "insert -1 chars"]
				updateHint
			}
		}
	}
}

body HintWin::updateHint {{initial false}} {
	clear
	set partialValueDict [$_sqlEditor getCurrentTokenPartialValue $initial]
	if {[dict get $partialValueDict returnCode] != 0} {
		cancel
		return
	}
	set partialValue [dict get $partialValueDict value]
	set partialSize [string length $partialValue]
	set completionList [$_sqlEditor filterCompletionList $_completionList $partialValueDict]

	if {[llength $completionList] == 0} {
		cancel
		return
	}

	set coords [$_sqlEditor getHintPos]
	if {[llength $coords] < 2} {
		cancel
		return
	}

	foreach it $completionList {
		lassign $it img el data label
		#puts "x: $img $el $data $label"
		addRow $img $el $data $label
	}

	leaveChars $partialSize
	activateFirst
	lassign $coords x y
	wm geometry $path +$x+$y

}

body HintWin::clear {} {
	$_tree delChilds root
}
