use src/parser/statement.tcl

class StatementDropTable {
	inherit Statement

	public {
		variable ifExists 0
		variable databaseName ""
		variable realDatabaseName ""
		variable tableName ""

		method afterParsing {} {
			set realDatabaseName [resolveDatabase $databaseName]
		}
	}
}
