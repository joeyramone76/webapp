use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatementBeginTransaction {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

body FormatStatementBeginTransaction::formatSql {} {
	set sql ""

	append sql [case "BEGIN"]
	if {[get type] != ""} {
		append sql " "
		append sql [case [getValue type]]
	}
	if {[get transactionKeyword]} {
		append sql [case " TRANSACTION"]
	}

	return $sql
}

