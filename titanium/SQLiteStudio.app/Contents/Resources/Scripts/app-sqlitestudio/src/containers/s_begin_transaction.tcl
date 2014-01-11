use src/parser/statement.tcl

class StatementBeginTransaction {
	inherit Statement

	public {
		variable type ""
		variable transactionKeyword 0
	}
}

