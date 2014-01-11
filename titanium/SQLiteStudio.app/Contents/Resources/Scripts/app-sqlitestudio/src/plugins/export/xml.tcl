use src/plugins/export_plugin.tcl

class XmlExportPlugin {
	inherit ExportPlugin

	constructor {} {}

	private {
		variable _xsdFile "src/plugins/export/xml_schema.xsd"
		variable _schemaNs "http://sqlitestudio.pl/export/xml"
		variable _format "unformatted"
		variable _genXsd 0
		variable _indent 0
		variable _lb ""
		variable _encoding [encoding system]

		method LB {}
		method TAB {}
		method xmlEncoding {}
		method write {data}
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
		method exportFileSchema {context}
		method afterExport {exportFile}
		method getEncoding {}
		method autoFileExtension {}
	}
}

body XmlExportPlugin::constructor {} {
	set checkState(format) $_format
	set checkState(gen_xsd) $_genXsd
	set checkState(encoding) $_encoding
}

body XmlExportPlugin::getName {} {
	return "XML"
}

body XmlExportPlugin::autoFileExtension {} {
	return ".xml"
}

body XmlExportPlugin::getEncoding {} {
	return $_encoding
}

body XmlExportPlugin::configurable {context} {
	return true
}

body XmlExportPlugin::createConfigUI {path context} {
	set checkState(format) $_format
	set checkState(gen_xsd) $_genXsd
	set checkState(encoding) $_encoding

	# Format
	pack [ttk::frame $path.format] -side top -fill x -padx 2 -pady 3
	foreach {w label hint} [list \
		unformatted [mc {No extra white-spaces or new lines}] [mc {XML tags will be places char-by-char, without any extra white-spaces.}] \
		formatted [mc {Format output to be human readable}] [mc "Each tag will be placed in new line and whole document\nwill be justified to be more readable in text editor."] \
	] {
		ttk::frame $path.format.$w
		ttk::radiobutton $path.format.$w.c -text $label -variable [scope checkState(format)] -value $w
		helpHint $path.format.$w.c $hint
		pack $path.format.$w -side top -fill x -padx 2 -pady 2
		pack $path.format.$w.c -side left
	}

	# Generate XSD
	set w xsd
	ttk::frame $path.$w
	ttk::checkbutton $path.$w.c -text [mc {Generate XSD file}] -variable [scope checkState(gen_xsd)]
	helpHint $path.$w.c [mc "Generates XML Schema Definition file using\nexport file name and extension *.xsd."]
	pack $path.$w -side top -fill x -padx 2 -pady 2
	pack $path.$w.c -side left

	# Encoding
	set w enc
	ttk::frame $path.$w
	ttk::label $path.$w.l -text [mc {Encoding:}]
	ttk::combobox $path.$w.c -values [lsort -dictionary [array names ::XML_encoding]] -state readonly -textvariable [scope checkState(encoding)]
	pack $path.$w -side top -fill x -padx 2 -pady 2
	pack $path.$w.l -side left
	pack $path.$w.c -side right
}

body XmlExportPlugin::applyConfig {path context} {
	set _format $checkState(format)
	set _genXsd $checkState(gen_xsd)
	set _encoding $checkState(encoding)
	if {$_format == "formatted"} {
		set _lb "\n"
	} else {
		set _lb ""
	}
}

body XmlExportPlugin::xmlEncoding {} {
	return [lindex $::XML_encoding($_encoding) 0]
}

body XmlExportPlugin::exportResults {columns totalRows} {
	ExportPlugin::write "<?xml version=\"1.0\" encoding=\"[xmlEncoding]\"?>\n"
	if {$checkState(gen_xsd)} {
		write "<results xmlns=\"$_schemaNs\">"
	} else {
		write "<results>"
	}
	incr _indent

	# Columns
	write "<columns>"
	incr _indent
	foreach col $columns {
		set table [dict get $col table]
		set name [dict get $col column]
		set type [dict get $col type]

		write "<column>"
		incr _indent
		write "<name>[escapeXML $name]</name>"
		write "<table>[escapeXML $table]</table>"
		write "<type>[escapeXML $type]</type>"
		incr _indent -1
		write "</column>"
	}
	incr _indent -1
	write "</columns>"
	write "<rows>"
	incr _indent
}

body XmlExportPlugin::exportResultsRow {cellsData columns} {
	write "<row>"
	incr _indent
	foreach cell $cellsData col $columns {
		set table [dict get $col table]
		set name [dict get $col column]
		set type [dict get $col type]
		lassign $cell cellValue isNull

		set str "<value"
		append str " column=\"[escapeXML $name]\""
		append str " table=\"$table\""
		if {$isNull} {
			append str " null=\"true\"/>"
		} else {
			append str " null=\"false\">[escapeXML $cellValue]</value>"
		}
		write $str
	}
	incr _indent -1
	write "</row>"
}

body XmlExportPlugin::exportResultsEnd {} {
	incr _indent -1
	write "</rows>"

	# End
	incr _indent -1
	write "</results>"
}

body XmlExportPlugin::exportTable {name columns ddl totalRows} {
	if {$_context == "TABLE"} {
		ExportPlugin::write "<?xml version=\"1.0\" encoding=\"[xmlEncoding]\"?>\n"
		if {$checkState(gen_xsd)} {
			write "<table xmlns=\"$_schemaNs\">"
		} else {
			write "<table>"
		}
	} else {
		write "<table>"
	}
	incr _indent
	write "<name>[escapeXML $name]</name>"
	write "<columns>"
	incr _indent
	foreach col $columns {
		lassign $col colName type pk notnull dfltValue
		lassign $dfltValue dflt_value dfltNull
		write "<column>"
		incr _indent
		write "<name>[escapeXML $colName]</name>"
		write "<type>[escapeXML $type]</type>"
		write "<primaryKey>$pk</primaryKey>"
		write "<notNull>$notnull</notNull>"
		if {!$dfltNull} {
			write "<defaultValue>[escapeXML $dflt_value]</defaultValue>"
		}
		incr _indent -1
		write "</column>"
	}
	incr _indent -1
	write "</columns>"

	write "<rows>"
	incr _indent
}

body XmlExportPlugin::exportTableRow {cellsData columns} {
	write "<row>"
	incr _indent
	foreach cell $cellsData c $columns {
		lassign $c colName type pk notnull dflt_value
		lassign $cell cellValue isNull
		set str "<value"
		append str " column=\"[escapeXML $colName]\""
		if {$isNull} {
			append str " null=\"true\"/>"
		} else {
			append str " null=\"false\">[escapeXML $cellValue]</value>"
		}
		write $str
	}
	incr _indent -1
	write "</row>"
}

body XmlExportPlugin::exportTableEnd {name} {
	incr _indent -1
	write "</rows>"
	incr _indent -1
	write "</table>"
}

body XmlExportPlugin::exportIndex {name table columns unique ddl} {
	write "<index>"
	incr _indent
	write "<name>[escapeXML $name]</name>"
	write "<table>[escapeXML $table]</table>"
	write "<unique>$unique</unique>"
	write "<columns>"
	incr _indent
	foreach col $columns {
		lassign $col colName collation sorting
		write "<column>"
		incr _indent
		write "<name>[escapeXML $colName]</name>"
		if {$collation != ""} {
			write "<collate>[escapeXML $collation]</collate>"
		}
		if {$sorting != ""} {
			write "<sort>$sorting</sort>"
		}
		incr _indent -1
		write "</column>"
	}
	incr _indent -1
	write "</columns>"
	incr _indent -1
	write "</index>"
}

body XmlExportPlugin::exportTrigger {name table when event condition code ddl} {
	write "<trigger>"
	incr _indent
	write "<name>[escapeXML $name]</name>"
	write "<when>[escapeXML $when]</when>"
	write "<action>[escapeXML $event]</action>"
	write "<table>[escapeXML $table]</table>"
	if {$condition != ""} {
		write "<condition>[escapeXML $condition]</condition>"
	}
	write "<code>[escapeXML $code]</code>"
	incr _indent -1
	write "</trigger>"
}

body XmlExportPlugin::exportView {name code ddl} {
	write "<view>"
	incr _indent
	write "<name>[escapeXML $name]</name>"
	write "<code>[escapeXML $code]</code>"
	incr _indent -1
	write "</view>"
}

body XmlExportPlugin::validateConfig {context} {
}

body XmlExportPlugin::databaseExportBegin {dbName dbType dbFile} {
	write "<name>[escapeXML $dbName]</name>"
	write "<type>[escapeXML $dbType]</type>"
}

body XmlExportPlugin::LB {} {
	return $_lb
}

body XmlExportPlugin::TAB {} {
	if {$_format == "formatted"} {
		return [string repeat "\t" $_indent]
	} else {
		return ""
	}
}

body XmlExportPlugin::write {data} {
	ExportPlugin::write "[TAB]$data[LB]"
}

body XmlExportPlugin::exportFileSchema {context} {
	switch -- $context {
		"DATABASE" {
			set output "<?xml version=\"1.0\" encoding=\"[xmlEncoding]\"?>\n"
			if {$checkState(gen_xsd)} {
				write "<database xmlns=\"$_schemaNs\">"
			} else {
				write "<database>"
			}
			incr _indent
			write "%BEGIN%"

			write "<tables>"
			incr _indent
			write "%TABLES%"
			incr _indent -1
			write "</tables>"

			write "<indexes>"
			incr _indent
			write "%INDEXES%"
			incr _indent -1
			write "</indexes>"

			write "<triggers>"
			incr _indent
			write "%TRIGGERS%"
			incr _indent -1
			write "</triggers>"

			write "<views>"
			incr _indent
			write "%VIEWS%"
			incr _indent -1
			write "</views>"
			incr _indent -1

			write "</database>"
			return $output
		}
		"TABLE" {
			return "%TABLE%"
		}
		"QUERY" {
			return "%RESULT%"
		}
	}
}

body XmlExportPlugin::afterExport {exportFile} {
	if {!$_genXsd} return

	set idx [string last "." $exportFile]
	set ext [string range $exportFile $idx end]
	set lgt [string length $ext]
	if {$lgt < 2} {
		set schemaFileName [string trimright $exportFile "."]
		append schemaFileName ".xsd"
	} elseif {$lgt > 5} {
		set schemaFileName $exportFile
		append schemaFileName "xsd"
	} else {
		set schemaFileName [string range $exportFile 0 $idx]
		append schemaFileName "xsd"
	}
	if {[catch {
		file copy -force $_xsdFile $schemaFileName
	} res]} {
		cutOffStdTclErr res
		Info [mc "There were problems while creating XSD file, but all data was successfly exported to XML file anyway. Problems details:\n%s" $res]
	}
}

body XmlExportPlugin::isContextSupported {context} {
	return true
}
