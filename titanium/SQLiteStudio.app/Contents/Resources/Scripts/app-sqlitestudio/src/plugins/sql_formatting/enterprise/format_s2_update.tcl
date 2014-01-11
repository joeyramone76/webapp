use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatement2Update {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

body FormatStatement2Update::formatSql {} {
	set sql ""

	# UPDATE OR ACTION
	append sql [case "UPDATE"]
	mark atUpdate $sql
	mark afterUpdate $sql +1
	if {[get orAction] != ""} {
		append sql " "
		append sql [case "OR"]
		append sql " "
		append sql [case [getValue orAction]]
	}

	# Table name
	append sql " "
	if {[get databaseName] != ""} {
		append sql [wrap [getValue databaseName]]
		append sql "[spaceBeforeDot].[spaceAfterDot]"
	}
	append sql [getValue tableName]

	# SET
	append sql [logicalBlockIndent atUpdate "SET"]
	append sql [case "SET"]

	# List of assignments
	set sqls [list]
	foreach colName [getListValue columnNames] valExpr [getListValue columnValues] {
		set exprFmt [createFormatStatement $valExpr]
		set exprSql [$exprFmt formatSql]

		set colSql [wrap $colName]
		append colSql [spaceBeforeMathOper]
		append colSql "="
		append colSql [spaceBeforeSql $exprSql [spaceAfterMathOper]]
		append colSql $exprSql
		set colSql [indentAllLinesToMark $colSql afterUpdate]
		lappend sqls $colSql
	}
	set assignSql [joinList $sqls $sql]
	append sql " "
	append sql $assignSql

	# WHERE expr
	set where [getValue whereExpr]
	if {$where != ""} {
		set whereFmt [createFormatStatement $where]
		append sql [logicalBlockIndent atUpdate "WHERE"]
		append sql "[case WHERE] [string trimleft [indentAllLinesToMark [$whereFmt formatSql] afterUpdate]]"
	}

	return $sql
}
