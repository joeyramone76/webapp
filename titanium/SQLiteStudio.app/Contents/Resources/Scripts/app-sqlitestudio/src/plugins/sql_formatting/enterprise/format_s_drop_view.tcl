use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatementDropView {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

body FormatStatementDropView::formatSql {} {
	set sql ""

	append sql [case "DROP VIEW "]
	if {[get ifExists]} {
		append sql [case "IF EXISTS "]
	}
	if {[get databaseName] != ""} {
		append sql [wrap [getValue databaseName]]
		append sql "[spaceBeforeDot].[spaceAfterDot]"
	}
	append sql [wrap [getValue viewName]]

	return $sql
}
