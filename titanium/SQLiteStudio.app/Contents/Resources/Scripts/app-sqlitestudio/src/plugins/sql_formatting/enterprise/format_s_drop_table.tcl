use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatementDropTable {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

body FormatStatementDropTable::formatSql {} {
	set sql ""

	append sql [case "DROP TABLE "]
	if {[get ifExists]} {
		append sql [case "IF EXISTS "]
	}
	if {[get databaseName] != ""} {
		append sql [wrap [getValue databaseName]]
		append sql "[spaceBeforeDot].[spaceAfterDot]"
	}
	append sql [wrap [getValue tableName]]

	return $sql
}

