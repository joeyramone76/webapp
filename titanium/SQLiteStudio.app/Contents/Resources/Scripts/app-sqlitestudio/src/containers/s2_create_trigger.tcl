use src/parser/statement2.tcl

class Statement2CreateTrigger {
	inherit Statement2

	public {
		variable temporary "" ;# TEMP or TEMPORARY or empty
		variable databaseName ""
		variable trigName ""
		variable realDatabaseName ""
		variable afterBefore "" ;# AFTER, BEFORE, or INSTEAD OF
		variable action "" ;# UPDATE, DELETE, INSERT
		variable ofKeyword 0
		variable columnList [list] ;# list of objects
		variable tableName ""
		variable forEachRow 0
		variable forEachStatement 0
		variable whenExpr "" ;# object
		variable bodyStatements [list] ;# list of objects

		method addColumn {col} {lappend columnList $col}
		method addBodyStatement {stmt} {lappend bodyStatements $stmt}
		method afterParsing {} {
			set realDatabaseName [resolveDatabase $databaseName]
		}
		method replaceTableToken {newTableName}
	}
}

body Statement2CreateTrigger::replaceTableToken {newTableName} {
	set idx [lsearch -exact $allTokens $tableName]
	if {$idx == -1} {
		debug "Could not find table token to replace by replaceTableToken.\nAll tokens: $allTokens\nTable token: $tableName"
		return
	}
	set token [lreplace [lindex $allTokens $idx] 1 1 $newTableName]
	set allTokens [lreplace $allTokens $idx $idx $token]
}
