use src/parser/statement.tcl

class StatementDropTrigger {
	inherit Statement

	public {
		variable ifExists 0
		variable databaseName ""
		variable realDatabaseName ""
		variable trigName ""

		method afterParsing {} {
			set realDatabaseName [resolveDatabase $databaseName]
		}
	}
}
