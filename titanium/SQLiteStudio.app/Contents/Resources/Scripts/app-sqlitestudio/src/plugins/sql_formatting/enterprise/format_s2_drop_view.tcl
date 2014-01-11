use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatement2DropView {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

body FormatStatement2DropView::formatSql {} {
	set sql ""

	append sql [case "DROP VIEW "]
	if {[get databaseName] != ""} {
		append sql [wrap [getValue databaseName]]
		append sql "[spaceBeforeDot].[spaceAfterDot]"
	}
	append sql [wrap [getValue viewName]]

	return $sql
}
