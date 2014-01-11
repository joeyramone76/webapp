use src/parser/statement.tcl

class StatementDelete {
	inherit Statement

	public {
		variable qualifiedTableName "" ;# object
		variable whereExpr "" ;# object

		# Variables below are optional syntax of sqlite3, disabled by default
		variable orderByKeyword 0
		variable orderingTerms [list] ;# list of objects
		variable limitKeyword 0
		variable offsetKeyword 0 ;# 1 for OFFSET, 2 for ","
		variable limit ""
		variable offset ""

		method getColumnNames {}
		method addOrderingTerm {val} {lappend orderingTerms $val}
	}
}

body StatementDelete::getColumnNames {} {
	set resultList [list]
	lappend resultList [dict create column [getContextValue whereExpr] type OBJECT]
	return $resultList
}
