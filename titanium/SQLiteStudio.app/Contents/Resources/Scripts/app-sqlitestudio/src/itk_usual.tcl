itk::usual TButton {
	keep -cursor -font
}

itk::usual TCheckbutton {
	keep -cursor -font
}

itk::usual TCombobox {
	keep -cursor -font
}

itk::usual TDialog {
	keep -cursor -font
}

itk::usual TEntry {
	keep -cursor -font
}

itk::usual TFrame {
	keep -cursor -font
}

itk::usual TLabel {
	keep -cursor -font
}

itk::usual TLabelframe {
	keep -cursor -font
}

itk::usual TMenubutton {
	keep -cursor -font
}

itk::usual TNotebook {
	keep -cursor -font
}

itk::usual TPaned {
	keep -cursor -font
}

itk::usual TProgressbar {
	keep -cursor -font
}

itk::usual TRadiobutton {
	keep -cursor -font
}

itk::usual TScrollbar {
	keep -cursor
}

itk::usual TSeparator {
	keep -cursor
}

itk::usual TSizegrip {
	keep -cursor
}

itk::usual TTreeview {
	keep -cursor -font
}

itk::usual TreeCtrl {
	keep -cursor -font -width -height
}

itk::usual Ctext {
	keep -background -cursor -foreground -font
	keep -insertbackground -insertborderwidth -insertwidth
	keep -insertontime -insertofftime
	keep -selectbackground -selectborderwidth -selectforeground
	keep -highlightcolor -highlightthickness

	rename -highlightbackground -background background Background
}
