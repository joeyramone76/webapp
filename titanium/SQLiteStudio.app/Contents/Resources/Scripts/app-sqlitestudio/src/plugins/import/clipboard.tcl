use src/plugins/import/csv.tcl

class ClipboardImportPlugin {
	inherit CsvImportPlugin

	constructor {} {}

	private {
		variable _lineIdx 0
		variable _lines [list]

		method exportLine {lineData}
	}

	protected {
		method openDataSource {}
		method getColumnList {}
		method getNextDataRow {}
	}

	public {
		proc getName {}
		proc configurable {}
		method closeDataSource {}
		method createConfigUI {path}
		method validateConfig {}
	}
}

body ClipboardImportPlugin::constructor {} {
}

body ClipboardImportPlugin::openDataSource {} {
	set _lines [split [clipboard get] \n]
}

body ClipboardImportPlugin::getColumnList {} {
	if {$_columnsInFirstRow} {
		incr _lineIdx
	}
	return [getColumnListFromLine [lindex $_lines 0]]
}

body ClipboardImportPlugin::getNextDataRow {} {
	set result [getNextDataRowFromLine [lindex $_lines $_lineIdx]]
	incr _lineIdx
	return $result
}

body ClipboardImportPlugin::closeDataSource {} {
	set _lines [list]
}

body ClipboardImportPlugin::getName {} {
	return "Clipboard"
}

body ClipboardImportPlugin::configurable {} {
	return true
}

body ClipboardImportPlugin::createConfigUI {path} {
	CsvImportPlugin::createConfigUI $path
	pack forget $path.file $path.showOpts
	set uiVar(show_opts) 1
	updateState
}

body ClipboardImportPlugin::validateConfig {} {
	if {$_separator == ""} {
		error [mc {CSV separator cannot be empty.}]
	}
}
