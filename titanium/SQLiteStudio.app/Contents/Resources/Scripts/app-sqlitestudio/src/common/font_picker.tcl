use src/common/panel.tcl

class FontPicker {
	inherit Panel

	constructor {args} {
		eval Panel::constructor $args
	}

	opt label
	opt variable

	private {
		variable _var ""
		variable _entry ""
		method fillFontLabel {font}
	}

	public {
		method choose {}
	}
}

body FontPicker::constructor {args} {
	set w [ttk::frame $path.f -relief groove -borderwidth 1]
	pack $w -side top -fill x

	ttk::button $w.btn -text [mc {Change}] -command "$this choose"
	#set _entry [ttk::entry $w.entry -justify right]
	set _entry [ttk::label $w.entry -justify right -relief sunken -background ${::SQLEditor::background_color}]
	ttk::label $w.lab -text ""
	pack $w.btn -side right
	pack $_entry -side right -padx 1
	pack $w.lab -side left

	eval itk_initialize $args
	set _var $itk_option(-variable)
	set fnt [set $_var]
	$w.lab configure -text $itk_option(-label)
	fillFontLabel $fnt
}

body FontPicker::choose {} {
	catch {::ChooseFont::Done 0}
	set fnt [::ChooseFont::ChooseFont [set $_var]]
	if {$fnt == ""} return
	#font configure [set $_var] {*}[font actual $fnt]
	set $_var $fnt
	fillFontLabel $fnt
}

body FontPicker::fillFontLabel {font} {
	set family [font actual $font -family]
	set size [font actual $font -size]
	if {$size < 0} {
		set size [expr {-$size}]
	}
	set bold [expr {[font actual $font -weight] == "bold" ? 1 : 0}]
	set underline [font actual $font -underline]
	set italic [expr {[font actual $font -slant] == "italic" ? 1 : 0}]
	set overstrike [font actual $font -overstrike]

	set buffer $family
	append buffer ", $size"
	if {$bold} {
		append buffer ", bold"
	}
	if {$underline} {
		append buffer ", underline"
	}
	if {$italic} {
		append buffer ", italic"
	}
	if {$overstrike} {
		append buffer ", overstrike"
	}

# 	$_entry configure -state normal
# 	$_entry delete 0 end
# 	$_entry configure -font $font
# 	$_entry insert end $buffer
# 	$_entry configure -state disabled -width [string length $buffer]
	$_entry configure -font $font -text $buffer
}
