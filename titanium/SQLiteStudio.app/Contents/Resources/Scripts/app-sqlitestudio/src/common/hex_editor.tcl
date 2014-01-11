use src/common/panel.tcl

#>
# @class HexEditor
# Widget for editing data with hexadecimal values. It's splitted to two <code>text</code> widgets.
# There is hexadecimal view on the left side and standard view on the right side.
# They are synchronized with each other, but only hexadecimal values can be edited.<br>
#<
class HexEditor {
	inherit Panel

	#>
	# @var background
	# Background color of editor. It's set by {@class CfgWin}.
	#<
	common background white

	#>
	# @var foreground
	# Font color of editor. It's set by {@class CfgWin}.
	#<
	common foreground black

	#>
	# @var selectionColor
	# Selection background color of editor. It's set by {@class CfgWin}.
	#<
	common selectionColor #000099

	#>
	# @var selectionFgColor
	# Selection font color of editor. It's set by {@class CfgWin}.
	#<
	common selectionFgColor white

	#>
	# @var markColor
	# Marked char background color of editor. It's set by {@class CfgWin}.
	#<
	common markColor #BBBBFF

	#>
	# @var markFgColor
	# Marked char foreground color of editor. It's set by {@class CfgWin}.
	#<
	common markFgColor black

	# Options
	opt yscrollcommand ""
	opt modifycmd ""
	opt height 16

	#>
	# @method constructor
	# @param args Option-value pairs. Valid option is: <code>-yscrollcommand</code>.
	# Creates widget.
	#<
	constructor {args} {}

	private {
		#>
		# @var _lgt
		# Number of characters to be edited in single line of the widget.
		#<
		final common _lgt 16

		#>
		# @var _sbBlocked
		# Switch used internally by widhet to mark if vertical scrollbar is blocked
		# (already managed by some command) or not. It's kind of a semaphore.
		#<
		variable _sbBlocked 0

		#>
		# @var _sb
		# Scrollbar widget object.
		#<
		variable _sb ""

		#>
		# @var _root
		# Frame object that everything is placed in. It's needed to fix themes drawing.
		#<
		variable _root ""

		#>
		# @var _value
		# Value of data edited in the widget. It's updated on the fly when data is edited by user.
		#<
		variable _value ""

		variable _canceled 0
		variable _readOnly 0
		variable _disabled 0

		method widgetHex {args}
		method updateMarkerInternal {pos}
	}

	public {
		variable _insertionMode "insert"

		#>
		# @method insert
		# @param str String to insert.
		# Widget doesn't really <i>insert</i>, it just appends string to end
		# of current value.
		#<
		method insert {str}

		#>
		# @method setFocus
		# Makes sure that the widget has input focus.
		#<
		method setFocus {}

		#>
		# @method get
		# @return Current value of edited data. It's exactly value of {@var _value}.
		#<
		method get {}

		#>
		# @method clear
		# Deletes data from both views and {@var _value}.
		#<
		method clear {}

		method event:insert {char}
		method event:delete {}
		method event:backSpace {}
		method resizeColumns {}
		method updateOffset {}
		method updateASCII {}
		method ascii:event:Button-1 {x y}
		method event:Button-1 {x y}
		method updateYview {args}
		method cancel {}
		method updateMarker {}
		method setReadOnly {boolean}
		method setDisabled {boolean}
		method isReadOnly {}
		method isDisabled {}
		method bindEdits {sequence script}
		method switchInsertionMode {}
	}
}

body HexEditor::constructor {args} {
	eval itk_initialize $args

	set win $path.h

	copyClassBinds Text HexEdit$win

	removeAllBindsBut HexEdit$win [list Key-Left Key-Right \
			Key-Up Key-Down Key-Next Key-Prior B1-Motion Button-2 B2-Motion]

	bind HexEdit$win <Button-1> [list $this event:Button-1 %x %y]
	bind HexEdit$win <Delete> [list $this event:delete]
	bind HexEdit$win <Key> [list $this event:insert %A]
	bind HexEdit$win <BackSpace> [list $this event:backSpace]
	bind HexEdit$win <Insert> [list $this switchInsertionMode]

	bind HexEditASCII$win <Button-1> [list $this ascii:event:Button-1 %x %y]
	bind HexEditASCII$win <B1-Motion> [bind Text <B1-Motion>]

	foreach seq {Key-Left Key-Right Key-Up Key-Down Key-Next Key-Prior} {
		bind HexEdit$win <$seq> "+$this updateMarker"
	}

	set bg $background
	set fg $foreground
	set insertbackground $markColor

	ttk::frame $win
	pack [ttk::scrollbar $win.scroll -command [list $win.hex yview]] -side right -fill y
	pack [text $win.offset -width 2 -height 6 -wrap none -foreground $fg -background $bg -font ${::SQLEditor::font}] \
		-side left -fill y

	bindtags $win.offset all

	pack [text $win.hex -width 33 -height 6 -wrap none -borderwidth 1 -relief solid -font ${::SQLEditor::font} \
			-yscrollcommand [list $this updateYview] -foreground $fg -background $bg] \
			-side left -fill y
	pack [text $win.ascii -width 17 -height 6 -wrap none -foreground $fg -background $bg \
			-borderwidth 1 -relief solid -font ${::SQLEditor::font}] \
			-side left -fill y

	pack [ttk::frame $win.opts] -side left -fill both -expand 1
	pack [ttk::checkbutton $win.opts.mode -variable [scope _insertionMode] -onvalue "overwrite" -offvalue "insert" \
		-text [mc "Overwrite characters,\ninstead of inserting"]] -side top -fill x

	$win.hex tag configure sel -background $selectionColor -foreground $selectionFgColor -borderwidth 0
	$win.hex configure -highlightthickness 0 -insertwidth 2
	$win.ascii tag configure sel -background $selectionColor -foreground $selectionFgColor -borderwidth 0
	$win.ascii configure -highlightthickness 0

	bindtags $win.hex [list HexEdit$win all]
	bindtags $win.ascii [list HexEditASCII$win all]

	bind $win <Configure> "$this updateYview %W \[%W.hex yview]"

	bind $win <Configure> "
		$this resizeColumns
		$this updateASCII
		$this updateOffset
	"

	pack $path.h -fill both -side top -anchor w -expand 1
}

body HexEditor::cancel {} {
	set _canceled 1
}

body HexEditor::insert {str} {
	if {[string bytelength $str]  == 0} return

	set progress [BusyDialog::show [mc {Processing}] [mc {Processing data...}] true 100 false "determinate"]
	$progress configure -onclose [list $this cancel]
	$progress setCloseButtonLabel [mc {Cancel}]

	binary scan $str H* hex

	set newHex ""
	set charCount 0
	set totalCharCount 0
	set hexLen [string length $hex]
	for {set i 0} {$i < $hexLen} {incr i} {
		incr charCount
		append newHex [string index $hex $i]
		if {$charCount == 32} {
			append newHex \n
			set charCount 0

		}
		if {$i % 30000 == 0} {
			set perc [expr {$i * 100 / $hexLen}]
			$progress setProgress $perc
			if {$_canceled} {
				return
			}
		}
	}

	set win $path.h
	$win.hex insert end $newHex

	updateASCII
	updateOffset

	BusyDialog::hide
}

body HexEditor::clear {} {
	set win $path.h
	$win.offset delete 1.0 end
	$win.hex delete 1.0 end
	$win.ascii delete 1.0 end
}

body HexEditor::get {} {
	set win $path.h
	set data [$win.hex get 1.0 end-1c]
	set data [string map {"\n" ""} $data]
	set data [binary format H* $data]
	return $data
}

body HexEditor::updateYview {args} {
	set pos [lindex $args 0]

	set win $path.h
	$win.hex yview moveto $pos
	resizeColumns
	updateASCII
	updateOffset

	eval $win.scroll set $args
}

body HexEditor::updateMarkerInternal {pos} {
	set win $path.h
	$win.hex mark set insert $pos
	$win.hex mark set anchor insert
	focus $win.hex

	$win.hex tag remove sel 0.0 end
	$win.ascii tag remove sel 0.0 end

	set cur [$win.hex index insert]
	set splitIndex [split $cur .]

	set line [lindex $splitIndex 0]
	set curChar [lindex $splitIndex 1]

	if {[expr {$curChar & 1}]} { ;# test if number is odd
		set curChar [expr {$curChar - 1}]
	}

	if {$curChar > 0} {
		set curChar [expr {$curChar / 2}]
	}

	set hexLine [$win.hex index @0,0]
	set offset [expr {int($line - $hexLine + 1.0)}]

	set cur "$offset.$curChar"
	set end [$win.ascii index "$cur + 1 chars"]
	$win.ascii tag add sel $cur $end
}

body HexEditor::updateMarker {} {
	set win $path.h
	set pos [$win.hex index insert]
	updateMarkerInternal $pos
}

body HexEditor::event:Button-1 {x y} {
	set win $path.h
	set pos [$win.hex index @$x,$y]
	updateMarkerInternal $pos
}

body HexEditor::ascii:event:Button-1 {x y} {
	set win $path.h
	set pos [$win.ascii index @$x,$y]
	$win.ascii mark set insert $pos
	$win.ascii mark set anchor insert
	focus $win.ascii

	$win.hex tag remove sel 0.0 end
	$win.ascii tag remove sel 0.0 end

	set cur [$win.ascii index insert]
	set splitIndex [split $cur .]

	set line [lindex $splitIndex 0]
	set curChar [lindex $splitIndex 1]

	set curChar [expr {$curChar * 2}]

	set asciiLine [$win.hex index @0,0]
	set offset [expr {int($line + $asciiLine - 1.0)}]

	set cur "$offset.$curChar"
	set end [$win.hex index "$cur + 2 chars"]
	$win.hex tag add sel $cur $end
}

body HexEditor::updateASCII {} {
	set win $path.h
	set start [$win.hex index @0,0]
	set end [$win.hex index @0,[winfo height $win.hex]]

	set end [expr {double($end + 1.0)}]
	#puts "$start $end"

	set data [split [$win.hex get $start $end] \n]

	$win.ascii delete 1.0 end
	foreach line $data {
		set lineLength [expr {[string length $line] / 2}]
		set line [binary format H* $line]

		for {set i 0} {$i < $lineLength} {incr i} {
			binary scan $line @${i}a1 ascii

			if {[string is alnum $ascii]} {
				$win.ascii insert end $ascii
			} else {
				$win.ascii insert end .
			}
		}
		$win.ascii insert end \n
	}
}

body HexEditor::updateOffset {} {
	set win $path.h
	set viewFirst [$win.hex index @0,0]
	set viewLast [$win.hex index @0,[winfo height $win.hex]]

	set viewFirstLine [lindex [split $viewFirst .] 0]
	set viewLastLine [lindex [split $viewLast .] 0]

	incr viewFirstLine -1

	$win.offset delete 1.0 end

	for {set i $viewFirstLine} {$i < $viewLastLine} {incr i} {
		set offset [expr {$i * 16}]
		$win.offset insert end $offset\n
	}

	$win.offset config -width [string length $offset]
}

body HexEditor::resizeColumns {} {
	set win $path.h
	set start [$win.hex index @0,0]
	set end [$win.hex index @0,[winfo height $win.hex]]

	set viewStartLine [lindex [split $start .] 0]
	set viewEndLine [lindex [split $end .] 0]

	#puts "viewStartLine $viewStartLine"
	#puts "viewEndLine $viewEndLine"

	for {set i $viewStartLine} {$i <= $viewEndLine} {incr i} {
		set lineend [$win.hex index "$i.0 lineend"]
		set charEnd [lindex [split $lineend .] 1]

		if {$charEnd < 32} {
			$win.hex delete $lineend
		} elseif {$charEnd > 32} {
			#delete the \n
			$win.hex delete "$i.$charEnd"
			$win.hex insert "$i.32" \n
		}
	}
}

body HexEditor::event:backSpace {} {
	set win $path.h
	set cur [$win.hex index insert]
	if {[regexp {[0-9]+\.0} $cur]} {
		return
	}

	if {[string compare [$win.hex tag nextrange sel 1.0 end] ""]} {
		$win.hex delete sel.first sel.last
	} elseif {[$win.hex compare insert != 1.0]} {
		$win.hex delete insert-1c
		$win.hex see insert
	}

	after idle [list $this resizeColumns]
	after idle [list $this updateASCII]
	after idle [list $this updateOffset]

	eval $itk_option(-modifycmd)
}

body HexEditor::event:delete {} {
	set win $path.h
	if {[catch {$win.hex delete sel.first sel.last}]} {
		$win.hex delete insert
	}

	after idle [list $this resizeColumns]
	after idle [list $this updateASCII]
	after idle [list $this updateOffset]

	eval $itk_option(-modifycmd)
}

body HexEditor::event:insert {char} {
	if {[isReadOnly] || [isDisabled]} return

	set win $path.h
	if {![regexp {[0-9a-f]} $char]} {
		return
	}

	if {$_insertionMode == "overwrite"} {
		$win.hex delete insert [$win.hex index "insert + 1 chars"]
	}

	$win.hex insert insert $char
	$win.hex see insert
	$this resizeColumns
	after idle [list $this updateASCII]
	after idle [list $this updateOffset]

	eval $itk_option(-modifycmd)
}

body HexEditor::setReadOnly {boolean} {
	if {$boolean} {
		$path.h.hex configure -state disabled
	} else {
		$path.h.hex configure -state normal -foreground ${::SQLEditor::foreground_color}
		$path.h.ascii configure -foreground ${::SQLEditor::foreground_color}
	}
	set _readOnly $boolean
}

body HexEditor::setDisabled {boolean} {
	if {$boolean} {
		$path.h.hex configure -state disabled -foreground $::DISABLED_FONT_COLOR
		$path.h.ascii configure -foreground $::DISABLED_FONT_COLOR
	} else {
		$path.h.hex configure -state normal -foreground ${::SQLEditor::foreground_color}
		$path.h.ascii configure -foreground ${::SQLEditor::foreground_color}
	}
	set _disabled $boolean
}

body HexEditor::isReadOnly {} {
	return $_readOnly
}

body HexEditor::isDisabled {} {
	return $_disabled
}

body HexEditor::bindEdits {sequence script} {
	bind HexEdit$path.h $sequence $script
	bind HexEditASCII$path.h $sequence $script
}

body HexEditor::setFocus {} {
	focus $path.h.hex
}

body HexEditor::switchInsertionMode {} {
	switch -- $_insertionMode {
		"insert" {
			set _insertionMode "overwrite"
			$path.h.hex configure -insertofftime 0
		}
		"overwrite" {
			set _insertionMode "insert"
			$path.h.hex configure -insertofftime 500
		}
	}
}

