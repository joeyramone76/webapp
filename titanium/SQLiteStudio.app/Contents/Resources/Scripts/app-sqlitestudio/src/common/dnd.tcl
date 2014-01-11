# This class uses some code from SimpleDnd:
## simplednd: implements simple mechanism for drag-and-drop within Tk applications.
## (c) 2009 WordTech Communications LLC.
## License: standard Tcl license,  http://www.tcl.tk/software/tcltk/license.html.

class Dnd {
	constructor {{copyFont false}} {}

	common tolerationRatio 10

	private {
		common _dragIcon ""
		common _dragText ""
		common _dragImage ""
		common _inProgress 0
		common _dragPrepared 0
		common _beginX 0
		common _beginY 0
		common _view ""

		variable _copyFont ""
		variable _toleration 0

		method dragRegister {w target dragcmd dropcmd}
	}

	protected {
		method createDnd {from to}
		method getDragImage {}
		method getDragLabel {}
		method makeDragIcon {txt img}
		method trackCursor {w globX globY x y target}
		method getDragIconPosition {}

		abstract method isDndPossible {x y}
		abstract method onDrag {x y}
		abstract method onDrop {x y}
		method onDragLeave {}
		method onDragReturn {}
		method canDropAt {x y}
	}

	public {
		common dndData ""

		method dragStart {w globX globY x y dragcmd target}
		method dragMove {w globX globY x y dragcmd target}
		method dragStop {w globX globY x y target dropcmd}
		method dragLeave {w}
		method dragReturn {w}

		method handleDragAction {globX globY x y}
		method handleDropAction {globX globY x y}

		proc setDndData {newData}
		proc getDndData {}
	}
}

body Dnd::constructor {{copyFont false}} {
	set _copyFont $copyFont
	makeDragIcon {} {}
}

body Dnd::setDndData {newData} {
	set dndData $newData
}

body Dnd::getDndData {} {
	return $dndData
}

body Dnd::createDnd {from to} {
	dragRegister $from $to "$this handleDragAction" "$this handleDropAction"
}

body Dnd::handleDragAction {globX globY x y} {
	$this onDrag $x $y
	set _dragImage [$this getDragImage]
	set _dragText [$this getDragLabel]
}

body Dnd::handleDropAction {globX globY x y} {
	$this onDrop $x $y
}

body Dnd::getDragImage {} {
	return img_drag_default
}

body Dnd::getDragLabel {} {
	return ""
}

body Dnd::makeDragIcon {txt img} {
	if {[winfo exists .dnd]} return

	set _dragText $txt
	set _dragImage $img

	set _dragIcon [toplevel .dnd -background black]
	wm withdraw $_dragIcon
	wm overrideredirect $_dragIcon true

	set _view [label $_dragIcon.view -background white -image $_dragImage -text $_dragText -compound left]
	pack $_view -padx 1 -pady 1
}

body Dnd::dragRegister {w target dragcmd dropcmd} {
	#binding for when drag motion begins
	set script [list $this dragStart %W %X %Y %x %y $dragcmd $target]
	bind $w <ButtonPress-1> +$script
	
	set script [list $this dragMove %W %X %Y %x %y $dragcmd $target]
	bind $w <B1-Motion> +$script

	#binding for when drop event occurs
	set script [list $this dragStop %W %X %Y %x %y $target $dropcmd]
	bind $w <ButtonRelease-1> +$script

	set script [list $this dragLeave %W]
	bind $w <FocusOut> +$script
	bind $w <B1-Leave> +$script

	set script [list $this dragReturn %W]
	bind $w <B1-Enter> +$script
}

body Dnd::dragStart {w globX globY x y dragcmd target} {
	set _dragPrepared [$this isDndPossible $x $y]
	set _toleration $tolerationRatio
	set _beginX $x
	set _beginY $y
}

body Dnd::dragMove {w globX globY x y dragcmd target} {
	if {!$_dragPrepared} return
	if {$_toleration > 0} {
		incr _toleration -1
		return
	}

	if {!$_inProgress} {
		eval $dragcmd $globX $globY $_beginX $_beginY

		# Configure drag icon with customized text and image
		$_view configure -text $_dragText -image $_dragImage

		if {$_copyFont && ![catch {$w cget -font}]} {
			$_view configure -font [$w cget -font]
		}
	}

	# This places the drag icon below the cursor
	switch -- [getDragIconPosition] {
		"right" {
			set iconX [expr {$globX + 10}]
			set iconY [expr {$globY - ([winfo reqheight $_dragIcon] / 2)}]
		}
		"left" {
			set iconX [expr {$globX - [winfo reqwidth $_dragIcon] - 10}]
			set iconY [expr {$globY - ([winfo reqheight $_dragIcon] / 2)}]
		}
		"bottom" {
			set iconX [expr {$globX - ([winfo reqwidth $_dragIcon] / 2)}]
			set iconY [expr {$globY - [winfo reqheight $_dragIcon] + 25}]
		}
		"top" {
			set iconX [expr {$globX - ([winfo reqwidth $_dragIcon] / 2)}]
			set iconY [expr {$globY - [winfo reqheight $_dragIcon] - 10}]
		}
		"center" {
			set iconX [expr {$globX - ([winfo reqwidth $_dragIcon] / 2)}]
			set iconY [expr {$globY - ([winfo reqheight $_dragIcon] / 2)}]
		}
	}

	wm geometry $_dragIcon +$iconX+$iconY
	if {!$_inProgress} {
		#dragicon appears
		wm deiconify $_dragIcon
		catch {raise $_dragIcon}

		set _inProgress 1
	}

	[namespace current]::trackCursor $w $globX $globY $x $y $target
}

body Dnd::trackCursor {w globX globY x y target} {
	#get the coordinates of the drop target
	set targetx [winfo rootx $target]
	set targety [winfo rooty $target]
	set targetwidth [expr [winfo width $target] + $targetx]
	set targetheight [expr [winfo height $target] + $targety]

	# Change the icon if over the drop target
	if {($globX > $targetx) && ($globX < $targetwidth) && ($globY > $targety) && ($globY < $targetheight) && [$this canDropAt $x $y]} {
		$w configure -cursor fleur
	} else {
		$w configure -cursor circle
	}
}

body Dnd::dragStop {w globX globY x y target dropcmd} {
	if {!$_inProgress || !$_dragPrepared} {
		return
	}
	set _inProgress 0
	# Hide dragicon on drop event
	wm withdraw $_dragIcon

	# Change cursor back to arrow
	$w configure -cursor ""

	# Execute callback or simply return
	if {[winfo containing $globX $globY] != $target || ![$this canDropAt $x $y]} {
		# Target not reached
		$this onDragLeave
	} else {
		focus $target
		eval $dropcmd $globX $globY $x $y
	}
}

body Dnd::onDragLeave {} {
}

body Dnd::onDragReturn {} {
}

body Dnd::dragLeave {w} {
	wm withdraw $_dragIcon
	$w configure -cursor ""
	$this onDragLeave
}

body Dnd::dragReturn {w} {
	$this onDragReturn
}

body Dnd::getDragIconPosition {} {
	return "right"
}

body Dnd::canDropAt {x y} {
	return true
}

