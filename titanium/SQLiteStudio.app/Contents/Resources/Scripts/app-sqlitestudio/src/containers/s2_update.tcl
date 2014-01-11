use src/parser/statement2.tcl

class Statement2Update {
	inherit Statement2

	public {
		variable orKeyword 0
		variable orAction "" ;# ROLLBACK, ABORT, REPLACE, FAIL, or IGNORE
		variable databaseName ""
		variable tableName ""
		variable realDatabaseName ""
		variable columnNames [list] ;# list of names
		variable columnValues [list] ;# list of objects
		variable whereExpr "" ;# object

		method addColumnName {name} {lappend columnNames $name}
		method addColumnValue {val} {lappend columnValues $val}

		method afterParsing {} {
			set realDatabaseName [resolveDatabase $databaseName]
		}

		method getColumnNames {}
		method getTableNames {}
		method getDatabaseNames {}
	}
}

body Statement2Update::getColumnNames {} {
	set resultList [list]
	foreach colName $columnNames {
		lappend resultList [dict create column [getContextValueFromToken $colName] type LITERAL]
	}
	if {$whereExpr != ""} {
		lappend resultList [dict create column [getContextValueFromToken $whereExpr] type OBJECT]
	}
	return $resultList
}

body Statement2Update::getTableNames {} {
	set res [dict create]
	if {$tableName != ""} {
		dict set res table [getContextValue tableName]
		if {$databaseName != ""} {
			dict set res database [getContextValue databaseName]
		}
	}
	return [list $res]
}

body Statement2Update::getDatabaseNames {} {
	if {$databaseName != ""} {
		return [list [dict create database [getContextValue databaseName] realname $realDatabaseName]]
	}
	return [list]
}
