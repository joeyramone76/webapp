use src/parser/statement.tcl

class StatementCreateTable {
	inherit Statement

	private {
		method getConstrList {branchIdx}
	}

	public {
		variable temporary "" ;# TEMP or TEMPORARY or empty
		variable ifNotExists 0
		variable databaseName ""
		variable tableName ""
		variable realDatabaseName ""
		variable subSelect "" ;# object
		variable asKeyword 0
		variable columnDefs [list] ;# list of objects
		variable tableConstraints [list] ;# list of objects

		method addColumnDef {def} {lappend columnDefs $def}
		method addTableConstraint {const} {lappend tableConstraints $const}

		method afterParsing {} {
			set realDatabaseName [resolveDatabase $databaseName]
		}

		method getPks {}
		method getFks {}
		method getUniqs {}
		method getChks {}
	}
}

class StatementColumnDef {
	inherit Statement

	private {
		method getConstr {branchIdx}
	}

	public {
		variable columnName ""
		variable typeName "" ;# object
		variable columnConstraints [list] ;# list of objects

		method addColumnConstraint {const} {lappend columnConstraints $const}

		method getPk {}
		method getFk {}
		method getNotNull {}
		method getDefault {}
		method getUniq {}
		method getChk {}
		method getCollate {}
	}
}

class StatementTypeName {
	inherit Statement

	constructor {} {
		lappend _listTypeVariableForDebug "name"
	}

	public {
		variable name [list]
		#variable nameKeywords [list]
		variable size ""
		variable precision ""

		method addNameWord {word} {lappend name $word}
		method addNameKeyword {word} {lappend nameKeywords $word}
		method appendSize {str}
		method appendPrecision {str}
		method toString {}
	}
}

class StatementColumnConstraint {
	inherit Statement

	public {
		variable namedConstraint 0
		variable constraintName ""
		variable branchIndex -1 ;# 0-based index of matched branch in SQLite documentation syntax diagram
		variable order "" ;# ASC or DESC or empty
		variable conflictClause "" ;# object
		variable autoincrement 0
		variable expr "" ;# object
		variable literalValue ""
		variable collationName ""
		variable foreignKey "" ;# object
		variable notKeyword 0

		method appendLiteralValue {val} ;# required for signed numbers for DEFAULT
	}
}

class StatementTableConstraint {
	inherit Statement

	constructor {} {
		lappend _listTypeVariableForDebug "columnNames"
	}

	public {
		variable namedConstraint 0
		variable constraintName ""
		variable branchIndex -1 ;# 0-based index of matched branch in SQLite documentation syntax diagram
		variable indexedColumns [list] ;# list of objects
		variable expr "" ;# object
		variable foreignKey "" ;# object
		variable autoincrement 0
		variable conflictClause "" ;# object
		variable columnNames [list] ;# list of names

		method addIndexedColumn {col} {lappend indexedColumns $col}
		method addColumnName {col} {lappend columnNames $col}
	}
}

class StatementForeignKeyClause {
	inherit Statement

	constructor {} {
		lappend _listTypeVariableForDebug "columnNames"
	}

	private {
		variable _nextAction ""
	}

	public {
		variable tableName ""
		variable columnNames [list] ;# list of names
		variable onDelete "" ;# "SET NULL", "SET DEFAULT", "CASCADE", "RESTRICT" or "NO ACTION"
		variable onUpdate "" ;# "SET NULL", "SET DEFAULT", "CASCADE", "RESTRICT" or "NO ACTION"
		variable matchKeyword 0
		variable matchName ""
		variable notKeyword 0
		variable deferrableKeyword 0
		variable initiallyKeyword 0
		variable deferredKeyword 0
		variable immediateKeyword 0

		method addColumnName {col} {lappend columnNames $col}
		method setNextAction {action} {set _nextAction $action}
		method setActionValue {action} {set $_nextAction $action}
	}
}

class StatementConflictClause {
	inherit Statement

	public {
		variable onKeyword 0
		variable conflictKeyword 0
		variable clause "" ;# ROLLBACK, ABORT, FAIL, IGNORE or REPLACE
	}
}

body StatementColumnConstraint::appendLiteralValue {val} {
	if {$literalValue != ""} {
		set tokenValue [lindex $literalValue 1]
		append tokenValue [lindex $val 1]
		set literalValue [list [lindex $val 0] $tokenValue [lindex $literalValue 2] [lindex $val 3]]
	} else {
		append literalValue $val
	}
}

body StatementCreateTable::getConstrList {branchIdx} {
	set list [list]
	foreach constr $tableConstraints {
		if {[$constr cget -branchIndex] == $branchIdx} {
			lappend list $constr
		}
	}
	return $list
}

body StatementCreateTable::getPks {} {
	return [getConstrList 0]
}

body StatementCreateTable::getFks {} {
	return [getConstrList 3]
}

body StatementCreateTable::getUniqs {} {
	return [getConstrList 1]
}

body StatementCreateTable::getChks {} {
	return [getConstrList 2]
}

body StatementColumnDef::getConstr {branchIdx} {
	foreach constr $columnConstraints {
		if {[$constr cget -branchIndex] == $branchIdx} {
			return $constr
		}
	}
	return ""
}

body StatementColumnDef::getPk {} {
	return [getConstr 0]
}

body StatementColumnDef::getFk {} {
	return [getConstr 6]
}

body StatementColumnDef::getNotNull {} {
	return [getConstr 1]
}

body StatementColumnDef::getDefault {} {
	return [getConstr 4]
}

body StatementColumnDef::getUniq {} {
	return [getConstr 2]
}

body StatementColumnDef::getChk {} {
	return [getConstr 3]
}

body StatementColumnDef::getCollate {} {
	return [getConstr 5]
}

body StatementTypeName::appendSize {str} {
	if {$size != ""} {
		set tokenValue [lindex $size 1]
		append tokenValue [lindex $str 1]
		set size [list [lindex $str 0] $tokenValue [lindex $size 2] [lindex $str 3]]
	} else {
		append size $str
	}
}

body StatementTypeName::appendPrecision {str} {
	if {$precision != ""} {
		set tokenValue [lindex $precision 1]
		append tokenValue [lindex $str 1]
		set precision [list [lindex $str 0] $tokenValue [lindex $precision 2] [lindex $str 3]]
	} else {
		append precision $str
	}
}

body StatementTypeName::toString {} {
	set type [getListValue name]
	set sizes [list]
	if {$size != ""} {
		lappend sizes [getValue size]
	}
	if {$precision != ""} {
		lappend sizes [getValue precision]
	}
	if {[llength $sizes] > 0} {
		append type [join $sizes ", "]
	}
	return $type
}
