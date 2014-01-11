use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatementAlterTable {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

body FormatStatementAlterTable::formatSql {} {
	set sql ""

	append sql [case "ALTER TABLE"]
	mark atTable $sql
	mark afterTable $sql +1
	append sql " "
	
	if {[get databaseName] != ""} {
		append sql [wrap [getValue databaseName]]
		append sql "[spaceBeforeDot].[spaceAfterDot]"
	}
	append sql [wrap [getValue tableName]]

	if {[get renameKeyword]} {
		# RENAME
		append sql [logicalBlockIndent atTable "RENAME TO"]
		append sql [case "RENAME TO "]
		append sql [wrap [getValue newTableName]]
	} else {
		# ADD COLUMN
		append sql [logicalBlockIndent atTable "ADD COLUMN"]
		append sql [case "ADD COLUMN "]
		
		set col [getValue columnDefinition]
		set colFmt [createFormatStatement $col]
		append sql [string trimleft [indentAllLinesToMark [$colFmt formatSql 0 0] afterTable]]
	}

	return $sql
}
