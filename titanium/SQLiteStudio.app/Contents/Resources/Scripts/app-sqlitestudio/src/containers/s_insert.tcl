use src/parser/statement.tcl

class StatementInsert {
	inherit Statement

	constructor {} {
		lappend _listTypeVariableForDebug "columnNames"
	}

	private {
		variable _partialColumnValues [list]
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
		variable columnValues [list] ;# list of lists of objects
		variable valuesKeyword 0
		variable subSelect "" ;# object
		variable defaultValues 0

		method afterParsing {} {
			set realDatabaseName [resolveDatabase $databaseName]
		}
		method addColumnName {name} {lappend columnNames $name}
		method addColumnValue {val}
		method columnValueSetEnd {}

		method getColumnNames {}
		method getTableNames {}
		method getDatabaseNames {}
	}
}

body StatementInsert::addColumnValue {val} {
	lappend _partialColumnValues $val
}

body StatementInsert::columnValueSetEnd {} {
	lappend columnValues $_partialColumnValues
	set _partialColumnValues [list]
}

body StatementInsert::getColumnNames {} {
	set resultList [list]
	foreach colName $columnNames {
		lappend resultList [dict create column [getContextValueFromToken $colName] type LITERAL]
	}
	return $resultList
}

body StatementInsert::getTableNames {} {
	set res [dict create]
# 	puts "jest!"
	if {$tableName != ""} {
# 		puts "tabela: $tableName"
		dict set res table [getContextValue tableName]
		if {$databaseName != ""} {
			dict set res database [getContextValue databaseName]
		}
	}
	return [list $res]
}

body StatementInsert::getDatabaseNames {} {
	if {$databaseName != ""} {
		return [list [dict create database [getContextValue databaseName] realname $realDatabaseName]]
	}
	return [list]
}
