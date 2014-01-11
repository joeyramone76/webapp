use src/parser/statement2.tcl

class Statement2CreateView {
	inherit Statement2

	public {
		variable temporary "" ;# TEMP or TEMPORARY or empty
		variable viewName ""
		variable databaseName ""
		variable realDatabaseName ""
		variable subSelect "" ;# object

		method afterParsing {} {
			set realDatabaseName [resolveDatabase $databaseName]
		}
	}
}

configbody Statement2CreateView::subSelect {
	$subSelect configure -checkRecurentlyForContext true
}
