use src/plugins/sql_formatting/enterprise/format_comments.tcl

class FormatStatement2Sql {
	inherit FormatComments

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

body FormatStatement2Sql::formatSql {} {
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

	# SubStatement
	lappend sqls [$subStatement formatSql]

	set sql [join $sqls " "]
	set sql [applyNeverBeforeSemicolon $sql]
	return $sql
}
