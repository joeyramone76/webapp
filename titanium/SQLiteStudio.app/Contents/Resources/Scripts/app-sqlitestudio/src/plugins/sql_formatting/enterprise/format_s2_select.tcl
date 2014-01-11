use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatement2Select {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

class FormatStatement2SelectCore {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

class FormatStatement2ResultColumn {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

class FormatStatement2JoinSource {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

class FormatStatement2SingleSource {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

class FormatStatement2JoinOp {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

class FormatStatement2JoinConstraint {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

class FormatStatement2OrderingTerm {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

class FormatStatement2CompoundOperator {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

body FormatStatement2Select::formatSql {} {
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

body FormatStatement2SelectCore::formatSql {} {
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

body FormatStatement2ResultColumn::formatSql {} {
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

body FormatStatement2JoinSource::formatSql {} {
	set singleSource [getValue singleSource]
	set joinOps [getListValue joinOps]
	set singleSources [getListValue singleSources]
	set joinConstraints [getListValue joinConstraints]

	set sql [[createFormatStatement $singleSource] formatSql]
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

body FormatStatement2SingleSource::formatSql {} {
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
			error "BranchIndex == 2 in SingleSource for SQLite2 Enterprise formatter."
		}
		default {
			error "BranchIndex == -1 in SingleSource for Enterprise formatter."
		}
	}
	return $sql
}

body FormatStatement2JoinOp::formatSql {} {
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
		} elseif {[get rightKeyword]} {
			lappend joinSql "[case RIGHT]"
		} elseif {[get fullKeyword]} {
			lappend joinSql "[case FULL]"
		}
		if {[get innerKeyword]} {
			lappend joinSql "[case INNER]"
		} elseif {[get outerKeyword]} {
			lappend joinSql "[case OUTER]"
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

body FormatStatement2JoinConstraint::formatSql {} {
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

body FormatStatement2OrderingTerm::formatSql {} {
	set sql ""
	set expr [getValue expr]
	set exprFmt [createFormatStatement $expr]
	append sql [$exprFmt formatSql]
	if {[get order] != ""} {
		append sql " "
		append sql [case [getValue order]]
	}
	return $sql
}

body FormatStatement2CompoundOperator::formatSql {} {
	set sql [case [getValue type]]
	if {[get allKeyword]} {
		append sql " [case ALL]"
	}
	return $sql
}
