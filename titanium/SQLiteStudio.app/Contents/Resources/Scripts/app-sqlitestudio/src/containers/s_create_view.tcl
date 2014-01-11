use src/parser/statement.tcl

class StatementCreateView {
	inherit Statement

	public {
		variable temporary "" ;# TEMP or TEMPORARY or empty
		variable ifNotExists 0
		variable databaseName ""
		variable viewName ""
		variable realDatabaseName ""
		variable subSelect "" ;# object

		method afterParsing {} {
			set realDatabaseName [resolveDatabase $databaseName]
		}
	}
}

configbody StatementCreateView::subSelect {
	$subSelect configure -checkRecurentlyForContext true
}
