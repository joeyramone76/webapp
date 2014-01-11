use src/parser/statement.tcl

class StatementDropIndex {
	inherit Statement

	public {
		variable ifExists 0
		variable databaseName ""
		variable realDatabaseName ""
		variable indexName ""

		method afterParsing {} {
			set realDatabaseName [resolveDatabase $databaseName]
		}
	}
}
