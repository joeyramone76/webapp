use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatementCreateVirtualTable {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}
	
	public {
		method formatSql {}
	}
}

class FormatStatementModuleArgument {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}
	
	public {
		method formatSql {}
	}
}

body FormatStatementCreateVirtualTable::formatSql {} {
	set sql ""

	# CREATE
	append sql [case "CREATE VIRTUAL TABLE "]

	# dbName.indexName
	if {[get databaseName] != ""} {
		append sql [wrap [getValue databaseName]]
		append sql "[spaceBeforeDot].[spaceAfterDot]"
	}
	append sql [wrap [getValue tableName]]

	# USING
	append sql [case " USING "]
	append sql [getValue moduleName]
	
	# Left parenthesis
	handleLeftParDef sql

	# Columns
	set colSqls [list]
	foreach arg [getListValue moduleArguments] {
		lappend argSqls [$arg toSqlWithoutComments]
	}
	append sql [joinList $argSqls $sql true]

	# Right parenthesis
	handleRightParDef sql

	return $sql
}

body FormatStatementModuleArgument::formatSql {} {
	set sql ""

	set sqls [list]
	foreach argWord [getListValue argumentWords] {
		lassign $argWord type value
		switch -- $type {
			"WORD" {
				lappend sqls [lindex $value 1]
			}
			"OBJECT" {
				set valueFmt [createFormatStatement $value]
				lappend sqls [$valueFmt formatSql]
			}
			default {
				error "Unsupported argument type while formatting CREATE VIRTUAL TABLE: $type"
			}
		}
	}
	append sql [join $sqls " "]

	return $sql
}
