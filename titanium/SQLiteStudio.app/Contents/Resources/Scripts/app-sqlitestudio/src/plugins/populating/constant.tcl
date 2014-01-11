class ConstantPopulatePlugin {
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

body ConstantPopulatePlugin::constructor {} {
	set checkState(const) ""
	array set checkStateOrig [array get checkState]
}

body ConstantPopulatePlugin::getName {} {
	return "CONSTANT";
}

body ConstantPopulatePlugin::configurable {} {
	return true
}

body ConstantPopulatePlugin::createConfigUI {path} {
	array set checkState [array get checkStateOrig]
	pack [ttk::frame $path.start] -side top -fill x -pady 2
	ttk::label $path.start.l -text [mc {Value to use:}] -justify left
	ttk::entry $path.start.e -textvariable [scope checkState](const)
	pack $path.start.l -side top -fill x -expand 1
	pack $path.start.e -side top -fill x -expand 1
	focus $path.start.e
}

body ConstantPopulatePlugin::applyConfig {path} {
	array set checkStateOrig [array get checkState]
}

body ConstantPopulatePlugin::nextValue {} {
	return $checkStateOrig(const)
}
