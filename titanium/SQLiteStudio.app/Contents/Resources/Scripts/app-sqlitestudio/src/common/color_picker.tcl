use src/common/panel.tcl

#>
# @class ColorPicker
# Button with color drawed on it. When pressed opens {@class ColorDialog}
# and gets new color from it. You have to pass <code>-variable</code> option
# to determinate in what variable store currently choosen color value.
#<
class ColorPicker {
	inherit Panel

	#>
	# @method constructor
	# @param args Parameters to pass to {@class Panel}.
	# This constructor interpretes extra options:
	# <ul>
	# <li><code>-variable</code> - name of the variable to store currently selected color value in (mandatory option).
	# <li><code>-label</code> - optional label for the button.
	# </ul>
	#<
	constructor {args} {
		Panel::constructor {*}$args
	} {}

	private {
		#>
		# @var _img
		# Tk image object used to draw color on the button.
		#<
		variable _img ""

		#>
		# @var _var
		# Name of variable to store color value in. It's the same value as passed to <code>-variable</code> option.
		#<
		variable _var ""
		
		variable _parent "."
		
		#>
		# @method fill
		# @param col Color to fill image with.
		# Fills {@var _img} image with given color.
		#<
		method fill {col}
	}

	public {
		#>
		# @method choose
		# Called when button is pressed. Opens {@class ColorDialog} and gets color from it,
		# then updates color drawed on the button and value of variable passed wit <code>-variable</code>.
		#<
		method choose {}
	}
}

body ColorPicker::constructor {args} {
	set label ""
	parseArgs {
		-variable {set _var $value}
		-label {set label $value}
		-parent {set _parent $value}
	}

	set _img [image create photo -width 14 -height 14]
	fill [set $_var]

	ttk::button $path.btn -image $_img -command "$this choose"
	ttk::label $path.lab -text $label
	pack $path.btn -side left
	pack $path.lab -side left -padx 5
}

body ColorPicker::choose {} {
	set col [GetColor -title [mc {Choose color}] -initialcolor [set $_var] -parent $_parent]
	if {$col == ""} return
	set $_var $col
	fill $col
}

body ColorPicker::fill {col} {
	if {[catch {
		$_img put $col -to 0 0 14 14
	}]} {
		set $_var #FFFFFF
		$_img put #FFFFFF -to 0 0 14 14
	}
}
