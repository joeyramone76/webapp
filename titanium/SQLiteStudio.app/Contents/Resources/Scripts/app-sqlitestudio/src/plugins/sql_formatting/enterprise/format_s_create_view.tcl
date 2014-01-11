use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatementCreateView {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

body FormatStatementCreateView::formatSql {} {
	set sql ""

	mark beforeCreate $sql
	append sql [case "CREATE"]
	mark afterCreate $sql +1
	if {[get temporary] != ""} {
		append sql " [case [getValue temporary]]"
	}
	append sql [case " VIEW "]
	if {[get ifNotExists]} {
		append sql [case "IF NOT EXISTS "]
	}
	if {[get databaseName] != ""} {
		append sql [wrap [getValue databaseName]]
		append sql "[spaceBeforeDot].[spaceAfterDot]"
	}
	append sql [wrap [getValue viewName]]
	append sql [case " AS"]

	append sql [logicalBlockIndent afterCreate ""]
	
	# SubSelect
	set subSelect [getValue subSelect]
	set subSelectFmt [createFormatStatement $subSelect]
	set subSelectSql [$subSelectFmt formatSql]
	set subSelectSql [indentAllLinesToMark $subSelectSql afterCreate]
	append sql [string trimleft $subSelectSql]

	return $sql
}
