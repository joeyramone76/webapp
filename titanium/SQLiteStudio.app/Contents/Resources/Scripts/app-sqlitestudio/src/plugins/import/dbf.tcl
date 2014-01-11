use src/plugins/import_plugin.tcl

class DbfImportPlugin {
	inherit ImportPlugin

	constructor {} {}

	private {
		variable _file ""
		variable _encodingEnabled 0
		variable _encoding [encoding system]
		variable _configVars [list file encodingEnabled encoding]

		variable _dbf ""
		variable _positioned 0
		variable _columns [list]
		variable _converter [dict create]
		variable _widget
		
		method mapType {name type length precision}
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
		method updateState {}
	}
}

body DbfImportPlugin::getName {} {
	return "dBase (DBF)"
}

body DbfImportPlugin::configurable {} {
	return true
}

body DbfImportPlugin::openDataSource {} {
	set _dbf [tdbf::dbf ::#auto]
	$_dbf open $_file
	if {$_encodingEnabled} {
		$_dbff setEncoding $_encoding
	}
}

body DbfImportPlugin::getColumnList {} {
	set cols [list]
	set _columns [list]
	foreach col [$_dbf getColumns] {
		set name [dict get $col name]
		set type [dict get $col type]
		set length [dict get $col length]
		set precision [dict get $col precision]

		set i 1
		set newName $name
		while {[lsearch -index 0 -nocase $cols $newName] > -1} {
			set newName "$name:$i"
		}
		set name $newName

		lappend cols [list $name [mapType $name $type $length $precision]]
		lappend _columns $name
	}
	return $cols
}

body DbfImportPlugin::mapType {name type length precision} {
	switch -- $type {
		"N" {
			return "NUMERIC($length, $precision)"
		}
		"C" {
			return "VARCHAR($length)"
		}
		"L" {
			return "BOOLEAN"
		}
		"D" {
			# Date as string YYYYMMDD
			dict set _converter $name {
				 set y [string range $value 0 3]
				 set m [string range $value 4 5]
				 set d [string range $value 6 7]
				 return "$y-$m-$d"
			}
			return "DATE"
		}
		"M" - "B" - "G" - "P" {
			return "BLOB"
		}
		"F" {
			return "FLOAT"
		}
		"Y" {
			# Currency (huge decimal number)
			return "NUMERIC"
		}
		"I" {
			return "INTEGER"
		}
		"+" {
			return "INTEGER PRIMARY KEY AUTOINCREMENT"
		}
		"@" - "T" {
			# Timestamp as two integers - day and msecs
			dict set _converter $name {
				lassign $value day msecs
				return "$day.[expr {double($msecs) / 86400000}]"
			}
			return "DATETIME"
		}
		"V" - "X" {
			# Variant. Hard to tell the type.
			return ""
		}
		"O" {
			return "DOUBLE"
		}
		default {
			return ""
		}
	}
}

body DbfImportPlugin::getNextDataRow {} {
	if {!$_positioned} {
		$_dbf seek 0
		set _positioned 1
	}

	set data [$_dbf gets]
	if {[llength $data] == 0} {
		return [list]
	}

	set values [list]
	# Return as dbf returns.
	foreach val $data col $_columns {
		if {[dict exists $_converter $col]} {
			lappend values [list [apply [list value [dict get $_converter $col]] $val] 0]
		} else {
			lappend values [list $val 0]
		}
	}
	return $values
}

body DbfImportPlugin::createConfigUI {path} {
	foreach var $_configVars {
		set uiVar($var) [set _$var]
	}

	#
	# File
	#
	ttk::labelframe $path.file -text [mc {Input file}]
	ttk::entry $path.file.e -textvariable [scope uiVar](file)
	ttk::button $path.file.b -text [mc {Browse}] -command [list $this browseFile $path.file.e] -compound left -image img_open
	pack $path.file.e -side left -fill x -expand 1
	pack $path.file.b -side right -padx 1
	pack $path.file -side top -fill x -padx 2 -pady 6 -ipady 3

	#
	# Encoding
	#
	set encodings [lsort -dictionary [ldelete [encoding names] "identity"]]
	
	set w $path.enc
	ttk::labelframe $w -text [mc {Encoding}]
	ttk::radiobutton $w.disable -text [mc {Auto-detect}] -variable [scope uiVar(encodingEnabled)] -value 0 -command [list $this updateState]
	ttk::radiobutton $w.enable -text [mc {Convert from encoding:}] -variable [scope uiVar(encodingEnabled)] -value 1 -command [list $this updateState]
	ttk::frame $w.bottom
	set _widget(encodingList) [ttk::combobox $w.bottom.c -values $encodings -state readonly -textvariable [scope uiVar(encoding)]]
	pack $w.disable -side top -fill x -pady 1
	pack $w.enable -side top -fill x -pady 1
	pack $w.bottom -side top -pady 1 -fill x -padx 3
	pack $w.bottom.c -side left
	pack $w -side top -fill x -padx 2 -pady 6 -ipady 3
	
	updateState
}

body DbfImportPlugin::updateState {} {
	$_widget(encodingList) configure -state [expr {$uiVar(encodingEnabled) ? "readonly" : "disabled"}]
}

body DbfImportPlugin::applyConfig {path} {
	foreach var $_configVars {
		set _$var $uiVar($var)
	}
}

body DbfImportPlugin::validateConfig {} {
	if {$uiVar(file)} {
		error [mc {Input file cannot be empty.}]
	}

	if {[file readable $uiVar(file)]} {
		error [mc {Input file is not readable.}]
	}
}

body DbfImportPlugin::closeDataSource {} {
	if {$_dbf != ""} {
		$_dbf close
		set _dbf ""
	}
}

body DbfImportPlugin::browseFile {e} {
	set dir $::startingDir
	set dir [getPathForFileDialog $dir]
	
	set types [list \
		[list [mc {dBase files}]	{.dbf}		] \
		[list [mc {All files}]		{*}			] \
	]

	if {[os] == "macosx"} {
		set file [GetOpenFile -title [mc {File to import from}] -initialdir $dir]
	} else {
		set file [GetOpenFile -title [mc {File to import from}] -initialdir $dir -filetypes $types]
	}
	if {![winfo exists $e]} return

	$e delete 0 end
	$e insert end $file
}
