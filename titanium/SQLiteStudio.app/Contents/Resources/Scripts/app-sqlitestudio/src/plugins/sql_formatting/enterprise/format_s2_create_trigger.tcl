use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatement2CreateTrigger {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

body FormatStatement2CreateTrigger::formatSql {} {
	set sql ""

	mark beforeCreate $sql
	append sql [case "CREATE"]
	mark afterCreate $sql +1
	if {[get temporary] != ""} {
		append sql " [case [getValue temporary]]"
	}
	append sql [case " TRIGGER "]
	mark atTrig $sql -1
	mark afterTrig $sql
	append sql [wrap [getValue trigName]]

	# BEFORE DELETE ON table / ...
	append sql [logicalBlockIndent afterCreate ""]
	append sql [case [getValue afterBefore]]
	append sql " "
	append sql [case [getValue action]]
	
	if {[get ofKeyword]} {
		append sql " "
		append sql [case "OF"]
		append sql " "
		set colList [list]
		foreach colName [getListValue columnList] {
			lappend colList [wrap $colName]
		}
		append sql [join $colList "[spaceBeforeComma],[spaceAfterComma]"]
	}
	
	append sql " "
	append sql [case "ON"]
	append sql " "
	if {[get databaseName] != ""} {
		append sql [wrap [getValue databaseName]]
		append sql "[spaceBeforeDot].[spaceAfterDot]"
	}
	append sql [wrap [getValue tableName]]

	# FOR EACH ROW
	if {[get forEachRow]} {
		append sql [logicalBlockIndent afterCreate ""]
		append sql [case "FOR EACH ROW"]
	} elseif {[get forEachStatement]} {
		append sql [logicalBlockIndent afterCreate ""]
		append sql [case "FOR EACH STATEMENT"]
	}
	
	# WHEN expr
	if {[get whenExpr] != ""} {
		append sql [logicalBlockIndent afterCreate ""]
		append sql [case "WHEN "]

		set expr [getValue whenExpr]
		set exprFmt [createFormatStatement $expr]
		append sql [$exprFmt formatSql]
	}
	
	append sql [logicalBlockIndent beforeCreate ""]
	append sql [case "BEGIN"]
	append sql [logicalBlockIndent beforeCreate ""]
	
	set sqls [list]
	incrIndent
	foreach stmt [getListValue bodyStatements] {
		set stmtFmt [createFormatStatement $stmt]
		set stmtSql [indentAllLinesBy [$stmtFmt formatSql] $_indent]
		if {[cfg nl_never_before_semicolon]} {
			set stmtSql [string trimright $stmtSql]
		}
		lappend sqls $stmtSql
	}
	decrIndent

	set sep ";"
	if {[cfg nl_after_semicolon]} {
		append sep "\n\n"
	}
	append sql "[join $sqls $sep];"
	
	append sql [logicalBlockIndent beforeCreate ""]
	append sql [case "END"]
	
	return $sql
}
