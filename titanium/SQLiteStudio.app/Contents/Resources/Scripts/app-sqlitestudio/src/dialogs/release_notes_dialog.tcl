use src/dialogs/text_browse.tcl

class ReleaseNotesDialog {
	inherit TextBrowseDialog

	constructor {args} {
		TextBrowseDialog::constructor {*}$args
	} {}

	private {
		method saveDisabled {}
		method getText {}
		method formatText {txt}
	}

	protected {
# 		method getSize {}
		method okClicked {}
		method cancelClicked {}
	}

	public {
		variable uiVar
	}
}

body ReleaseNotesDialog::constructor {args} {
	ttk::frame $_root.disable
	pack $_root.disable -side bottom -fill x -after $_root.d -pady 3
	set uiVar(disabled) 0
	ttk::checkbutton $_root.disable.c -text [mc {Don't show this dialog after update.}] -variable [scope uiVar](disabled)
	pack $_root.disable.c -side left -fill x
	
	setText [getText]

	set font [$_text cget -font]
	if {[llength $font] == 1} {
		set act [font actual $font]
		set font [list [dict get $act -family] [dict get $act -size]]
	}
	$_text tag configure bold -font "$font bold"

	set startIdx 1.0
	set was [list]
	set re {[\*\-]{3}\s[^\n]+}
	while {[set idx [$_text search -forwards -regexp -- $re $startIdx]] != ""} {
		if {[lsearch -exact $was $idx] != -1} {
			break
		}
		$_text tag add bold $idx [$_text index "$idx lineend"]
		lappend was $idx
		set startIdx [$_text index "$idx +1 chars"]
	}
}

body ReleaseNotesDialog::okClicked {} {
	saveDisabled
}

body ReleaseNotesDialog::cancelClicked {} {
	# In case user closed with "X" of window
	saveDisabled
}

body ReleaseNotesDialog::saveDisabled {} {
}

body ReleaseNotesDialog::getText {} {
	set txt ""
	foreach idx [lsort -dictionary -decreasing [array names ::releaseNotes]] {
		append txt "*** $idx"
		append txt \n\n
		append txt [formatText $::releaseNotes($idx)]
	}
	return $txt
}

body ReleaseNotesDialog::formatText {txt} {
	set lines [list]
	set bufferedLine [list]
	foreach line [lrange [split $txt \n] 1 end-1] {
		if {[string trim $line] == ""} {
			lappend lines [string map [list "\\n " "\n" "\\n" "\n"] [join $bufferedLine " "]] ""
			set bufferedLine [list]
		} else {
			lappend bufferedLine [string range $line 1 end]
		}
	}

	if {[llength $bufferedLine] > 0} {
		lappend lines [string map [list "\\n " "\n" "\\n" "\n"] [join $bufferedLine " "]] ""
	}

	return [join $lines \n]
}
