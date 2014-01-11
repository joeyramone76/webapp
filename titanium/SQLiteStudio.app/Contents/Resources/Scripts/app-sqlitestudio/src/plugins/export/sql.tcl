use src/plugins/export_plugin.tcl

class SqlExportPlugin {
	inherit ExportPlugin

	private {
		variable _queryTable ""
		variable _includeTableDeclaration 1
		variable _createTable 0
		variable _resultCols [list]
		variable _tableCols [list]
		variable _tableName ""
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
		method exportResults {columns totalRows}
		method exportResultsRow {cellsData columns}
		method exportResultsEnd {}
		method exportTable {name columns ddl totalRows}
		method exportTableRow {cellsData columns}
		method exportTableEnd {name}
		method exportIndex {name table columns unique ddl}
		method exportTrigger {name table when event condition code ddl}
		method exportView {name code ddl}
		method getEncoding {}
		method autoFileExtension {}
	}
}

body SqlExportPlugin::getName {} {
	return "SQL"
}

body SqlExportPlugin::getEncoding {} {
	return $_encoding
}

body SqlExportPlugin::autoFileExtension {} {
	return ".sql"
}

body SqlExportPlugin::configurable {context} {
# 	if {$context in [list "QUERY" "TABLE"]} {
		return true
# 	} else {
# 		return false
# 	}
}

body SqlExportPlugin::createConfigUI {path context} {
	switch -- $context {
		"QUERY" {
			ttk::label $path.table_lab -text [mc {Name of table for exported data:}] -justify left
			ttk::entry $path.table_edit
			pack $path.table_lab $path.table_edit -side top -fill x

			set checkState(createTable) $_createTable
			ttk::checkbutton $path.create_table -text [mc {Include "CREATE TABLE" statement at the begining.}] -variable [scope checkState(createTable)]
			pack $path.table_lab $path.create_table -side top -fill x

			$path.table_edit insert end $_queryTable

			set help [mc "Query results exported to SQL INSERTs have to be defined\nfor some table. It's the name of this table."]
			helpHint $path.table_lab $help
			helpHint $path.table_edit $help

			focus $path.table_edit
		}
		"TABLE" {
			ttk::checkbutton $path.incTab -text [mc {Include table declaration}] -variable [scope checkState](inc_table)
			set checkState(inc_table) $_includeTableDeclaration
			pack $path.incTab -side top -fill x
			helpHint $path.incTab [mc "If enabled, then table DDL (CREATE TABLE)\nwill be included in exported SQL."]
		}
	}

	set checkState(encoding) $_encoding

	# Encoding
	set w enc
	ttk::frame $path.$w
	ttk::label $path.$w.l -text [mc {Encoding:}]
	ttk::combobox $path.$w.c -values [lsort -dictionary [encoding names]] -state readonly -textvariable [scope checkState(encoding)]
	pack $path.$w -side top -fill x -padx 2 -pady 2
	pack $path.$w.l -side left
	pack $path.$w.c -side right
}

body SqlExportPlugin::applyConfig {path context} {
	switch -- $context {
		"QUERY" {
			set _queryTable [$path.table_edit get]
			set _createTable $checkState(createTable)
		}
		"TABLE" {
			set _includeTableDeclaration $checkState(inc_table)
		}
	}
	set _encoding $checkState(encoding)
}

body SqlExportPlugin::exportResults {columns totalRows} {
	set dialect [$_db getDialect]

	set _resultCols [list]
	foreach c $columns {
		lappend _resultCols [dict get $c displayName]
	}

	if {$_createTable} {
		set cols [list]
		foreach c $columns {
			lappend cols [string trim "[wrapObjName [dict get $c displayName] $dialect] [dict get $c type]"]
		}
		write [Formatter::format "CREATE TABLE [wrapObjName $_queryTable $dialect] ([join $cols {, }]);" $_db]
		write "\n"
		write "\n"
	}
}

body SqlExportPlugin::exportResultsRow {cellsData columns} {
	set dialect [$_db getDialect]
	set vals [list]
	foreach cell $cellsData {
		lassign $cell cellData isNull
		if {$isNull} {
			lappend vals "null"
		} elseif {[validateSignedNumeric $cellData]} {
			lappend vals $cellData
		} else {
			lappend vals "'[string map [list ' ''] $cellData]'"
		}
	}
	write "INSERT INTO [wrapObjName $_queryTable $dialect] ([join $_resultCols {, }]) VALUES ([join $vals {, }]);\n"
}

body SqlExportPlugin::exportResultsEnd {} {
}

body SqlExportPlugin::exportTable {name columns ddl totalRows} {
	set dialect [$_db getDialect]
	set _tableName $name

	set _tableCols [list]
	foreach c $columns {
		lappend _tableCols [wrapObjName [lindex $c 0] $dialect]
	}

	if {$_includeTableDeclaration} {
		write "\n"
		write "-- Table: $name\n"
		set ddl [Formatter::format $ddl $_db]
		write $ddl
		if {[string index [string trimright $ddl] end] != ";"} {
			write ";\n"
		}
		write "\n"
	}
}

body SqlExportPlugin::exportTableRow {cellsData columns} {
	set dialect [$_db getDialect]
	set vals [list]
	foreach cell $cellsData {
		lassign $cell cellData isNull
		if {$isNull} {
			lappend vals "null"
		} elseif {[validateSignedNumeric $cellData]} {
			lappend vals $cellData
		} else {
			lappend vals "'[string map [list ' ''] $cellData]'"
		}
	}
	write "INSERT INTO [wrapObjName $_tableName $dialect] ([join $_tableCols {, }]) VALUES ([join $vals {, }]);\n"
}

body SqlExportPlugin::exportTableEnd {name} {
}

body SqlExportPlugin::exportIndex {name table columns unique ddl} {
	write "\n"
	write "-- Index: $name\n"
	write [Formatter::format $ddl $_db]
	if {[string index [string trimright $ddl] end] != ";"} {
		write ";\n"
	}
	write "\n"
}

body SqlExportPlugin::exportTrigger {name table when event condition code ddl} {
	write "\n"
	write "-- Trigger: $name\n"
	write [Formatter::format $ddl $_db]
	if {[string index [string trimright $ddl] end] != ";"} {
		write ";\n"
	}
	write "\n"
}

body SqlExportPlugin::exportView {name code ddl} {
	write "\n"
	write "-- View: $name\n"
	write [Formatter::format $ddl $_db]
	if {[string index [string trimright $ddl] end] != ";"} {
		write ";\n"
	}
	write "\n"
}

body SqlExportPlugin::validateConfig {context} {
	switch -- $context {
		"QUERY" {
			if {$_queryTable == ""} {
				error [mc "You need to configure table name to export query results to SQL.\nSQL INSERTs require table in their syntax."]
			}
		}
	}
}

body SqlExportPlugin::isContextSupported {context} {
	return true
}
