use src/common/ui.tcl

class StatusField {
	inherit UI

	constructor {root} {}

	common background_color "white"
	common foreground_color "black"
	common error_color "red"
	common info_color "blue"
	common info2_color "green"
	common font "StatusFont"
	common boldFont "StatusFontBold"

	private {
		variable _root ""
		variable _edit ""
		variable _editWin ""
	}

	public {
		method clear {}
		method addMessage {msg {type normal} {bold 0}}
		method getWidget {}
		method updateUISettings {}
	}
}

body StatusField::constructor {root} {
	set _root $root
	ttk::frame $_root

	upvar this editWin
	set _editWin $editWin

	pack [ttk::frame $_root.top] -side top -fill x
	button $_root.top.close -image img_small_close -border 1 -command "$_editWin hideStatus"
	pack $_root.top.close -side right -padx 5 -pady 1

	pack [ttk::frame $_root.bottom] -side bottom -fill both -expand 1
	set _edit [text $_root.bottom.text -background $background_color -foreground $foreground_color -borderwidth 1 -state disabled -selectborderwidth 0 \
		-insertbackground white -yscrollcommand "$_root.bottom.s set" -height 3 -font $font -wrap word]
	#set fnt [$_edit cget -font]
	ttk::scrollbar $_root.bottom.s -command "$_edit yview"
	pack $_root.bottom.s -side right -fill y
	pack $_edit -side left -fill both -expand 1

	$_edit tag configure col_err -foreground $error_color
	$_edit tag configure col_info -foreground $info_color
	$_edit tag configure col_info2 -foreground $info2_color
	$_edit tag configure bold -font $boldFont
}

body StatusField::clear {} {
	$_edit configure -state normal
	$_edit delete 1.0 end
	$_edit configure -state disabled
}

body StatusField::addMessage {msg {type normal} {bold 0}} {
	if {[string index $msg end] != "\n"} {
		append msg "\n"
	}

	$_edit configure -state normal
	set tags [list]
	set img ""
	switch -- $type {
		error {
			lappend tags col_err
			set img "img_error"
		}
		info {
			lappend tags col_info
			set img "img_info"
		}
		info2 {
			lappend tags col_info2
			set img "img_info"
		}
		warning {
			lappend tags col_info
			set img "img_warning"
		}
	}
	if {$bold} {
		lappend tags bold
	}
	if {$img != ""} {
		$_edit image create end -image $img
		$_edit insert end " "
	}
	$_edit insert end $msg $tags
	$_edit see end
	$_edit configure -state disabled
}

body StatusField::getWidget {} {
	return $_edit
}

body StatusField::updateUISettings {} {
	font configure $boldFont -family [font actual $font -family] -size [font actual $font -size] -weight bold
	$_edit configure -background $background_color -foreground $foreground_color -font $font

	$_edit tag configure col_err -foreground $error_color
	$_edit tag configure col_info -foreground $info_color
	$_edit tag configure col_info2 -foreground $info2_color
	$_edit tag configure bold -font $boldFont
}
