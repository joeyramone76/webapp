use src/common/signal.tcl
use src/common/dnd.tcl

class TaskBar {
	inherit Signal Dnd Session

	constructor {root} {}

	private {
		variable _root ""
		variable _canvas ""
		variable _current ""
		variable _items [list]
		variable _hiddenBtn 0
		variable _hiddenBtnPath ""
		variable _menu ""
		variable _taskMenu ""
		variable _dragTask ""
		variable _relativeDragPosition ""
		variable _restoredSessionNames ""
		variable _restoredSessionNamesActive ""
		variable _taskSemaphore 0

		method getNextItemPosition {}
		method delTask {it}
		method getTaskAt {x y}
		method getTaskNear {x y}
		method destroyWithTempDummy {it}
	}

	public {
		method addTask {title path obj {img "img_window"}}
		method delTaskByIdx {idx}
		method delTaskByTitle {title}
		method delTaskByPath {path}
		method getTaskByTitle {title}
		method clearActive {}
		method checkForHiddenItems {v1 v2}
		method repaint {}
		method postMenu {}
		method hideCurrent {}
		method setCurrent {it}
		method taskExists {title}
		method renameTask {title newTitle}
		method select {title}
		method selectByWinObj {obj}
		method selectWithDelay {ms title}
		method postTaskMenu {X Y x y}
		method closeSelectedTask {}
		method closeOtherTasks {}
		method closeAllTasks {}
		method closeTaskByWinObj {winObj}
		method signal {receiver data}
		method nextTask {}
		method prevTask {}
		method callForAll {args}
		method renameSelectedTask {}
		method onDrag {x y}
		method onDrop {x y}
		method isDndPossible {x y}
		method getDragImage {}
		method getDragLabel {}
		method getDragIconPosition {}
		method createTask {class args}
		method getSessionString {}
		method applyRestoredSession {}
		method setRestoredSessionNames {names active}
		proc restoreSession {sessionString}
	}
}

class ::TaskBar::Item {
	constructor {title {img "img_window"}} {}
	destructor {}

	common helpHintWin ".taskBarHelpHint"

	private {
		variable _canvas ""
		variable _path ""
		variable _title ""
		variable _itemtxt ""
		variable _itemrect ""
		variable _itemimg ""
		variable _active 0
		variable _width 0
		variable _tb ""
		variable _img ""
		variable _winObj ""
		variable _titleExceeds 0
	}

	public {
		common normal_col [. cget -background]
		common highlighted_col "#EEEEEE"
		common active_col "#DDDDFF"
		common outline_col "#AAAAAA"
		common active_outline_col "black"

		method setPath {path}
		method getPath {}
		method setWinObj {obj}
		method getWinObj {}
		method callOnWinObj {args}
		method setActive {{isNew 0}}
		method unsetActive {}
		method highlight {}
		method unhighlight {}
		method mouseEntered {}
		method mouseLeft {}
		method helpHint {w data}
		method fillHint {hintTable}
		method getWidth {}
		method active {}
		method repaint {x}
		method getImg {}
		method getTitle {}
		method setTitle {title}
		method getFont {}
		method containsItem {item}
		method canDestroy {}
		method getBBox {}
		proc initHelpHint {}
	}
}

body TaskBar::Item::constructor {title {img "img_window"}} {
	set _title $title
	upvar _root _root
	upvar this tb
	set _tb $tb
	set _canvas $_root.c
	set _img $img

	set _itemtxt [$_canvas create text -100 0 -text " [string range $title 0 15] "]
	set _itemrect [$_canvas create rect -100 1 -90 29 -outline $outline_col -fill $normal_col]
	set _itemimg [$_canvas create image -100 1 -image $img]
	$_canvas raise $_itemtxt $_itemrect
	repaint [uplevel {getNextItemPosition}]

	$_canvas bind $_itemrect <Any-Enter> "$this mouseEntered"
	$_canvas bind $_itemrect <Any-Leave> "$this mouseLeft"
	$_canvas bind $_itemtxt <Any-Enter> "$this mouseEntered"
	$_canvas bind $_itemtxt <Any-Leave> "$this mouseLeft"
	$_canvas bind $_itemimg <Any-Enter> "$this mouseEntered"
	$_canvas bind $_itemimg <Any-Leave> "$this mouseLeft"
	$_canvas bind $_itemimg <Button-1> "$this setActive"
	$_canvas bind $_itemrect <Button-1> "$this setActive"
	$_canvas bind $_itemtxt <Button-1> "$this setActive"
	$_canvas bind $_itemimg <Button-$::RIGHT_BUTTON> "$this setActive"
	$_canvas bind $_itemrect <Button-$::RIGHT_BUTTON> "$this setActive"
	$_canvas bind $_itemtxt <Button-$::RIGHT_BUTTON> "$this setActive"
}

body TaskBar::Item::destructor {} {
	$_canvas delete $_itemtxt $_itemrect $_itemimg
}

body TaskBar::Item::initHelpHint {} {
	initFancyHelpHint $helpHintWin
}

body TaskBar::Item::mouseEntered {} {
	helpHint_onEnter $_canvas "" [list $this helpHint] 600 false
	highlight
}

body TaskBar::Item::mouseLeft {} {
	helpHint_onLeave $_canvas "" $helpHintWin [list $this helpHint] 600 false
	unhighlight
}

body TaskBar::Item::helpHint {w data} {
	set cmd "$this fillHint \$container"
	raiseFancyHelpHint $helpHintWin $cmd $w $data
}

body TaskBar::Item::fillHint {hintTable} {
	$hintTable setTitle [getTitle]
	switch -- [$_winObj info class] {
		"::TableWin" {
			set db [$_winObj getDb]
			set table [$_winObj getTable]
			$hintTable addRow [mc {Database:}] [$db getName]
			$hintTable addRow [mc {Table:}] $table
		}
		"::EditorWin" {
			set db [$_winObj getDB true]
			$hintTable addRow [mc {Database:}] [$db getName]
		}
	}
}

body TaskBar::Item::repaint {x} {
	set wd [font measure [$_canvas itemcget $_itemtxt -font] " [string range $_title 0 15] "]
	if {$wd < 60} {set wd 60}
	$_canvas coords $_itemtxt [expr {$x+$wd/2+18}] 15
	$_canvas coords $_itemrect $x 3 [expr {$x+$wd+16}] 27
	$_canvas coords $_itemimg [expr {$x+10}] 15
	$_canvas configure -scrollregion [list 0 0 [expr {$x+$wd+26}] 30]
	set _width [expr {$wd+18}]

	if {[string length $_title] > 16} {
		set _titleExceeds 1
	}
}

body TaskBar::Item::setPath {path} {
	set _path $path
}

body TaskBar::Item::getPath {} {
	return $_path
}

body TaskBar::Item::setWinObj {obj} {
	set _winObj $obj
}

body TaskBar::Item::getWinObj {} {
	return $_winObj
}

body TaskBar::Item::callOnWinObj {args} {
	$_winObj {*}$args
}

body TaskBar::Item::setActive {{isNew 0}} {
	if {$_active || ($::MDIWin::activatedLately && !$isNew)} return
	$_tb clearActive
	$_canvas itemconfigure $_itemrect -fill $active_col -outline $active_outline_col
	set _active 1
	$_tb setCurrent $this
	$_winObj raiseWindow
	set ::MDIWin::activatedLately 1
	after 100 "set ::MDIWin::activatedLately 0"
	$_winObj activated
}

body TaskBar::Item::unsetActive {} {
	$_canvas itemconfigure $_itemrect -fill $normal_col -outline $outline_col
	set _active 0
	$_tb hideCurrent
}

body TaskBar::Item::highlight {} {
	if {$_active} return
	$_canvas itemconfigure $_itemrect -fill $highlighted_col
}

body TaskBar::Item::unhighlight {} {
	if {$_active} return
	$_canvas itemconfigure $_itemrect -fill $normal_col
}

body TaskBar::Item::getWidth {} {
	return $_width
}

body TaskBar::Item::active {} {
	return $_active
}

body TaskBar::Item::getTitle {} {
	return $_title
}

body TaskBar::Item::setTitle {title} {
	set _title $title
	$_canvas itemconfigure $_itemtxt -text " [string range $title 0 15] "
	$_tb repaint
}

body TaskBar::Item::getImg {} {
	return $_img
}

body TaskBar::Item::getFont {} {
	return [$_canvas itemcget $_itemtxt -font]
}

body TaskBar::Item::containsItem {item} {
	if {$item in [list $_itemtxt $_itemrect $_itemimg]} {
		return true
	} else {
		return false
	}
}

body TaskBar::Item::canDestroy {} {
	return [$_winObj canDestroy]
}

body TaskBar::Item::getBBox {} {
	$_canvas bbox $_itemrect
}

body TaskBar::constructor {root} {
	set _root $root
	ttk::frame $_root
	set _canvas [canvas $_root.c -height 30 -background [. cget -background] -border 1 -highlightthickness 0 \
		-xscrollcommand "$this checkForHiddenItems"]
	pack $_root.c -fill x -expand 1 -side left

	set _hiddenBtnPath [ttk::frame $_root.hbtn]
	ttk::button $_root.hbtn.b -image img_tab_right -command "$this postMenu"
	pack $_root.hbtn.b -fill both

	set _menu $_root.hbtn.menu
	set _taskMenu $_root.menu
	
	bind $_root.c <Button-$::RIGHT_BUTTON> [list $this postTaskMenu %X %Y %x %y]

	createDnd $_root.c $_root.c
}

body TaskBar::addTask {title path obj {img "img_window"}} {
	set it [TaskBar::Item ::#auto $title $img]
	$it setPath $path
	$it setWinObj $obj
	lappend _items $it
	return $it
}

body TaskBar::delTaskByIdx {idx} {
	set i 0
	foreach it $_items {
		if {$i == $idx} {
			set obj [$it getWinObj]
			if {[delTask $it]} {
				$obj rememberClosedWindow
				#delete object $obj
				$obj destroyWithDelay
			}
			break
		}
		incr i
	}
}

body TaskBar::delTaskByTitle {title} {
	foreach it $_items {
		if {[$it getTitle] == $title} {
			set obj [$it getWinObj]
			if {[delTask $it]} {
				$obj rememberClosedWindow
				#delete object $obj
				$obj destroyWithDelay
			}
			break
		}
	}
}

body TaskBar::delTaskByPath {path} {
	foreach it $_items {
		if {[$it getPath] == $path} {
			set obj [$it getWinObj]
			if {[delTask $it]} {
				$obj rememberClosedWindow
				#delete object $obj
				$obj destroyWithDelay
			}
			break
		}
	}
}

body TaskBar::delTask {it} {
	if {![$it canDestroy]} {
		return 0
	}

	# It turns out that calling [setActive] makes call to [MDIWin::activated], which for TableWin is implemented
	# to call [TableWin::focusTab]. That one makes [update], which could desynchronize operations
	# of removing $it from $_items and deleting $it.
	# 
	# Therefore I'm putting the semaphore variable here.
	# This is suppose to fix following bugs: 1479, 1483, 1563.
	if {$_taskSemaphore > 0} {
		return 0
	}
	incr _taskSemaphore

	set idx [lsearch -exact $_items $it]
	lremove _items $it
	set isActive [expr {[$it active] || $it == $_current}]
	
	destroyWithTempDummy $it

	if {$isActive} { ;# sometimes $it seems to not be active yet, even it's current. BUG #685
		hideCurrent
		if {[lindex $_items $idx] != ""} {
			[lindex $_items $idx] setActive
		} else {
			incr idx -1
			if {$idx > -1} {
				[lindex $_items $idx] setActive
			}
		}
	}

	if {[llength $_items] == 0} {
		MAIN setSubTitle
	}
	repaint
	incr _taskSemaphore -1
	return 1
}

body TaskBar::destroyWithTempDummy {it} {
	# Destroy object and keep a dummy command for a while,
	# to lie to event handlers. This aims to solve 1700.
	# Unfortunately events have to be processed by Tk
	# quite often by damand (with [update idletasks])
	# in order to make everything resize properly, etc,
	# but it also causes nasty desynchronizations.
	delete object $it
	set name ::[string trimleft $it ::]
	proc $name {args} {
		# No-op
	}
	after 5000 [list ::rename $name {}]
}

body TaskBar::clearActive {} {
	foreach it $_items {
		if {[$it active]} {
			$it unsetActive
		}
	}
}

body TaskBar::getNextItemPosition {} {
	set pos 5
	foreach it $_items {
		incr pos [$it getWidth]
		incr pos 5
	}
	return $pos
}

body TaskBar::repaint {} {
	set pos 5
	foreach it $_items {
		$it repaint $pos
		incr pos [$it getWidth]
		incr pos 5
	}
}

body TaskBar::checkForHiddenItems {v1 v2} {
	if {!($v2 < 1 ^ $_hiddenBtn)} return
	if {!$_hiddenBtn} {
		set _hiddenBtn 1
		pack $_hiddenBtnPath -side right -fill x
	} else {
		set _hiddenBtn 0
		pack forget $_hiddenBtnPath
	}
}

body TaskBar::postMenu {} {
	set w [winfo width $_root.c]
	catch {destroy $_menu}
	menu $_menu -borderwidth 1 -tearoff 0 -activeborderwidth 1
	set pos 5
	set i 0
	foreach it $_items {
		incr pos [$it getWidth]

		if {$pos > $w} {
			set col ""
			set font [$it getFont]
			set attribs [font actual $font]
			set font [list [dict get $attribs -family] [dict get $attribs -size]]
			if {[$it active]} {
				set col "${TaskBar::Item::active_col}"
				lappend font " bold"
			}
			set colbreak 0
			if {[expr {$i % 20}] == 0 && $i > 0} {
				set colbreak 1
			}
			$_menu add command -image [$it getImg] -label [$it getTitle] -compound left \
				-background $col -activebackground $col -font $font -command "$it setActive" -columnbreak $colbreak

			incr i
		}

		incr pos 5
	}

	set x [winfo rootx $_hiddenBtnPath]
	set y [winfo rooty $_hiddenBtnPath]
	set h [winfo height $_hiddenBtnPath]
	tk_popup $_menu $x \
		[expr {$y+$h+2}]
}

body TaskBar::hideCurrent {} {
	if {$_current == ""} return
	pack forget [$_current getPath]
	set _current ""
}

body TaskBar::setCurrent {it} {
	set _current $it
}

body TaskBar::getTaskByTitle {title} {
	foreach it $_items {
		if {[$it getTitle] == $title} {
			return $it
		}
	}
	return ""
}

body TaskBar::taskExists {title} {
	foreach it $_items {
		if {[$it getTitle] == $title} {
			return 1
		}
	}
	return 0
}

body TaskBar::selectByWinObj {obj} {
	set item ""
	foreach it $_items {
		if {[$it getWinObj] == $obj} {
			set item $it
		}
	}
	if {$item == "" || $_current == $item} return
	$item setActive
	#set _current $item
}

body TaskBar::select {title} {
	set item ""
	foreach it $_items {
		if {[$it getTitle] == $title} {
			set item $it
		}
	}
	if {$item == "" || $_current == $item} return
	#$_current unsetActive #; this line coused problems with distribution wrapped into starkit for linux
	$item setActive
	#set _current $item
}

body TaskBar::selectWithDelay {ms title} {
	after $ms [list catch [list $this select $title]]
}

body TaskBar::renameTask {title newTitle} {
	foreach it $_items {
		if {[$it getTitle] == $title} {
			$it setTitle $newTitle
			break
		}
	}
}

body TaskBar::renameSelectedTask {} {
	if {$_current == ""} return

	InputDialog .newTaskName -message [mc {Type new name for a window}] -default [$_current getTitle]
	set newTitle [.newTaskName exec]

	if {$newTitle == ""} return

	while {[getTaskByTitle $newTitle] != ""} {
		Warning [mc "Window with given name already exists. Please type other name."]
		InputDialog .newTaskName -message [mc {Type new name for a task}]
		set newTitle [.newTaskName exec]
		if {$newTitle == ""} return
	}

	[$_current getWinObj] changeTitle $newTitle
}

body TaskBar::postTaskMenu {X Y x y} {
	set items [$_canvas find overlapping $x $y [expr {$x+1}] [expr {$y+1}]]
	set onItem [expr {[llength $items] > 0}]

	catch {destroy $_taskMenu}
	menu $_taskMenu -tearoff 0 -borderwidth 1 -activeborderwidth 1
	if {$onItem} {
		$_taskMenu add command -compound left -image img_win_close -label [mc {Close selected window}] -command "$this closeSelectedTask"
		$_taskMenu add command -compound left -image img_win_close_other -label [mc {Close other windows}] -command "$this closeOtherTasks"
	}
	$_taskMenu add command -compound left -image img_win_close_all -label [mc {Close all windows}] -command "$this closeAllTasks"
	$_taskMenu add separator
	$_taskMenu add command -compound left -image img_win_restore -label [mc {Restore last closed window}] -command "MDIWin::restoreLastClosedWindow"
	if {$onItem} {
		$_taskMenu add command -compound left -image img_rename -label [mc {Rename selected window}] -command "$this renameSelectedTask"
	}
	tk_popup $_taskMenu $X $Y
}

body TaskBar::closeSelectedTask {} {
	if {$_current == ""} return
# 	if {$_taskSemaphore > 0} return
# 	incr _taskSemaphore
	# I'm commenting out [catch] once again in order to check if fix in [delTask] (see its comments inside)
	# did the trick and the delTask won't throw the error anymore.
	#catch { ;# sometimes 2 events calls this method while destruction of the object is still in progress
		set obj [$_current getWinObj]
		if {[delTask $_current]} {
			$obj rememberClosedWindow
			#delete object $obj
			$obj destroyWithDelay
		}
#	}
	#update
# 	incr _taskSemaphore -1
}

body TaskBar::closeTaskByWinObj {winObj} {
	if {$_current == ""} return
# 	if {$_taskSemaphore > 0} return
# 	incr _taskSemaphore
	foreach it $_items {
		if {[$it getWinObj] == $winObj} {
			if {[delTask $it]} {
				$winObj rememberClosedWindow
				#delete object $winObj
				$winObj destroyWithDelay
				break
			}
		}
	}
# 	incr _taskSemaphore -1
}

body TaskBar::createTask {class args} {
# 	if {$_taskSemaphore > 0} return
# 	incr _taskSemaphore
	set obj [$class ::#auto {*}$args]
	set item [addTask [$obj getTitle] [$obj getRoot] $obj [$obj getImage]]
	if {![$obj isa MDIWin]} {
		error "Trying to create task using not MDIWin branch class."
	}
	$item setActive 1
# 	incr _taskSemaphore -1
	return $obj

}

body TaskBar::closeOtherTasks {} {
	foreach it $_items {
		if {$it != $_current} {
			set obj [$it getWinObj]
			if {[delTask $it]} {
				$obj rememberClosedWindow
				#delete object $obj
				$obj destroyWithDelay
			}
		}
	}
}

body TaskBar::closeAllTasks {} {
	foreach it $_items {
		set obj [$it getWinObj]
		if {[delTask $it]} {
			$obj rememberClosedWindow
			#delete object $obj
			$obj destroyWithDelay
		}
	}
}

body TaskBar::signal {receiver data} {
	foreach it $_items {
		[$it getWinObj] signal $receiver $data
	}
	DBTREE signal $receiver $data
}

body TaskBar::nextTask {} {
	if {$_current == ""} return
	set idx [lsearch -exact $_items $_current]
	incr idx
	set it [lindex $_items $idx]
	if {$it != ""} {
		$it setActive
	}
}

body TaskBar::prevTask {} {
	if {$_current == ""} return
	set idx [lsearch -exact $_items $_current]
	incr idx -1
	set it [lindex $_items $idx]
	if {$it != ""} {
		$it setActive
	}
}

body TaskBar::callForAll {args} {
	foreach it $_items {
		$it {*}$args
	}
}

body TaskBar::getTaskAt {x y} {
	set canvItems [$_root.c find overlapping $x $y $x $y]
	if {[llength $canvItems] == 0} {
		return ""
	}
	set canvItem [lindex $canvItems 0]
	foreach task $_items {
		if {[$task containsItem $canvItem]} {
			return $task
		}
	}
	return ""
}

body TaskBar::getTaskNear {x y} {
	set canvItems [$_root.c find closest $x $y]
	if {[llength $canvItems] == 0} {
		return ""
	}
	set canvItem [lindex $canvItems 0]
	foreach task $_items {
		if {[$task containsItem $canvItem]} {
			return $task
		}
	}
	return ""
}

body TaskBar::isDndPossible {x y} {
	set task [getTaskAt $x $y]
	return [expr {$task != ""}]
}

body TaskBar::onDrag {x y} {
	set task [getTaskAt $x $y]
	set _dragTask $task
	lassign [$task getBBox] left top right bottom
	set _relativeDragPosition [expr {double($x - $left) / ($right - $left)}]
}

body TaskBar::onDrop {x y} {
	set task [getTaskNear $x $y]

	if {[string equal [string trimleft $task :] [string trimleft $_dragTask :]]} return

	lassign [$task getBBox] left top right bottom
	set relativeDropPosition [expr {double($x - $left) / ($right - $left)}]

	set srcIdx [lsearch -exact $_items $_dragTask]
	set trgIdx [lsearch -exact $_items $task]
	set modifier 0
	if {$srcIdx < $trgIdx} {
		set modifier 1
	}

	if {$modifier} {
		# Moving to right
		if {$_relativeDragPosition >= $relativeDropPosition + 0.4} return
	} else {
		# Moving to left
		if {$_relativeDragPosition + 0.4 <= $relativeDropPosition} return
	}

	# Removing moved task from old position
	lremove _items $_dragTask

	# Inserting moved column to new position
	set idx [lsearch -exact $_items $task]
	incr idx $modifier
	set _items [linsert $_items $idx $_dragTask]

	# Clearing drag cache
	set _dragTask ""

	# Refreshing view
	repaint
}

body TaskBar::getDragImage {} {
	return [$_dragTask getImg]
}

body TaskBar::getDragLabel {} {
	return [$_dragTask getTitle]
}

body TaskBar::getDragIconPosition {} {
	return "top"
}

body TaskBar::getSessionString {} {
	set names [list]
	set active ""
	foreach item $_items {
		lappend names [$item getTitle]
		if {[$item active]} {
			set active [$item getTitle]
		}
	}
	return [list TASKBAR $names $active]
}

body TaskBar::restoreSession {sessionString} {
	lassign $sessionString type names active
	if {$type != "TASKBAR"} {
		return false
	}

	set tb [lindex [itcl::find objects -isa TaskBar] 0]
	if {$tb == ""} {
		return false
	}

	$tb setRestoredSessionNames $names $active
	return true
}

body TaskBar::setRestoredSessionNames {names active} {
	set _restoredSessionNames $names
	set _restoredSessionNamesActive $active
}

body TaskBar::applyRestoredSession {} {
	set newItems [list]
	set allItems $_items
	foreach name $_restoredSessionNames {
		foreach item $_items {
			if {[string equal [$item getTitle] $name]} {
				lappend newItems $item
				lremove allItems $item
				break
			}
		}
	}
	lappend newItems {*}$allItems
	set _items $newItems
	repaint

	if {$_restoredSessionNamesActive != ""} {
		update idletasks
		select $_restoredSessionNamesActive
	}
}
