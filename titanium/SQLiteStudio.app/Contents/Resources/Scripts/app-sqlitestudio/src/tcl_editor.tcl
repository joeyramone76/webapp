use src/sql_editor.tcl

class TclEditor {
	inherit SQLEditor

	common brackets_color "#222222"
	common square_brackets_color "black"
	common keywords_color "black"
	common options_color "black"
	common variables_color "blue"
	common comments_color "#CCCCCC"
	common chars_color "pink"
	common selected_background "#DDDDEE"
	common selected_foreground "#442222"
	common strings_color "#007700"
	common foreground_color "black"
	common background_color "white"
	common disabled_background "gray"
	common matched_bracket_bgcolor "black"
	common matched_bracket_fgcolor "white"

	#>
	# @method constructor
	# @param args Option-value pairs. Valid option is: <code>-yscrollcommand</code>.
	# Supported are all options handled by <code>text</code> widget and additionaly the followings:
	# <code>-yscroll</code> - <code>true</code> to enable vertical scrollbar, <code>false</code> to hide it. Defaults to <code>true</code>,<br>
	# <code>-linenumbers</code> - <code>true</code> to show linue nubers in editor, or <code>false</code> otherwise.
	#<
	constructor {args} {
		SQLEditor::constructor {*}$args
	} {}

	public {
		method updateUISettings {}
		method updateShortcuts {}
		method handleUserInput {key state}
	}
}

body TclEditor::constructor {args} {
	ctext::getAr $_edit config ar
	set ar(ext_strings) 0
	set ar(ext_comments) 0
}

body TclEditor::updateShortcuts {} {
	SQLEditor::updateShortcuts
	bind $_edit.t <${::Shortcuts::editorComplete}> ""
}

body TclEditor::updateUISettings {} {
	# Refreshing configuration
	$_edit configure -background $background_color -foreground $foreground_color \
		-selectbackground $selected_background -selectforeground $selected_foreground \
		-font $::SQLEditor::font

	set keywordFont $::SQLEditor::boldFont
	if {!$useBoldFontForKeywords} {
		set keywordFont $::SQLEditor::font
	}

	ctext::clearHighlightClasses $_edit
	ctext::disableComments $_edit
	ctext::addHighlightClassForSpecialChars $_edit brackets $brackets_color {{}}
	ctext::addHighlightClassForSpecialChars $_edit square_brackets $square_brackets_color {[]}
	ctext::addHighlightClass $_edit keywords $keywords_color $::TCL_KEYWORDS
	ctext::addHighlightClassWithOnlyCharStart $_edit vars $variables_color "\$"
	ctext::addHighlightClassForRegexp $_edit options $options_color {\-[a-zA-Z0-9\_\-]+}
	ctext::addHighlightClassForRegexp $_edit comments $comments_color {(;[\s\t]*#[^\n\r]*|^[\s\t]*#[^\n\r]*)}
	ctext::addHighlightClassForRegexp $_edit chars $chars_color {\\.?}
	$_edit.t tag configure keywords -font $keywordFont
	$_edit.t tag configure brackets -font $::SQLEditor::boldFont
	$_edit.t tag configure square_brackets -font $::SQLEditor::boldFont
	$_edit.t tag configure matched_brackets -background $matched_bracket_bgcolor -foreground $matched_bracket_fgcolor
	reHighlight
}

body TclEditor::handleUserInput {key state} {
	# Does nothing
	return 0
}
