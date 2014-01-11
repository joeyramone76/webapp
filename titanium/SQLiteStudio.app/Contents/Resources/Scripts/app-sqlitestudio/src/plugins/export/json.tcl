use src/plugins/export_plugin.tcl

class JsonExportPlugin {
	inherit ExportPlugin

	constructor {} {}
	destructor {}

	private {
		variable _indented 0
		variable _aligned 0
		variable _asObject 0
		variable _encoding [encoding system]
		variable _json ""
		variable _widget

		method exportRow {cellsData columns}
		method exportDataBegin {}
		method exportDataEnd {}
		method createJson {}
		method deleteJson {}
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
		method databaseExportBegin {dbName dbType dbFile}
		method getEncoding {}
		method beforeStart {}
		method finished {}
		method updateConfigState {}
	}
}

body JsonExportPlugin::constructor {} {
	set checkState(indented) $_indented
	set checkState(aligned) $_aligned
	set checkState(encoding) $_encoding
	set checkState(asObject) $_asObject
}

body JsonExportPlugin::destructor {} {
	deleteJson
}

body JsonExportPlugin::createJson {} {
	set _json [Json ::#auto]
	$_json configure -indent $_indented -align $_aligned
}

body JsonExportPlugin::deleteJson {} {
	if {$_json != ""} {
		delete object $_json
		set _json ""
	}
}

body JsonExportPlugin::getName {} {
	return "JSON"
}

body JsonExportPlugin::getEncoding {} {
	return $_encoding
}

body JsonExportPlugin::configurable {context} {
	return true
}

body JsonExportPlugin::createConfigUI {path context} {
	set checkState(indented) $_indented
	set checkState(aligned) $_aligned
	set checkState(encoding) $_encoding
	set checkState(asObject) $_asObject

	pack [ttk::frame $path.format] -side top -fill x -padx 2 -pady 3
	foreach {w label hint} [list \
		indented [mc {Indented lines}] [mc "SQLiteStudio will break the generated JSON code across lines\nand indent it according to its inner structure,\nwith each key of an object on a separate line."] \
		aligned [mc {Align lines}] [mc "SQLiteStudio ensures that the values for the keys\nin an object are vertically aligned with each other,\nfor a nice table effect."] \
		asObject [mc {Each row as object}] [mc "If disabled, then each row is exported as JSON array.\nIf enabled, then each row is exported as JSON object\nwith column names as object keys."] \
	] {
		ttk::frame $path.format.$w
		ttk::checkbutton $path.format.$w.c -text $label -variable [scope checkState($w)]
		helpHint $path.format.$w.c $hint
		pack $path.format.$w -side top -fill x -padx 2 -pady 2
		pack $path.format.$w.c -side left
		set _widget($w) $path.format.$w.c
	}

	$_widget(indented) configure -command [list $this updateConfigState]

	# Encoding
	set w enc
	ttk::frame $path.$w
	ttk::label $path.$w.l -text [mc {Encoding:}]
	set encodings [lsort -dictionary [ldelete [encoding names] "identity"]]
	ttk::combobox $path.$w.c -values $encodings -state readonly -textvariable [scope checkState(encoding)]
	pack $path.$w -side top -fill x -padx 2 -pady 2
	pack $path.$w.l -side left
	pack $path.$w.c -side right

	updateConfigState
}

body JsonExportPlugin::updateConfigState {} {
	$_widget(aligned) configure -state [expr {$checkState(indented) ? "normal" : "disabled"}]
	if {!$checkState(indented)} {
		set checkState(aligned) 0
	}
}

body JsonExportPlugin::applyConfig {path context} {
	set _indented $checkState(indented) 
	set _aligned $checkState(aligned)
	set _encoding $checkState(encoding)
	set _asObject $checkState(asObject)
}

body JsonExportPlugin::beforeStart {} {
	createJson
	return true
}

body JsonExportPlugin::finished {} {
	deleteJson
}

body JsonExportPlugin::exportResults {columns totalRows} {
	exportDataBegin
}

body JsonExportPlugin::exportResultsRow {cellsData columns} {
	set data [list]
	set cols [list]
	foreach cell $cellsData col $columns {
		lassign $cell cellValue isNull
		if {$isNull} {
			set cellValue ""
		}
		lappend data $cellValue
		lappend cols [dict get $col displayName]
	}
	exportRow $data $cols
}

body JsonExportPlugin::exportResultsEnd {} {
	exportDataEnd
}

body JsonExportPlugin::exportTable {name columns ddl totalRows} {
	exportDataBegin
}

body JsonExportPlugin::exportTableRow {cellsData columns} {
	set data [list]
	set cols [list]
	foreach cell $cellsData c $columns {
		lassign $c colName ;# type pk notnull dflt_value
		lassign $cell cellValue isNull
		
		if {$isNull} {
			set cellValue ""
		}
		lappend data $cellValue
		lappend cols $colName
	}
	exportRow $data $cols
}

body JsonExportPlugin::exportTableEnd {name} {
	exportDataEnd
}

body JsonExportPlugin::exportDataBegin {} {
	write [$_json beginArray]
}

body JsonExportPlugin::exportDataEnd {} {
	write [$_json endArray]
}

body JsonExportPlugin::exportRow {cellsData columns} {
	if {$_asObject} {
		write [$_json beginObject $columns]
		foreach value $cellsData colName $columns {
			write [$_json addValue $colName $value]
		}
		write [$_json endObject]
	} else {
		write [$_json beginArray]
		foreach value $cellsData {
			write [$_json addValue $value]
		}
		write [$_json endArray]
	}
}

body JsonExportPlugin::exportIndex {name table columns unique ddl} {
}

body JsonExportPlugin::exportTrigger {name table when event condition code ddl} {
}

body JsonExportPlugin::exportView {name code ddl} {
}

body JsonExportPlugin::validateConfig {context} {
}

body JsonExportPlugin::databaseExportBegin {dbName dbType dbFile} {
}

body JsonExportPlugin::isContextSupported {context} {
	expr {$context != "DATABASE"}
}
