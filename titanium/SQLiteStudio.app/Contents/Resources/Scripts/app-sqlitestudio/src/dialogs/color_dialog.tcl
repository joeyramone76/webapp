use src/common/modal.tcl

#>
# @class ColorDialog
# Replacement for standard Unix tk_colorChooser, which is very poor.
# This one is similar to many common color pickers.
#<
class ColorDialog {
	inherit Modal

	#>
	# @var palette
	# This variable keeps a name of Tk image object with colors palette used in the dialog.
	#<
	common palette "ColorDialogPalette"

	#>
	# @method constructor
	# @param args Parameters to pass to {@class Modal}.
	# Constructor interpretes extra option in parameters:
	# <ul>
	# <li><code>-initialcolor</code> - specifies initial color to choose when creating dialog.
	# </ul>
	# @see var _color
	#<
	constructor {args} {
		Modal::constructor {*}$args -modal 1
	} {}

	private {
		#>
		# @var _color
		# Keeps currently selected color in format <code>#RRGGBB</code>.
		#<
		variable _color "#FF0000"

		#>
		# @var _choosenSideValue
		# Keeps value choosen on brightness as vertical position on right side bar.
		# "194" means a black color and "2" means an essential of color.
		# Any values less then 2 or greater than 194 are rounded to fit that bounds.
		#<
		variable _choosenSideValue 0

		#>
		# @var _choosenValueX
		# Keeps X position of choosen color on colors palette.
		# Any values less then 2 or greater than 194 are rounded to fit that bounds.
		#<
		variable _choosenValueX 0

		#>
		# @var _choosenValueY
		# Keeps Y position of choosen color on colors palette.
		# Any values less then 2 or greater than 194 are rounded to fit that bounds.
		#<
		variable _choosenValueY 0

		#>
		# @arr _entry
		# Array of red, blue and green variables linked to parallel {@var _edit} widgets.
		# Each of them contain value of its color in range of 0-255.
		#<
		variable _entry

		#>
		# @var _currColImg
		# Tk image object representing currently choosen color.
		#<
		variable _currColImg ""

		#>
		# @var _sidePalette
		# Image representing palette of brightness on the right side.
		#<
		variable _sidePalette ""

		#>
		# @var _tmpImage
		# This image isn't shown anywhere. It's used to transform named colors to RGB values representation easly.
		#<
		variable _tmpImage ""

		#>
		# @var _canvSide
		# Canvas widget used to make right side bar (brightness bar).
		#<
		variable _canvSide ""

		#>
		# @var _canv
		# Canvas widget used to make the main color palette.
		#<
		variable _canv ""

		#>
		# @var _sidePtr
		# Canvas item representing brightness picker on right side bar.
		#<
		variable _sidePtr ""

		#>
		# @var _ptr
		# Canvas item representing color picker on the main colors palette.
		#<
		variable _ptr ""

		#>
		# @var _edit
		# Array of red, blue, green and html entry field widgets. Indexed with: 'r', 'g', 'b' and 'html'.
		#<
		variable _edit

		#>
		# @method updateSidePaletteStatus
		# Updates {@var _sidePalette} image so brightness bar is appropriate for currently selected color.
		#<
		method updateSidePaletteStatus {}

		#>
		# @method updateCurrColor
		# Updates color value entry fields ({@var _edit}, {@var _entry}), current color representation ({@var _currColImg})
		# and brightness side bar palette ({@var _sidePalette})
		#<
		method updateCurrColor {}

		#>
		# @method updatePresetColor
		# This method is called at dialog creation moment and also whenever any {@var _edit} value is changed.
		# It moves pickers on main color palette, picker on brightness side bar and updates brightness side bar palette.
		#<
		method updatePresetColor {}

		#>
		# @method sideBarPut
		# @param y Y coordinate to put color at.
		# @param r Red value of color to put.
		# @param g Green value of color to put.
		# @param b Blue value of color to put.
		# It's used to refresh brightness bar palette. Puts 1-pixel height line on the palette with given color.
		#<
		method sideBarPut {y r g b}

		#>
		# @method getChoosenColor
		# Calls {@method getColor} with currently selected values.
		# @return Results of {@method getColor}.
		#<
		method getChoosenColor {}

		#>
		# @method getColor
		# @param x X coordinate of main color palette picker.
		# @param y Y coordinate of main color palette picker.
		# @param z Position of brightness palette picker.
		#<
		method getColor {x y z}

		#>
		# @method rgbToHsv
		# @param r Red color value.
		# @param g Green color value.
		# @param b Blue color value.
		# Converts RGB color representation to HSV representation.
		# @return List of 3 elements: <b>H</b>ue, <b>S</b>aturation and <b>V</b>alue.
		#<
		proc rgbToHsv {r g b}

		#>
		# @method hsvToRgb
		# @param h Hue color value.
		# @param s Saturation color value.
		# @param v Value (brightness) color value.
		# Converts HSV color representation to RGB representation.
		# @return List of 3 elements: <b>R</b>ed, <b>G</b>reen and <b>B</b>lue.
		#<
		proc hsvToRgb {h s v}
	}

	public {
		#>
		# @method grabWidget
		# @overloaded Modal
		#<
		method grabWidget {}

		#>
		# @method okClicked
		# @overloaded Modal
		#<
		method okClicked {}

		#>
		# @method moveSidePtr
		# @param y New position to set.
		# Moves brightness side bar picker to given position. Also updates all necessary widgets and variables.
		# Called by {@var _canvSide} widget while using mouse button on it.
		#<
		method moveSidePtr {y}

		#>
		# @method movePtr
		# @param x New X position to set.
		# @param y New Y position to set.
		# Moves main color picker to given position. Also updates all necessary widgets and variables.
		# Called by {@var _canv} widget while using mouse button on it.
		#<
		method movePtr {x y}

		#>
		# @method colorEdited
		# @param type One of 'r', 'g', 'b', or 'html'.
		# @param newVal New filled value.
		# Updates all necessaty widgets and variables to fit newly entered value in some color entry field
		# (<i>type</i> parameter determinates which one is it). Called by all widgets from {@var _edit} array,
		# whenever their values are changed by application user.
		#<
		method colorEdited {type newVal}
	}
}

body ColorDialog::constructor {args} {
	pack [ttk::frame $_root.u] -side top -fill both -expand 1
	pack [ttk::frame $_root.d] -side bottom -fill x
	pack [ttk::frame $_root.u.l] -side left -fill both
	pack [ttk::frame $_root.u.r] -side right -fill both

	parseArgs {
		-initialcolor {set _color $value}
	}

	set _tmpImage [image create photo]

	# Main color palette
	set _canv $_root.u.l.canv
	canvas $_canv -width 192 -height 192 -borderwidth 1 -relief solid
	pack $_canv -side left
	$_canv create image 98 98 -image $palette
	set _ptr [$_canv create image 0 0 -image img_color_dialog_main_ptr]
	bind $_canv <ButtonPress-1> "$this movePtr %x %y"
	bind $_canv <B1-Motion> "$this movePtr %x %y"

	# Side color palette
	set _canvSide $_root.u.l.canvside
	canvas $_canvSide -width 28 -height 192 -background white -borderwidth 1 -relief solid
	pack $_canvSide -side right
	set _sidePalette [image create photo -format png -height 193 -width 20]
	$_canvSide create image 10 98 -image $_sidePalette
	set _sidePtr [$_canvSide create image 25 2 -image img_color_dialog_ptr]
	bind $_canvSide <ButtonPress-1> "$this moveSidePtr %y"
	bind $_canvSide <B1-Motion> "$this moveSidePtr %y"

	# Current color
	set _currColImg [image create photo -width 40 -height 40]
	label $_root.u.r.currColor -image $_currColImg -relief sunken -borderwidth 1
	pack $_root.u.r.currColor -side top -pady 10 -padx 15

	# RGB inputs
	pack [ttk::frame $_root.u.r.f] -side bottom -fill both -padx 10 -pady 10
	set _edit(html) [ttk::entry $_root.u.r.f.rgb -textvariable [scope _color] -width 9 -justify left \
		-validate key -validatecommand [list $this colorEdited html %P]]
	pack $_root.u.r.f.rgb -side top -pady 3
	foreach c {r g b} l {R: G: B:} {
		pack [ttk::frame $_root.u.r.f.$c] -side top -fill x -pady 3
		ttk::label $_root.u.r.f.$c.l -text $l
		set _entry($c) 0
		set _edit($c) [ttk::entry $_root.u.r.f.$c.e -textvariable [scope _entry($c)] -width 4 -justify right \
			-validate key -validatecommand [list $this colorEdited $c %P]]
		pack $_root.u.r.f.$c.l -side left
		pack $_root.u.r.f.$c.e -side right
	}

	# Bottom buttons
	ttk::button $_root.d.ok -text [mc {Ok}] -command "$this clicked ok" -compound left -image img_ok
	ttk::button $_root.d.cancel -text [mc {Cancel}] -command "$this clicked cancel" -compound left -image img_cancel
	pack $_root.d.ok -side left -padx 15 -pady 3
	pack $_root.d.cancel -side right -padx 15 -pady 3

	# Initializing
	updateSidePaletteStatus
	updatePresetColor
	updateCurrColor
}

body ColorDialog::updatePresetColor {} {
	$_tmpImage put $_color -to 0 0
	lassign [$_tmpImage get 0 0] r g b
	lassign [rgbToHsv $r $g $b] h s v

	set x [expr { round( double($h) / 360 * 192 ) + 2 }]
	set y [expr { 192 - round( double($s) / 255 * 192 ) + 2 }]
	set z [expr { 192 - round( double($v) / 255 * 192 ) + 2 }]

	movePtr $x $y
	moveSidePtr $z
}

body ColorDialog::rgbToHsv {r g b} {
	set temp [min $r $g $b]
	set v [max $r $g $b]
	set value $v
	set bottom [expr {$v-$temp}]
	if {$bottom == 0} {
		set hue 0
		set saturation 0
		set value $v
	} else {
		if {$v == $r} {
			set top [expr {$g-$b}]
			if {$g >= $b} {
				set angle 0
			} else {
				set angle 360
			}
		} elseif {$v == $g} {
			set top [expr {$b-$r}]
			set angle 120
		} elseif {$v == $b} {
			set top [expr {$r-$g}]
			set angle 240
		}
		set hue [expr { round( 60 * ( double($top) / $bottom ) + $angle ) }]
	}

	if {$v == 0} {
		set saturation 0
	} else {
		set saturation [expr { round( 255 - 255 * ( double($temp) / $v ) ) }]
	}
	return [list $hue $saturation $value]
}

body ColorDialog::hsvToRgb {h s v} {
	set Hi [expr { int( double($h) / 60 ) % 6 }]
	set f [expr { double($h) / 60 - $Hi }]
	set s [expr { double($s)/255 }]
	set v [expr { double($v)/255 }]
	set p [expr { double($v) * (1 - $s) }]
	set q [expr { double($v) * (1 - $f * $s) }]
	set t [expr { double($v) * (1 - (1 - $f) * $s) }]
	switch -- $Hi {
		0 {
			set r $v
			set g $t
			set b $p
		}
		1 {
			set r $q
			set g $v
			set b $p
		}
		2 {
			set r $p
			set g $v
			set b $t
		}
		3 {
			set r $p
			set g $q
			set b $v
		}
		4 {
			set r $t
			set g $p
			set b $v
		}
		5 {
			set r $v
			set g $p
			set b $q
		}
		default {
			error "Hi=6 in hsvToRgb procedure! This should never happen!"
		}
	}
	set r [expr {round($r*255)}]
	set g [expr {round($g*255)}]
	set b [expr {round($b*255)}]
	return [list $r $g $b]
}

body ColorDialog::moveSidePtr {y} {
	if {$y < 2} {
		set y 2
	}
	if {$y > 194} {
		set y 194
	}
	$_canvSide coords $_sidePtr 25 $y
	incr y -2
	set _choosenSideValue $y
	updateCurrColor
}

body ColorDialog::movePtr {x y} {
	if {$y < 2} {
		set y 2
	}
	if {$y > 194} {
		set y 194
	}
	if {$x < 2} {
		set x 2
	}
	if {$x > 193} {
		set x 193
	}
	$_canv coords $_ptr $x $y
	incr y -2
	incr x -2
	set _choosenValueX $x
	set _choosenValueY $y
	updateCurrColor
}

body ColorDialog::getColor {x y z} {
	set h [expr { round( double($x) / 192 * 360 ) }]
	set s [expr { round( double(192 - $y) / 192 * 255 ) }]
	set v [expr { round( double(192 - $z) / 192 * 255 ) }]
	lassign [hsvToRgb $h $s $v] r g b
	return [format {#%02X%02X%02X} $r $g $b]
}

body ColorDialog::getChoosenColor {} {
	return [getColor $_choosenValueX $_choosenValueY $_choosenSideValue]
}

body ColorDialog::updateCurrColor {} {
	set _color [getChoosenColor]
	updateSidePaletteStatus

	$_currColImg put $_color -to 0 0 40 40
	$_tmpImage put $_color -to 0 0
	foreach name {r g b} col [$_tmpImage get 0 0] {
		set _entry($name) $col
	}
}

body ColorDialog::sideBarPut {y r g b} {
	$_sidePalette put [format #%02x%02x%02x $r $g $b] -to 0 $y 20 [expr {$y+1}]
}

body ColorDialog::updateSidePaletteStatus {} {
	$_tmpImage put [getColor $_choosenValueX $_choosenValueY 0] -to 0 0
	lassign [$_tmpImage get 0 0] r g b

	set max [max $r $g $b]
	if {$r == $max} {
		set oldR $r
		set r 255
		set g [expr {round( (double($r) / ($oldR == 0 ? 1 : $oldR)) * $g)}]
		set b [expr {round( (double($r) / ($oldR == 0 ? 1 : $oldR)) * $b)}]
	} elseif {$g == $max} {
		set oldG $g
		set g 255
		set r [expr {round( (double($g) / ($oldG == 0 ? 1 : $oldG)) * $r)}]
		set b [expr {round( (double($g) / ($oldG == 0 ? 1 : $oldG)) * $b)}]
	} elseif {$b == $max} {
		set oldB $b
		set b 255
		set r [expr {round( (double($b) / ($oldB == 0 ? 1 : $oldB)) * $r)}]
		set g [expr {round( (double($b) / ($oldB == 0 ? 1 : $oldB)) * $g)}]
	} else {
		error "Error while determinating maximal value of color."
	}

	set incr(R) [expr {double($r) / 192}]
	set incr(G) [expr {double($g) / 192}]
	set incr(B) [expr {double($b) / 192}]

	for {set i 0} {$i < 193} {incr i} {
		sideBarPut $i [expr {round($r)}] [expr {round($g)}] [expr {round($b)}]
		set r [expr {$r - $incr(R)}]
		set g [expr {$g - $incr(G)}]
		set b [expr {$b - $incr(B)}]
	}
}

body ColorDialog::grabWidget {} {
	return $_root
}

body ColorDialog::okClicked {} {
	return $_color
}

body ColorDialog::colorEdited {type newVal} {
	switch -- $type {
		"r" {
			set r $newVal
			if {!([string is digit $r] && $r < 256 && $r >= 0)} {
				return false
			}
			set g [$_edit(g) get]
			set b [$_edit(b) get]
			set _color [format {#%02X%02X%02X} $r $g $b]
		}
		"g" {
			set g $newVal
			if {!([string is digit $g] && $g < 256 && $g >= 0)} {
				return false
			}
			set r [$_edit(r) get]
			set b [$_edit(b) get]
			set _color [format {#%02X%02X%02X} $r $g $b]
		}
		"b" {
			set b $newVal
			if {!([string is digit $b] && $b < 256 && $b >= 0)} {
				return false
			}
			set r [$_edit(r) get]
			set g [$_edit(g) get]
			set _color [format {#%02X%02X%02X} $r $g $b]
		}
		"html" {
			set c $newVal
 			if {![regexp -- {^#{1}[a-fA-F0-9]{6}$} $c]} {
				if {[regexp -- {^#{0,1}[a-fA-F0-9]{0,6}$} $c]} {
					return true
				} else {
 					return false
				}
 			}
			set _color $c
		}
		default {
			error "Unknown edition type: $type"
		}
	}
	updatePresetColor
	return true
}

image create photo ${ColorDialog::palette} -format png -data {
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
TkSuQmCC
}
