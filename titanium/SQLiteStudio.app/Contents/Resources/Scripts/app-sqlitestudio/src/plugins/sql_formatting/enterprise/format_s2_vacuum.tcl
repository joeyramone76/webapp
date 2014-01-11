use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatement2Vacuum {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

body FormatStatement2Vacuum::formatSql {} {
	set sql ""

	append sql [case "VACUUM"]

	return $sql
}
