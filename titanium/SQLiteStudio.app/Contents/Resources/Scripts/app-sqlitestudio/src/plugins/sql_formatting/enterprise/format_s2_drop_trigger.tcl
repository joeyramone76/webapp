use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatement2DropTrigger {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

body FormatStatement2DropTrigger::formatSql {} {
	set sql ""

	append sql [case "DROP TRIGGER "]
	if {[get databaseName] != ""} {
		append sql [wrap [getValue databaseName]]
		append sql "[spaceBeforeDot].[spaceAfterDot]"
	}
	append sql [wrap [getValue trigName]]

	return $sql
}
