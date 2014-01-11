use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatementAttach {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

body FormatStatementAttach::formatSql {} {
	set sql ""

	append sql [case "ATTACH "]
	mark atAttach $sql -1
	if {[get databaseKeyword]} {
		append sql [case "DATABASE "]
	}

	append sql [getValue fileName]

	append sql [logicalBlockIndent atAttach "AS"]
	append sql [case "AS "]
	append sql [wrap [getValue databaseName]]

	return $sql
}

