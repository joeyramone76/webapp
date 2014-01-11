use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatementAnalyze {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

body FormatStatementAnalyze::formatSql {} {
	set sql ""

	append sql [case "ANALYZE "]
	
	if {[get databaseName] != ""} {
		append sql [wrap [getValue databaseName]]
		append sql "[spaceBeforeDot].[spaceAfterDot]"
		append sql [wrap [getValue tableName]]
	} else {
		append sql [wrap [getValue tableOrDatabaseName]]
	}

	return $sql
}

