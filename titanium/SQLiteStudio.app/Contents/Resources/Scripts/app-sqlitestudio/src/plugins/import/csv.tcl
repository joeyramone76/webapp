use src/plugins/import_plugin.tcl

class CsvImportPlugin {
	inherit ImportPlugin

	common sepLabels [list [mc {, (comma)}] [mc {; (semicolon)}] [mc "\\t (tab)"] [mc {  (white-space)}] [mc {Custom}]]
	common separators [list "," ";" "\t" " "]

	constructor {} {}

	protected {
		variable _columnsInFirstRow 0
		variable _separator ","
		variable _nullAs ""
		variable _handleNull 0
		variable _encoding [encoding system]
		variable _doDecoding 0
		variable _microsoftFormat 0
		variable _fd ""
		variable _widget

		method openDataSource {}
		method getColumnList {}
		method getNextDataRow {}
		method getColumnListFromLine {line}
		method getNextDataRowFromLine {line}
	}

	public {
		variable uiVar

		proc getName {}
		proc configurable {}
		method closeDataSource {}
		method createConfigUI {path}
		method applyConfig {path}
		method validateConfig {}
		method sepSelected {path}
		method updateState {}
		method browseFile {e}
		proc validateMax1Char {str}
	}
}

body CsvImportPlugin::constructor {} {
	set uiVar(customSeparator) $_separator
	set uiVar(columns_in_first_row) $_columnsInFirstRow
	set uiVar(null_as) $_nullAs
	set uiVar(encoding) $_encoding
	set uiVar(handle_null) $_handleNull
	set uiVar(input_file) ""
	set uiVar(encodingEnabled) $_doDecoding
	set uiVar(microsoftFormat) $_microsoftFormat
	set uiVar(show_opts) 0
}

body CsvImportPlugin::openDataSource {} {
	set fd [open $uiVar(input_file) r]
	fconfigure $fd -blocking 0
	set _fd $fd
}

body CsvImportPlugin::getColumnList {} {
	# We need first line, no matter if it's column names or not.
	# We will need it for number of columns anyway.
	gets $_fd line
	if {!$_columnsInFirstRow} {
		seek $_fd 0
	}

	return [getColumnListFromLine $line]
}

body CsvImportPlugin::getNextDataRow {} {
	if {[eof $_fd]} {
		# Nothing more to read
		return [list]
	}

	# Read next line
	gets $_fd line

	getNextDataRowFromLine $line
}

body CsvImportPlugin::getColumnListFromLine {line} {
	# Parse line
	if {$_microsoftFormat} {
		set values [::csv::split -alternate $line $_separator]
	} else {
		set values [::csv::split $line $_separator]
	}

	set colList [list]
	if {$_columnsInFirstRow} {
		# Interprete line as column names
		foreach v $values {
			lappend colList [list $v ""]
		}
	} else {
		# Generate same amount of column names as fields in first data row
		set i 1
		foreach v $values {
			lappend colList [list "Col_$i" ""]
			incr i
		}
	}
	return $colList
}

body CsvImportPlugin::getNextDataRowFromLine {line} {
	# Encoding
	if {$_doDecoding && $_encoding ne [encoding system]} {
		set line [encoding convertfrom $_encoding $line]
	}

	# Parse it
	if {$_microsoftFormat} {
		set values [::csv::split -alternate $line $_separator]
	} else {
		set values [::csv::split $line $_separator]
	}

	# NULLs
	set newVals [list]
	if {$_handleNull} {
		foreach v $values {
			if {$v eq $_nullAs} {
				lappend newVals [list $v 1]
			} else {
				lappend newVals [list $v 0]
			}
		}
	} else {
		foreach v $values {
			lappend newVals [list $v 0]
		}
	}

	# ...and return
	return $newVals
}

body CsvImportPlugin::closeDataSource {} {
	if {$_fd != ""} {
		catch {close $_fd}
		set _fd ""
	}
}

body CsvImportPlugin::getName {} {
	return "CSV"
}

body CsvImportPlugin::configurable {} {
	return true
}

body CsvImportPlugin::createConfigUI {path} {
	set customEditState "disabled"
	set listIndex 0
	if {$_separator in $separators} {
		set listIndex [lsearch -exact $separators $_separator]
	} else {
		set customEditState "normal"
		set listIndex [expr {[llength $sepLabels]-1}]
	}

	set pady 6
	set ipady 2

	#
	# File
	#
	ttk::labelframe $path.file -text [mc {Input file}]
	ttk::entry $path.file.e -textvariable [scope uiVar](input_file)
	ttk::button $path.file.b -text [mc {Browse}] -command [list $this browseFile $path.file.e] -compound left -image img_open
	pack $path.file.e -side left -fill x -expand 1
	pack $path.file.b -side right -padx 1
	pack $path.file -side top -fill x -padx 2 -pady $pady -ipady $ipady

	#
	# Show options
	#
	ttk::checkbutton $path.showOpts -text [mc {Show options}] -variable [scope uiVar(show_opts)] -command [list $this updateState]
	set _widget(opts) [ttk::frame $path.opts]
	pack $path.showOpts -side top -fill x -padx 2 -pady $pady

	#
	# Include columns
	#
	ttk::labelframe $_widget(opts).incCol -text [mc {Column names}]
	ttk::checkbutton $_widget(opts).incCol.c -text [mc {Treat first row as column names}] -variable [scope uiVar(columns_in_first_row)]
	pack $_widget(opts).incCol.c -side left -fill x
	pack $_widget(opts).incCol -side top -fill x -pady $pady -ipady $ipady

	helpHint $_widget(opts).incCol.c [mc "If enabled, then first row of CSV file will be interpreted as column names.\nThey are ignored if data is imported to existing table."]

	#
	# Separator
	#
	ttk::labelframe $_widget(opts).sep -text [mc {Columns separator:}]
	ttk::frame $_widget(opts).sep.val
	ttk::combobox $_widget(opts).sep.val.list -values $sepLabels -state readonly
	ttk::entry $_widget(opts).sep.val.edit -width 2 -textvariable [scope uiVar(customSeparator)] \
		 -validatecommand [list CsvImportPlugin::validateMax1Char %P] -validate all -state $customEditState
	pack $_widget(opts).sep.val -side top -fill x
	pack $_widget(opts).sep.val.list -side left -padx 2 -fill x
	pack $_widget(opts).sep.val.edit -side left -padx 2
	pack $_widget(opts).sep -side top -fill x -pady $pady -ipady $ipady

	$_widget(opts).sep.val.list current $listIndex
	bind $_widget(opts).sep.val.list <<ComboboxSelected>> [list $this sepSelected $_widget(opts)]

	set help [mc "Character used to separate each column data\nfrom each other. Separator can be part of column value as far,\nas the value is enclosed in quotation marks."]
	helpHint $_widget(opts).sep.val.edit $help
	helpHint $_widget(opts).sep.val.list $help

	#
	# Null handling
	#
	ttk::labelframe $_widget(opts).null -text [mc {NULL handling}]
	ttk::checkbutton $_widget(opts).null.lab -text [mc {Treat following values as NULL:}] -variable [scope uiVar(handle_null)] -command [list $this updateState]
	set _widget(nullEdit) [ttk::entry $_widget(opts).null.edit -textvariable [scope uiVar](null_as)]
	pack $_widget(opts).null.lab -side top -fill x
	pack $_widget(opts).null.edit -side top -padx 2 -fill x
	pack $_widget(opts).null -side top -fill x -pady $pady -ipady $ipady

	#
	# MS format
	#
	ttk::labelframe $_widget(opts).msFormat -text [mc {Workarounds}]
	ttk::checkbutton $_widget(opts).msFormat.c -text [mc {Expect Microsoft format of CSV}] -variable [scope uiVar(microsoftFormat)]
	pack $_widget(opts).msFormat.c -side left -fill x
	pack $_widget(opts).msFormat -side top -fill x -pady $pady -ipady $ipady

	helpHint $_widget(opts).msFormat.c [mc "Microsoft products uses slightly different format of CSV files.\nIf you're importing an output CSV from such application, use this option."]

	#
	# Encoding
	#
	set w enc
	set encodings [lsort -dictionary [ldelete [encoding names] "identity"]]
	ttk::labelframe $_widget(opts).$w -text [mc {Encoding}]
	ttk::checkbutton $_widget(opts).$w.enable -text [mc {Convert from encoding:}] -variable [scope uiVar(encodingEnabled)] -command [list $this updateState]
	ttk::frame $_widget(opts).$w.bottom
	set _widget(encodingList) [ttk::combobox $_widget(opts).$w.bottom.c -values $encodings -state readonly -textvariable [scope uiVar(encoding)]]
	pack $_widget(opts).$w.enable -side top -fill x -pady 1
	pack $_widget(opts).$w.bottom -side top -pady 1 -fill x
	pack $_widget(opts).$w.bottom.c -side left
	pack $_widget(opts).$w -side top -fill x -padx 2 -pady $pady -ipady $ipady

	updateState

	focus $_widget(opts).sep.val.list
}

body CsvImportPlugin::applyConfig {path} {
	set idx [$_widget(opts).sep.val.list current]
	if {[lindex $separators $idx] == ""} {
		set _separator $uiVar(customSeparator)
	} else {
		set _separator [lindex $separators $idx]
	}
	set _columnsInFirstRow $uiVar(columns_in_first_row)
	set _nullAs $uiVar(null_as)
	set _handleNull $uiVar(handle_null)
	set _encoding $uiVar(encoding)
	set _doDecoding $uiVar(encodingEnabled)
	set _microsoftFormat $uiVar(microsoftFormat)
}

body CsvImportPlugin::validateConfig {} {
	if {$uiVar(input_file)} {
		error [mc {Input file cannot be empty.}]
	}

	if {[file readable $uiVar(input_file)]} {
		error [mc {Input file is not readable.}]
	}

	if {$_separator == ""} {
		error [mc {CSV separator cannot be empty.}]
	}
}

body CsvImportPlugin::validateMax1Char {str} {
	return [expr {[string length $str] <= 1}]
}

body CsvImportPlugin::updateState {} {
	if {$uiVar(show_opts)} {
		pack $_widget(opts) -side top -fill both
	} else {
		catch {pack forget $_widget(opts)}
	}

	if {$uiVar(handle_null)} {
		$_widget(nullEdit) configure -state normal
	} else {
		$_widget(nullEdit) configure -state disabled
	}
	
	if {$uiVar(encodingEnabled)} {
		$_widget(encodingList) configure -state readonly
	} else {
		$_widget(encodingList) configure -state disabled
	}
}

body CsvImportPlugin::sepSelected {path} {
	set idx [$_widget(opts).sep.val.list current]
	if {[lindex $separators $idx] == ""} {
		update
		$_widget(opts).sep.val.edit configure -state normal
		focus $path.sep.val.edit
	} else {
		$_widget(opts).sep.val.edit configure -state disabled
	}
}

body CsvImportPlugin::browseFile {e} {
	set dir $::startingDir
	set dir [getPathForFileDialog $dir]
	
	set types [list \
		[list [mc {CSV files}]		{.csv}		] \
		[list [mc {Text files}]		{.txt}		] \
		[list [mc {All files}]		{*}			] \
	]
	
	set file [GetOpenFile -title [mc {File to import from}] -initialdir $dir -filetypes $types]
	if {![winfo exists $e]} return

	$e delete 0 end
	$e insert end $file
}
