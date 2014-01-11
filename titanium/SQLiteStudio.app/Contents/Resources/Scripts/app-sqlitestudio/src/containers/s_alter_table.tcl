use src/parser/statement.tcl

class StatementAlterTable {
	inherit Statement

	public {
		variable databaseName ""
		variable realDatabaseName ""
		variable tableName ""
		variable newTableName ""
		variable renameKeyword 0
		variable addKeyword 0
		variable columnDefinition "" ;# object

		method afterParsing {} {
			set realDatabaseName [resolveDatabase $databaseName]
		}
	}
}
