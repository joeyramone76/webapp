use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatementVacuum {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

body FormatStatementVacuum::formatSql {} {
	set sql ""

	append sql [case "VACUUM"]

	return $sql
}
