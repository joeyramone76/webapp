use src/parser/statement2.tcl

class Statement2Delete {
	inherit Statement2

	public {
		variable databaseName ""
		variable tableName ""
		variable realDatabaseName ""
		variable whereExpr "" ;# object

		method afterParsing {} {
			set realDatabaseName [resolveDatabase $databaseName]
		}

		method getColumnNames {}
		method getTableNames {}
		method getDatabaseNames {}
	}
}

body Statement2Delete::getColumnNames {} {
	set resultList [list]
	lappend resultList [dict create column [getContextValue whereExpr] type OBJECT]
	return $resultList
}

body Statement2Delete::getTableNames {} {
	set res [dict create]
	if {$tableName != ""} {
		dict set res table [getContextValue tableName]
		if {$databaseName != ""} {
			dict set res database [getContextValue databaseName]
		}
	}
	return [list $res]
}

body Statement2Delete::getDatabaseNames {} {
	if {$databaseName != ""} {
		return [list [dict create database [getContextValue databaseName] realname $realDatabaseName]]
	}
	return [list]
}
