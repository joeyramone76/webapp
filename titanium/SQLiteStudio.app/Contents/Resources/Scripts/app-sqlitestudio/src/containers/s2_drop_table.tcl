use src/parser/statement2.tcl

class Statement2DropTable {
	inherit Statement2

	public {
		variable databaseName ""
		variable realDatabaseName ""
		variable tableName ""

		method afterParsing {} {
			set realDatabaseName [resolveDatabase $databaseName]
		}
	}
}
