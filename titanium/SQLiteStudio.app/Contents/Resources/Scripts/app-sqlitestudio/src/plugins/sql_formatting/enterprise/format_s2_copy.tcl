use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatement2Copy {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

body FormatStatement2Copy::formatSql {} {
	set sql ""

	append sql [case "COPY"]
	mark atCopy $sql
	mark afterCopy $sql +1
	if {[get orKeyword]} {
		append sql [case " OR "]
		append sql [case [getValue orAction]]
	}

	append sql " "
	if {[get databaseName] != ""} {
		append sql [wrap [getValue databaseName]]
		append sql "[spaceBeforeDot].[spaceAfterDot]"
	}
	append sql [wrap [getValue tableName]]
	append sql [logicalBlockIndent afterCopy ""]
	append sql [case "FROM "]
	append sql [getValue fileName]

	if {[get usingDelimiter]} {
		append sql [logicalBlockIndent afterCopy ""]
		append sql [case "USING DELIMITERS "]
		append sql [getValue delimiter]
	}

	return $sql
}
