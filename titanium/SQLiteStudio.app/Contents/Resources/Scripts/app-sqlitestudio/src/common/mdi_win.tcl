use src/common/session.tcl
use src/common/signal.tcl
use src/common/UI.tcl
use src/common/leaking_stack.tcl

#>
# @class MDIWin
# Base class for all MDI windows. It takes care of all aspects
# related to windowing system, such as maximizing, resizing, moving,
# closing, etc. Can't (and shouldn't) be created by itself - it needs
# to by extended by another class.
#<
class MDIWin {
	inherit Session UI Signal

	#>
	# @method constructor
	# @param title Window title (displayed on top border).
	# @param img Image used for window icon (displayed in top left corner of window and on taskbar).
	# Creates Window, its title border, binds shortcuts and restores maximized/normalized state from configuration.
	# Also calls {@method TaskBar::addTask} to add window to tasks list.<br><br>
	# As you can guess - proper way to create window-task pairs is to create MDIWin-extended class instance
	# and it will take care about everything.
	#<
	constructor {title {img "img_window"}} {}

	#>
	# @method destructor
	# Destroys MDI window and removes it from tasks list.
	#<
	destructor {}

	#>
	# @var borderBackground
	# Configuration variable.
	# It's background color of title border.
	#<
	common borderBackground #000099

	#>
	# @var borderForeground
	# Configuration variable.
	# It's foreground color of title border.
	#<
	common borderForeground white

	#>
	# @var borderButtonBackground
	# Configuration variable.
	# It's background color of title border buttons.
	#<
	common borderButtonBackground #7777CC

	#>
	# @var borderButtonActiveBackground
	# Configuration variable.
	# It's background color of active title border buttons.
	#<
	common borderButtonActiveBackground #9999DD

	#>
	# @var createY
	# Default X-coordinate of each newly created MDI window.
	#<
	common createX 0

	#>
	# @var createY
	# Default Y-coordinate of each newly created MDI window.
	#<
	common createY 0

	#>
	# @var createY
	# Default width of each newly created MDI window.
	#<
	final common createW 600

	#>
	# @var createY
	# Default height of each newly created MDI window.
	#<
	final common createH 500

	#>
	# @var createY
	#<
	final common nextWinIncr 22

	#>
	# @var activatedLately
	# Used for protection against 'focus fighting'.
	#<
	common activatedLately 0
	
	protected {
		#>
		# @var mdimode
		# Contains current mode of all MDI windows, that can be:<br>
		# <ul>
		# <li><code>NORMAL</code>,
		# <li><code>MAXIMIZED</code>
		# </ul>
		#<
		# TODO: write configscript to handle setting this variable to change mdimode on the fly.
		common mdimode "NORMAL"

		#>
		# @var wins
		# List of all existing MDI window objects.
		#<
		common wins [list]

		#>
		# @var currentPacked
		# Contains MDIWin object that is currently packed in <code>MAXIMIZED</code> mode.
		#<
		common currentPacked ""

		common recentlyClosedWindows [LeakingStack ::#auto 20]

		#>
		# @var normalModeCoords
		# Coordinates (x, y, width, height) of window in <code>NORMAL</code> mode.
		#<
		variable normalModeCoords [list]

		#>
		# @var qx
		# Current X coordinate of top-left window corner.
		#<
		variable qx

		#>
		# @var qy
		# Current Y coordinate of top-left window corner.
		#<
		variable qy

		#>
		# @var qw
		# Current window width.
		#<
		variable qw

		#>
		# @var qh
		# Current window height.
		#<
		variable qh

		#>
		# @var nx
		# Pointer X coordinate.
		# It's helper variable used while moving window in <code>NORMAL</code> mode.
		#<
		variable nx

		#>
		# @var nx
		# Pointer Y coordinate.
		# It's helper variable used while moving window in <code>NORMAL</code> mode.
		#<
		variable ny

		#>
		# @var minWidth
		# Minimal width of MDI windows.
		# It's kind of constraint, not configurable by UI.
		#<
		final common minWidth 100

		#>
		# @var minHeight
		# Minimal height of MDI windows.
		# It's kind of constraint, not configurable by UI.
		#<
		final common minHeight 100

		#>
		# @method setMaximized
		# Switches window to <code>MAXIMIZED</code> mode. Only this one, local window.
		#<
		method setMaximized {}

		#>
		# @method setNormal
		# Switches window to <code>NORMAL</code> mode. Only this one, local window.
		#<
		method setNormal {}

		#>
		# @method packForget
		# Calls <code>pack forget</code> on {@var _root} to make window disappear in case when it's packed.
		# It makes sense only in case when current window object is value of {@var currentPacked}.<br>
		# It's used in <code>MAXIMIZED</code> mode to switch from one window to another.
		#<
		method packForget {}
		method placeForget {}

		method updateGeometry {}

		#>
		# @var _root
		# Root panel. Window is built on to of it.
		#<
		variable _root ""

		#>
		# @var _title
		# Title of window.
		#<
		variable _title ""

		variable _image ""

		#>
		# @var _main
		# Working area panel. Classes that extends <code>MDIWin</code> can place their widgets
		# on this panel.
		#<
		variable _main ""

		variable _resizeMode ""
	}

	public {
		#>
		# @method closeButtonPressed
		# Destroys MDI window object. It's called by pressing <i>Close</i> button on top-right window corner.
		#<
		method closeButtonPressed {}

		#>
		# @method minmaxButtonPressed
		# Switches mode of all MDI windows - from <code>NORMAL</code> to <code>MAXIMIZED</code> and vice-versa.<br>
		# It's called by pressing <i>Close</i> button on top-right window corner.
		#<
		method minmaxButtonPressed {}

		#>
		# @method changeTitle
		# @param title New title to set.
		# Changes window title text to given one.
		#<
		method changeTitle {title}

		#>
		# @method resizeStart
		# @param x X coordinate of mouse pointer when the event happens.
		# @param y Y coordinate of mouse pointer when the event happens.
		# Called when window begins to be resized by application user.
		#<
		method resizeStart {x y}

		#>
		# @method resizeDo
		# @param x X coordinate of mouse pointer when the event happens.
		# @param y Y coordinate of mouse pointer when the event happens.
		# It's called each time when mouse pointer moves across MDI area keeping <i>Button-1</i>
		# pressed after {@method resizeStart} was called.
		# Passed coordinates tells a way that the window was resized in.
		#<
		method resizeDo {x y}

		#>
		# @method moveStart
		# Called when window begins to be moved by application user.
		#<
		method moveStart {}

		#>
		# @method moveDo
		# Called when mouse pointer moves across MDI area with <i>Button-1</i> pressed on window title.
		#<
		method moveDo {}

		#>
		# @method moveStop
		# Called when user stops moving window (releases <i>Button-1</i>). Remembers window coordinates
		# in {@var normalModeCoords}.
		#<
		method moveStop {}

		#>
		# @method checkCursor
		# @param x X coordinates of mouse pointer.
		# @param y Y coordinates of mouse pointer.
		# Called always when mouse pointer is moved over window border.
		#<
		method checkCursor {x y}

		#>
		# @method setGeoms
		# @param x X coordinate of top-left corner of the window.
		# @param y Y coordinate of top-left corner of the window.
		# @param w Width of the window.
		# @param h Height of the window.
		#<
		method setGeoms {x y {w ""} {h ""}}
		method getGeoms {}

		#>
		# @method refreshWindowPlacement
		# Updates window placement. In <code>NORMAL</code> mode - places window in last saved coordinates,
		# resizes it to last saved size. In <code>MAXIMIZED</code> makes sure, then {@var currentPacked}
		# window is really currently packed.
		#<
		method refreshWindowPlacement {}

		#>
		# @method getTitle
		# @return Window title. It's exactly {@var _title}.
		#<
		method getTitle {}
		method getImage {}
		method getRoot {}

		#>
		# @method updateUISettings
		# @overloaded UI
		#<
		method updateUISettings {}

		#>
		# @method raiseWindow
		# In <code>NORMAL</code> raises window to top of windows stack. Does nothing in <code>MAXIMIZED</code> mode.
		#<
		method raiseWindow {}

		method focusWithDelay {}
		method canDestroy {}
		method destroyWithDelay {}
		method isAt {x y}
		proc isNormalMode {}
		proc getWinFor {x y}

		#>
		# @method activated
		# It's called always when window is activated - no matter if it's done by click on {@class TaskBar} or
		# any part of the window, but window has to be covered by some other window to call this method.<br><br>
		# Derived class can do here whatever it wants. Usually it's used to give keyboard focus to some widget
		# inside of the window.
		#<
		abstract method activated {}

		#>
		# @method saveWinMode
		# Saves current window MDI mode (<code>MAXIMIZED</code> or <code>NORMAL</code>) in configuration file
		# to restore it on next start.
		#<
		proc saveWinMode {}

		#>
		# @method cascadeWins
		# Arranges all windows coordinates and sizes in <i>Cascade</i> mode. Windows are switched to <code>NORMAL</code>
		# mode (if needed) and placed one by one from top-left corner to bottom-right.
		#<
		proc cascadeWins {}

		#>
		# @method intellWins
		# Arranges all windows coordinates and sizes in <i>Intelligent</i> mode. Windows are switched to <code>NORMAL</code>
		# mode (if needed), placed one next to another (optionally in numerous rows) and resized to fit whole MDI area.
		#<
		proc intellWins {}

		#>
		# @method maximizedCloseButtonPressed
		# Called when close button is pressed in <code>MAXIMIZED</code> mode (it's different button than standard one,
		# and needs other implementation).
		#<
		proc maximizedCloseButtonPressed {}

		#>
		# @method maximizedMinButtonPressed
		# Called when minimize button is pressed in <code>MAXIMIZED</code> mode (it's different button than standard one,
		# and needs other implementation).
		#<
		proc maximizedMinButtonPressed {}
		
		proc restoreLastClosedWindow {}
		method rememberClosedWindow {}

		proc init {}
	}
}

body MDIWin::constructor {title {img "img_window"}} {
	set _root [MAIN getNewWin]
	set _title $title
	set _image $img
	frame $_root -borderwidth 2 -relief ridge
	frame $_root.top -background $borderBackground -cursor "left_ptr"
	pack $_root.top -side top -fill x
	label $_root.top.img -image $img -background $borderBackground
	pack $_root.top.img -side left -padx 2
	label $_root.top.l -text $title -foreground $borderForeground -background $borderBackground
	pack $_root.top.l -side left
	if {$mdimode == "NORMAL"} {
		set minmax_img img_maximize_win
	} else {
		set minmax_img img_normal_win
	}
	button $_root.top.close -image img_close_win -command "$this closeButtonPressed" -border 0 -highlightthickness 0 \
		-background $borderButtonBackground -activebackground $borderButtonActiveBackground
	pack $_root.top.close -side right -padx 1 -pady 1
	button $_root.top.minmax -image $minmax_img -command "$this minmaxButtonPressed" -border 0 -highlightthickness 0 \
		-background $borderButtonBackground -activebackground $borderButtonActiveBackground
	pack $_root.top.minmax -side right -padx 1 -pady 1
	bind $_root.top <Double-Button-1> "$this minmaxButtonPressed"
	bind $_root.top.l <Double-Button-1> "$this minmaxButtonPressed"
	bind $_root.top.img <Double-Button-1> "$this closeButtonPressed"

	set _main [ttk::frame $_root.main -cursor "left_ptr"]
	pack $_main -side bottom -fill both -expand 1

	bind $_root.top <1> [list $this moveStart]
	bind $_root.top <B1-Motion> [list $this moveDo]
	bind $_root.top <ButtonRelease-1> [list $this moveStop]

	bind $_root.top.l <1> [list $this moveStart]
	bind $_root.top.l <B1-Motion> [list $this moveDo]
	bind $_root.top.l <ButtonRelease-1> [list $this moveStop]

	bind $_root.top.img <1> [list $this moveStart]
	bind $_root.top.img <B1-Motion> [list $this moveDo]
	bind $_root.top.img <ButtonRelease-1> [list $this moveStop]

	bind $_root <1> [list $this resizeStart %x %y]
	bind $_root <B1-Motion> [list $this resizeDo %x %y]
	bind $_root <Motion> [list $this checkCursor %x %y]
	if {$::tcl_platform(platform) == "windows"} {
		# Workaround for windows problem #965
		bind $_main <Leave> [list $this checkCursor %x %y]
	}
	bind $_root <FocusIn> [list $this focusWithDelay]

	if {$mdimode == "NORMAL"} {
		set x $createX
		set y $createY
		set w $createW
		set h $createH
		set p [winfo parent $_root]
		set par_w [winfo width $p]
		set par_h [winfo height $p]

		if {[expr {$x+$w}] > $par_w} {
			if {$x > 0} {
				set createX 0
				set x 0
				if {$w > $par_w} {
					set w $par_w
				}
			} else {
				set w $par_w
			}
		}

		if {[expr {$y+$h}] > $par_h} {
			if {$y > 0} {
				set createY 0
				set y 0
				if {$h > $par_h} {
					set h $par_h
				}
			} else {
				set h $par_h
			}
		}

		place $_root -x $x -y $y -width $w -height $h
		MAIN setMaxBtnsVisible false
	} else {
		setMaximized
		MAIN setMaxBtnsVisible true
	}
	set normalModeCoords [list $createX $createY $createW $createH]
	incr createX $nextWinIncr
	incr createY $nextWinIncr

	lappend wins $this
}

body MDIWin::destructor {} {
	lremove wins $this
	if {[llength $wins] == 0} {
		MAIN setMaxBtnsVisible false
	}
	if {$currentPacked == $this} {
		set currentPacked ""
	}
	destroy $_root
}

body MDIWin::focusWithDelay {} {
	set title [getTitle]
	if {[TASKBAR taskExists $title]} {
		TASKBAR select $title
	}

	# Code below is no longer necessary, because of switch from [update] to [update idletasks].
	# Keeping it here, cause new solution is not well tested yet and might be still usable.
	# 10ms delay for protection against "focus fight" with Grid commitEdit
	#TASKBAR selectWithDelay 10 [getTitle]
}

body MDIWin::updateGeometry {} {
	if {$mdimode == "NORMAL"} {
		#update
		set info [place info $_root]
		set qx [dict get $info -x]
		set qy [dict get $info -y]
		set qw [winfo width $_root]
		set qh [winfo height $_root]
	} else {
		lassign [list 0 0 0 0] qx qy qw qh
	}
}

body MDIWin::closeButtonPressed {} {
	TASKBAR closeTaskByWinObj $this
}

body MDIWin::refreshWindowPlacement {} {
	if {$mdimode == "NORMAL"} {
		place $_root -x [lindex $normalModeCoords 0] -y [lindex $normalModeCoords 1] \
			-width [lindex $normalModeCoords 2] -height [lindex $normalModeCoords 3]
	}
}

body MDIWin::minmaxButtonPressed {} {
	if {$mdimode == "NORMAL"} {
		foreach win $wins {
			$win setMaximized
		}
		MAIN setMaxBtnsVisible true
		TASKBAR select $_title
	} else {
		foreach win $wins {
			$win setNormal
		}
		MAIN setMaxBtnsVisible false
	}
}

body MDIWin::maximizedCloseButtonPressed {} {
	TASKBAR closeSelectedTask
}

body MDIWin::maximizedMinButtonPressed {} {
	if {$mdimode == "NORMAL"} return
	foreach win $wins {
		$win setNormal
	}
	MAIN setMaxBtnsVisible false
}

body MDIWin::getTitle {} {
	return $_title
}

body MDIWin::getImage {} {
	return $_image
}

body MDIWin::getRoot {} {
	return $_root
}

body MDIWin::setMaximized {} {
	set mdimode "MAXIMIZE"
	set minmax_img img_normal_win
	set size [MAIN getWinAreaSize]
	set qx [winfo x $_root]
	set qy [winfo y $_root]
	set qw [winfo width $_root]
	set qh [winfo height $_root]
	set normalModeCoords [list $qx $qy $qw $qh]
	place forget $_root
	pack forget $_root.top
	if {$currentPacked == $this} {
		pack $_root -side top -fill both -expand 1
		MAIN setSubTitle $_title
	}
	$_root configure -borderwidth 0
	refreshWindowPlacement
	saveWinMode
}

body MDIWin::setNormal {} {
	set mdimode "NORMAL"
	if {$currentPacked == $this} {
		pack forget $_root
	}
	place $_root -x [lindex $normalModeCoords 0] -y [lindex $normalModeCoords 1] \
		-width [lindex $normalModeCoords 2] -height [lindex $normalModeCoords 3]
	$_root.top.minmax configure -image img_maximize_win
	pack $_root.top -side top -fill x
	$_root configure -borderwidth 2
	MAIN setSubTitle ""
	refreshWindowPlacement
	saveWinMode
}

body MDIWin::setGeoms {x y {w ""} {h ""}} {
	if {$w == ""} {
		set w [lindex $normalModeCoords 2]
	}
	if {$h == ""} {
		set h [lindex $normalModeCoords 3]
	}
	set normalModeCoords [list $x $y $w $h]
# 	if {$mdimode == "NORMAL"} {
# 		place $_root -x [lindex $normalModeCoords 0] -y [lindex $normalModeCoords 1] \
# 			-width [lindex $normalModeCoords 2] -height [lindex $normalModeCoords 3]
# 	}
	refreshWindowPlacement
}

body MDIWin::getGeoms {} {
	return $normalModeCoords
}

body MDIWin::changeTitle {title} {
	TASKBAR renameTask $_title $title
	set _title $title
	$_root.top.l configure -text $_title
	if {$mdimode == "MAXIMIZE"} {
		MAIN setSubTitle $_title
	}
}

body MDIWin::resizeStart {x y} {
	if {$mdimode != "NORMAL"} return
	if {$_resizeMode == ""} return

	set qx $x
	set qy $y
	set qw [winfo width $_root]
	set qh [winfo height $_root]
}

body MDIWin::resizeDo {x y} {
	if {$mdimode != "NORMAL"} return
	if {$_resizeMode == ""} return
	if {![info exists qx]} return ;# not risizing, just Motion-1 by moving toolbar, or similar
	set dqx [expr {$x-$qx}]
	set dqy [expr {$y-$qy}]
	set cx [winfo x $_root]
	set cy [winfo y $_root]
	switch -- $_resizeMode {
		br {
			set new_w [expr {$qw+$dqx}]
			set new_h [expr {$qh+$dqy}]
			if {$new_w >= $minWidth} {place $_root -width $new_w}
			if {$new_h >= $minHeight} {place $_root -height $new_h}
		}
		tl {
			set qw [winfo width $_root]
			set qh [winfo height $_root]
			incr cx $dqx
			incr cy $dqy

			set new_w [expr {$qw-$dqx}]
			set new_h [expr {$qh-$dqy}]
			if {$new_w >= $minWidth} {place $_root -width $new_w -x $cx}
			if {$new_h >= $minHeight} {place $_root -height $new_h -y $cy}
		}
		tr {
			set qh [winfo height $_root]
			incr cy $dqy

			set new_w [expr {$qw+$dqx}]
			set new_h [expr {$qh-$dqy}]
			if {$new_w >= $minWidth} {place $_root -width $new_w -x $cx}
			if {$new_h >= $minHeight} {place $_root -height $new_h -y $cy}
		}
		bl {
			set qw [winfo width $_root]
			incr cx $dqx

			set new_w [expr {$qw-$dqx}]
			set new_h [expr {$qh+$dqy}]
			if {$new_w >= $minWidth} {place $_root -width $new_w -x $cx}
			if {$new_h >= $minHeight} {place $_root -height $new_h -y $cy}
		}
		l {
			set qw [winfo width $_root]
			incr cx $dqx
			set new_w [expr {$qw-$dqx}]
			if {$new_w >= $minWidth} {place $_root -width $new_w -x $cx}
		}
		r {
			set new_w [expr {$qw+$dqx}]
			if {$new_w >= $minWidth} {place $_root -width $new_w -x $cx}
		}
		t {
			set qh [winfo height $_root]
			incr cy $dqy

			set new_h [expr {$qh-$dqy}]
			if {$new_h >= $minHeight} {place $_root -height $new_h -y $cy}
		}
		b {
			set new_h [expr {$qh+$dqy}]
			if {$new_h >= $minHeight} {place $_root -height $new_h}
		}
	}
}

body MDIWin::moveStart {} {
	if {$mdimode != "NORMAL"} return
	if {![winfo exists $_root]} return
	set nx [winfo pointerx .]
	set ny [winfo pointery .]
	TASKBAR select [getTitle]
	raise $_root
}

body MDIWin::moveDo {} {
	if {$mdimode != "NORMAL"} return
	if {![winfo exists $_root]} return
	if {![info exists nx]} return ;# BUGFIX #921
	set x [winfo pointerx .]
	set y [winfo pointery .]
	set dx [expr {$x-$nx}]
	set dy [expr {$y-$ny}]
	array set p [place info $_root]
	set px [expr {$p(-x)+$dx}]
	set py [expr {$p(-y)+$dy}]
	place $_root -x $px -y $py
	set nx $x
	set ny $y
}

body MDIWin::moveStop {} {
	if {$mdimode != "NORMAL"} return
	if {![winfo exists $_root]} return
	set x [winfo x $_root]
	set y [winfo y $_root]
	set normalModeCoords [list $x $y [lindex $normalModeCoords 2] [lindex $normalModeCoords 3]]
}

body MDIWin::checkCursor {x y} {
	if {$mdimode != "NORMAL"} return
	set q 10
	set c ""
	set w [winfo width $_root]
	set h [winfo height $_root]
	set _resizeMode ""
	if {[expr {$w-$x}] <= $q && [expr {$h-$y}] <= $q} {

		# Right-bottom corner
		set c bottom_right_corner
		set _resizeMode br

	} elseif {$x <= $q && $y <= $q} {

		# Left-top corner
		set c top_left_corner
		set _resizeMode tl

	} elseif {$x <= $q && [expr {$h-$y}] <= $q} {

		# Left-bottom corner
		set c bottom_left_corner
		set _resizeMode bl

	} elseif {[expr {$w-$x}] <= $q && $y <= $q} {

		# Right-top corner
		set c top_right_corner
		set _resizeMode tr

	} elseif {[expr {$h-$y}] <= 3} {

		# Bottom side
		set c sb_v_double_arrow
		set _resizeMode b

	} elseif {$y <= 3} {

		# Top side
		set c sb_v_double_arrow
		set _resizeMode t

	} elseif {[expr {$w-$x}] <= 3} {

		# Right side
		set c sb_h_double_arrow
		set _resizeMode r

	} elseif {$x <= 3} {

		# Left side
		set c sb_h_double_arrow
		set _resizeMode l

	} else {

		set c ""
		set _resizeMode ""

	}
	$_root configure -cursor $c
}

body MDIWin::saveWinMode {} {
	CfgWin::save [list ::MDIWin::mdimode ${::MDIWin::mdimode}]
}

body MDIWin::cascadeWins {} {
	set x 0
	set y 0
	set parent [join [lrange [split [MAIN getNewWin] .] 0 end-1] .]
	set W [winfo width $parent]
	set H [winfo height $parent]
	foreach win $wins {
		$win setNormal
		set w [expr {$W-$x}]
		set h [expr {$H-$y}]
		$win setGeoms $x $y $w $h
		incr x $nextWinIncr
		incr y $nextWinIncr
		if {$x >= $W} {
			set x 0
		}
		if {$y >= $H} {
			set x 0
		}
	}
	MAIN setMaxBtnsVisible false
}

body MDIWin::intellWins {} {
	set minWd 120					;# Minimal window width
	set minHg 80					;# Minimal window height
	set cnt [llength $wins]			;# Number of windows
	set size [MAIN getWinAreaSize]	;# Size of MDI area
	set mainWd [lindex $size 0]		;# MDI area width
	set mainHg [lindex $size 1]		;# MDI area height

	set wdWins [expr {int(floor( double($mainWd) / double($minWd) ))}]	;# How many windows fits by width
	set hgWins [expr {int(floor( double($mainHg) / double($minHg) ))}]	;# How many windows fits by height
	set maxWins [expr {$wdWins*$hgWins}]								;# Total windows we can fit
	set wdDiff [expr {int(floor( (double($mainWd) - double($minWd) * $wdWins) / double($wdWins) ))}]	;# Rest of width we can use
	set hgDiff [expr {int(floor( (double($mainHg) - double($minHg) * $hgWins) / double($wdWins) ))}]	;# Rest of height we can use
	incr minWd $wdDiff
	incr minHg $hgDiff

	if {$maxWins == 0} return

	if {$maxWins == $cnt} {
		# Just perfect. Only need to fix windows positions.

		set ptr 0
		set y 0
		for {set iy 0} {$iy < $hgWins} {incr iy} {
			set x 0
			for {set ix 0} {$ix < $wdWins} {incr ix} {
				set win [lindex $wins $ptr]
				$win setNormal

				$win setGeoms $x $y $minWd $minHg

				incr x $minWd
				incr ptr
			}
			incr y $minHg
		}
	} elseif {$maxWins < $cnt} {
		# We have more windows than we can arrange. We need to put one over another.

		set ptr 0
		while {[lindex $wins $ptr] != ""} {
			set y 0
			for {set iy 0} {$iy < $hgWins && [lindex $wins $ptr] != ""} {incr iy} {
				set x 0
				for {set ix 0} {$ix < $wdWins && [lindex $wins $ptr] != ""} {incr ix} {
					set win [lindex $wins $ptr]
					$win setNormal

					$win setGeoms $x $y $minWd $minHg

					incr x $minWd
					incr ptr
				}
				incr y $minHg
			}
		}
	} elseif {$maxWins > $cnt && $cnt > 0} {
		# We have less windows than we can arrange. Recalculation is needed.

		set iter 1
		set val 0
		set jVal 0
		try {	;# The only way to get out of recurent loops is throwing and catching an error
			for {set i 0} {1} {incr i} {
				foreach j {0 1} {
					for {set k 0} {$k < $iter} {incr k} {
						incr val
						set jVal $j
						if {$val == $cnt} {
							error "" "" 10
						}
					}
				}
				incr iter
			}
		} catch {
			if {$::errorCode == 10} {
				set wd [expr {int(floor( double($mainWd) / ($iter+$jVal) ))}]
				set hg [expr {int(floor( double($mainHg) / $iter ))}]
				set cols [expr {$iter+$jVal}]
			} else {
				error $error $::errorInfo $::errorCode
			}
		}

		set x 0
		set y 0
		set c 0
		foreach win $wins {
			$win setNormal
			$win setGeoms $x $y $wd $hg
			incr x $wd
			incr c
			if {$c == $cols} {
				set c 0
				set x 0
				incr y $hg
			}
		}
	}
	MAIN setMaxBtnsVisible false
}

body MDIWin::updateUISettings {} {
	$_root.top.close configure -background $borderButtonBackground -activebackground $borderButtonActiveBackground
	$_root.top.minmax configure -background $borderButtonBackground -activebackground $borderButtonActiveBackground
	$_root.top configure -background $borderBackground
	$_root.top.img configure -background $borderBackground
	$_root.top.l configure -foreground $borderForeground -background $borderBackground
}

body MDIWin::destroyWithDelay {} {
	# See BUG 1700 and comment in TaskBar::destroyWithTempDummy
	if {$mdimode == "NORMAL"} {
		$this placeForget
	} else {
		$this packForget
	}
	after 5000 [list delete object $this]
}

body MDIWin::placeForget {} {
	place forget $_root
}

body MDIWin::packForget {} {
	pack forget $_root
}

body MDIWin::raiseWindow {} {
	if {$mdimode == "NORMAL"} {
		set currentPacked $this
		raise $_root
	} else {
		if {$currentPacked != ""} {
			if {$currentPacked == $this} return
			$currentPacked packForget
		}
		set currentPacked $this
		pack $_root -fill both -expand 1
		MAIN setSubTitle $_title
	}
}

body MDIWin::canDestroy {} {
	return true
}

body MDIWin::isAt {x y} {
	lassign [getGeoms] x1 y1 w h
	set x2 [expr {$x1+$w}]
	set y2 [expr {$y1+$h}]
	return [expr {$x >= $x1 && $x <= $x2 && $y >= $y1 && $y <= $y2}]
}

body MDIWin::isNormalMode {} {
	return [expr {$mdimode == "NORMAL"}]
}

body MDIWin::getWinFor {x y} {
	foreach win $wins {
		if {[$win isAt $x $y]} {
			return $win
		}
	}
	return ""
}

body MDIWin::restoreLastClosedWindow {} {
	set sessItem [$recentlyClosedWindows pop]
	if {$sessItem == ""} return

	set handlers [findClassesBySuperclass "::MDIWin"]
	foreach handler $handlers {
		if {[info commands ::${handler}::restoreSession] == ""} {
			lremove handlers $handler
		}
	}

	foreach handler $handlers {
		if {[${handler}::restoreSession $sessItem]} {
			break
		}
	}
}

body MDIWin::rememberClosedWindow {} {
	if {$::QUITTING} return
	$recentlyClosedWindows push [getSessionString]
}

body MDIWin::init {} {
	if {$::tcl_platform(platform) == "unix" && [tk windowingsystem] != "aqua"} {
		set defaultCursor "left_ptr"
	} else {
		set defaultCursor "arrow"
	}
}
