use src/plugins/import_plugin.tcl

class RegExpImportPlugin {
	inherit ImportPlugin

	constructor {} {}

	private {
		common _regExpHelpUrl "http://sqlitestudio.pl/docs/html/manual.html#RegExpImportPlug"
		common _chunkSize 4096

		variable _file ""
		variable _regexp ""
		variable _nocase 0
		variable _encodingEnabled 0
		variable _encoding [encoding system]
		variable _configVars [list file regexp nocase encodingEnabled encoding]
		
		variable _fd ""
		variable _dataBuffer ""
		variable _values [list]
		variable _widget

		method find {}
		method countColumns {}
		method readToFind {}
	}

	protected {
		method openDataSource {}
		method getColumnList {}
		method getNextDataRow {}
	}

	public {
		variable uiVar
		proc getName {}
		proc configurable {}
		method createConfigUI {path}
		method applyConfig {path}
		method closeDataSource {}
		method validateConfig {}
		method browseFile {e}
		method visualEditor {}
		method help {}
		method updateState {}
	}
}

body RegExpImportPlugin::getName {} {
	return "RegExp"
}

body RegExpImportPlugin::configurable {} {
	return true
}

body RegExpImportPlugin::openDataSource {} {
	set _fd [open $_file r]
	if {$_encodingEnabled} {
		fconfigure $_fd -encoding $_encoding
	} else {
		fconfigure $_fd -translation binary
	}
}

body RegExpImportPlugin::getColumnList {} {
	set cols [countColumns]
	set colList [list]
	for {set i 0} {$i < $cols} {incr i} {
		lappend colList [list "column_$i" "TEXT"]
	}
	return $colList
}

body RegExpImportPlugin::getNextDataRow {} {
	find
	set newVals [list]
	foreach v $_values {
		lappend newVals [list $v 0]
	}
	return $newVals
}

body RegExpImportPlugin::readToFind {} {
	set found 0
	set size [string length $_dataBuffer]
	set chunk " "
	while {!$found && $size < 512*1024*1024 && $chunk != ""} {
		set chunk [read $_fd $_chunkSize]

		if {$_encodingEnabled && $_encoding ne [encoding system]} {
			set chunk [encoding convertfrom $_encoding $chunk]
		}

		append _dataBuffer $chunk
		set found [regexp -- $_regexp $_dataBuffer]
	}
	return $found
}

body RegExpImportPlugin::find {} {
	set _values [list]
	if {[readToFind]} {
		set _values [lrange [regexp -inline -- $_regexp $_dataBuffer] 1 end]

		regexp -indices -- $_regexp $_dataBuffer range
		lassign $range begin end
		incr end
		set _dataBuffer [string range $_dataBuffer $end end]

		return true
	} else {
		set _dataBuffer ""
		return false
	}
}

body RegExpImportPlugin::countColumns {} {
	set count 0
	set escape 0
	foreach c [split $_regexp ""] {
		switch -- $c {
			"\\" {
				if {$escape} {
					set escape 0
				} else {
					set escape 1
				}
			}
			"(" {
				if {!$escape} {
					incr count
				} else {
					set escape 0
				}
			}
			default {
				set escape 0
			}
		}
	}

	return $count
}

body RegExpImportPlugin::createConfigUI {path} {
	foreach var $_configVars {
		set uiVar($var) [set _$var]
	}

	#
	# File
	#
	set w $path.file
	ttk::labelframe $w -text [mc {Input file}]
	ttk::entry $w.e -textvariable [scope uiVar(file)]
	ttk::button $w.b -text [mc {Browse}] -command [list $this browseFile $w.e] -compound left -image img_open
	pack $w.e -side left -fill x -expand 1 -padx 1
	pack $w.b -side right -padx 1
	pack $w -side top -fill x -padx 2 -pady 6 -ipady 3

	#
	# RegExp
	#
	set w $path.regexp
	ttk::labelframe $w -text [mc {Regular expression}]

	ttk::frame $w.u
	ttk::entry $w.u.e -textvariable [scope uiVar(regexp)]
	# Visual Editor - maybe in future
	#ttk::button $w.u.b -text [mc {Visual editor}] -command [list $this visualEditor [scope uiVar(regexp)]] -compound left -image img_regexp_visual
	pack $w.u.e -side left -fill x -expand 1 -padx 1
	#pack $w.u.b -side right -padx 1
	pack $w.u -side top -fill x -pady 2

	helpHint $w.u.e [mc {Use Regular Expression Groups to identify columns.}]

	ttk::frame $w.d
	ttk::checkbutton $w.d.c -text [mc {Case insensitive}] -variable [scope uiVar(nocase)]
	ttk::button $w.d.help -text [mc {Help}] -compound left -image img_help -command [list $this help]
	pack $w.d.help -side right -padx 1
	pack $w.d.c -side left
	pack $w.d -side top -fill x -pady 2

	pack $w -side top -fill x -padx 2 -pady 6 -ipady 3

	#
	# Encoding
	#
	set encodings [lsort -dictionary [ldelete [encoding names] "identity"]]
	
	set w $path.enc
	ttk::labelframe $w -text [mc {Encoding}]
	ttk::checkbutton $w.enable -text [mc {Convert from encoding:}] -variable [scope uiVar(encodingEnabled)] -command [list $this updateState]
	ttk::frame $w.bottom
	set _widget(encodingList) [ttk::combobox $w.bottom.c -values $encodings -state readonly -textvariable [scope uiVar(encoding)]]
	pack $w.enable -side top -fill x -pady 1
	pack $w.bottom -side top -pady 1 -fill x
	pack $w.bottom.c -side left
	pack $w -side top -fill x -padx 2 -pady 6 -ipady 3

	updateState
}

body RegExpImportPlugin::updateState {} {
	$_widget(encodingList) configure -state [expr {$uiVar(encodingEnabled) ? "readonly" : "disabled"}]
}

body RegExpImportPlugin::applyConfig {path} {
	foreach var $_configVars {
		set _$var $uiVar($var)
	}
}

body RegExpImportPlugin::validateConfig {} {
	if {[catch {regexp -- $_regexp ""} err]} {
		cutOffStdTclErr err
		error [mc "RegExp error:\n%s" $err]
	}

	if {$uiVar(file)} {
		error [mc {Input file cannot be empty.}]
	}

	if {[file readable $uiVar(file)]} {
		error [mc {Input file is not readable.}]
	}
}

body RegExpImportPlugin::closeDataSource {} {
	if {$_fd != ""} {
		close $_fd
		set _fd ""
	}
}

body RegExpImportPlugin::browseFile {e} {
	set dir $::startingDir
	set dir [getPathForFileDialog $dir]
	
	set file [GetOpenFile -title [mc {File to import from}] -initialdir $dir]
	if {![winfo exists $e]} return

	$e delete 0 end
	$e insert end $file
}

body RegExpImportPlugin::visualEditor {} {
}

body RegExpImportPlugin::help {} {
	MAIN openWebBrowser $_regExpHelpUrl
}
