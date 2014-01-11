use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatement2Delete {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}
	
	public {
		method formatSql {}
	}
}

body FormatStatement2Delete::formatSql {} {
	set sql ""

	append sql [case "DELETE"]
	mark atDelete $sql
	mark afterDelete $sql +1

	append sql [logicalBlockIndent atDelete "FROM"]
	append sql [case "FROM"]
	append sql " "

	# Table name
	if {[get databaseName] != ""} {
		append sql [wrap [getValue databaseName]]
		append sql "[spaceBeforeDot].[spaceAfterDot]"
	}
	append sql [wrap [getValue tableName]]

	# WHERE expr
	set where [getValue whereExpr]
	if {$where != ""} {
		set whereFmt [createFormatStatement $where]
		append sql [logicalBlockIndent atDelete "WHERE"]
		append sql "[case WHERE] [string trimleft [indentAllLinesToMark [$whereFmt formatSql] afterDelete]]"
	}

	return $sql
}
