use src/parser/statement2.tcl

class Statement2CreateTable {
	inherit Statement2

	private {
		method getConstrList {branchIdx}
	}

	public {
		variable temporary "" ;# TEMP or TEMPORARY or empty
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
		method getUniqs {}
		method getChks {}
	}
}

class Statement2ColumnDef {
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
		method getNotNull {}
		method getDefault {}
		method getUniq {}
		method getChk {}
	}
}

class Statement2TypeName {
	inherit Statement

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

class Statement2ColumnConstraint {
	inherit Statement

	public {
		variable namedConstraint 0
		variable constraintName ""
		variable branchIndex -1 ;# 0-based index of matched branch in SQLite documentation syntax diagram
		variable order "" ;# ASC or DESC or empty
		variable conflictClause "" ;# object
		variable expr "" ;# object
		variable literalValue ""
		#variable collationName ""
		variable notKeyword 0

		method appendLiteralValue {val} ;# required for signed numbers for DEFAULT
	}
}

class Statement2TableConstraint {
	inherit Statement

	constructor {} {
		lappend _listTypeVariableForDebug "columnNames"
	}

	public {
		variable namedConstraint 0
		variable constraintName ""
		variable branchIndex -1 ;# 0-based index of matched branch in SQLite documentation syntax diagram
		variable expr "" ;# object
		variable conflictClause "" ;# object
		variable literalValue ""
		variable columnNames [list] ;# list of names

		method addColumnName {col} {lappend columnNames $col}
	}
}

class Statement2ConflictClause {
	inherit Statement

	public {
		variable onKeyword 0
		variable conflictKeyword 0
		variable clause "" ;# ROLLBACK, ABORT, FAIL, IGNORE or REPLACE
	}
}

body Statement2CreateTable::getConstrList {branchIdx} {
	set list [list]
	foreach constr $tableConstraints {
		if {[$constr cget -branchIndex] == $branchIdx} {
			lappend list $constr
		}
	}
	return $list
}

body Statement2CreateTable::getPks {} {
	return [getConstrList 0]
}

body Statement2CreateTable::getUniqs {} {
	return [getConstrList 1]
}

body Statement2CreateTable::getChks {} {
	return [getConstrList 2]
}

body Statement2ColumnDef::getConstr {branchIdx} {
	foreach constr $columnConstraints {
		if {[$constr cget -branchIndex] == $branchIdx} {
			return $constr
		}
	}
	return ""
}

body Statement2ColumnDef::getPk {} {
	return [getConstr 0]
}

body Statement2ColumnDef::getNotNull {} {
	return [getConstr 1]
}

body Statement2ColumnDef::getDefault {} {
	return [getConstr 4]
}

body Statement2ColumnDef::getUniq {} {
	return [getConstr 2]
}

body Statement2ColumnDef::getChk {} {
	return [getConstr 3]
}


body Statement2ColumnConstraint::appendLiteralValue {val} {
	if {$literalValue != ""} {
		set tokenValue [lindex $literalValue 1]
		append tokenValue [lindex $val 1]
		set literalValue [list [lindex $val 0] $tokenValue [lindex $literalValue 2] [lindex $val 3]]
	} else {
		append literalValue $val
	}
}

body Statement2TypeName::appendSize {str} {
	if {$size != ""} {
		set tokenValue [lindex $size 1]
		append tokenValue [lindex $str 1]
		set size [list [lindex $str 0] $tokenValue [lindex $size 2] [lindex $str 3]]
	} else {
		append size $str
	}
}

body Statement2TypeName::appendPrecision {str} {
	if {$precision != ""} {
		set tokenValue [lindex $precision 1]
		append tokenValue [lindex $str 1]
		set precision [list [lindex $str 0] $tokenValue [lindex $precision 2] [lindex $str 3]]
	} else {
		append precision $str
	}
}

body Statement2TypeName::toString {} {
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
