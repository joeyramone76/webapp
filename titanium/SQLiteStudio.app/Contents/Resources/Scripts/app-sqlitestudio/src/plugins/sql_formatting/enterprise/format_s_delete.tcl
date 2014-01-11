use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatementDelete {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

body FormatStatementDelete::formatSql {} {
	set sql ""

	append sql [case "DELETE"]
	mark atDelete $sql
	mark afterDelete $sql +1

	append sql [logicalBlockIndent atDelete "FROM"]
	append sql [case "FROM"]
	append sql " "

	# Table name
	set table [getValue qualifiedTableName]
	set tableFmt [createFormatStatement $table]
	append sql [$tableFmt formatSql]

	# WHERE expr
	set where [getValue whereExpr]
	if {$where != ""} {
		set whereFmt [createFormatStatement $where]
		append sql [logicalBlockIndent atDelete "WHERE"]
		append sql "[case WHERE] [string trimleft [indentAllLinesToMark [$whereFmt formatSql] afterDelete]]"
	}

	# ORDER BY
	set orderByList [getListValue orderingTerms]
	if {[llength $orderByList] > 0} {
		append sql [logicalBlockIndent atDelete "ORDER"]
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

		append sql [logicalBlockIndent atDelete "LIMIT"]
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
