use src/plugins/export/csv.tcl

class XlsExportPlugin {
	inherit CsvExportPlugin

	constructor {} {}

	protected {
		variable _columnsInFirstRow 0
		variable _encoding [encoding system]
	}

	public {
		variable checkState
		proc getName {}
		proc configurable {context}
		proc isContextSupported {context}
		method createConfigUI {path context}
		method applyConfig {path context}
		method validateConfig {context}
		method getEncoding {}
		method autoFileExtension {}
		proc validateMax1Char {str}
	}
}

body XlsExportPlugin::constructor {} {
	set checkState(encoding) $_encoding
	set _separator "\t"
	set _nullAs ""
}

body XlsExportPlugin::getName {} {
	return "XLS (MS Excel)"
}

body XlsExportPlugin::autoFileExtension {} {
	return ".xls"
}

body XlsExportPlugin::getEncoding {} {
	return $_encoding
}

body XlsExportPlugin::configurable {context} {
	return true
}

body XlsExportPlugin::createConfigUI {path context} {
	# Include columns
	ttk::checkbutton $path.incCol -text [mc {Column names as first row}] -variable [scope checkState](columns_in_first_row)
	set checkState(columns_in_first_row) $_columnsInFirstRow
	pack $path.incCol -side top -fill x
	helpHint $path.incCol [mc "If enabled, then first row of exported document will be a list of column names."]

	# Encoding
	set w enc
	ttk::frame $path.$w
	ttk::label $path.$w.l -text [mc {Encoding:}]
	ttk::combobox $path.$w.c -values [lsort -dictionary [encoding names]] -state readonly -textvariable [scope checkState(encoding)]
	pack $path.$w -side top -fill x -padx 2 -pady 2
	pack $path.$w.l -side left
	pack $path.$w.c -side right
}

body XlsExportPlugin::applyConfig {path context} {
	set _columnsInFirstRow $checkState(columns_in_first_row)
	set _encoding $checkState(encoding)
}

body XlsExportPlugin::validateConfig {context} {
}

body XlsExportPlugin::isContextSupported {context} {
	expr {$context != "DATABASE"}
}
