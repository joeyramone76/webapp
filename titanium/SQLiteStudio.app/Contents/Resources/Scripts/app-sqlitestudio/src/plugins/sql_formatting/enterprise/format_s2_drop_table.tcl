use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatement2DropTable {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

body FormatStatement2DropTable::formatSql {} {
	set sql ""

	append sql [case "DROP TABLE "]
	if {[get databaseName] != ""} {
		append sql [wrap [getValue databaseName]]
		append sql "[spaceBeforeDot].[spaceAfterDot]"
	}
	append sql [wrap [getValue tableName]]

	return $sql
}

