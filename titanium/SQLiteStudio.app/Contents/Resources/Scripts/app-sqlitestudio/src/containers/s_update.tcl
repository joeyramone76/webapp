use src/parser/statement.tcl

class StatementUpdate {
	inherit Statement

	public {
		variable orKeyword 0
		variable orAction "" ;# ROLLBACK, ABORT, REPLACE, FAIL, or IGNORE
		variable qualifiedTableName "" ;# object
		variable columnNames [list] ;# list of names
		variable columnValues [list] ;# list of objects
		variable whereExpr "" ;# object

		# Variables below are optional syntax of sqlite3, disabled by default
		variable orderByKeyword 0
		variable orderingTerms [list] ;# list of objects
		variable limitKeyword 0
		variable offsetKeyword 0 ;# 1 for OFFSET, 2 for ","
		variable limit ""
		variable offset ""

		method addColumnName {name} {lappend columnNames $name}
		method addColumnValue {val} {lappend columnValues $val}
		method addOrderingTerm {val} {lappend orderingTerms $val}

		method getColumnNames {}
	}
}

body StatementUpdate::getColumnNames {} {
	set resultList [list]
	foreach colName $columnNames {
		lappend resultList [dict create column [getContextValueFromToken $colName] type LITERAL]
	}
	if {$whereExpr != ""} {
		lappend resultList [dict create column [getContextValueFromToken $whereExpr] type OBJECT]
	}
	return $resultList
}

class StatementQualifiedTableName {
	inherit Statement

	public {
		variable databaseName ""
		variable tableName ""
		variable realDatabaseName ""
		variable indexedKeyword 0
		variable indexName ""
		variable notKeyword 0

		method afterParsing {} {
			set realDatabaseName [resolveDatabase $databaseName]
		}

		method getTableNames {}
		method getDatabaseNames {}
	}
}

body StatementQualifiedTableName::getTableNames {} {
	set res [dict create]
	if {$tableName != ""} {
		dict set res table [getContextValue tableName]
		if {$databaseName != ""} {
			dict set res database [getContextValue databaseName]
		}
	}
	return [list $res]
}

body StatementQualifiedTableName::getDatabaseNames {} {
	if {$databaseName != ""} {
		return [list [dict create database [getContextValue databaseName] realname $realDatabaseName]]
	}
	return [list]
}
