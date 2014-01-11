use src/parser/statement.tcl

class StatementPragma {
	inherit Statement

	public {
		variable databaseName ""
		variable realDatabaseName ""
		variable pragmaName ""
		variable pragmaValue "" ;# object
		variable equalOperator 0
		variable parenthesis 0

		method afterParsing {} {
			set realDatabaseName [resolveDatabase $databaseName]
		}
	}
}

class StatementPragmaValue {
	inherit Statement

	public {
		variable signedNumber "" ;# [-/+]number
		variable name "" ;# something or [something] or "something"
		variable stringLiteral "" ;# 'something'
	}
}


