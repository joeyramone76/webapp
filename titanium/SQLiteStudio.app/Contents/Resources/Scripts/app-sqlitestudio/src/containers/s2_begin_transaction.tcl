use src/parser/statement2.tcl

class Statement2BeginTransaction {
	inherit Statement2

	public {
		variable transactionKeyword 0
		variable transactionName ""
		variable onConflict "" ;# object
	}
}

