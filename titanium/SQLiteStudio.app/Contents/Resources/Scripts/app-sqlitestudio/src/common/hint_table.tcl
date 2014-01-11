class HintTable {
	inherit Panel

	common background "#EEEEEE"
	common foreground "#000000"
	common boldFont "TkTooltipFontBold"
	common font "TkTooltipFont"

	constructor {args} {
		eval Panel::constructor $args
	} {}

	private {
		variable _root ""
		variable _seq 1
		variable _toplevel ""
		variable _mode "label-label"
		variable _valueWrapLength 500

		method doBind {w}
	}

	public {
		method setTitle {title}
		method addRow {key value}
		method addGroup {{title ""}}
		method setMode {mode}
		method setValueWrapLength {value}
	}
}

body HintTable::constructor {args} {
	eval itk_initialize $args

	set _toplevel [winfo toplevel $path]

	set _root [frame $path.f -background $background]
	pack $_root -fill both -expand 1

	grid anchor $_root center

	doBind $_root
}

body HintTable::setMode {mode} {
	set _mode $mode
}

body HintTable::setValueWrapLength {value} {
	set _valueWrapLength $value
}

body HintTable::doBind {w} {
	bind $w <ButtonPress-1> [list catch [list destroy $_toplevel]]
}

body HintTable::setTitle {title} {
	label $_root.title -background $foreground -foreground $background -font $boldFont -justify center -text $title
	grid $_root.title -row 0 -column 0 -columnspan 2 -sticky we -ipady 2 -pady 2 -padx 2
	doBind $_root.title
}

body HintTable::addRow {key value} {
	switch -- $_mode {
		"label-label" {
			label $_root.left_$_seq -background $background -foreground $foreground -font $font -justify left -text $key
			label $_root.right_$_seq -background $background -foreground $foreground -font $boldFont -justify right -text $value \
				-wraplength $_valueWrapLength
			grid $_root.left_$_seq -row $_seq -column 0 -sticky nw -pady 2 -padx 1
			grid $_root.right_$_seq -row $_seq -column 1 -sticky ne -pady 2 -padx 1
			doBind $_root.left_$_seq
			doBind $_root.right_$_seq
		}
		"img-label" {
			label $_root.left_$_seq -background $background -justify left -image $key
			label $_root.right_$_seq -background $background -foreground $foreground -font $boldFont -justify right -text $value \
				-wraplength $_valueWrapLength
			grid $_root.left_$_seq -row $_seq -column 0 -sticky nw -pady 2 -padx 1
			grid $_root.right_$_seq -row $_seq -column 1 -sticky nw -pady 2 -padx 1
			doBind $_root.left_$_seq
			doBind $_root.right_$_seq
		}
		"img-label-label" {
			lassign $key img key
			label $_root.left_$_seq -background $background -justify left -image $img -text $key -compound left -font $font
			label $_root.right_$_seq -background $background -foreground $foreground -font $boldFont -justify right -text $value \
				-wraplength $_valueWrapLength
			grid $_root.left_$_seq -row $_seq -column 0 -sticky nw -pady 2 -padx 1
			grid $_root.right_$_seq -row $_seq -column 1 -sticky e -pady 2 -padx 1
			doBind $_root.left_$_seq
			doBind $_root.right_$_seq
		}
		"-label" {
			label $_root.left_$_seq -background $background -foreground $foreground -font $boldFont -justify left -text $value \
				-wraplength $_valueWrapLength
			grid $_root.left_$_seq -row $_seq -column 0 -columnspan 2 -sticky ne -pady 2 -padx 1
			doBind $_root.left_$_seq
		}
	}
	incr _seq
}

body HintTable::addGroup {{title ""}} {
	frame $_root.group_$_seq -background $foreground
	grid $_root.group_$_seq -row $_seq -column 0 -columnspan 2 -pady 4 -padx 1 ;#-sticky we

	set group [HintTable $_root.group_$_seq.table]
	if {$title != ""} {
		$group setTitle $title
	}
	pack $group -fill both -padx 1 -pady 1 -expand 1
	return $group
}
