use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatementRelease {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

body FormatStatementRelease::formatSql {} {
	set sql ""

	append sql [case "RELEASE "]
	if {[get savepointKeyword]} {
		append sql [case "SAVEPOINT "]
	}
	append sql [wrap [getValue name]]

	return $sql
}
