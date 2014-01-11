class RandomPopulatePlugin {
	inherit PopulatingPlugin

	constructor {} {}

	private {
		common _alpha "abcdefghijklmnopqrstxvwxyz"
		common _digit "0123456789"
		common _space " "
	}

	public {
		variable checkState
		variable checkStateOrig

		proc getName {}
		proc configurable {}
		method createConfigUI {path}
		method applyConfig {path}
		method nextValue {}
	}
}

body RandomPopulatePlugin::constructor {} {
	set checkState(lgtMin) 4
	set checkState(lgtMax) 20
	set checkState(incAlpha) 1
	set checkState(incDigit) 1
	set checkState(incSpaces) 1
	set checkState(incBin) 0
	array set checkStateOrig [array get checkState]
}

body RandomPopulatePlugin::getName {} {
	return "RANDOM CHARACTERS";
}

body RandomPopulatePlugin::configurable {} {
	return true
}

body RandomPopulatePlugin::createConfigUI {path} {
	array set checkState [array get checkStateOrig]
	foreach {w lab} [list \
		incAlpha [mc {Include alpha characters}] \
		incDigit [mc {Include numeric characters}] \
		incSpaces [mc {Include whitespace characters}] \
		incBin [mc {Include binary characters}] \
	] {
		ttk::frame $path.$w
		ttk::checkbutton $path.$w.cb -text $lab -variable [scope checkState]($w)
		pack $path.$w -side top -fill x -pady 2
		pack $path.$w.cb -side left -fill x
	}

	pack [ttk::frame $path.lgt_min] -side top -fill x -pady 2
	ttk::label $path.lgt_min.l -text [mc {Minimum length:}] -justify left
	ttk::spinbox $path.lgt_min.sb -textvariable [scope checkState](lgtMin) -increment 1 -from 0 \
					-to 999999999999999 -validatecommand "validateIntWithEmpty %S" -validate key
	pack $path.lgt_min.l -side top -fill x -expand 1
	pack $path.lgt_min.sb -side top -fill x -expand 1

	pack [ttk::frame $path.lgt_max] -side top -fill x -pady 2
	ttk::label $path.lgt_max.l -text [mc {Maximum length:}] -justify left
	ttk::spinbox $path.lgt_max.sb -textvariable [scope checkState](lgtMax) \
					-increment 1 -from 0 -to 999999999999999 \
					-validatecommand "validateIntWithEmpty %S" -validate key
	pack $path.lgt_max.l -side top -fill x -expand 1
	pack $path.lgt_max.sb -side left -fill x -expand 1

	if {$::ttk::currentTheme == "vista"} { ;# fix for vista theme to left-align spinbox
		$path.lgt_min.sb configure -style TSpinboxLeftAligned
		$path.lgt_max.sb configure -style TSpinboxLeftAligned
	}

	focus $path.lgt_min.sb
}

body RandomPopulatePlugin::applyConfig {path} {
	if {$checkState(lgtMin) > $checkState(lgtMax)} {
		set checkState(lgtMax) $checkState(lgtMin)
	}
	array set checkStateOrig [array get checkState]
}

body RandomPopulatePlugin::nextValue {} {
	set chars ""
	if {$checkStateOrig(incAlpha)} {
		append chars $_alpha
	}
	if {$checkStateOrig(incDigit)} {
		append chars $_digit
	}
	if {$checkStateOrig(incSpaces)} {
		append chars $_space
	}
	if {$checkStateOrig(incBin)} {
		append chars [binary format c* [jot 0 255]]
	}
	set maxChar [string length $chars]
	set length [rand $checkStateOrig(lgtMin) $checkStateOrig(lgtMax)]

	set crap ""
	while {$length > 0} {
		append crap [string index $::randchars [rand $maxChar]]
		incr length -1
	}
	return $crap
}
