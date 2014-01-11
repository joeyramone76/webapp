use src/plugins/export/csv.tcl

class ClipboardExportPlugin {
	inherit CsvExportPlugin

	constructor {} {}

	public {
		proc getName {}
		proc useFile {}
		proc configurable {context}
		proc isContextSupported {context}

		method beforeStart {}
		method write {data}
	}
}

body ClipboardExportPlugin::constructor {} {
	set _separator "\t"
}

body ClipboardExportPlugin::getName {} {
	return "Clipboard"
}

body ClipboardExportPlugin::useFile {} {
	return false
}

body ClipboardExportPlugin::configurable {context} {
	return true
}

body ClipboardExportPlugin::beforeStart {} {
	clipboard clear
	return true
}

body ClipboardExportPlugin::write {data} {
	clipboard append $data
}

body ClipboardExportPlugin::isContextSupported {context} {
	expr {$context != "DATABASE"}
}
