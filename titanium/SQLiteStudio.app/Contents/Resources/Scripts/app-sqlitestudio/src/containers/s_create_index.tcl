use src/parser/statement.tcl

class StatementCreateIndex {
	inherit Statement

	public {
		variable isUnique 0
		variable ifNotExists 0
		variable databaseName ""
		variable realDatabaseName ""
		variable indexName ""
		variable onTable ""
		variable indexColumns [list] ;# list of objects

		method addIndexColumn {obj}

		method replaceTableToken {newTableName}
		method getTableNames {}
		method afterParsing {} {
			set realDatabaseName [resolveDatabase $databaseName]
		}
	}
}

class StatementIndexedColumn {
	inherit Statement

	public {
		variable columnName ""
		variable collation 0
		variable collationName ""
		variable order ""
	}
}

body StatementCreateIndex::getTableNames {} {
	if {$onTable != ""} {
		set res [dict create]
		dict set res table [getContextValue onTable]
		if {$databaseName != ""} {
			dict set res database [getContextValue databaseName]
		}
		return [list $res]
	}
	return [list]
}

body StatementCreateIndex::addIndexColumn {obj} {
	lappend indexColumns $obj
}

body StatementCreateIndex::replaceTableToken {newTableName} {
	set idx [lsearch -exact $allTokens $onTable]
	if {$idx == -1} {
		debug "Could not find table token to replace by replaceTableToken.\nAll tokens: $allTokens\nTable token: $onTable"
		return
	}
	set token [lreplace [lindex $allTokens $idx] 1 1 $newTableName]
	set allTokens [lreplace $allTokens $idx $idx $token]
}
