use src/parser/statement2.tcl

class Statement2Rollback {
	inherit Statement2

	public {
		variable transactionKeyword 0
		variable name ""
	}
}
