use src/parser/statement.tcl

class StatementRelease {
	inherit Statement

	public {
		variable savepointKeyword 0
		variable name ""
	}
}
