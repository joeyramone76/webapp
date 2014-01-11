use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatementUpdate {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

class FormatStatementQualifiedTableName {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

body FormatStatementUpdate::formatSql {} {
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
	set table [getValue qualifiedTableName]
	set tableFmt [createFormatStatement $table]
	append sql [$tableFmt formatSql]

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

	# ORDER BY
	set orderByList [getListValue orderingTerms]
	if {[llength $orderByList] > 0} {
		append sql [logicalBlockIndent atUpdate "ORDER"]
		append sql [case "ORDER BY "]
		set orderSqls [list]
		foreach orderBy $orderByList {
			set orderByStmt [createFormatStatement $orderBy]
			lappend orderSqls [$orderByStmt formatSql]
		}
		append sql [joinList $orderSqls $sql]
	}

	# LIMIT
	set limit [getValue limit]
	if {$limit != ""} {
		set limitFmt [createFormatStatement $limit]
		set limitSql [$limitFmt formatSql]

		append sql [logicalBlockIndent atUpdate "LIMIT"]
		append sql "[case LIMIT] $limitSql"
		set offset [getValue offset]
		if {$offset != ""} {
			set offsetFmt [createFormatStatement $offset]
			set offsetSql [$offsetFmt formatSql]
			switch -- [get offsetKeyword] {
				1 {
					append sql " [case OFFSET] $offsetSql"
				}
				2 {
					append sql "[spaceBeforeComma],[spaceAfterComma]$offsetSql"
				}
			}
		}
	}

	return $sql
}

body FormatStatementQualifiedTableName::formatSql {} {
	set sql ""

	if {[get databaseName] != ""} {
		append sql [wrap [getValue databaseName]]
		append sql "[spaceBeforeDot].[spaceAfterDot]"
	}
	append sql [wrap [getValue tableName]]

	if {[get indexedKeyword]} {
		if {[get notKeyword]} {
			# NOT INDEXED
			append sql " "
			append sql [case "NOT INDEXED"]
		} else {
			# INDEXED BY indexName
			append sql " "
			append sql [case "INDEXED BY"]
			append sql " "
			append sql [wrap [getValue indexName]]
		}
	}

	return $sql
}
