use src/plugins/export_plugin.tcl

class CsvExportPlugin {
	inherit ExportPlugin

	common sepLabels [list [mc {, (comma)}] [mc {; (semicolon)}] [mc "\\t (tab)"] [mc {  (white-space)}] [mc {Custom}]]
	common separators [list "," ";" "\t" " "]

	constructor {} {}

	protected {
		variable _columnsInFirstRow 0
		variable _separator ","
		variable _nullAs ""
		variable _encoding [encoding system]

		method exportLine {lineData}
	}

	public {
		variable checkState
		proc getName {}
		proc configurable {context}
		proc isContextSupported {context}
		method createConfigUI {path context}
		method applyConfig {path context}
		method validateConfig {context}
		method exportResults {columns totalRows}
		method exportResultsRow {cellsData columns}
		method exportResultsEnd {}
		method exportTable {name columns ddl totalRows}
		method exportTableRow {cellsData columns}
		method exportTableEnd {name}
		method exportIndex {name table columns unique ddl}
		method exportTrigger {name table when event condition code ddl}
		method exportView {name code ddl}
		method sepSelected {path}
		method databaseExportBegin {dbName dbType dbFile}
		method getEncoding {}
		proc validateMax1Char {str}
	}
}

body CsvExportPlugin::constructor {} {
	set checkState(customSeparator) $_separator
	set checkState(columns_in_first_row) $_columnsInFirstRow
	set checkState(null_as) $_nullAs
	set checkState(encoding) $_encoding
}

body CsvExportPlugin::getName {} {
	return "CSV"
}

body CsvExportPlugin::getEncoding {} {
	return $_encoding
}

body CsvExportPlugin::configurable {context} {
	return true
}

body CsvExportPlugin::createConfigUI {path context} {
	set checkState(customSeparator) $_separator
	set checkState(columns_in_first_row) $_columnsInFirstRow
	set checkState(null_as) $_nullAs
	set customEditState "disabled"
	set listIndex 0
	if {$_separator in $separators} {
		set listIndex [lsearch -exact $separators $_separator]
	} else {
		set customEditState "normal"
		set listIndex [expr {[llength $sepLabels]-1}]
	}

	# Include columns
	ttk::checkbutton $path.incCol -text [mc {Column names as first row}] -variable [scope checkState](columns_in_first_row)
	set checkState(columns_in_first_row) $_columnsInFirstRow
	pack $path.incCol -side top -fill x
	helpHint $path.incCol [mc "If enabled, then first row of exported CSV will be a list of column names."]

	# Separator
	ttk::frame $path.sep
	ttk::label $path.sep.lab -text [mc {Columns separator:}] -justify left
	ttk::frame $path.sep.val
	ttk::combobox $path.sep.val.list -values $sepLabels -state readonly
	ttk::entry $path.sep.val.edit -width 2 -textvariable [scope checkState](customSeparator) \
		 -validatecommand [list CsvExportPlugin::validateMax1Char %P] -validate all -state $customEditState
	pack $path.sep -side top -fill x -pady 5
	pack $path.sep.lab -side top -fill x
	pack $path.sep.val -side top -fill x
	pack $path.sep.val.list -side left -padx 2 -fill x
	pack $path.sep.val.edit -side left -padx 2

	$path.sep.val.list current $listIndex
	bind $path.sep.val.list <<ComboboxSelected>> [list $this sepSelected $path]

	set help [mc "Character used to separate each column data\nfrom each other. If separator occures in any data column,\nthen the value is enclosed in quote characters.\nAny quote character in value is replaced with two quote characters."]
	helpHint $path.sep.lab $help
	helpHint $path.sep.val.edit $help
	helpHint $path.sep.val.list $help

	# Null handling
	ttk::frame $path.null
	ttk::label $path.null.lab -text [mc {Export NULL values as:}] -justify left
	ttk::entry $path.null.edit -textvariable [scope checkState](null_as)
	pack $path.null -side top -fill x -pady 5
	pack $path.null.lab -side top -fill x
	pack $path.null.edit -side top -padx 2 -fill x

	# Encoding
	set w enc
	ttk::frame $path.$w
	ttk::label $path.$w.l -text [mc {Encoding:}]
	ttk::combobox $path.$w.c -values [lsort -dictionary [encoding names]] -state readonly -textvariable [scope checkState(encoding)]
	pack $path.$w -side top -fill x -padx 2 -pady 2
	pack $path.$w.l -side left
	pack $path.$w.c -side right

	focus $path.sep.val.list
}

body CsvExportPlugin::applyConfig {path context} {
	set idx [$path.sep.val.list current]
	if {[lindex $separators $idx] == ""} {
		set _separator $checkState(customSeparator)
	} else {
		set _separator [lindex $separators $idx]
	}
	set _columnsInFirstRow $checkState(columns_in_first_row)
	set _nullAs $checkState(null_as)
	set _encoding $checkState(encoding)
}

body CsvExportPlugin::exportResults {columns totalRows} {
	if {$_columnsInFirstRow} {
		set cols [list]
		foreach colPair $columns {
			lappend cols [dict get $colPair displayName]
		}
		$this write [exportLine $cols]
		$this write "\n"
	}
}

body CsvExportPlugin::exportResultsRow {cellsData columns} {
	set outputRow [list]
	foreach cellPair $cellsData {
		if {[lindex $cellPair 1]} {
			lappend outputRow $_nullAs
		} else {
			lappend outputRow [lindex $cellPair 0]
		}
	}
	$this write [exportLine $outputRow]
	$this write "\n"
}

body CsvExportPlugin::exportResultsEnd {} {
}

body CsvExportPlugin::exportTable {name columns ddl totalRows} {
	if {$_columnsInFirstRow} {
		set cols [list]
		foreach colPair $columns {
			lappend cols [lindex $colPair 0]
		}
		$this write [exportLine $cols]
		$this write "\n"
	}
}

body CsvExportPlugin::exportTableRow {cellsData columns} {
	set outputRow [list]
	foreach cellPair $cellsData {
		if {[lindex $cellPair 1]} {
			lappend outputRow $_nullAs
		} else {
			lappend outputRow [lindex $cellPair 0]
		}
	}
	$this write [exportLine $outputRow]
	$this write "\n"
}

body CsvExportPlugin::exportTableEnd {name} {
}

body CsvExportPlugin::exportIndex {name table columns unique ddl} {
}

body CsvExportPlugin::exportTrigger {name table when event condition code ddl} {
}

body CsvExportPlugin::exportView {name code ddl} {
}

body CsvExportPlugin::validateConfig {context} {
	if {$_separator == ""} {
		error [mc {CSV separator cannot be empty.}]
	}
}

body CsvExportPlugin::validateMax1Char {str} {
	return [expr {[string length $str] <= 1}]
}

body CsvExportPlugin::exportLine {lineData} {
	set list [list]
	foreach val $lineData {
		if {[string first $_separator $val] > -1 || [string first "\n" $val] > -1 || [string first "\"" $val] > -1} {
			set val [string map [list \" \"\"] $val]
			set val "\"$val\""
		}
		lappend list $val
	}
	return [join $list $_separator]
}

body CsvExportPlugin::sepSelected {path} {
	set idx [$path.sep.val.list current]
	if {[lindex $separators $idx] == ""} {
		update
		$path.sep.val.edit configure -state normal
		focus $path.sep.val.edit
	} else {
		$path.sep.val.edit configure -state disabled
	}
}

body CsvExportPlugin::databaseExportBegin {dbName dbType dbFile} {
}

body CsvExportPlugin::isContextSupported {context} {
	expr {$context != "DATABASE"}
}
