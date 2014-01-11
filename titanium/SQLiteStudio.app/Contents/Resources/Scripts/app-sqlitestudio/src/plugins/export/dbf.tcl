use src/plugins/export_plugin.tcl

class DbfExportPlugin {
	inherit ExportPlugin

	constructor {} {}

	private {
		variable _dbf ""
		variable _filePath ""
		variable _colNames [list]

		method mapType {inputType}
		method getColName {name}
		method exportDataRow {cellsData}
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
		method provideColumnWidths {}
		method beforeStart {}
		method finished {}
		method handleError {errorType args}
		method manageFile {}
		method setFile {path}
		method autoFileExtension {}
	}
}

body DbfExportPlugin::constructor {} {
}

body DbfExportPlugin::getName {} {
	return "dBase (DBF)"
}

body DbfExportPlugin::getEncoding {} {
	return "binary"
}

body DbfExportPlugin::autoFileExtension {} {
	return ".dbf"
}

body DbfExportPlugin::configurable {context} {
	return false
}

body DbfExportPlugin::createConfigUI {path context} {
}

body DbfExportPlugin::applyConfig {path context} {
}

body DbfExportPlugin::handleError {errorType args} {
	switch -- $errorType {
		"DBT_DOESNT_EXIST" {
			error "The dbt file doesn't exist"
		}
		"DBT_READ_ONLY" {
			error "The dbt file is read-only."
		}
		"COLUMN_EXISTS" {
			error "Column already exists: $args"
		}
		"RECORDS_EXIST" {
			error "Records already exists, cannot add new column."
		}
		"COLUMN_NAME_TOO_LONG" {
			error "Too long column name: $args"
		}
		"VALUE_TOO_LONG" {
			error "Value too long."
		}
		"NO_RECORDS_WHILE_UPDATING" {
			error "No records to update while trying to update."
		}
	}
}

body DbfExportPlugin::beforeStart {} {
	set _colNames [list]
	set _dbf [tdbf::dbf ::#auto [list $this handleError]]
	$_dbf open $_filePath
	#$_dbf setEncoding cp1250
	return true
}

body DbfExportPlugin::finished {} {
	$_dbf close
	set _dbf ""
}

body DbfExportPlugin::getColName {name} {
	set newName [string range $name 0 9] ;# Column names can be max 10 chars
	if {$newName in $_colNames} {
		set i 8
		while {([string length $newName] > 10 || $newName in $_colNames) && $i > 0} {
			set prefix [string range $name 0 $i]
			set newName [genUniqueSeqName $_colNames $prefix]
			incr i -1
		}
		if {$newName in $_colNames} {
			error "Cannot generate unique 10-characters column name for column $name."
		}
	}
	lappend _colNames $newName
	return $newName
}

body DbfExportPlugin::exportResults {columns totalRows} {
	foreach col $columns {
		set name [getColName [dict get $col displayName]]
		set maxWidth [dict get $c maxDataWidth]

		if {$maxWidth > 254} {
			set type "M"
			set length 0
		} else {
			set type "C"
			set length $maxWidth
		}
		
		$_dbf addColumn $name $type $length
	}
}

body DbfExportPlugin::exportDataRow {cellsData} {
	set outputRow [list]
	foreach cellPair $cellsData {
		if {[lindex $cellPair 1]} {
			lappend outputRow ""
		} else {
			lappend outputRow [lindex $cellPair 0]
		}
	}
	$_dbf insert $outputRow
}

body DbfExportPlugin::exportResultsRow {cellsData columns} {
	exportDataRow $cellsData
}

body DbfExportPlugin::exportResultsEnd {} {
}

body DbfExportPlugin::exportTable {name columns ddl totalRows} {
	foreach col $columns {
		lassign $col colName colType pk notnull dflt_value colDataMaxWidth
		set name [getColName $colName]

		if {$colDataMaxWidth > 254} {
			set type "M"
			set length 0
		} else {
			set type "C"
			set length $colDataMaxWidth
		}

		$_dbf addColumn $name $type $length
	}
}

body DbfExportPlugin::exportTableRow {cellsData columns} {
	exportDataRow $cellsData
}

body DbfExportPlugin::exportTableEnd {name} {
}

body DbfExportPlugin::exportIndex {name table columns unique ddl} {
}

body DbfExportPlugin::exportTrigger {name table when event condition code ddl} {
}

body DbfExportPlugin::exportView {name code ddl} {
}

body DbfExportPlugin::validateConfig {context} {
}

body DbfExportPlugin::databaseExportBegin {dbName dbType dbFile} {
}

body DbfExportPlugin::isContextSupported {context} {
	expr {$context != "DATABASE"}
}

body DbfExportPlugin::provideColumnWidths {} {
	return true
}

body DbfExportPlugin::manageFile {} {
	return true
}

body DbfExportPlugin::setFile {path} {
	set _filePath $path
	if {[file exists $path] && [catch {file delete -force $path} err]} {
		Error [mc {Cannot overwrite file '%s'.} $path]
		return false
	}
	return true
}
