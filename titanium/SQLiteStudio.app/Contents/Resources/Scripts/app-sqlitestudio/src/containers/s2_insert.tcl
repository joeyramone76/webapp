use src/parser/statement2.tcl

class Statement2Insert {
	inherit Statement2

	constructor {} {
		lappend _listTypeVariableForDebug "columnNames"
	}

	public {
		variable orKeyword 0
		variable orAction "" ;# ROLLBACK, ABORT, REPLACE, FAIL, or IGNORE
		variable insertKeyword 0
		variable replaceKeyword 0
		variable databaseName ""
		variable tableName ""
		variable realDatabaseName ""
		variable columnNames [list] ;# list of names
		variable columnValues [list] ;# list of objects
		variable valuesKeyword 0
		variable subSelect "" ;# object

		method afterParsing {} {
			set realDatabaseName [resolveDatabase $databaseName]
		}
		method addColumnName {name} {lappend columnNames $name}
		method addColumnValue {val} {lappend columnValues $val}

		method getColumnNames {}
		method getTableNames {}
		method getDatabaseNames {}
	}
}

body Statement2Insert::getColumnNames {} {
	set resultList [list]
	foreach colName $columnNames {
		lappend resultList [dict create column [getContextValueFromToken $colName] type LITERAL]
	}
	return $resultList
}

body Statement2Insert::getTableNames {} {
	set res [dict create]
	if {$tableName != ""} {
		dict set res table [getContextValue tableName]
		if {$databaseName != ""} {
			dict set res database [getContextValue databaseName]
		}
	}
	return [list $res]
}

body Statement2Insert::getDatabaseNames {} {
	if {$databaseName != ""} {
		return [list [dict create database [getContextValue databaseName] realname $realDatabaseName]]
	}
	return [list]
}
