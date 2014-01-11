use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatementSelect {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

class FormatStatementSelectCore {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

class FormatStatementResultColumn {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

class FormatStatementJoinSource {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

class FormatStatementSingleSource {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

class FormatStatementJoinOp {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

class FormatStatementJoinConstraint {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

class FormatStatementOrderingTerm {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

class FormatStatementCompoundOperator {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

body FormatStatementSelect::formatSql {} {
	set sql ""
	# Cores
	set cores [getListValue selectCores]
	set compounds [getListValue compOpers]
	set firstCore [createFormatStatement [lindex $cores 0]]
	append sql [$firstCore formatSql]
	foreach coreObj [lrange $cores 1 end] compoundObj $compounds {
		set compoundStmt [createFormatStatement $compoundObj]
		set coreStmt [createFormatStatement $coreObj]
		if {[cfg nl_after_logical_blocks_of_query]} {
			append sql "\n"
		} else {
			append sql " "
		}
		append sql [$compoundStmt formatSql]
		if {[cfg nl_after_logical_blocks_of_query]} {
			append sql "\n"
		} else {
			append sql " "
		}
		append sql [$coreStmt formatSql]
	}

	# ORDER BY
	copyMarkFrom $firstCore selectWithDistinct
	set orderByList [getListValue orderBy]
	if {[llength $orderByList] > 0} {
		append sql [logicalBlockIndent selectWithDistinct "ORDER"]
		append sql [case "ORDER BY "]
		set orderSqls [list]
		foreach orderBy $orderByList {
			set orderByStmt [createFormatStatement $orderBy]
			lappend orderSqls [$orderByStmt formatSql]
		}
		append sql [joinList $orderSqls $sql]
	}

	# LIMIT
	set limit [getValue limit]
	if {$limit != ""} {
		set limitFmt [createFormatStatement $limit]
		set limitSql [$limitFmt formatSql]

		append sql [logicalBlockIndent selectWithDistinct "LIMIT"]
		append sql "[case LIMIT] $limitSql"
		set offset [getValue offset]
		if {$offset != ""} {
			set offsetFmt [createFormatStatement $offset]
			set offsetSql [$offsetFmt formatSql]
			switch -- [get offsetKeyword] {
				1 {
					append sql " [case OFFSET] $offsetSql"
				}
				2 {
					append sql "[spaceBeforeComma],[spaceAfterComma]$offsetSql"
				}
			}
		}
	}
	return $sql
}

body FormatStatementSelectCore::formatSql {} {
	# SELECT DISTINCT
	#set sql [indent]
	set sql ""
	append sql [case "SELECT"]
	set distinct [getValue allOrDistinct]
	if {$distinct != ""} {
		append sql " [case $distinct]"
	}
	mark selectWithDistinct $sql
	mark beforeColumns $sql +1

	# Result columns
	set cols [getListValue resultColumns]
	set colSqls [list]
	foreach col $cols {
		set colFmt [createFormatStatement $col]
		set colSql [$colFmt formatSql]
		set colSql [indentAllLinesToMark $colSql beforeColumns]
		lappend colSqls $colSql
	}
	append sql " [joinList $colSqls $sql]"

	# FROM
	set from [getValue from]
	if {$from != ""} {
		set fromFmt [createFormatStatement $from]
		copyMarkTo $fromFmt selectWithDistinct
		copyMarkTo $fromFmt beforeColumns
		append sql [logicalBlockIndent selectWithDistinct "FROM"]
		append sql "[case FROM] [$fromFmt formatSql]"
	}

	# WHERE
	set where [getValue where]
	if {$where != ""} {
		set whereFmt [createFormatStatement $where]
		#copyMarkTo $whereFmt selectWithDistinct
		append sql [logicalBlockIndent selectWithDistinct "WHERE"]
		append sql "[case WHERE] [string trimleft [indentAllLinesToMark [$whereFmt formatSql] beforeColumns]]"
	}

	# GROUP BY
	set groupBy [getListValue groupBy]
	if {[llength $groupBy] > 0} {
		append sql [logicalBlockIndent selectWithDistinct "GROUP"]
		append sql [case "GROUP BY"]
		mark beforeGroupByColumns $sql +1

		# Group by columns
		set groupCols [getListValue groupBy]
		set colSqls [list]
		foreach col $groupCols {
			set colFmt [createFormatStatement $col]
			lappend colSqls [$colFmt formatSql]
		}
		append sql " [joinList $colSqls $sql]"

		# HAVING
		set having [getValue having]
		if {$having != ""} {
			set havingFmt [createFormatStatement $having]
			append sql [logicalBlockIndent selectWithDistinct "HAVING"]
			set havingSql [$havingFmt formatSql]
			append sql "[case HAVING][spaceBeforeSql $havingSql]$havingSql"
		}
	}
	return $sql
}

body FormatStatementResultColumn::formatSql {} {
	set tableName [getValue tableName]
	set star [get star]
	set expr [getValue expr]
	set alias [getValue columnAlias]

	set sql ""
	if {[get tableName] != ""} {
		append sql [wrap $tableName]
		append sql "[spaceBeforeDot].[spaceAfterDot]"
		append sql "*"
	} elseif {$star} {
		append sql "*"
	} elseif {$expr != ""} {
		append sql [[createFormatStatement $expr] formatSql]
	} else {
		error "Unknown state of ResultColumn for Enterprise formatter."
	}

	# Alias
	if {[get columnAlias] != ""} {
		set sql [spaceBeforeSql $sql]$sql
		if {[get asKeyword]} {
			append sql [spaceAfterSql $sql]
			append sql [case "AS"]
		}
		append sql " [wrap $alias]"
	}

	return $sql
}

body FormatStatementJoinSource::formatSql {} {
	set singleSource [getValue singleSource]
	set joinOps [getListValue joinOps]
	set singleSources [getListValue singleSources]
	set joinConstraints [getListValue joinConstraints]

	set singleSourceFmt [createFormatStatement $singleSource]
	copyMarkTo $singleSourceFmt selectWithDistinct
	copyMarkTo $singleSourceFmt beforeColumns
	set sql [$singleSourceFmt formatSql]

	foreach joinOp $joinOps singleSrc $singleSources joinConst $joinConstraints {
		set joinOpFmt [createFormatStatement $joinOp]
		copyMarkTo $joinOpFmt selectWithDistinct
		copyMarkTo $joinOpFmt beforeColumns
		append sql [$joinOpFmt formatSql]
		copyMarkFrom $joinOpFmt joinOp ;# Getting mark for JoinOp, so it can be used for "ON ()"
		copyMarkFrom $joinOpFmt joinOpAfter ;# Getting mark for JoinOpAfter, so it can be used for "USING ()"

		set singleSrcFmt [createFormatStatement $singleSrc]
		copyMarkTo $singleSrcFmt selectWithDistinct
		copyMarkTo $singleSrcFmt beforeColumns
		append sql [$singleSrcFmt formatSql]

		if {$joinConst != ""} {
			set joinConstFmt [createFormatStatement $joinConst]
			copyMarkTo $joinConstFmt selectWithDistinct
			copyMarkTo $joinConstFmt beforeColumns
			copyMarkTo $joinConstFmt joinOp
			copyMarkTo $joinConstFmt joinOpAfter
			append sql [$joinConstFmt formatSql]
		}
	}
	return $sql
}

body FormatStatementSingleSource::formatSql {} {
	set sql ""

	set branchIdx [get branchIndex]
	switch -- $branchIdx {
		0 {
			# Explicit table
			if {[get databaseName] != ""} {
				append sql [wrap [getValue databaseName]]
				append sql "[spaceBeforeDot].[spaceAfterDot]"
			}
			append sql [wrap [getValue tableName]]
			if {[get asKeyword]} {
				append sql " [case AS]"
			}
			if {[get tableAlias] != ""} {
				append sql " [wrap [getValue tableAlias]]"
			}
			# INDEXED BY or NOT INDEXED
			if {[get indexedKeyword]} {
				if {[get byKeyword]} {
					# INDEXED BY
					append [case " INDEXED BY "]
					append sql [wrap [getValue indexName]]
				} else {
					# NOT INDEXED
					append [case " NOT INDEXED"]
				}
			}
		}
		1 {
			# Subselect
			handleLeftParDef sql
			set select [getValue selectStmt]
			set selectFmt [createFormatStatement $select]
			
			set selectSql [$selectFmt formatSql]
			set indentedSql [indentAllLinesSelectivelyBy $selectSql $_indent 1 1]
			append sql $indentedSql
			
			handleRightParDef sql
			if {[get asKeyword] || [get tableAlias] != ""} {
				if {[cfg nl_after_close_parenthesis_def]} {
					append sql "[indent]"
				} else {
					append sql " "
				}
				if {[get asKeyword]} {
					append sql "[case AS] "
				}
				append sql "[wrap [getValue tableAlias]]"
			}
		}
		2 {
			# Sub join-source
			handleLeftParDef sql
			set joinSource [getValue joinSource]
			set joinFmt [createFormatStatement $joinSource]
			copyMarkTo $joinFmt selectWithDistinct
			copyMarkTo $joinFmt beforeColumns

			set joinSql [$joinFmt formatSql]
			set indentedSql [indentAllLinesSelectivelyBy $joinSql $_indent 1 1]
			append sql $indentedSql

			handleRightParDef sql
			if {[get asKeyword] || [get tableAlias] != ""} {
				if {[cfg nl_after_close_parenthesis_def]} {
					append sql "[indent]"
				} else {
					append sql " "
				}
				if {[get asKeyword]} {
					append sql "[case AS] "
				}
				append sql "[wrap [getValue tableAlias]]"
			}
		}
		default {
			error "BranchIndex == -1 in SingleSource for Enterprise formatter."
		}
	}
	return $sql
}

body FormatStatementJoinOp::formatSql {} {
	set sql ""
	if {[get period]} {
		# Just a period
		append sql "[spaceBeforeComma],[spaceAfterComma][nlAfterComma]"
		mark joinOp ""
		if {[cfg nl_after_comma]} {
			append sql [listElementSql beforeColumns ""]
		}
		mark joinOpAfter $sql
	} else {
		append sql [logicalBlockIndent beforeColumns ""]

		# JOIN
		set joinSql [list]
		if {[get naturalKeyword]} {
			lappend joinSql "[case NATURAL]"
		}
		if {[get leftKeyword]} {
			lappend joinSql "[case LEFT]"
			if {[get outerKeyword]} {
				lappend joinSql "[case OUTER]"
			}
		} elseif {[get innerKeyword]} {
			lappend joinSql "[case INNER]"
		} elseif {[get crossKeyword]} {
			lappend joinSql "[case CROSS]"
		}
		lappend joinSql "[case JOIN]"

		append sql [join $joinSql " "]
		mark joinOp $sql
		append sql " "
		mark joinOpAfter $sql
	}
	return $sql
}

body FormatStatementJoinConstraint::formatSql {} {
	set sql ""
	if {[get onKeyword]} {
		set expr [getValue expr]
		set exprFmt [createFormatStatement $expr]
		append sql "[logicalBlockIndent joinOp ON][case ON] [string trimleft [$exprFmt formatSql]]"
	} elseif {[get usingKeyword]} {
		set cols [getListValue columnNames]
		foreach col $cols {
			set colSqls [wrap $col]
		}
		append sql "[logicalBlockIndent joinOpAfter {}][case USING]"
		handleLeftParDefFlat sql
		append sql [joinList $colSqls true]
		handleRightParDefFlat sql
	}
	return $sql
}

body FormatStatementOrderingTerm::formatSql {} {
	set sql ""
	set expr [getValue expr]
	set exprFmt [createFormatStatement $expr]
	append sql [$exprFmt formatSql]
	if {[get collateKeyword]} {
		if {[cfg nl_after_close_parenthesis_def]} {
			append sql "[indent]"
		} else {
			append sql " "
		}
		append sql "[case COLLATE] [getValue collationName]"
	}
	if {[get order] != ""} {
		append sql " "
		append sql [case [getValue order]]
	}
	return $sql
}

body FormatStatementCompoundOperator::formatSql {} {
	set sql [case [getValue type]]
	if {[get allKeyword]} {
		append sql " [case ALL]"
	}
	return $sql
}
