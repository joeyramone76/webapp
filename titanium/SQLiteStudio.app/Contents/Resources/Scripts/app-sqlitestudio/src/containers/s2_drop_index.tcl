use src/parser/statement2.tcl

class Statement2DropIndex {
	inherit Statement2

	public {
		variable databaseName ""
		variable realDatabaseName ""
		variable indexName ""

		method afterParsing {} {
			set realDatabaseName [resolveDatabase $databaseName]
		}
	}
}
