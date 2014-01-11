use src/parser/statement2.tcl

class Statement2CreateIndex {
	inherit Statement2

	public {
		variable isUnique 0
		variable databaseName ""
		variable realDatabaseName ""
		variable indexName ""
		variable onTable ""
		variable indexColumns [list] ;# list of objects
		variable onConflict "" ;# object

		method addIndexColumn {obj}

		method replaceTableToken {newTableName}
		method getTableNames {}
		method afterParsing {} {
			set realDatabaseName [resolveDatabase $databaseName]
		}
	}
}

class Statement2ColumnName {
	inherit Statement

	public {
		variable columnName ""
		variable order "" ;# ASC or DESC or empty
	}
}

body Statement2CreateIndex::getTableNames {} {
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

body Statement2CreateIndex::addIndexColumn {obj} {
	lappend indexColumns $obj
}

body Statement2CreateIndex::replaceTableToken {newTableName} {
	set idx [lsearch -exact $allTokens $onTable]
	if {$idx == -1} {
		debug "Could not find table token to replace by replaceTableToken.\nAll tokens: $allTokens\nTable token: $onTable"
		return
	}
	set token [lreplace [lindex $allTokens $idx] 1 1 $newTableName]
	set allTokens [lreplace $allTokens $idx $idx $token]
}
