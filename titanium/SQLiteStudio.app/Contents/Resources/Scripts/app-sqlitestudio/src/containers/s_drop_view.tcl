use src/parser/statement.tcl

class StatementDropView {
	inherit Statement

	public {
		variable ifExists 0
		variable databaseName ""
		variable realDatabaseName ""
		variable viewName ""

		method afterParsing {} {
			set realDatabaseName [resolveDatabase $databaseName]
		}
	}
}
