use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatementReindex {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}


body FormatStatementReindex::formatSql {} {
	set sql ""

	append sql [case "REINDEX "]
	if {[get databaseName] != ""} {
		append sql [wrap [getValue databaseName]]
		append sql "[spaceBeforeDot].[spaceAfterDot]"
	}
	append sql [wrap [getValue name]]

	return $sql
}
