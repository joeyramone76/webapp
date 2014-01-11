use src/parser/statement2.tcl

class Statement2DropTrigger {
	inherit Statement2

	public {
		variable databaseName ""
		variable realDatabaseName ""
		variable trigName ""

		method afterParsing {} {
			set realDatabaseName [resolveDatabase $databaseName]
		}
	}
}
