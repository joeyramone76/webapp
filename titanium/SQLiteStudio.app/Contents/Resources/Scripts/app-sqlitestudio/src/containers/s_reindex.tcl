use src/parser/statement.tcl

class StatementReindex {
	inherit Statement

	public {
		variable databaseName ""
		variable realDatabaseName ""
		variable name "" ;# name of index, table, or collation. If database is given, then collation name doesn't apply here.

		method afterParsing {} {
			if {$databaseName != ""} {
				# In case of *.*
				set realDatabaseName [resolveDatabase $databaseName]
			}
		}
	}
}
