use src/parser/statement.tcl

class StatementSelect {
	inherit Statement

	constructor {} {set checkRecurentlyForContext false}

	public {
		variable selectCores [list] ;# list of objects
		variable compOpers [list] ;# list of objects
		variable orderBy [list] ;# list of objects
		variable limit ""
		variable offset ""
		variable offsetKeyword 0 ;# 1 for OFFSET, 2 for ","

		method addSelectCore {selectCore} {lappend selectCores $selectCore}
		method addCompoundOperator {compOper} {lappend compOpers $compOper}
		method addOrderBy {order} {lappend orderBy $order}
		method afterParsing {}
	}
}

body StatementSelect::afterParsing {} {
	if {$offsetKeyword == 2} {
		# For "," we need to switch limit and offset
		set tmp $limit
		set limit $offset
		set offset $tmp
	}
}

class StatementSelectCore {
	inherit Statement

	public {
		variable allOrDistinct ""
		variable resultColumns [list] ;# list of objects
		variable from "" ;# object
		variable where "" ;# object
		variable groupBy [list] ;# list of objects
		variable having "" ;# object

		method addResultColumn {col} {lappend resultColumns $col}
		method addGroupBy {grp} {lappend groupBy $grp}
	}
}

class StatementResultColumn {
	inherit Statement

	public {
		variable star 0
		variable tableName ""
		variable expr "" ;# object
		variable columnAlias ""
		variable asKeyword 0

		method getColumnNames {}
		method getAllAliases {}
	}
}

body StatementResultColumn::getAllAliases {} {
	if {$columnAlias != ""} {
		return [list [getContextValue columnAlias]]
	} else {
		return [list]
	}
}

body StatementResultColumn::getColumnNames {} {
	if {!$star && $expr != ""} {
		# Column is identified by alias, so it doesn't matter what's in expr.
		$expr configure -checkRecurentlyForContext false
		if {$columnAlias != ""} {
			return [list [dict create column $expr type OBJECT alias [getContextValue columnAlias]]]
		} else {
			return [list [dict create column $expr type OBJECT]]
		}
	}

	return [list]
}

class StatementJoinSource {
	inherit Statement

	public {
		variable singleSource "" ;# object
		variable joinOps [list] ;# list of objects
		variable singleSources [list] ;# list of objects
		variable joinConstraints [list] ;# list of objects

		method addJoinOp {jop}
		method addSingleSource {sSrc} {lappend singleSources $sSrc}
		method addJoinConstraint {joinConst} {lappend joinConstraints $joinConst}
		method getSingleSources {}
	}
}

body StatementJoinSource::getSingleSources {} {
	list [getValue singleSource] {*}[getListValue singleSources]
}

body StatementJoinSource::addJoinOp {jop} {
	if {[llength $joinOps] > [llength $joinConstraints]} {
		lappend joinConstraints ""
	}
	lappend joinOps $jop
}

class StatementSingleSource {
	inherit Statement

	public {
		variable branchIndex -1 ;# index of matched branch from SQLite documentation diagram (0-based)

		variable databaseName ""
		variable realDatabaseName ""
		variable tableName ""
		variable asKeyword 0
		variable tableAlias ""
		variable indexedKeyword 0
		variable byKeyword 0
		variable notKeyword 0
		variable indexName ""
		variable leftPar 0
		variable rightPar 0
		variable selectStmt "" ;# object
		variable joinSource "" ;# object

		method afterParsing {} {
			set realDatabaseName [resolveDatabase $databaseName]
		}

		method getTableNames {}
		method getDatabaseNames {}
		method getAllAliases {}
	}
}

body StatementSingleSource::getTableNames {} {
	if {$tableName != ""} {
		set res [dict create]
		dict set res table [getContextValue tableName]
		if {$databaseName != ""} {
			dict set res database [getContextValue databaseName]
		}
		if {$tableAlias != ""} {
			dict set res alias [getContextValue tableAlias]
		}
		return [list $res]
	}
	return [list]
}

body StatementSingleSource::getDatabaseNames {} {
	if {$databaseName != ""} {
		return [list [dict create database [getContextValue databaseName] realname $realDatabaseName]]
	} else {
		return [list]
	}
}

body StatementSingleSource::getAllAliases {} {
	if {$tableAlias != ""} {
		return [list [getContextValue tableAlias]]
	} else {
		return [list]
	}
}

class StatementJoinOp {
	inherit Statement

	public {
		variable period 0
		variable naturalKeyword 0
		variable leftKeyword 0
		variable outerKeyword 0
		variable innerKeyword 0
		variable crossKeyword 0
		variable joinKeyword 0
	}
}

class StatementJoinConstraint {
	inherit Statement

	public {
		variable onKeyword 0
		variable usingKeyword 0
		variable expr "" ;# object
		variable columnNames [list] ;# plain names

		method addColumnName {col} {lappend columnNames $col}
	}
}

class StatementOrderingTerm {
	inherit Statement

	public {
		variable expr "" ;# object
		variable collateKeyword 0
		variable collationName ""
		variable order "" ;# DESC or ASC
	}
}

class StatementCompoundOperator {
	inherit Statement

	public {
		variable type "" ;# UNION, INTERSECT or EXCEPT
		variable allKeyword 0
	}
}
