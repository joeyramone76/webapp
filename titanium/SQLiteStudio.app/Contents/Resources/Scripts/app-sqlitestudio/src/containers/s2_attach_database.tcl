use src/parser/statement2.tcl

class Statement2Attach {
	inherit Statement2

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

body Statement2Attach::getDatabaseNames {} {
	if {$databaseName != ""} {
		return [list [getContextValue databaseName]]
	} else {
		return [list]
	}
}
