use src/parser/statement.tcl

class StatementCreateVirtualTable {
	inherit Statement

	public {
		variable databaseName ""
		variable realDatabaseName ""
		variable tableName ""
		variable moduleName ""
		variable moduleArguments [list] ;# list of objects

		method addModuleArgument {arg} {lappend moduleArguments $arg}
		method afterParsing {} {
			set realDatabaseName [resolveDatabase $databaseName]
		}
	}
}

class StatementModuleArgument {
	inherit Statement

	public {
		variable argumentWords [list] ;# list of words and objects as pairs {WORD|OBJECT value}
		variable allSubObjects [list] ;# list of objects

		method addArgumentWord {word} {lappend argumentWords [list WORD $word]}
		method addArgumentObject {obj} {
			lappend argumentWords [list OBJECT $obj]
			lappend allSubObjects $obj
		}
	}
}
