use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatement2Commit {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

body FormatStatement2Commit::formatSql {} {
	set sql ""

	append sql [case [getValue commitOrEnd]]
	if {[get transactionKeyword]} {
		append sql [case " TRANSACTION"]
	}
	append sql " "
	append sql [wrap [getValue name]]

	return $sql
}
