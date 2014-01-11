class DictionaryPopulatePlugin {
	inherit PopulatingPlugin

	constructor {} {}

	private {
		variable _data [list]
		variable _idx 0
		variable _max 0
		variable _path ""
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

body DictionaryPopulatePlugin::constructor {} {
	set checkState(file) ""
	set checkState(sep) " "
	set checkState(random) 0
	array set checkStateOrig [array get checkState]
}

body DictionaryPopulatePlugin::getName {} {
	return "DICTIONARY";
}

body DictionaryPopulatePlugin::configurable {} {
	return true
}

body DictionaryPopulatePlugin::createConfigUI {path} {
	array set checkState [array get checkStateOrig]

	pack [ttk::frame $path.file] -side top -fill x -pady 2
	ttk::label $path.file.l -text [mc {Dictionary file:}] -justify left
	ttk::frame $path.file.path
	ttk::entry $path.file.path.e -textvariable [scope checkState](file)
	ttk::button $path.file.path.browse -image img_open -command "$this chooseFile"
	pack $path.file.l -side top -fill x -expand 1
	pack $path.file.path -side top -fill x -expand 1
	pack $path.file.path.e -side left -fill x -expand 1
	pack $path.file.path.browse -side right

	pack [ttk::labelframe $path.sep -text [mc {Dictionary words separator:}]] -side top -fill x -pady 2
	ttk::radiobutton $path.sep.ws -variable [scope checkState](sep) -value " " -text [mc {Whitespace}]
	ttk::radiobutton $path.sep.nl -variable [scope checkState](sep) -value "\n" -text [mc {Line break}]
	pack $path.sep.ws -side top -fill x -expand 1
	pack $path.sep.nl -side top -fill x -expand 1

	pack [ttk::labelframe $path.random -text [mc {Method of using words:}]] -side top -fill x -pady 2
	ttk::radiobutton $path.random.rand -variable [scope checkState](random) -value 1 -text [mc {Randomly}]
	ttk::radiobutton $path.random.seq -variable [scope checkState](random) -value 0 -text [mc {Consecutively}]
	pack $path.random.rand -side top -fill x -expand 1
	pack $path.random.seq -side top -fill x -expand 1

	set _path $path

	focus $path.file.path.e
}

body DictionaryPopulatePlugin::applyConfig {path} {
	array set checkStateOrig [array get checkState]

	if {[catch {
		set fd [open $checkState(file) r]
		set data [read $fd]
		close $fd
	}]} {
		Warning [mc {Dictionary file doesn't exist, or unreadable.}]
		return
	}

	set _data [split $data $checkState(sep)]
	set _max [llength $_data]
}

body DictionaryPopulatePlugin::nextValue {} {
	if {[string trim $_data] == ""} {
		error [mc {Dictionary file is empty!}]
	}

	if {$checkState(random)} {
		set _idx [rand $_max]
	}
	set res [lindex $_data $_idx]
	if {!$checkState(random)} {
		incr _idx
		if {$_idx >= $_max} {
			set _idx 0
		}
	}
	return $res
}

body DictionaryPopulatePlugin::chooseFile {} {
	set t [winfo toplevel $_path]
	wm withdraw $t
	set f [GetOpenFile -title [mc {Dictionary file}] -parent $_path]
	wm deiconify $t
	if {$f == ""} return
	set checkState(file) $f
}
