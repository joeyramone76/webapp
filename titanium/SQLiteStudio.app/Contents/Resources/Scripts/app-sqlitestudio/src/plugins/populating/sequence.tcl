class SequencePopulatePlugin {
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

body SequencePopulatePlugin::constructor {} {
	set checkState(start) -1 ;# It's smaller by 1 then real start value, because [incr] returns inremented value as result.
	set checkState(suffix) ""
	set checkState(prefix) ""
	array set checkStateOrig [array get checkState]
}

body SequencePopulatePlugin::getName {} {
	return "SEQUENCE";
}

body SequencePopulatePlugin::configurable {} {
	return true
}

body SequencePopulatePlugin::createConfigUI {path} {
	array set checkState [array get checkStateOrig]
	incr checkState(start)
	pack [ttk::frame $path.start] -side top -fill x -pady 2
	pack [ttk::frame $path.prefix] -side top -fill x -pady 2
	pack [ttk::frame $path.suffix] -side top -fill x -pady 2
	ttk::label $path.start.l -text [mc {Start from:}] -justify left
	ttk::spinbox $path.start.sb -textvariable [scope checkState](start) -increment 1 -from 0 \
					-to 999999999999999 -validatecommand "validateIntWithEmpty %S" -validate key
	ttk::label $path.prefix.l -text [mc {Constant prefix:}] -justify left
	ttk::entry $path.prefix.e -textvariable [scope checkState](prefix)
	ttk::label $path.suffix.l -text [mc {Constant suffix:}] -justify left
	ttk::entry $path.suffix.e -textvariable [scope checkState](suffix)
	pack $path.start.l -side top -fill x -expand 1
	pack $path.start.sb -side top -fill x -expand 1
	pack $path.prefix.l -side top -fill x -expand 1
	pack $path.prefix.e -side top -fill x -expand 1
	pack $path.suffix.l -side top -fill x -expand 1
	pack $path.suffix.e -side top -fill x -expand 1

	if {$::ttk::currentTheme == "vista"} { ;# fix for vista theme to left-align spinbox
		$path.start.sb configure -style TSpinboxLeftAligned
	}

	focus $path.start.sb
}

body SequencePopulatePlugin::applyConfig {path} {
	incr checkState(start) -1
	array set checkStateOrig [array get checkState]
}

body SequencePopulatePlugin::nextValue {} {
	return "$checkStateOrig(prefix)[incr checkStateOrig(start)]$checkStateOrig(suffix)"
}
