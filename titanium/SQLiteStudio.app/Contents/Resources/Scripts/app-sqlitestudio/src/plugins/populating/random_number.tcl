class RandNumPopulatePlugin {
	inherit PopulatingPlugin

	constructor {} {}

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

body RandNumPopulatePlugin::constructor {} {
	set checkState(min) 0
	set checkState(max) 9999999
	set checkState(suffix) ""
	set checkState(prefix) ""
	array set checkStateOrig [array get checkState]
}

body RandNumPopulatePlugin::getName {} {
	return "RANDOM NUMBER";
}

body RandNumPopulatePlugin::configurable {} {
	return true
}

body RandNumPopulatePlugin::createConfigUI {path} {
	array set checkState [array get checkStateOrig]
	pack [ttk::frame $path.lgt_min] -side top -fill x -pady 2
	ttk::label $path.lgt_min.l -text [mc {Minimum value:}] -justify left
	ttk::spinbox $path.lgt_min.sb -textvariable [scope checkState](min) -increment 1 -from 0 \
					-to 999999999999999 -validatecommand "validateIntWithEmpty %S" -validate key
	pack $path.lgt_min.l -side top -fill x -expand 1
	pack $path.lgt_min.sb -side top -fill x -expand 1

	pack [ttk::frame $path.lgt_max] -side top -fill x -pady 2
	ttk::label $path.lgt_max.l -text [mc {Maximum value:}] -justify left
	ttk::spinbox $path.lgt_max.sb -textvariable [scope checkState](max) -increment 1 -from 0 \
					-to 999999999999999 -validatecommand "validateIntWithEmpty %S" -validate key
	pack $path.lgt_max.l -side top -fill x -expand 1
	pack $path.lgt_max.sb -side left -fill x -expand 1

	if {$::ttk::currentTheme == "vista"} { ;# fix for vista theme to left-align spinbox
		$path.lgt_min.sb configure -style TSpinboxLeftAligned
		$path.lgt_max.sb configure -style TSpinboxLeftAligned
	}

	pack [ttk::frame $path.prefix] -side top -fill x -pady 2
	pack [ttk::frame $path.suffix] -side top -fill x -pady 2
	ttk::label $path.prefix.l -text [mc {Constant prefix:}] -justify left
	ttk::entry $path.prefix.e -textvariable [scope checkState](prefix)
	ttk::label $path.suffix.l -text [mc {Constant suffix:}] -justify left
	ttk::entry $path.suffix.e -textvariable [scope checkState](suffix)
	pack $path.prefix.l -side top -fill x -expand 1
	pack $path.prefix.e -side top -fill x -expand 1
	pack $path.suffix.l -side top -fill x -expand 1
	pack $path.suffix.e -side top -fill x -expand 1

	focus $path.lgt_min.sb
}

body RandNumPopulatePlugin::applyConfig {path} {
	if {$checkState(min) > $checkState(max)} {
		set checkState(max) $checkState(min)
	}
	array set checkStateOrig [array get checkState]
}

body RandNumPopulatePlugin::nextValue {} {
	return "$checkStateOrig(prefix)[rand $checkStateOrig(min) $checkStateOrig(max)]$checkStateOrig(suffix)"
}
