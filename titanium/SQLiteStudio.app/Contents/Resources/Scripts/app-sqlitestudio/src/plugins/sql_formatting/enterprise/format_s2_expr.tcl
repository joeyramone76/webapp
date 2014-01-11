use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatement2Expr {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

class FormatStatement2ExprSuffix {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

class FormatStatement2ExprOnly {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

class FormatStatement2RaiseFunction {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

body FormatStatement2Expr::formatSql {} {
	set exprOnly [getValue exprOnly]
	set exprSuffixes [getListValue exprSuffixList]
	set exprOnlyFmt [createFormatStatement $exprOnly]
	
	set sql ""
	mark exprOnlyBegin $sql
	copyMarkTo $exprOnlyFmt exprOnlyBegin
	append sql [$exprOnlyFmt formatSql]
	foreach suffix $exprSuffixes {
		set suffixFmt [createFormatStatement $suffix]
		copyMarkTo $suffixFmt exprOnlyBegin
		append sql [$suffixFmt formatSql]
	}
	return $sql
}

body FormatStatement2ExprOnly::formatSql {} {
	set sql ""
	switch -- [get branchIndex] {
		0 {
			# Literal value
			if {[get literalValueKeyword] != ""} {
				append sql [case [get literalValueKeyword]]
			} else {
				append sql [getValue literalValue]
			}
		}
		1 {
			# Bind parameter
			append sql [getValue bindParameter]
		}
		2 {
			# db.table.column
			if {[get tableName] != ""} {
				if {[get databaseName] != ""} {
					append sql [wrap [getValue databaseName]]
					append sql "[spaceBeforeDot].[spaceAfterDot]"
				}
				append sql [wrap [getValue tableName]]
				append sql "[spaceBeforeDot].[spaceAfterDot]"
			}
			append sql [wrap [getValue columnName]]
		}
		3 {
			# unary-op expr
			append sql [case [getValue unaryOperator]]
			set expr [getValue expr1]
			set exprFmt [createFormatStatement $expr]
			append sql [$exprFmt formatSql]
		}
		5 {
			# function
			append sql [getValue functionName]
			set exprList [getListValue exprList]

			# Left par
			pushIndent
			set _indent 0
			handleLeftParExprFunc sql

			# Arguments
			if {[get star]} {
				if {[cfg nl_after_open_parenthesis_expr]} {
					append sql [indent]
				}
				append sql "*"
			} elseif {[llength $exprList] > 0} {
				set sqls [list]
				foreach expr $exprList {
					set exprFmt [createFormatStatement $expr]
					lappend sqls [$exprFmt formatSql]
				}

				# DISTINCT
				if {[get distinctKeyword] && [llength $sqls] > 0} {
					set firstSql [lindex $sqls 0]
					set firstSql "[case {DISTINCT }]$firstSql"
					if {[cfg nl_after_open_parenthesis_expr]} {
						set firstSql "[indent]$firstSql"
					}
					set sqls [lreplace $sqls 0 0 $firstSql]
				}
				
				if {[cfg nl_after_comma_in_func_args]} {
					set argsSql [joinList $sqls $sql true]
				} else {
					set argsSql [join $sqls "[spaceBeforeComma],[spaceAfterComma]"]
				}
				if {[cfg nl_after_open_parenthesis_expr]} {
					append sql $argsSql
				} else {
					append sql [string trimleft $argsSql]
				}
			}

			# Right par
			handleRightParExpr sql
			popIndent
		}
		6 {
			# ( expr )
			set expr [getValue expr1]
			set exprFmt [createFormatStatement $expr]
			handleSubStmt sql $exprFmt expr
		}
		7 {
			# cast (...)
			error "Unsupported branchIndex during formatting SQLite2 expr: 7"
		}
		14 {
			# (select)
			set subSelect [getValue subSelect]
			set subSelectFmt [createFormatStatement $subSelect]
			handleSubStmt sql $subSelectFmt def
		}
		15 {
			# case expr when ....
			append sql [case "CASE"]
			mark case $sql +1
			set expr [getValue expr1]
			if {$expr != ""} {
				set exprFmt [createFormatStatement $expr]
				set exprSql [$exprFmt formatSql]
				append sql "[spaceBeforeSql $exprSql]$exprSql[spaceAfterSql $exprSql]"
			}
			# WHEN THEN
			set whenExprList [getListValue whenExprList]
			set thenExprList [getListValue thenExprList]
			foreach whenExpr $whenExprList thenExpr $thenExprList {
				set whenExprFmt [createFormatStatement $whenExpr]
				set thenExprFmt [createFormatStatement $thenExpr]
				set whenSql [$whenExprFmt formatSql]
				set thenSql [$thenExprFmt formatSql]
				append sql [logicalBlockIndent case ""]
				append sql [case "WHEN"]
				append sql "[spaceBeforeSql $whenSql]$whenSql[spaceAfterSql $whenSql]"
				append sql [case "THEN"]
				append sql "[spaceBeforeSql $thenSql]$thenSql[spaceAfterSql $thenSql]"
			}
			# ELSE
			if {[get elseKeyword]} {
				set elseExpr [getValue expr2]
				set elseExprFmt [createFormatStatement $elseExpr]
				set elseSql [$elseExprFmt formatSql]
				append sql [logicalBlockIndent case ""]
				append sql [case "ELSE"]
				append sql "[spaceBeforeSql $elseSql]$elseSql[spaceAfterSql $elseSql]"
			}
			append sql [logicalBlockIndent exprOnlyBegin ""]
			append sql [case "END"]
		}
		16 {
			# raise function
			set raiseFunction [getValue raiseFunction]
			set fnFmt [createFormatStatement $raiseFunction]
			append sql [$fnFmt formatSql]
		}
	}
	return $sql
}

body FormatStatement2ExprSuffix::formatSql {} {
	upvar sql exprOnlySql
	set sql ""
	switch -- [get branchIndex] {
		4 {
			# expr bin-op expr
			set binOp [getValue binaryOperator]
			append sql [spaceAfterSql $exprOnlySql$sql [spaceBeforeMathOper]]
			set orAnd 0
			if {[get binOpWord]} {
				if {[string toupper $binOp] in [list "AND" "OR"]} {
					set orAnd 1
					append sql [logicalBlockIndent exprOnlyBegin ""]
					append sql $binOp
					append sql [logicalBlockIndent exprOnlyBegin ""]
				} else {
					append sql $binOp
				}
			} else {
				append sql [case $binOp]
			}
			set expr [getValue expr2]
			set exprFmt [createFormatStatement $expr]
			set exprSql [$exprFmt formatSql]
			if {!($orAnd && [nlAfterLogicalBlock])} {
				append sql [spaceBeforeSql $exprSql [spaceAfterMathOper]]
				append sql [spaceAfterSql $sql [spaceBeforeSql $exprSql]]
			}
 			mark afterOp "$exprOnlySql$sql"
			append sql [indentAllLinesToMarkForExpr $exprSql afterOp]
		}
		8 {
			# expr collate
			append sql [spaceAfterSql $exprOnlySql]
			append sql [case "COLLATE "]
			append sql [getValue collationName]
		}
		9 {
			# expr not (like/glob/...) expr
			if {[get notKeyword]} {
				append sql [spaceAfterSql $exprOnlySql]
				append sql [case "NOT "]
			} else {
				append sql [spaceAfterSql $exprOnlySql]
			}
			mark atOp "$exprOnlySql$sql"
			append sql [case [getValue binaryOperator]]

			set expr [getValue expr2]
			set exprFmt [createFormatStatement $expr]
			set exprSql [$exprFmt formatSql]
			append sql [indentAllLinesToMarkForExpr $exprSql atOp]

			# escape
			if {[get escapeKeyword]} {
				append sql [spaceAfterSql $sql]
				mark atOp "$exprOnlySql$sql"
				append sql [case "ESCAPE"]
				set expr [getValue expr3]
				set exprFmt [createFormatStatement $expr]
				set exprSql [$exprFmt formatSql]
				append sql [indentAllLinesToMarkForExpr $exprSql atOp]
			}
		}
		10 {
			# expr isnull/notnull
			append sql [spaceAfterSql $exprOnlySql]
			append sql [case [getValue nullDefinition]]
		}
		11 {
			# expr is (not) expr
			error "Unsupported branchIndex during formatting SQLite2 expr: 11"
		}
		12 {
			# expr not between expr and expr
			if {[get notKeyword]} {
				append sql [spaceAfterSql $exprOnlySql]
				append sql [case "NOT "]
			} else {
				append sql [spaceAfterSql $exprOnlySql]
			}
			mark atOp "$exprOnlySql$sql"
			append sql [case "BETWEEN "]

			set expr2 [getValue expr2]
			set expr2Fmt [createFormatStatement $expr2]
			set expr2Sql [$expr2Fmt formatSql]
			append sql [indentAllLinesToMarkForExpr $expr2Sql atOp]

			append sql [spaceAfterSql $sql]
			append sql [case "AND "]

			set expr3 [getValue expr3]
			set expr3Fmt [createFormatStatement $expr3]
			set expr3Sql [$expr3Fmt formatSql]
			append sql [indentAllLinesToMarkForExpr $expr3Sql atOp]
		}
		13 {
			# expr not in (select or table)
			if {[get notKeyword]} {
				append sql [spaceAfterSql $exprOnlySql]
				append sql [case "NOT "]
			} else {
				append sql [spaceAfterSql $exprOnlySql]
			}
			append sql [case "IN"]
			if {[get tableName] != ""} {
				# tableName
				append sql " "
				if {[get databaseName] != ""} {
					append sql [wrap [getValue databaseName]]
					append sql "[spaceBeforeDot].[spaceAfterDot]"
				}
				append sql [wrap [getValue tableName]]
			} elseif {[get subSelect] != ""} {
				# subselect
				set select [getValue subSelect]
				set selectFmt [createFormatStatement $select]
				handleSubStmt sql $selectFmt def
			} else {
				# expr
				set exprList [getListValue exprList]
				set exprFmts [list]
				foreach expr $exprList {
					lappend exprFmts [createFormatStatement $expr]
				}
				handleSubStmtList sql $exprFmts defFlat
			}
		}
	}
	return $sql
}

body FormatStatement2RaiseFunction::formatSql {} {
	set sql [case "RAISE"]
	handleLeftParExpr sql
	if {[get ignoreKeyword]} {
		append sql [case "IGNORE"]
	} else {
		if {[get rollbackKeyword]} {
			append sql [case "ROLLBACK"]
		} elseif {[get abortKeyword]} {
			append sql [case "ABORT"]
		} elseif {[get failKeyword]} {
			append sql [case "FAIL"]
		} else {
			error "No keyword for Raise function in expression for Enterprise formatter."
		}
		append sql "[spaceBeforeComma],[spaceAfterComma][getValue errorMessage]"
	}
	handleRightParExpr sql
	return $sql
}
