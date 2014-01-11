use src/parser/statement2.tcl

class Statement2Commit {
	inherit Statement2

	public {
		variable commitOrEnd "" ;# COMMIT or END
		variable transactionKeyword 0
		variable name ""
	}
}
