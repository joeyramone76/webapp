use src/plugins/sql_formatting/enterprise/format_comments.tcl

class FormatStatementSql {
	inherit FormatComments

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

body FormatStatementSql::formatSql {} {
	if {[get subStatement] == ""} {
		return "" ;# only comments in this statement
	}

	# Creating substatement object
	set subStatement [createFormat subStatement]

	# Creating output sql
	set sqls [list]

	# EXPLAIN
	if {[get explainKeyword]} {
		lappend sqls "EXPLAIN"
	}

	# QUERY PLAN
	if {[get queryPlanKeywords]} {
		lappend sqls "QUERY PLAN"
	}

	# SubStatement
	lappend sqls [$subStatement formatSql]

	set sql [join $sqls " "]
	set sql [applyNeverBeforeSemicolon $sql]
	
	return $sql
}
