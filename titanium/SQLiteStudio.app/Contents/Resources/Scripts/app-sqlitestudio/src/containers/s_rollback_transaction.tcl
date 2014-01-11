use src/parser/statement.tcl

class StatementRollback {
	inherit Statement

	public {
		variable transactionKeyword 0
		variable savepointKeyword 0
		variable savepointName ""
		variable rollbackToSavepoint 0
	}
}
