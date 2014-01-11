use src/common/panel.tcl

#>
# @class BlobEditPanel
# Hexadecimal/text editors pair widget used for example to edit database BLOBs.
# It updates each editor tab while switching to it. It fits for editing binary data
# (using hexadecimal codes), but unfortunately it's too slow to work with big amount of data.
#<
class BlobEditPanel {
	inherit Panel

	opt value
	opt readonly 0
	opt modifycmd ""
	opt textheight 16

	#>
	# @var _maxSize
	# Maximal number of bytes that is allowed to put into the hex editor.
	# Larger data amount will be denied by a widget. 1MB is pretty reasonable value.
	#<
	#final common _maxSize 1048576 ;# not used anymore, big data sets are now supported better

	#>
	# @method constructor
	# @param args Parameters passed to {@method Panel::constructor}.
	# Default constructor.
	#<
	constructor {args} {
		eval Panel::constructor $args
	} {}

	private {
		#>
		# @var hexedit
		# Hexadecimal editor widget (second tab).
		#<
		variable hexedit ""

		#>
		# #var txtedit
		# Text editor widget (first tab).
		#<
		variable txtedit ""

		#>
		# @var value
		# Current value edited in the widget. It differs
		# from what is displayed in hex editor.
		# It's the real value that will be returned by {@method get}.
		#<
		variable value ""

		#>
		# @var nb
		# Notebook widget that both of editors are placed in.
		#<
		variable nb ""

		variable _readOnly 0
		variable _disabled 0
	}

	public {
		#>
		# @method tabChanged
		# Called on every tab changed in notebook widget.
		# Updates value in newly displayed editor from {@var value}.
		#<
		method tabChanged {}

		#>
		# @method clear
		# Clears value for both of editors and for {@var value}.
		#<
		method clear {}

		#>
		# @method get
		# @return Current value.
		#<
		method get {}

		method setTextFocus {}
		method setHexFocus {}

		#>
		# @method setValue
		# @param val Value to set.
		# Sets new value for blob edit.
		#<
		method setValue {val}

		method setReadOnly {boolean}
		method setDisabled {boolean}
		method isDisabled {}
		method isReadOnly {}
		method checkIfTextModified {}
		method setModified {boolean}
		method focusCurrent {}
		method bindEdits {sequence script}
	}
}


body BlobEditPanel::constructor {args} {
	# Notebook
	set nb [ttk::notebook $path.nb -takefocus 0]
	pack $path.nb -side top -fill both -expand 1 -side top

	# First tab
	ttk::frame $path.nb.t1
	$nb add $path.nb.t1 -text [mc {Text edit}]

	eval itk_initialize $args

	set txtedit [text $path.nb.t1.e -height $itk_option(-textheight) -width 64 -borderwidth 1 -yscrollcommand "$path.nb.t1.s set" -wrap char \
		-background ${::SQLEditor::background_color} -foreground ${::SQLEditor::foreground_color} -font ${::SQLEditor::font} \
		-selectbackground ${::SQLEditor::selected_background} -selectforeground ${::SQLEditor::selected_foreground}]
	ttk::scrollbar $path.nb.t1.s -orient vertical -command "$txtedit yview"
	pack $txtedit -fill both -expand 1 -side left
	pack $path.nb.t1.s -side right -fill y

	attachStdContextMenu $txtedit
	bind $txtedit <Control-a> "
		$txtedit tag remove sel 1.0 end
		$txtedit tag add sel 1.0 {end -1 chars}
		break
	"

	bind $txtedit <<Modified>> "$this checkIfTextModified"

	# Second tab
	ttk::frame $path.nb.f
	set f [frame $path.nb.f.t2 -background ${::SQLEditor::background_color}]
	pack $f -side top -fill both -expand 1
	$nb add $path.nb.f -text [mc {Hexadecimal edit}] -sticky nswe

	set hexedit [HexEditor $f.e -height $itk_option(-textheight) -width 280 -modifycmd $itk_option(-modifycmd)]
	#ttk::scrollbar $f.s -orient vertical -command "$hexedit yview"
	#-yscrollcommand "$f.s set"
	pack $hexedit -fill both -expand 1 -side left
	#pack $f.s -side right -fill y

	# Rest
	update idletasks
	set value $itk_option(-value)
	setValue $value

	if {$itk_option(-readonly)} {
		setReadOnly true
# 		$hexedit setReadOnly true
# 		$txtedit configure -state disabled
	}

	update ;# to process out "tab changed" at initializaton time
	bind $nb <<NotebookTabChanged>> "$this tabChanged"
	bind $path <FocusIn> "$this focusCurrent"
}

body BlobEditPanel::checkIfTextModified {} {
	if {[$txtedit edit modified]} {
		eval $itk_option(-modifycmd)
	}
}

body BlobEditPanel::setValue {val} {
	set value $val
	set tab [$nb index current]

	set ro 0
	set dis 0
	if {[isDisabled]} {
		setDisabled 0
		set dis 1
	} elseif {[isReadOnly]} {
		setReadOnly 0
		set ro 1
	}

	switch -- $tab {
		0 {
			$txtedit delete 1.0 end
			$txtedit insert end $value
		}
		1 {
			$hexedit clear
			$hexedit insert $value
		}
	}

	if {$dis} {
		setDisabled 1
	} elseif {$ro} {
		setReadOnly 1
	}
}

body BlobEditPanel::tabChanged {} {
	set ro 0
	set dis 0
	if {[isDisabled]} {
		setDisabled 0
		set dis 1
	} elseif {[isReadOnly]} {
		setReadOnly 0
		set ro 1
	}

	set tab [$nb index current]
	switch -- $tab {
		0 {
			$txtedit delete 1.0 end
			$txtedit insert end [$hexedit get]
			focus $txtedit
		}
		1 {
			$hexedit clear
			$hexedit insert [$txtedit get 1.0 "end -1 chars"]
			$hexedit setFocus
		}
	}

	if {$dis} {
		setDisabled 1
	} elseif {$ro} {
		setReadOnly 1
	}
}

body BlobEditPanel::focusCurrent {} {
	set tab [$nb index current]
	switch -- $tab {
		0 {
			focus $txtedit
		}
		1 {
			$hexedit setFocus
		}
	}
}

body BlobEditPanel::get {} {
	set tab [$nb index current]
	switch -- $tab {
		0 {
			return [$txtedit get 1.0 "end -1 chars"]
		}
		1 {
			return [$hexedit get]
		}
	}
}

body BlobEditPanel::clear {} {
	$txtedit delete 1.0 end
	$hexedit clear
	set value ""
}

body BlobEditPanel::setDisabled {boolean} {
	$hexedit setDisabled $boolean
	if {$boolean} {
		$txtedit configure -state disabled -foreground $::DISABLED_FONT_COLOR
	} else {
		$txtedit configure -state normal -foreground ${::SQLEditor::foreground_color}
	}
	set _disabled $boolean
}

body BlobEditPanel::setReadOnly {boolean} {
	$hexedit setReadOnly $boolean
	if {$boolean} {
		$txtedit configure -state disabled
	} else {
		$txtedit configure -state normal -foreground ${::SQLEditor::foreground_color}
	}
	set _readOnly $boolean
}

body BlobEditPanel::isReadOnly {} {
	return $_readOnly
}

body BlobEditPanel::isDisabled {} {
	return $_disabled
}

body BlobEditPanel::setModified {boolean} {
	$txtedit edit modified $boolean
}

body BlobEditPanel::setTextFocus {} {
	focus $txtedit
}

body BlobEditPanel::setHexFocus {} {
	focus $hexedit
}

body BlobEditPanel::bindEdits {sequence script} {
	bind $txtedit $sequence $script
	$hexedit bindEdits $sequence $script
}
