use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatementCommit {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

body FormatStatementCommit::formatSql {} {
	set sql ""

	append sql [case [getValue commitOrEnd]]
	if {[get transactionKeyword]} {
		append sql [case " TRANSACTION"]
	}

	return $sql
}
