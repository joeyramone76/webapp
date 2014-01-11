use src/parser/statement2.tcl

class Statement2Detach {
	inherit Statement2

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

body Statement2Detach::getDatabaseNames {} {
	if {$databaseName != ""} {
		return [list [getContextValue databaseName]]
	} else {
		return [list]
	}
}
