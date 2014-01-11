use src/common/modal.tcl
use src/common/ui.tcl

#>
# @class TextBrowseDialog
# Simple text browsing dialog.
#<
class TextBrowseDialog {
	inherit Modal UI

	opt fixedfont 0
	opt width 70
	opt modal 0

	#>
	# @method constructor
	# @param args Options passed to {@class Modal}.
	# Default constructor. Initializes all contents.
	#<
	constructor {args} {
		eval Modal::constructor $args -modal $modal -resizable 1 -expandcontainer 1
	} {}

	protected {
		#>
		# @var _text
		# Contents for text browser.
		#<
		variable _text ""
	}

	public {
		#>
		# @method okClicked
		# @overloaded Modal
		#<
		method okClicked {}

		#>
		# @method grabWidget
		# @overloaded Modal
		#<
		method grabWidget {}

		#>
		# @method setText
		# @param txt Text contents to set.
		# Inserts given text to the text area, erasing any previous contents.
		#<
		method setText {txt}

		#>
		# @method updateUISettings
		# @overloaded UI
		#<
		method updateUISettings {}

		#>
		# @method textWidget
		# @return Text edit widget used in browser.
		#<
		method textWidget {}
	}
}

body TextBrowseDialog::constructor {args} {
	ttk::frame $_root.u
	pack $_root.u -side top -fill both -expand 1

	set _text [text $_root.u.txt -highlightthickness 0 -borderwidth 1 -relief solid -yscrollcommand "$_root.u.s set" \
			-background ${::SQLEditor::background_color} -foreground ${::SQLEditor::foreground_color} \
			-selectbackground ${::SQLEditor::selected_background} -selectforeground ${::SQLEditor::selected_foreground} \
			-insertontime 500 -insertofftime 500 -selectborderwidth 0 -wrap word -state disabled \
			-width 70 -height 26 \
		]
	ttk::scrollbar $_root.u.s -command "$_root.u.txt yview"
	pack $_text -side left -fill both -expand 1
	pack $_root.u.s -side right -fill y

	ttk::frame $_root.d
	pack $_root.d -side bottom -fill x

	ttk::button $_root.d.ok -text [mc "Close"] -command "$this clicked ok" -compound left -image img_ok
	pack $_root.d.ok -side top -pady 3

	eval itk_initialize $args

	if {$itk_option(-fixedfont)} {
		$_text configure -font ${::SQLEditor::font}
	}
	if {$itk_option(-width)} {
		$_text configure -width $itk_option(-width)
	}
}

body TextBrowseDialog::okClicked {} {
}

body TextBrowseDialog::grabWidget {} {
	return $_root.d.ok
}

body TextBrowseDialog::setText {txt} {
	$_text configure -state normal
	$_text delete 1.0 end
	$_text insert end $txt
	$_text configure -state disabled
}

body TextBrowseDialog::updateUISettings {} {
	$_text configure -background ${::SQLEditor::background_color} -foreground ${::SQLEditor::foreground_color} \
		-selectbackground ${::SQLEditor::background_color} -selectforeground ${::SQLEditor::foreground_color}

	if {$itk_option(-fixedfont)} {
		$_text configure -font ${::SQLEditor::font}
	}
}

body TextBrowseDialog::textWidget {} {
	return $_text
}
