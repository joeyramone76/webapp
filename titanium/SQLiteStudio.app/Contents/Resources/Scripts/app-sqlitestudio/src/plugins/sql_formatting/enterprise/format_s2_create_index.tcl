use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatement2CreateIndex {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

class FormatStatement2ColumnName {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {nameLength}
		method getNameLength {}
	}
}

body FormatStatement2CreateIndex::formatSql {} {
	# CREATE INDEX IF NOT EXISTS
	set sql [case "CREATE "]
	if {[get isUnique]} {
		append sql [case "UNIQUE "]
	}
	append sql [case "INDEX "]
	mark indexOrExists $sql -1

	# dbName.indexName
	append sql [wrap [getValue indexName]]

	# ON tableName
	append sql " "
	append sql [case "ON "]
	if {[get databaseName] != ""} {
		append sql [wrap [getValue databaseName]]
		append sql "[spaceBeforeDot].[spaceAfterDot]"
	}
	set tableName [wrap [getValue onTable]]
	append sql $tableName

	# Detecting lenghts of column names and types
	set longestName 0
	set longestCollation 0
	foreach colDef [getListValue indexColumns] {
		set fmtCol [createFormatStatement $colDef]
		# Name
		set lgt [$fmtCol getNameLength]
		if {$lgt > $longestName} {
			set longestName $lgt
		}
	}

	# Left parenthesis
	handleLeftParDef sql

	# Columns
	set colSqls [list]
	foreach col [getListValue indexColumns] {
		set fmtCol [createFormatStatement $col]
		lappend colSqls [$fmtCol formatSql $longestName]
	}
	append sql [indentAllLinesBy [joinList $colSqls $sql true] $_indent]

	# Right parenthesis
	handleRightParDef sql

	return $sql
}

body FormatStatement2ColumnName::formatSql {nameLength} {
	set sql [pad $nameLength { } [wrap [getValue columnName]]]
	if {[get order] != ""} {
		append sql " [case [getValue order]]"
	}
	return $sql
}

body FormatStatement2ColumnName::getNameLength {} {
	return [string length [wrap [getValue columnName]]]
}
