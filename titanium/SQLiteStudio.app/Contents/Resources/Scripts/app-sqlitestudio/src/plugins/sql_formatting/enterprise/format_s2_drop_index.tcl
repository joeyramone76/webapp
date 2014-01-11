use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatement2DropIndex {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

body FormatStatement2DropIndex::formatSql {} {
	set sql ""

	append sql [case "DROP INDEX "]
	if {[get databaseName] != ""} {
		append sql [wrap [getValue databaseName]]
		append sql "[spaceBeforeDot].[spaceAfterDot]"
	}
	append sql [wrap [getValue indexName]]

	return $sql
}
