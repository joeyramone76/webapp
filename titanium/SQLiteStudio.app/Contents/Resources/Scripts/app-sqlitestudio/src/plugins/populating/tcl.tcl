class TclPopulatePlugin {
	inherit PopulatingPlugin

	constructor {} {}
	destructor {}

	private {
		variable _initialised 0
		variable _interp ""

		method init {}
		method finish {}
	}

	public {
		variable checkState
		variable checkStateOrig

		proc getName {}
		proc configurable {}
		method createConfigUI {path}
		method applyConfig {path}
		method nextValue {}
		method chooseFile {}
	}
}

body TclPopulatePlugin::constructor {} {
	set checkState(initCode) ""
	set checkState(iterCode) ""
	set checkState(finishCode) ""
	array set checkStateOrig [array get checkState]
}

body TclPopulatePlugin::destructor {} {
	if {$_initialised} {
		if {[catch {finish} err]} {
			debug "TclPopulatePlugin::finish: $err"
		}
	}
	if {$_interp != ""} {
		interp delete $_interp
	}
}

body TclPopulatePlugin::getName {} {
	return "TCL CODE";
}

body TclPopulatePlugin::configurable {} {
	return true
}

body TclPopulatePlugin::createConfigUI {path} {
	array set checkState [array get checkStateOrig]

	set w $path.initCode
	ttk::labelframe $w -text [mc {Initialisation code}]
	pack $w -side top -fill both -padx 2 -pady 2 -expand 1

	TclEditor $w.e
	pack $w.e -side top -fill both -expand 1
	$w.e setContents $checkState(initCode)

	set w $path.iterCode
	ttk::labelframe $w -text [mc {Per iteration code}]
	pack $w -side top -fill both -padx 2 -pady 2 -expand 1

	TclEditor $w.e
	pack $w.e -side top -fill both -expand 1
	$w.e setContents $checkState(iterCode)

	set w $path.closeCode
	ttk::labelframe $w -text [mc {Closing code}]
	pack $w -side top -fill both -padx 2 -pady 2 -expand 1

	TclEditor $w.e
	pack $w.e -side top -fill both -expand 1
	$w.e setContents $checkState(finishCode)

	$path.initCode.e setFocus
}

body TclPopulatePlugin::applyConfig {path} {
	array set checkStateOrig [array get checkState]
	set checkState(initCode) [$path.initCode.e getContents]
	set checkState(iterCode) [$path.iterCode.e getContents]
	set checkState(finishCode) [$path.closeCode.e getContents]
}

body TclPopulatePlugin::nextValue {} {
	if {!$_initialised} {
		init
	}
	set r [$_interp eval $checkState(iterCode)]
	return $r
}

body TclPopulatePlugin::init {} {
	set _initialised 1
	
	set _interp [interp create]
	$_interp eval $checkState(initCode)
}

body TclPopulatePlugin::finish {} {
	$_interp eval $checkState(finishCode)
}
