use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatement2CreateTable {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

class FormatStatement2ColumnDef {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {longestName longestType}
		method getNameLength {}
		method getTypeLength {}
	}
}

class FormatStatement2TypeName {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

class FormatStatement2ColumnConstraint {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	private {
		method formatConflictSql {}
	}

	public {
		method formatSql {}
	}
}

class FormatStatement2TableConstraint {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	private {
		method formatConflictSql {}
	}

	public {
		method formatSql {}
	}
}

class FormatStatement2ConflictClause {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

body FormatStatement2CreateTable::formatSql {} {
	set sql [case "CREATE"]
	if {[get temporary] != ""} {
		append sql " [case [getValue temporary]]"
	}
	append sql [case " TABLE "]
	mark atTable $sql -1
	mark afterTable $sql
	append sql [wrap [getValue tableName]]

	if {[get asKeyword]} {
		# AS subselect
		append sql [logicalBlockIndent atTable "AS"]
		append sql [case "AS "]
		set subSelect [getValue subSelect]
		set subSelectFmt [createFormatStatement $subSelect]
		append sql [string trimleft [indentAllLinesToMark [$subSelectFmt formatSql] afterTable]]
	} else {
		# Columns and constraints
		set sqls [list]

		# Detecting lenghts of column names and types
		set longestName 0
		set longestType 0
		foreach colDef [getListValue columnDefs] {
			set fmtCol [createFormatStatement $colDef]
			# Name
			set lgt [$fmtCol getNameLength]
			if {$lgt > $longestName} {
				set longestName $lgt
			}

			# Type
			set lgt [$fmtCol getTypeLength]
			if {$lgt > $longestType} {
				set longestType $lgt
			}
		}

		# Left par
		handleLeftParDef sql

		# Columns
		foreach colDef [getListValue columnDefs] {
			set fmtCol [createFormatStatement $colDef]
			lappend sqls [$fmtCol formatSql $longestName $longestType]
		}

		# Constraints
		foreach constrDef [getListValue tableConstraints] {
			set fmtConstr [createFormatStatement $constrDef]
			lappend sqls [string trimleft [indentAllLinesBy [$fmtConstr formatSql] $_indent]]
		}

		# Getting all togather
		append sql [indentAllLinesBy [joinList $sqls $sql true] $_indent]

		# Right par
		handleRightParDef sql
	}
	return $sql
}

body FormatStatement2ColumnDef::formatSql {longestName longestType} {
	set sql ""

	# Column name
	append sql [pad $longestName { } [wrap [getValue columnName]]]
	append sql " "
	mark afterColumnName $sql

	# Type name
	if {[get typeName] != ""} {
		set type [getValue typeName]
		set typeFmt [createFormatStatement $type]
		set typeName [$typeFmt formatSql]
		if {[cfg nam_uppercase_datatype_names]} {
			set typeName [string toupper $typeName]
		} else {
			set typeName [string tolower $typeName]
		}

		append sql [pad $longestType { } $typeName]
	} else {
		append sql [pad $longestType { } {}]
	}
	mark afterColumnType $sql +1

	# Constraints
	set constrSql ""
	mark constrBegin $constrSql
	foreach constrDef [lsort [getListValue columnConstraints]] {
		set fmtConstr [createFormatStatement $constrDef]
		append constrSql [logicalBlockIndent constrBegin ""]
		append constrSql [string trimleft [$fmtConstr formatSql]]
	}
	if {$constrSql != ""} {
		append sql " "
		append sql [string trimleft [indentAllLinesToMark $constrSql afterColumnType]]
	}

	return $sql
}

body FormatStatement2ColumnDef::getNameLength {} {
	return [string length [wrap [getValue columnName]]]
}

body FormatStatement2ColumnDef::getTypeLength {} {
	if {[get typeName] != ""} {
		set type [getValue typeName]
		set typeFmt [createFormatStatement $type]
		set typeName [$typeFmt formatSql]

		return [string length $typeName]
	} else {
		return 0
	}
}

body FormatStatement2TypeName::formatSql {} {
	set sql [join [getListValue name] " "]
	if {[get size] != "" || [get precision] != ""} {
		set sizes [list]
		if {[get size] != ""} {
			lappend sizes [getValue size]
		}
		if {[get precision] != ""} {
			lappend sizes [getValue precision]
		}
		set sep "[spaceBeforeComma],[spaceAfterComma]"
		handleLeftParExprFunc sql
		append sql [join $sizes $sep]
		handleRightParExpr sql
	}
	return $sql
}

body FormatStatement2ColumnConstraint::formatSql {} {
	set sql ""

	if {[get namedConstraint]} {
		append sql [case "CONSTRAINT "]
		append sql [getValue constraintName]
		append sql " "
	}

	switch -- [get branchIndex] {
		0 {
			# PK
			append sql [case "PRIMARY KEY"]
			if {[get order] != ""} {
				append sql " "
				append sql [case [getValue order]]
			}
			formatConflictSql
		}
		1 {
			# NOT NULL
			if {[getValue notKeyword]} {
				append sql [case "NOT NULL"]
			} else {
				append sql [case "NULL"]
			}
			formatConflictSql
		}
		2 {
			# UNIQUE
			append sql [case "UNIQUE"]
			formatConflictSql
		}
		3 {
			# CHECK
			append sql [case "CHECK"]
			set expr [getValue expr]
			set exprFmt [createFormatStatement $expr]
			handleSubStmt sql $exprFmt expr
			formatConflictSql
		}
		4 {
			# DEFAULT
			append sql [case "DEFAULT"]
			append sql " "
			set value [getValue literalValue]
			if {[string toupper $value] == "NULL"} {
				append sql [case $value]
			} else {
				append sql $value
			}
		}
		5 {
			# Ignored for sqlite2
		}
		6 {
			# Ignored for sqlite2
		}
		default {
			error "Unsupported branchIndex in Statement2ColumnConstraint: [get branchIndex]"
		}
	}

	return $sql
}

body FormatStatement2ColumnConstraint::formatConflictSql {} {
	upvar sql sql
	if {[get conflictClause] != ""} {
		append sql " "
		set fmtConflict [createFormatStatement [getValue conflictClause]]
		append sql [$fmtConflict formatSql]
	}
}

body FormatStatement2TableConstraint::formatSql {} {
	set sql ""

	if {[get namedConstraint]} {
		append sql [case "CONSTRAINT "]
		append sql [getValue constraintName]
		append sql " "
	}

	switch -- [get branchIndex] {
		0 {
			# PK
			append sql [case "PRIMARY KEY"]

			handleLeftParDefFlat sql
			set sqls [list]
			foreach col [getListValue columnNames] {
				lappend sqls $col
			}
			append sql [join $sqls "[spaceBeforeComma],[spaceAfterComma]"]
			handleRightParDefFlat sql

			formatConflictSql
		}
		1 {
			# UNIQUE
			append sql [case "UNIQUE"]

			handleLeftParDefFlat sql
			set sqls [list]
			foreach col [getListValue columnNames] {
				lappend sqls $col
			}
			append sql [join $sqls "[spaceBeforeComma],[spaceAfterComma]"]
			handleRightParDefFlat sql

			formatConflictSql
		}
		2 {
			# CHECK
			append sql [case "CHECK"]
			set expr [getValue expr]
			set exprFmt [createFormatStatement $expr]
			handleSubStmt sql $exprFmt expr

			formatConflictSql
		}
	}

	return $sql
}

body FormatStatement2TableConstraint::formatConflictSql {} {
	upvar sql sql
	if {[get conflictClause] != ""} {
		append sql " "
		set fmtConflict [createFormatStatement [getValue conflictClause]]
		append sql [$fmtConflict formatSql]
	}
}

body FormatStatement2ConflictClause::formatSql {} {
	set sql ""

	if {[get onKeyword] != ""} {
		append sql [case "ON CONFLICT [getValue clause]"]
	}

	return $sql
}
