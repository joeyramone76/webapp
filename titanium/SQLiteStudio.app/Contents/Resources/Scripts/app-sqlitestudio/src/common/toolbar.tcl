use src/common/ui.tcl
use src/common/panel.tcl

#>
# @class Toolbar
# Toolbar widget. It simplifies adding tool buttons, separators, other tool widgets,
# grouping them, allows to move groups by user to personalize toolbar.
# @example
# {set tb \[Toolbar .toolbar]}
# {}
# {\$tb addGroup grp1}
# {\$tb addButton some_image {Button hint} {button command 1}}
# {\$tb addButton other_image1 {Button hint 2} {button command 2}}
# {}
# {\$tb addGroup grp2}
# {\$tb addButton other_image2 {Other hint} {button command 3}}
# {\$tb addSeparator}
# {\$tb addButton other_image3 {Other hint 2} {button command 4}}
# {}
# {\$tb setConfigVar \"ToolbarOrderVariable\"}
# @endofexample
#<

class Toolbar {
	inherit Panel UI

	constructor {args} {
		eval Panel::constructor $args
	} {}

	private {
		method checkGrp {}
	}

	protected {
		variable _backgroundFrames [list]
		variable _cfgVar ""
		variable _cnt 0
		variable _move ""
		variable _widgets [list]
		variable _root ""
		variable _currentGrp ""
		variable _grpWidgets
		variable _order [list]
		method addWidget {w {tip ""}}
	}

	public {
		method addButton {img tip cmd}
		method addComboBox {tip readonly {values ""} {onChange ""}}
		method addLabel {text tip}
		method addEntry {tip textVariable}
		method addCheckButton {label tip variable}
		method addImageCheckButton {imgForSelected imgForDeselected tipForSelected tipForDeselected variable {on 1} {off 0} {cmd ""}}
		method addSeparator {}
		method addDoubleSeparator {}
		method setActive {state {id ""}}
		method isActive {id}
		method addGroup {name}
		method updateImgCbHint {w var on tip1 tip2}

		#>
		# @method setConfigVar
		# @param varName Name of variable to store toolbar order in.
		# Restores saved (under given variable name) order of groups in toolbar.
		# Any changes in order (moving groups) will be saved under the variable
		# since this method is called.<br><br>
		# <b>!!!IMPORTANT!!!</b> This method <b>must</b> be called just after all groups
		# are added to the toolbar (and group buttons/widgets are added too). Not earlier, not later.
		#<
		method setConfigVar {varName}
		method hide {grp}
		method show {grp}
		method getSpace {}
		method drag {X x grp}
		method drop {X x}
		method move {X x}
		method updateOrder {}

		#>
		# @method updateUISettings
		# @overloaded UI
		#<
		method updateUISettings {}
	}
}

body Toolbar::constructor {args} {
	pack [frame $path.tb] -fill x -side top
	set themedTb [getThemeSetting ${::ttk::currentTheme} toolbar use_themed_background]
	if {$themedTb} {
		set style Toolbutton
	} else {
		set style TFrame
	}
	set _root [ttk::frame $path.tb.tbframe -style $style]
	lappend _backgroundFrames $_root
	pack $_root -side top -fill x
	bind $_root <B1-Motion> "$this move %X %x"
	bind $_root <Leave> "$this drop %X %x"
}

body Toolbar::setConfigVar {varName} {
	set _cfgVar $varName

	if {[info exists $_cfgVar]} {
		# We don't use order that has invalid entries.
		# Use default order then. #1907
		if {[lsort [set $_cfgVar]] == [lsort $_order]} {
			set _order [set $_cfgVar]
			updateOrder
		}
	}
}

body Toolbar::updateOrder {} {
	if {[llength $_order] == 0} return
	set last [lindex $_order 0]
	pack $last -fill x -side left
	foreach w [lrange $_order 1 end] {
		pack $w -fill x -side left -after $last
		set last $w
	}
}

body Toolbar::addGroup {name} {
	set themedTb [getThemeSetting ${::ttk::currentTheme} toolbar use_themed_background]
	if {$themedTb} {
		set style Toolbutton
	} else {
		set style TFrame
	}
	lappend _backgroundFrames [ttk::frame $_root.grp_$name -style $style]
	set _currentGrp $name
	set _grpWidgets($name) [list]
	addDoubleSeparator
	show $name
	bind $_root.grp_$name <B1-Motion> "$this move %X %x"
	lappend _order $_root.grp_$name
	return $_root.grp_$name
}

body Toolbar::addButton {img tip cmd} {
	checkGrp
	set grp $_root.grp_$_currentGrp
	ttk::button $grp.w$_cnt -style Toolbutton -image $img -command $cmd -takefocus 0
	bind $grp.w$_cnt <B1-Motion> "$this move %X %x"
	return [addWidget $grp.w$_cnt $tip]
}

body Toolbar::addComboBox {tip readonly {values ""} {onChange ""}} {
	checkGrp
	set grp $_root.grp_$_currentGrp
	if {$readonly} {
		ttk::combobox $grp.w$_cnt -values $values -state readonly
	} else {
		ttk::combobox $grp.w$_cnt -values $values
	}
	bind $grp.w$_cnt <B1-Motion> "$this move %X %x"
	bind $grp.w$_cnt <<ComboboxSelected>> $onChange
	return [addWidget $grp.w$_cnt $tip]
}

body Toolbar::addEntry {tip textVariable} {
	checkGrp
	set grp $_root.grp_$_currentGrp
	ttk::entry $grp.w$_cnt -textvariable $textVariable
	return [addWidget $grp.w$_cnt $tip]
}

body Toolbar::addCheckButton {label tip variable} {
	checkGrp
	set grp $_root.grp_$_currentGrp
	ttk::checkbutton $grp.w$_cnt -text $label -variable $variable
	return [addWidget $grp.w$_cnt $tip]
}

body Toolbar::addImageCheckButton {imgForSelected imgForDeselected tipForSelected tipForDeselected variable {on 1} {off 0} {cmd ""}} {
	checkGrp
	set grp $_root.grp_$_currentGrp

	set command [list $this updateImgCbHint $grp.w$_cnt $variable $on $tipForSelected $tipForDeselected]
	if {$cmd != ""} {
		append command "; "
		append command $cmd
	}

	ImgCheckButton $grp.w$_cnt -onimage $imgForSelected -offimage $imgForDeselected -onvalue $on -offvalue $off \
		-command $command -variable $variable

	return [addWidget $grp.w$_cnt [expr {[set $variable] == $on ? $tipForSelected : $tipForDeselected}]]
}

body Toolbar::updateImgCbHint {w var on tip1 tip2} {
	if {[set $var] == $on} {
		cancelHelpHint $w $tip2
		helpHint $w $tip1
	} else {
		cancelHelpHint $w $tip1
		helpHint $w $tip2
	}
}

body Toolbar::addLabel {text tip} {
	checkGrp
	set grp $_root.grp_$_currentGrp
	ttk::label $grp.w$_cnt -style Toolbutton -text $text
	bind $grp.w$_cnt <B1-Motion> "$this move %X %x"
	return [addWidget $grp.w$_cnt $tip]
}

body Toolbar::addSeparator {} {
	checkGrp
	set padx [getThemeSetting ${::ttk::currentTheme} toolbar separator_padx]
	set grp $_root.grp_$_currentGrp
	pack [ttk::separator $grp.w$_cnt -orient vertical] -side left -fill y -pady 2 -padx $padx
	bind $grp.w$_cnt <B1-Motion> "$this move %X %x"
	incr _cnt
}

body Toolbar::addDoubleSeparator {} {
	checkGrp
	set grp $_root.grp_$_currentGrp
	set cur sb_h_double_arrow
	set themedTb [getThemeSetting ${::ttk::currentTheme} toolbar use_themed_background]
	if {$themedTb} {
		set style Toolbutton
	} else {
		set style TFrame
	}
	lappend [ttk::frame $grp.w$_cnt -height 3 -cursor $cur -style $style]
	ttk::separator $grp.w$_cnt.s1 -orient vertical -cursor $cur
	ttk::separator $grp.w$_cnt.s2 -orient vertical -cursor $cur
	pack $grp.w$_cnt -side left -padx 3 -fill y
	pack $grp.w$_cnt.s1 $grp.w$_cnt.s2 -side left -fill y -pady 2

	foreach w [list $grp.w$_cnt $grp.w$_cnt.s1 $grp.w$_cnt.s2] {
		bind $w <ButtonPress-1> "$this drag %X %x $grp"
		bind $w <ButtonRelease-1> "$this drop %X %x"
		bind $w <B1-Motion> "$this move %X %x"
	}

	incr _cnt
}

body Toolbar::drag {X x grp} {
	set _move $grp
	set newX [expr {$X-[winfo rootx $_root]-5}]
	place $_move -x $newX -y [expr {[winfo y $_root] - 1}]
}

body Toolbar::drop {X x} {
	if {$_move == ""} return

	set newX [expr {[winfo x $_move]+3}]

	set slaves [pack slaves $_root]

	set max 0
	foreach c $slaves {
		if {[string match "*maxbtns*" $c]} continue
		if {$c == $_move} continue
		incr max [winfo width $c]
	}

	if {$newX <= 3} {
		lremove _order $_move
		set grp [lindex $slaves 0]
		set _order [linsert $_order 0 $_move]
		if {$grp != ""} {
			pack $_move -fill x -side left -before $grp
		} else {
			pack $_move -fill x -side left
		}
		CfgWin::save [list $_cfgVar $_order]
		return
	} elseif {$max <= $newX} {
		lremove _order $_move
		set grp [lindex $slaves end]
		set _order [linsert $_order end $_move]
		if {$grp != ""} {
			pack $_move -fill x -side left -after $grp
		} else {
			pack $_move -fill x -side left
		}
		CfgWin::save [list $_cfgVar $_order]
		return
	}

	foreach c $slaves {
		if {[string match "*maxbtns*" $c]} continue
		if {$c == $_move} continue
		set start [winfo x $c]
		set end [expr {$start+[winfo width $c]}]
		if {$newX >= $start && $newX < $end} {
			set grp $c
			break
		}
		set start ""
		set end ""
		set overGrp ""
	}
	if {$start == "" || $end == ""} {
		set _move ""
		error "Internal critical error while dropping toolbar (1)."
	}

	set half [expr { ($end + $start) / 2 }]
	if {$newX < $half} {
		lremove _order $_move
		set idx [lsearch -exact $_order $grp]
		if {$idx == -1} {
			set _move ""
			error "Internal critical Error while moving toolbar (2)."
		}
		set _order [linsert $_order $idx $_move]
		pack $_move -fill x -side left -before $grp
		CfgWin::save [list $_cfgVar $_order]
	} elseif {$newX >= $half} {
		lremove _order $_move
		set idx [lsearch -exact $_order $grp]
		if {$idx == -1} {
			set _move ""
			error "Internal critical Error while moving toolbar (3)."
		}
		set _order [linsert $_order [expr {$idx+1}] $_move]
		pack $_move -fill x -side left -after $grp
		CfgWin::save [list $_cfgVar $_order]
	}
	set _move ""
}

body Toolbar::move {X x} {
	if {$_move == ""} return
	set newX [expr {$X-[winfo rootx $_root]-5}]
	place $_move -x $newX -y [expr {[winfo y $_root] - 1}]
	raise $_move
}

body Toolbar::checkGrp {} {
	if {$_currentGrp == ""} {
		addGroup default
	}
}

body Toolbar::addWidget {w {tip ""}} {
	set padx [getThemeSetting ${::ttk::currentTheme} toolbar button_padx]
	pack $w -side left -padx $padx;# -pady 2
	lappend _widgets $w
	lappend _grpWidgets($_currentGrp) $w
	bind $w <B1-Motion> "$this move %X %x"
	incr _cnt

	if {$tip != ""} {
		helpHint $w $tip
	}

	return $w
}

body Toolbar::setActive {state {id ""}} {
	set stat [expr {$state ? "!disabled" : "disabled"}]
	if {$id != ""} {
		if {$id in $_widgets} {
			$id state $stat
		} elseif {[info exists _grpWidgets($id)]} {
			foreach i $_grpWidgets($id) {
				$i state $stat
			}
		}
	} else {
		foreach i $_widgets {
			$i state $stat
		}
	}
}

body Toolbar::isActive {id} {
	if {$id in $_widgets} {
		return [expr {[$id state] != "disabled"}]
	} else {
		return false
	}
}

body Toolbar::hide {grp} {
	pack forget $_root.grp_$grp
}

body Toolbar::show {grp} {
	set myIdx [lsearch -exact $_order $_root.grp_$grp]
	set slaves [pack slaves $_root]

	set after ""
	set before ""

	# Lets find closest group packed before current group
	foreach g [lreverse [lrange $_order 0 [expr {$myIdx-1}]]] {
		set idx [lsearch -exact $slaves $g]
		if {$idx > -1} {
			set after $g
			break
		}
	}

	# Lets find closest group packed after current group
	foreach g [lrange $_order [expr {$myIdx+1}] end] {
		set idx [lsearch -exact $slaves $g]
		if {$idx > -1} {
			set before $g
			break
		}
	}

	eval pack $_root.grp_$grp -fill x -side left \
		[expr {$before != "" ? "-before $before" : ""}] \
		[expr {$after != "" ? "-after $after" : ""}]
}

body Toolbar::getSpace {} {
	return $_root
}

body Toolbar::updateUISettings {} {
	set themedTb [getThemeSetting ${::ttk::currentTheme} toolbar use_themed_background]
	if {$themedTb} {
		set style Toolbutton
	} else {
		set style TFrame
	}
	foreach f $_backgroundFrames {
		$f configure -style $style
	}
}
