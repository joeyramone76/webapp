use src/parser/statement.tcl

class StatementAttach {
	inherit Statement

	public {
		variable databaseKeyword 0
		variable fileName ""
		variable databaseName ""
		variable realDatabaseName ""

		method afterParsing {} {
			set realDatabaseName [resolveDatabase $databaseName]
		}

		method getDatabaseNames {}
	}
}

body StatementAttach::getDatabaseNames {} {
	if {$databaseName != ""} {
		return [list [getContextValue databaseName]]
	} else {
		return [list]
	}
}
