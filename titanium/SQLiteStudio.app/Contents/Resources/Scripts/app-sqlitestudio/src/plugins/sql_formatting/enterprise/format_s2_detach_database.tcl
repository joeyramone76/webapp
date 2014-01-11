use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatement2Detach {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

body FormatStatement2Detach::formatSql {} {
	set sql ""

	append sql [case "DETACH "]
	mark atAttach $sql -1
	if {[get databaseKeyword]} {
		append sql [case "DATABASE "]
	}

	append sql [wrap [getValue databaseName]]

	return $sql
}
