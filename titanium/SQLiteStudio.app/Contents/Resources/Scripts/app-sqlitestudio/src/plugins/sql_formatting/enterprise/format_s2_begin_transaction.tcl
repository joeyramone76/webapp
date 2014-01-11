use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatement2BeginTransaction {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

body FormatStatement2BeginTransaction::formatSql {} {
	set sql ""

	append sql [case "BEGIN"]
	mark atBegin $sql
	mark afterBegin $sql +1
	if {[get transactionKeyword]} {
		append sql [case " TRANSACTION"]
	}
	append sql " "
	append sql [wrap [getValue transactionName]]
	if {[get onConflict] != ""} {
		set onConflict [getValue onConflict]
		set onConflictFmt [createFormatStatement $onConflict]
		append sql [logicalBlockIndent atBegin "ON"]
		append sql [$onConflictFmt formatSql]
	}

	return $sql
}




