use src/parser/statement.tcl

class StatementDetach {
	inherit Statement

	public {
		variable databaseKeyword 0
		variable databaseName ""
		variable realDatabaseName ""

		method afterParsing {} {
			set realDatabaseName [resolveDatabase $databaseName]
		}

		method getDatabaseNames {}
	}
}

body StatementDetach::getDatabaseNames {} {
	if {$databaseName != ""} {
		return [list [getContextValue databaseName]]
	} else {
		return [list]
	}
}
