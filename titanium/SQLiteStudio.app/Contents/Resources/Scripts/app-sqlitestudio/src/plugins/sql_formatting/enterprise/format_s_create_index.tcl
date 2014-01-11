use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatementCreateIndex {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

class FormatStatementIndexedColumn {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {{nameLength ""} {collationLength ""}}
		method getNameLength {}
		method getCollationLength {}
	}
}

body FormatStatementCreateIndex::formatSql {} {
	# CREATE INDEX IF NOT EXISTS
	set sql [case "CREATE "]
	if {[get isUnique]} {
		append sql [case "UNIQUE "]
	}
	append sql [case "INDEX "]
	mark indexOrExists $sql -1
	if {[get ifNotExists]} {
		append sql [case "IF NOT EXISTS "]
		mark indexOrExists $sql -1
	}

	# dbName.indexName
	if {[get databaseName] != ""} {
		append sql [wrap [getValue databaseName]]
		append sql "[spaceBeforeDot].[spaceAfterDot]"
	}
	append sql [wrap [getValue indexName]]

	# ON tableName
	append sql " "
	append sql [case "ON "]
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

		# Collation
		set lgt [$fmtCol getCollationLength]
		if {$lgt > $longestCollation} {
			set longestCollation $lgt
		}
	}

	# Left parenthesis
	handleLeftParDef sql

	# Columns
	set colSqls [list]
	foreach col [getListValue indexColumns] {
		set fmtCol [createFormatStatement $col]
		lappend colSqls [$fmtCol formatSql $longestName $longestCollation]
	}
	append sql [indentAllLinesBy [joinList $colSqls $sql true] $_indent]

	# Right parenthesis
	handleRightParDef sql

	return $sql
}

body FormatStatementIndexedColumn::formatSql {{nameLength ""} {collationLength ""}} {
	if {$nameLength != ""} {
		set sql [pad $nameLength { } [wrap [getValue columnName]]]
	} else {
		set sql [wrap [getValue columnName]]
	}
	if {$collationLength != ""} {
		if {[get collation]} {
			append sql " [case COLLATE] [pad $collationLength { } [getValue collationName]]"
		} elseif {$collationLength > 0} {
			append sql "         [pad $collationLength { } {}]"
		}
	} else {
		if {[get collation]} {
			append sql " [case COLLATE] [getValue collationName]"
		}
	}

	if {[get order] != ""} {
		append sql " [case [getValue order]]"
	}
	return $sql
}

body FormatStatementIndexedColumn::getNameLength {} {
	return [string length [wrap [getValue columnName]]]
}

body FormatStatementIndexedColumn::getCollationLength {} {
	if {[get collation]} {
		return [string length [getValue collationName]]
	} else {
		return 0
	}
}
