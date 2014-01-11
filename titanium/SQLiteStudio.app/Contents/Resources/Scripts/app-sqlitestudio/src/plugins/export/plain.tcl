use src/plugins/export_plugin.tcl

class PlainExportPlugin {
	inherit ExportPlugin


	constructor {} {}

	private {
		variable _nullRepresentation ""
		variable _maxWidth 30
		variable _encoding [encoding system]
		variable _rowNum 0

		method exportLine {lineData}
		method writeHeader {columns}
		method writeRow {row}
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

body PlainExportPlugin::constructor {} {
	set checkState(nullRepresentation) $_nullRepresentation
	set checkState(maxWidth) $_maxWidth
	set checkState(encoding) $_encoding
}

body PlainExportPlugin::getName {} {
	return "PLAIN"
}

body PlainExportPlugin::getEncoding {} {
	return $_encoding
}

body PlainExportPlugin::configurable {context} {
	return true
}

body PlainExportPlugin::createConfigUI {path context} {
	set checkState(nullRepresentation) $_nullRepresentation
	set checkState(maxWidth) $_maxWidth
# 	set customEditState "disabled"
# 	set listIndex 0
# 	if {$_separator in $separators} {
# 		set listIndex [lsearch $separators $_separator]
# 	} else {
# 		set customEditState "normal"
# 		set listIndex [expr {[llength $sepLabels]-1}]
# 	}

	ttk::frame $path.null
	ttk::label $path.null.l -text [mc {Export NULL values as:}]
	ttk::entry $path.null.e -textvariable [scope checkState(nullRepresentation)] -cursor xterm
	pack $path.null.l -side left
	pack $path.null.e -side right

	ttk::frame $path.width
	ttk::label $path.width.l -text [mc {Fixed column width:}]
	ttk::spinbox $path.width.e -textvariable [scope checkState(maxWidth)] -from 1 -to 9999999 -increment 1 -width 8 \
		-validate all -validatecommand "string is digit %P"
	pack $path.width.l -side left
	pack $path.width.e -side right

	pack $path.null $path.width -side top -fill x -padx 3 -pady 3

	# Encoding
	set w enc
	ttk::frame $path.$w
	ttk::label $path.$w.l -text [mc {Encoding:}]
	ttk::combobox $path.$w.c -values [lsort -dictionary [encoding names]] -state readonly -textvariable [scope checkState(encoding)]
	pack $path.$w -side top -fill x -padx 2 -pady 2
	pack $path.$w.l -side left
	pack $path.$w.c -side right

	focus $path.null.e
}

body PlainExportPlugin::applyConfig {path context} {
	set _nullRepresentation $checkState(nullRepresentation)
	set _maxWidth $checkState(maxWidth)
	set _encoding $checkState(encoding)
}

body PlainExportPlugin::writeHeader {columns} {
	# Adding column labels
	set rowToAdd [list]
	set addedColumns [list]
	set colNum 0
	foreach dataCol [concat [dict create column "#" table ""] $columns] {
# 		lassign $dataCol fullName type
		set table [dict get $dataCol table]
		set name [dict get $dataCol column]
# 		lassign [splitSqlObjectsFromPath $fullName] table name
# 		if {$name == ""} {
# 			set name $table
# 			set table ""
# 		}

		if {$name in $addedColumns && $table != ""} {
			set name "$table.$name"
		}
		lappend addedColumns $name
		lappend rowToAdd [pad $_maxWidth " " $name]
		incr colNum
	}
	write [join $rowToAdd "|"]
	write "\n"

	# Adding header separator
	set rowToAdd [list]
	lappend rowToAdd [pad $_maxWidth "-" ""] ;# this one for rowNum column
	foreach dataCol $columns {
		lappend rowToAdd [pad $_maxWidth "-" ""]
	}
	write [join $rowToAdd "+"]
	write "\n"
	set _rowNum 1
}

body PlainExportPlugin::writeRow {row} {
	set rowToAdd [list]
	set colNum 0
	set maxMinusOne [expr {$_maxWidth - 1}]
	foreach colValue [concat [list [list $_rowNum 0]] $row] {
		lassign $colValue cellData isNull
		if {$isNull} {
			set value [string range $_nullRepresentation 0 $maxMinusOne]
		} else {
			set value [string range $cellData 0 $maxMinusOne]
		}
		lappend rowToAdd [pad $_maxWidth " " $value]
		incr colNum
	}
	write [join $rowToAdd "|"]
	write "\n"
	incr _rowNum
}

body PlainExportPlugin::databaseExportBegin {dbName dbType dbFile} {
	write [mc {Database: %s (%s, %s)} $dbName $dbFile $dbType]
	write "\n\n"
}

body PlainExportPlugin::exportResults {columns totalRows} {
	writeHeader $columns
}

body PlainExportPlugin::exportResultsRow {cellsData columns} {
	writeRow $cellsData
}

body PlainExportPlugin::exportResultsEnd {} {
}

body PlainExportPlugin::exportTable {name columns ddl totalRows} {
	if {$_context == "DATABASE"} {
		write "\n"
	}
	write [mc {Table: %s} $name]
	write "\n"

	set cols [list]
	foreach c $columns {
		lappend cols [dict create table $name column [lindex $c 0]]
	}

	writeHeader $cols
}

body PlainExportPlugin::exportTableRow {cellsData columns} {
	writeRow $cellsData
}

body PlainExportPlugin::exportTableEnd {name} {
	if {$_context == "DATABASE"} {
		write "\n\n"
	}
}

body PlainExportPlugin::exportIndex {name table columns unique ddl} {
	write "\n"
	write [mc {Index: %s} $name]
	write "\n"
	write "-----------------------------------------\n"
	write $ddl
	write "\n"
}

body PlainExportPlugin::exportTrigger {name table when event condition code ddl} {
	write "\n"
	write [mc {Trigger: %s} $name]
	write "\n"
	write "-----------------------------------------\n"
	write [Formatter::format $ddl $_db]
	write "\n"
}

body PlainExportPlugin::exportView {name code ddl} {
	write "\n"
	write [mc {View: %s} $name]
	write "\n"
	write "-----------------------------------------\n"
	write [Formatter::format $ddl $_db]
	write "\n"
}

body PlainExportPlugin::validateConfig {context} {
}

body PlainExportPlugin::isContextSupported {context} {
	return true
}
