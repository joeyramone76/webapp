use src/parser/statement2.tcl

class Statement2Expr {
	inherit Statement2

	public {
		variable exprOnly "" ;# object
		variable exprSuffixList [list] ;# list of objects

		method addExprSuffix {obj} {set exprSuffixList [linsert $exprSuffixList 0 $obj]}
		method getBranchIndex {}
	}
}

body Statement2Expr::getBranchIndex {} {
	$exprOnly cget -branchIndex
}

class Statement2ExprSuffix {
	inherit Statement

	public {
		variable binaryOperator ""
		variable expr1 "" ;# object
		variable expr2 "" ;# object
		variable expr3 "" ;# object
		variable nullDefinition "" ;# ISNULL, NOTNULL, IS NULL, NOT NULL, or IS NOT NULL.
		variable inKeyword 0
		variable subSelect "" ;# object
		variable exprList [list] ;# list of objects
		variable betweenKeyword 0
		variable escapeKeyword 0
		variable notKeyword 0
		variable andKeyword 0
		variable collateKeyword 0
		variable collationName ""
		variable branchIndex -1 ;# 0-based index of matched branch in SQLite documentation syntax diagram
		variable binOpWord 0 ;# 1 if binaryOperator is alpha-WORD, instead of strict operator, like ==, or >
		variable databaseName ""
		variable realDatabaseName ""
		variable tableName ""

		method addExpr {e} {lappend exprList $e}
		method getAllTableNames {}
		method afterParsing {} {
			set realDatabaseName [resolveDatabase $databaseName]
		}
	}
}

class Statement2ExprOnly {
	inherit Statement

	public {
		variable branchIndex -1 ;# 0-based index of matched branch in SQLite documentation syntax diagram
		variable literalValue ""
		variable literalValueKeyword ""
		variable bindParameter ""
		variable databaseName ""
		variable realDatabaseName ""
		variable tableName ""
		variable subSelect "" ;# object
		variable columnName ""
		variable unaryOperator ""
		variable expr1 "" ;# object
		variable expr2 "" ;# object
		variable expr3 "" ;# object
		variable functionName ""
		variable star 0
		variable distinctKeyword 0
		variable exprList [list] ;# list of objects
		variable asKeyword 0
		variable typeName ""
		variable castKeyword 0
		variable notKeyword 0
		variable andKeyword 0
		variable existsKeyword 0
		variable caseKeyword 0
		variable whenExprList [list] ;# list of objects
		variable thenExprList [list] ;# list of objects
		variable elseKeyword 0
		variable endKeyword 0
		variable raiseFunction "" ;# object

		method addExpr {e} {lappend exprList $e}
		method addWhenExpr {e} {lappend whenExprList $e}
		method addThenExpr {e} {lappend thenExprList $e}
		method addWhen {str} {lappend whenList $str}
		method addThen {str} {lappend thenList $str}
		method appendLiteralValue {str}
		method getFunctions {}
		method getDatabaseNames {}
		method getAllTableNames {}
		method afterParsing {} {
			set realDatabaseName [resolveDatabase $databaseName]
		}
	}
}

body Statement2ExprOnly::getDatabaseNames {} {
	if {$databaseName != ""} {
		return [list [dict create database [getContextValue databaseName] realname $realDatabaseName]]
	} else {
		return [list]
	}
}

body Statement2ExprOnly::appendLiteralValue {str} {
	if {$literalValue != ""} {
		set tokenValue [lindex $literalValue 1]
		append tokenValue [lindex $str 1]
		set literalValue [list [lindex $str 0] $tokenValue [lindex $literalValue 2] [lindex $str 3]]
	} else {
		append literalValue $str
	}
}

class Statement2RaiseFunction {
	inherit Statement

	public {
		variable raiseKeyword 0
		variable ignoreKeyword 0
		variable rollbackKeyword 0
		variable abortKeyword 0
		variable failKeyword 0
		variable errorMessage ""
	}
}

body Statement2ExprOnly::getFunctions {} {
	if {$functionName == ""} {
		return [list]
	}
	set args [list]
	if {![getValue star]} {
		set exprs [getListValue exprList]
		foreach expr $exprs {
			lappend args [$expr toSql]
		}
	} else {
		lappend args "*"
	}
	set funcList [list [list [getValue functionName] $args]]
	return $funcList
}

body Statement2ExprOnly::getAllTableNames {} {
	if {$tableName != ""} {
		set res [dict create]
		dict set res table [getContextValue tableName]
		if {$databaseName != ""} {
			dict set res database [getContextValue databaseName]
		}
		return [list $res]
	}
	return [list]
}

body Statement2ExprSuffix::getAllTableNames {} {
	if {$tableName != ""} {
		set res [dict create]
		dict set res table [getContextValue tableName]
		if {$databaseName != ""} {
			dict set res database [getContextValue databaseName]
		}
		return [list $res]
	}
	return [list]
}
