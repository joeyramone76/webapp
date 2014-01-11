use src/parser/statement.tcl

class StatementCommit {
	inherit Statement

	public {
		variable commitOrEnd "" ;# COMMIT or END
		variable transactionKeyword 0
	}
}
