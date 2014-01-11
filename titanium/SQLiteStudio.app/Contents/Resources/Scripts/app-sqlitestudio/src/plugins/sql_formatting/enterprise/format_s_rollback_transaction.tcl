use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatementRollback {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

body FormatStatementRollback::formatSql {} {
	set sql ""

	append sql [case "ROLLBACK "]
	mark atRollback $sql -1
	mark afterRollback $sql
	if {[get transactionKeyword]} {
		append sql [case "TRANSACTION "]
	}

	if {[get rollbackToSavepoint]} {
		append sql [logicalBlockIndent atRollback "TO"]
		append sql [case "TO "]
		if {[get savepointKeyword]} {
			append sql [case "SAVEPOINT "]
			append sql [wrap [getValue savepointName]]
		}
	}

	return $sql
}
