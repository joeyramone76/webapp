class SLabel {
	inherit itk::Widget

	# Workaround for Itk+Ttk
	itk_option define -anchor anchor Anchor "center"
	itk_option define -justify justify Justify "center"
	# The -background doesn't want to work in any way. Have to exluce it.

	itk_option define -wrap wrap Wrap "none"
	itk_option define -text text Text ""

	constructor {args} {}

	private {
		variable _text ""
		variable _label ""
	}
	
	public {
		method updateTextWrap {w}
	}
}

body SLabel::constructor {args} {
	set typeIdx [lsearch -exact $args "-type"]
	set type "ttk"
	if {$typeIdx > -1} {
		set argIdx [expr {$typeIdx+1}]
		set type [lindex $args $argIdx]
		set args [lreplace $args $typeIdx $argIdx]
	}

	switch -- $type {
		"ttk" {
			itk_component add -protected label.ttk {
				ttk::label $itk_interior.l
			} {
				usual SLabel
				keep -padding -style
			}
			set _label $itk_component(label.ttk)
		}
		"tk" {
			itk_component add -protected label.tk {
				label $itk_interior.l
			} {
				usual SLabel
				keep -activebackground -activeforeground -anchor -background -bitmap
				keep -borderwidth -disabledforeground -highlightbackground
				keep -highlightcolor -highlightthickness -justify -padx -pady -wraplength
				keep -height -state
			}
			set _label $itk_component(label.tk)
		}
	}

	pack $_label

	itk_initialize {*}$args
}

body SLabel::updateTextWrap {w} {
	set wd [winfo width [winfo parent $w]]
	set font [expr {$itk_option(-font) != "" ? $itk_option(-font) : "TkDefaultFont"}]
	set textWd [font measure $font $_text]
	
	switch -- $itk_option(-wrap) {
		"word" {
			$_label configure -wraplength $wd
		}
		"char" {
			if {$textWd < $wd} {
				$_label configure -text $_text
				return
			}
			$_label configure -text [wrapTextByChar $_text $font $wd]
		}
		"none" {
			$_label configure -text $_text
		}
	}
}

configbody SLabel::text {
	set _text $itk_option(-text)
	$_label configure -text $_text
	updateTextWrap $itk_component(hull)
}

configbody SLabel::anchor {
	$_label configure -anchor $itk_option(-anchor)
}

configbody SLabel::justify {
	$_label configure -justify $itk_option(-justify)
}

configbody SLabel::wrap {
	if {$itk_option(-wrap) != "word"} {
		$_label configure -wraplength 0
	}

	if {$itk_option(-wrap) in [list "word" "char"]} {
		bind $itk_component(hull) <Configure> [list $this updateTextWrap %W]
	} elseif {$itk_option(-wrap) == "none"} {
		bind $itk_component(hull) <Configure> ""
	} else {
		error "invalid value for -wrap option: $itk_option(-wrap). Should be one of: word, char, or none."
	}
}

usual SLabel {
	keep -compound -cursor -image
	keep -takefocus -textvariable -underline
	keep -width -font -foreground
	keep -relief
}
