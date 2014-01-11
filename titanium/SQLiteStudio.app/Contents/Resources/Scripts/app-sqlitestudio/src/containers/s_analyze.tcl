use src/parser/statement.tcl

class StatementAnalyze {
	inherit Statement

	public {
		variable databaseName ""
		variable realDatabaseName ""
		variable tableName ""
		variable tableOrDatabaseName ""

		method afterParsing {} {
			if {$databaseName != ""} {
				# In case of *.*
				set realDatabaseName [resolveDatabase $databaseName]
			} elseif {$tableOrDatabaseName != ""} {
				# In case of single word we need to check out if this is database or table
				set realDatabaseName [resolveDatabase $tableOrDatabaseName]
				if {$realDatabaseName != ""} {
					# Seems to be database
					set tableOrDatabaseName ""
				} else {
					# Not database, so it can be only table, but this has to be checked on higher level.
					set tableName $tableOrDatabaseName
				}
			}
		}
	}
}
