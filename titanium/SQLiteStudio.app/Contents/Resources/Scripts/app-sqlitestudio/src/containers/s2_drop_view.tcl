use src/parser/statement2.tcl

class Statement2DropView {
	inherit Statement2

	public {
		variable databaseName ""
		variable realDatabaseName ""
		variable viewName ""

		method afterParsing {} {
			set realDatabaseName [resolveDatabase $databaseName]
		}
	}
}
