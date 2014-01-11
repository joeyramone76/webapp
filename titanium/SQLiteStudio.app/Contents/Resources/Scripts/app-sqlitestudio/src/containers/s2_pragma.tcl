use src/parser/statement2.tcl

class Statement2Pragma {
	inherit Statement2

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

class Statement2PragmaValue {
	inherit Statement

	public {
		variable signedNumber "" ;# [-/+]number
		variable name "" ;# something or [something] or "something"
		variable stringLiteral "" ;# 'something'
	}
}


