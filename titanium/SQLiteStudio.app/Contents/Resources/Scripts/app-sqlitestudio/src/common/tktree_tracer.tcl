class TkTreeTracer {
	private {
		variable _tree ""
	}

	protected {
		variable _itemUnderPointer ""
		variable _columnUnderPointer ""
		variable _headerUnderPointer ""
		variable _itemEnterCmd ""
		variable _itemLeaveCmd ""
		variable _columnEnterCmd ""
		variable _columnLeaveCmd ""
		variable _headerEnterCmd ""
		variable _headerLeaveCmd ""
		variable _tracerButtonPressed ""

		method initTracer {tree}
	}

	public {
		method tracePointer {x y}
		method itemEnter {it col}
		method itemLeave {it col}
		method columnEnter {col}
		method columnLeave {col}
		method headerEnter {col}
		method headerLeave {col}
		method leaveWidget {}
		method tracerButtonPressed {button it col}
		method _tracerButtonPressed {button x y}
	}
}


body TkTreeTracer::initTracer {tree} {
	set _tree $tree
	bind $_tree <Motion> "+$this tracePointer %x %y"
	bind $_tree <Leave> "+$this leaveWidget"
	bind $_tree <ButtonPress-1> "+$this _tracerButtonPressed 1 %x %y"
	bind $_tree <ButtonPress-$::MIDDLE_BUTTON> "+$this _tracerButtonPressed 2 %x %y"
	bind $_tree <ButtonPress-$::RIGHT_BUTTON> "+$this _tracerButtonPressed 3 %x %y"
}

body TkTreeTracer::tracePointer {x y} {
	set item [$_tree identify $x $y]

	if {[lindex $item 0] == "header" && [lindex $item 1] == "tail"} {
		set item ""
	}
	
	switch -- [lindex $item 0] {
		"item" {
			set it [lindex $item 1]
			set col [lindex $item 3]
			set item [list $it $col]

			# Row
			if {$_itemUnderPointer != $item} {
				if {$_itemUnderPointer != ""} {
					$this itemLeave {*}$_itemUnderPointer
				}
				set _itemUnderPointer $item
				$this itemEnter $it $col
			}

			# Column
			if {$_columnUnderPointer != $col} {
				if {$_columnUnderPointer != ""} {
					$this columnLeave {*}$_columnUnderPointer
				}
				set _columnUnderPointer $col
				$this columnEnter $col
			}

			# Header
			if {$_headerUnderPointer != ""} {
				$this headerLeave {*}$_headerUnderPointer
			}
			set _headerUnderPointer ""
		}
		"header" {
			set col [lindex $item 1]

			# Row
			if {$_itemUnderPointer != ""} {
				$this itemLeave {*}$_itemUnderPointer
			}
			set _itemUnderPointer ""

			# Column
			if {$_columnUnderPointer != $col} {
				if {$_columnUnderPointer != ""} {
					$this columnLeave {*}$_columnUnderPointer
				}
				set _columnUnderPointer $col
				$this columnEnter $col
			}

			# Header
			if {$_headerUnderPointer != $col} {
				if {$_headerUnderPointer != ""} {
					$this headerLeave {*}$_headerUnderPointer
				}
				set _headerUnderPointer $col
				$this headerEnter $col
			}
		}
		default {
			# Is there any old item?
			if {$_itemUnderPointer != ""} {
				$this itemLeave {*}$_itemUnderPointer
			}
			set _itemUnderPointer ""

			# Checking if column changed
			if {$_columnUnderPointer != ""} {
				$this columnLeave {*}$_columnUnderPointer
			}
			set _columnUnderPointer ""

			# Header
			if {$_headerUnderPointer != ""} {
				$this headerLeave {*}$_headerUnderPointer
			}
			set _headerUnderPointer ""
		}
	}
}

body TkTreeTracer::itemEnter {it col} {
	if {$_itemEnterCmd != ""} {
		eval $_itemEnterCmd $it $col
	}
}

body TkTreeTracer::itemLeave {it col} {
	if {$_itemLeaveCmd != ""} {
		eval $_itemLeaveCmd $it $col
	}
}

body TkTreeTracer::columnEnter {col} {
	if {$_columnEnterCmd != ""} {
		eval $_columnEnterCmd $col
	}
}

body TkTreeTracer::columnLeave {col} {
	if {$_columnLeaveCmd != ""} {
		eval $_columnLeaveCmd $col
	}
}

body TkTreeTracer::headerEnter {col} {
	if {$_headerEnterCmd != ""} {
		eval $_headerEnterCmd $col
	}
}

body TkTreeTracer::headerLeave {col} {
	if {$_headerLeaveCmd != ""} {
		eval $_headerLeaveCmd $col
	}
}

body TkTreeTracer::leaveWidget {} {
	if {$_itemUnderPointer != ""} {
		itemLeave {*}$_itemUnderPointer
	}
	if {$_columnUnderPointer != ""} {
		columnLeave {*}$_columnUnderPointer
	}
	if {$_headerUnderPointer != ""} {
		headerLeave {*}$_headerUnderPointer
	}
}

body TkTreeTracer::_tracerButtonPressed {button x y} {
	set item [$_tree identify $x $y]
	switch -- [lindex $item 0] {
		"item" {
			tracerButtonPressed $button [lindex $item 1] [lindex $item 3]
		}
	}
}

body TkTreeTracer::tracerButtonPressed {button it col} {
	if {$_tracerButtonPressed != ""} {
		eval $_tracerButtonPressed $button $it $col
	}
}
