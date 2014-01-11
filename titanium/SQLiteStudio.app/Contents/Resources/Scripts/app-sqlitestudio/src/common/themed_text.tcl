use src/common/ui.tcl

class Text {
	inherit UI Panel

	constructor {args} {
		Panel::constructor {*}$args
	} {}

	private {
		variable _edit ""
	}

	public {
		method updateUISettings {}
		method getEdit {}
		method readonly {boolean}
		method select {startIdx endIdx}
	}
}

body Text::constructor {args} {
	ttk::frame $path.top
	ttk::frame $path.bottom
	itk_component add edit {
		text $path.top.edit -background ${::SQLEditor::background_color} -foreground ${::SQLEditor::foreground_color} \
			-selectbackground ${::SQLEditor::selected_background} -selectforeground ${::SQLEditor::selected_foreground} \
			-yscrollcommand "$path.top.vscroll set" -xscrollcommand "$path.bottom.hscroll set" \
			-wrap none -height 1 -width 1
	}
	ttk::scrollbar $path.top.vscroll -command "$path.top.edit yview" -orient vertical
	ttk::scrollbar $path.bottom.hscroll -command "$path.top.edit xview" -orient horizontal

	set _edit $path.top.edit

	pack $_edit -side left -fill both -expand 1
	pack $path.top.vscroll -side right -fill y
	pack $path.bottom.hscroll -side bottom -fill x
	pack $path.top -side top -fill both -expand 1
	pack $path.bottom -side bottom -fill x
	autoscroll $path.top.vscroll

	bind $path.top.edit <Control-a> "$this select 1.0 end; break"

	itk_initialize {*}$args
	updateUISettings
}

body Text::updateUISettings {} {
	$_edit configure -background ${::SQLEditor::background_color} -foreground ${::SQLEditor::foreground_color} \
		-selectbackground ${::SQLEditor::selected_background} -selectforeground ${::SQLEditor::selected_foreground}
}

body Text::getEdit {} {
	return $_edit
}

body Text::readonly {boolean} {
	$_edit configure -state [expr {$boolean ? "disabled" : "normal"}]
	bind $_edit <1> {focus %W}
}

body Text::select {startIdx endIdx} {
	$path.top.edit tag add sel $startIdx $endIdx
}

