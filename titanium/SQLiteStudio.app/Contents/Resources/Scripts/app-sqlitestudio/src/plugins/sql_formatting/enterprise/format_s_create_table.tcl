use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatementCreateTable {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

class FormatStatementColumnDef {
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

class FormatStatementTypeName {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

class FormatStatementColumnConstraint {
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

class FormatStatementTableConstraint {
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

class FormatStatementForeignKeyClause {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

class FormatStatementConflictClause {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

body FormatStatementCreateTable::formatSql {} {
	set sql [case "CREATE"]
	if {[get temporary] != ""} {
		append sql " [case [getValue temporary]]"
	}
	append sql [case " TABLE "]
	mark atTable $sql -1
	mark afterTable $sql
	if {[get ifNotExists]} {
		append sql [case "IF NOT EXISTS "]
	}
	if {[get databaseName] != ""} {
		append sql [wrap [getValue databaseName]]
		append sql "[spaceBeforeDot].[spaceAfterDot]"
	}
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

body FormatStatementColumnDef::formatSql {longestName longestType} {
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

body FormatStatementColumnDef::getNameLength {} {
	return [string length [wrap [getValue columnName]]]
}

body FormatStatementColumnDef::getTypeLength {} {
	if {[get typeName] != ""} {
		set type [getValue typeName]
		set typeFmt [createFormatStatement $type]
		set typeName [$typeFmt formatSql]

		return [string length $typeName]
	} else {
		return 0
	}
}

body FormatStatementTypeName::formatSql {} {
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

body FormatStatementColumnConstraint::formatSql {} {
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
			if {[get autoincrement]} {
				append sql [case " AUTOINCREMENT"]
			}
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
		}
		4 {
			# DEFAULT
			append sql [case "DEFAULT"]
			if {[get expr] != ""} {
				set expr [getValue expr]
				set exprFmt [createFormatStatement $expr]
				handleSubStmt sql $exprFmt expr
			} else {
				append sql " "
				set value [getValue literalValue]
				if {[string toupper $value] in [list "NULL" "CURRENT_DATE" "CURRENT_TIME" "CURRENT_TIMESTAMP"]} {
					append sql [case $value]
				} else {
					append sql $value
				}
			}
		}
		5 {
			# COLLATE
			append sql [case "COLLATE "]
			append sql [getValue collationName]
		}
		6 {
			# FK
			set fk [getValue foreignKey]
			set fkFmt [createFormatStatement $fk]
			append sql [$fkFmt formatSql]
		}
		default {
			error "Unsupported branchIndex in StatementColumnConstraint: [get branchIndex]"
		}
	}

	return $sql
}

body FormatStatementColumnConstraint::formatConflictSql {} {
	upvar sql sql
	if {[get conflictClause] != ""} {
		append sql " "
		set fmtConflict [createFormatStatement [getValue conflictClause]]
		append sql [$fmtConflict formatSql]
	}
}

body FormatStatementTableConstraint::formatSql {} {
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
			foreach idxCol [getListValue indexedColumns] {
				set fmtCol [createFormatStatement $idxCol]
				lappend sqls [$fmtCol formatSql]
			}
			append sql [join $sqls "[spaceBeforeComma],[spaceAfterComma]"]

			if {[getValue autoincrement]} {
				append sql " [case AUTOINCREMENT]"
			}

			handleRightParDefFlat sql

			formatConflictSql
		}
		1 {
			# UNIQUE
			append sql [case "UNIQUE"]

			handleLeftParDefFlat sql
			set sqls [list]
			foreach idxCol [getListValue indexedColumns] {
				set fmtCol [createFormatStatement $idxCol]
				lappend sqls [$fmtCol formatSql]
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
		}
		3 {
			# FK
			append sql [case "FOREIGN KEY"]

			handleLeftParDefFlat sql
			set sqls [list]
			foreach idxCol [getListValue columnNames] {
				lappend sqls [wrap $idxCol]
			}
			append sql [join $sqls "[spaceBeforeComma],[spaceAfterComma]"]
			handleRightParDefFlat sql

			mark afterFkRightPar $sql

			set fk [getValue foreignKey]
			set fkFmt [createFormatStatement $fk]
			append sql [string trimleft [indentAllLinesToMark [$fkFmt formatSql] afterFkRightPar]]
		}
	}

	return $sql
}

body FormatStatementTableConstraint::formatConflictSql {} {
	upvar sql sql
	if {[get conflictClause] != ""} {
		append sql " "
		set fmtConflict [createFormatStatement [getValue conflictClause]]
		append sql [$fmtConflict formatSql]
	}
}

body FormatStatementForeignKeyClause::formatSql {} {
	set sql ""

	append sql [case "REFERENCES "]
	mark fkTableBegin $sql
	append sql [wrap [getValue tableName]]

	set cols [getListValue columnNames]
	if {[llength $cols] > 0} {
		handleLeftParDefFlat sql
		set sqls [list]
		foreach col [getListValue columnNames] {
			lappend sqls [wrap $col]
		}
		append sql [join $sqls "[spaceBeforeComma],[spaceAfterComma]"]
		handleRightParDefFlat sql
	}

	mark afterRightPar $sql

	set restSql ""

	# ON DELETE
	if {[get onDelete] != ""} {
		append restSql [logicalBlockIndent afterRightPar ""]
		append restSql [case "ON DELETE "]
		append restSql [case [getValue onDelete]]
	}

	# ON UPDATE
	if {[get onUpdate] != ""} {
		append restSql [logicalBlockIndent afterRightPar ""]
		append restSql [case "ON UPDATE "]
		append restSql [case [getValue onUpdate]]
	}

	# MATCH
	if {[get matchKeyword]} {
		append restSql [logicalBlockIndent afterRightPar ""]
		append restSql [case "MATCH "]
		append restSql [getValue matchName]
	}

	# DEFERRABLE
	if {[get deferrableKeyword]} {
		append restSql [logicalBlockIndent afterRightPar ""]
		if {[get notKeyword]} {
			append restSql [case "NOT "]
		}
		append restSql [case "DEFERRABLE"]
		if {[get deferredKeyword]} {
			append restSql [case " INITIALLY DEFERRED"]
		} elseif {[get immediateKeyword]} {
			append restSql [case " INITIALLY IMMEDIATE"]
		}
	}

	if {$restSql != ""} {
		if {[string index $sql end] != " "} {
			# If there was no specific column in 'sql', just a table name,
			# then there would be no space after right parenthesis.
			append sql " "
		}
		append sql [string trimleft $restSql]
	}

	return $sql
}

body FormatStatementConflictClause::formatSql {} {
	set sql ""

	if {[get onKeyword] != ""} {
		append sql [case "ON CONFLICT [getValue clause]"]
	}

	return $sql
}
