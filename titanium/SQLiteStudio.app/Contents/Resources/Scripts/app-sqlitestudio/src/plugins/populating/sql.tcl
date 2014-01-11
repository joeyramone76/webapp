class SqlPopulatePlugin {
	inherit PopulatingPlugin

	constructor {} {}
	destructor {}

	private {
		variable _initialised 0

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

body SqlPopulatePlugin::constructor {} {
	set checkState(initCode) ""
	set checkState(iterCode) ""
	set checkState(finishCode) ""
	array set checkStateOrig [array get checkState]
}

body SqlPopulatePlugin::destructor {} {
	if {$_initialised} {
		if {[catch {finish} err]} {
			debug "SqlPopulatePlugin::finish: $err"
		}
	}
	if {$_interp != ""} {
		interp delete $_interp
	}
}

body SqlPopulatePlugin::getName {} {
	return "SQL CODE";
}

body SqlPopulatePlugin::configurable {} {
	return true
}

body SqlPopulatePlugin::createConfigUI {path} {
	array set checkState [array get checkStateOrig]

	set w $path.initCode
	ttk::labelframe $w -text [mc {Initialisation code}]
	pack $w -side top -fill both -padx 2 -pady 2 -expand 1

	SQLEditor $w.e -validatesql true
	$w.e setDB $_db
	pack $w.e -side top -fill both -expand 1
	$w.e setContents $checkState(initCode)

	set w $path.iterCode
	ttk::labelframe $w -text [mc {Per iteration code}]
	pack $w -side top -fill both -padx 2 -pady 2 -expand 1

	SQLEditor $w.e -validatesql true
	$w.e setDB $_db
	pack $w.e -side top -fill both -expand 1
	$w.e setContents $checkState(iterCode)

	set w $path.closeCode
	ttk::labelframe $w -text [mc {Closing code}]
	pack $w -side top -fill both -padx 2 -pady 2 -expand 1

	SQLEditor $w.e -validatesql true
	$w.e setDB $_db
	pack $w.e -side top -fill both -expand 1
	$w.e setContents $checkState(finishCode)

	$path.initCode.e setFocus
}

body SqlPopulatePlugin::applyConfig {path} {
	array set checkStateOrig [array get checkState]
	set checkState(initCode) [$path.initCode.e getContents]
	set checkState(iterCode) [$path.iterCode.e getContents]
	set checkState(finishCode) [$path.closeCode.e getContents]
}

body SqlPopulatePlugin::nextValue {} {
	if {!$_initialised} {
		init
	}
	set r [$_db eval $checkState(iterCode)]
	return $r
}

body SqlPopulatePlugin::init {} {
	set _initialised 1
	
	set _interp [interp create]
	$_db eval $checkState(initCode)
}

body SqlPopulatePlugin::finish {} {
	$_db eval $checkState(finishCode)
}
