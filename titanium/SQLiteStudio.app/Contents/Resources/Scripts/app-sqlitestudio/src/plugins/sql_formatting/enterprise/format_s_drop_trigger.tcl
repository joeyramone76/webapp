use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatementDropTrigger {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

body FormatStatementDropTrigger::formatSql {} {
	set sql ""

	append sql [case "DROP TRIGGER "]
	if {[get ifExists]} {
		append sql [case "IF EXISTS "]
	}
	if {[get databaseName] != ""} {
		append sql [wrap [getValue databaseName]]
		append sql "[spaceBeforeDot].[spaceAfterDot]"
	}
	append sql [wrap [getValue trigName]]

	return $sql
}
