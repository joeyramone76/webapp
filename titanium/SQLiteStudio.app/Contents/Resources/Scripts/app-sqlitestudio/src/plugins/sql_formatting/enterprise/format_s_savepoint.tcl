use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatementSavepoint {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

body FormatStatementSavepoint::formatSql {} {
	set sql ""

	append sql [case "SAVEPOINT "]
	append sql [wrap [getValue name]]

	return $sql
}
