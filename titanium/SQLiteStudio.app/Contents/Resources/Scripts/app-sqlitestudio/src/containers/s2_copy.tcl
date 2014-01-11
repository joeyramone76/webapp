use src/parser/statement2.tcl

class Statement2Copy {
	inherit Statement2

	public {
		variable orKeyword 0
		variable orAction "" ;# ROLLBACK, ABORT, REPLACE, FAIL, or IGNORE
		variable databaseName ""
		variable tableName ""
		variable realDatabaseName ""
		variable fileName ""
		variable usingDelimiter 0
		variable delimiter ""

		method afterParsing {} {
			set realDatabaseName [resolveDatabase $databaseName]
		}
	}
}
