class FormatStatement {
	constructor {obj} {}

	protected {
		variable _statement ""
		variable _dialect ""
		variable _lineupMark
		variable _constantIndent 0
		common _indent 0
		common _indentStack [list]

		method get {varName}
		method getValue {varName}
		method getListValue {varName}
		method getType {varName}
		method createFormat {fieldName}
		method createFormatStatement {stmt}
		method cfg {varName}
		method spaceBeforOrAfter {varName}
		method nlBeforeOrAfter {varName}
		method setMark {name value}
		method getMark {name}
		method copyMarkTo {stmt markName}
		method copyMarkFrom {stmt markName}
		method applyNeverBeforeSemicolon {sqlVar}

		# Common formatting rules methods
		method wrap {obj}
		method case {str}
		method spaceBeforeDot {}
		method spaceAfterDot {}
		method spaceBeforeComma {}
		method spaceAfterComma {}
		method spaceBeforeLeftPar {}
		method spaceAfterLeftPar {}
		method spaceBeforeRightPar {}
		method spaceAfterRightPar {}
		method spaceBeforeMathOper {}
		method spaceAfterMathOper {}
		method spaceNeverBeforeSemicolon {}
		method spaceBeforeSql {sql {spaces " "}}
		method spaceAfterSql {sql {spaces " "}}
		method nlBeforeLeftParDef {}
		method nlAfterLeftParDef {}
		method nlBeforeRightParDef {}
		method nlAfterRightParDef {}
		method nlBeforeLeftParExpr {}
		method nlAfterLeftParExpr {}
		method nlBeforeRightParExpr {}
		method nlAfterRightParExpr {}
		method nlAfterLogicalBlock {}
		method nlAfterSemicolon {}
		method nlAfterComma {}
		method nlNeverBeforeSemicolon {}
		method indent {{value ""}}
		method incrIndent {}
		method decrIndent {}
		method lineup {}
		method lineupFor {str markName}
		method parBlockIndent {}
		method parBlockContentsIndent {}
		method pushIndent {}
		method popIndent {}
		method indentAllLinesToMark {sql markName}
		method indentAllLinesBy {sql indentLength}
		method indentAllLinesSelectivelyBy {sql indentLength begin end}

		#>
		# @method mark
		# @param name
		# @param sql
		# @param modifier
		# Marks current length of sql under given name. Optionally modifies length by modifier.
		# It's used to remember at what position next line should be lined up.
		# It should be called after last keyword in current line.
		#<
		method mark {name sql {modifier 0}}
		method markWithIndent {name sql {modifier 0}} ;# adds indent - for recurent formatting
		method markExists {name}

		# More general formatting methods
		method handleLeftParDef {sqlVar {markNameToSet ""}}
		method handleRightParDef {sqlVar {markForIndent ""}}
		method handleLeftParDefFlat {sqlVar}
		method handleRightParDefFlat {sqlVar}
		method handleLeftParExpr {sqlVar {markNameToSet ""}}
		method handleLeftParExprFunc {sqlVar {markNameToSet ""}}
		method handleRightParExpr {sqlVar {markForIndent ""}}
		method handleSubStmt {sqlVar subStmtFmt defOrExpr}
		method handleSubStmtList {sqlVar subStmtFmtList defOrExpr}
		method handleSubList {sqlVar subList doWrap defOrExpr}
		method joinList {list sql {insideOfParenthesis false}}
		method listElementSql {markName sql}
		method logicalBlockIndent {markName lineupWord}
		method indentAfterOpenParDef {{value ""}}
		method indentAfterOpenParExpr {{value ""}}
		method indentAllLinesToMarkForExpr {sql markName}
		method indentAllLinesForExpr {sql indentLength}
	}

	public {
		method setDialect {dialect}
		abstract method formatSql {}
		proc createGenericFormatStatement {stmt}
		proc reset {}
	}
}

body FormatStatement::constructor {obj} {
	set _statement $obj
}

body FormatStatement::setDialect {dialect} {
	set _dialect $dialect
}

body FormatStatement::reset {} {
	set _indent 0
	set _lineupIndent ""
	array set _lineupMark {}
}

body FormatStatement::get {varName} {
	return [$_statement cget -$varName]
}

body FormatStatement::getValue {varName} {
	return [$_statement getValue $varName false]
}

body FormatStatement::getListValue {varName} {
	return [$_statement getListValue $varName false]
}

body FormatStatement::getType {varName} {
	return [$_statement getType $varName]
}

body FormatStatement::createFormat {fieldName} {
	set stmt [getValue subStatement]
	return [createFormatStatement $stmt]
}

body FormatStatement::createGenericFormatStatement {stmt} {
	set stmtClassName [string trimleft [$stmt info class] :]
	set fmtStmt [Format$stmtClassName ::#auto $stmt]
	return $fmtStmt
}

body FormatStatement::createFormatStatement {stmt} {
	set fmtStmt [createGenericFormatStatement $stmt]
	$fmtStmt setDialect $_dialect
	return $fmtStmt
}

body FormatStatement::cfg {varName} {
	if {$::EnterpriseSqlFormattingPlugin::config(useUiVar)} {
		return $::EnterpriseSqlFormattingPlugin::uiVar($varName)
	} else {
		return $::EnterpriseSqlFormattingPlugin::config($varName)
	}
}

body FormatStatement::setMark {name value} {
	set _lineupMark($name) $value
}

body FormatStatement::getMark {name} {
	return $_lineupMark($name)
}

body FormatStatement::copyMarkTo {stmt markName} {
	$stmt setMark $markName $_lineupMark($markName)
}

body FormatStatement::copyMarkFrom {stmt markName} {
	set _lineupMark($markName) [$stmt getMark $markName]
}

body FormatStatement::applyNeverBeforeSemicolon {sql} {
	set sqls [regexp -inline -- {^.*?(\s*)$} $sql]
	#lassign -- $sqls all ws
	set all [lindex $sqls 0]
	set ws [lindex $sqls 1]
	if {[cfg sp_never_before_semicolon]} {
		set ws [strip $ws " "]
	}
	if {[cfg nl_never_before_semicolon]} {
		set ws [strip $ws "\n"]
	}
	return "[string trimright $sql]$ws"
}

###############################
# Common
###############################

body FormatStatement::handleLeftParDef {sqlVar {markNameToSet ""}} {
	upvar $sqlVar sql
	set endChar [string index $sql end]
	if {$endChar ni [list "\n" "\t" " " ""]} {
		append sql "[spaceBeforeLeftPar]"
	}
	if {$endChar != "\n"} {
		append sql "[nlBeforeLeftParDef]"
	}
	if {[cfg nl_before_open_parenthesis_def]} {
		if {[parBlockIndent]} {incrIndent} ;# indent++
		append sql "[indent]"
	}
	append sql "("
	if {$markNameToSet != ""} {
		mark $markNameToSet $sql
	}
	append sql "[spaceAfterLeftPar][nlAfterLeftParDef]"
	if {[parBlockContentsIndent]} {incrIndent} ;# indent++
}

body FormatStatement::handleRightParDef {sqlVar {markForIndent ""}} {
	upvar $sqlVar sql
	if {[parBlockContentsIndent]} {decrIndent} ;# indent--
	append sql "[spaceBeforeRightPar][nlBeforeRightParDef]"
	if {[cfg nl_before_close_parenthesis_def]} {
		append sql "[indent]"
	}
	if {[parBlockIndent]} {decrIndent} ;# indent--
	if {$markForIndent != ""} {
		append sql [indent $_lineupMark($markForIndent)]
	}
	append sql ")"
	append sql [spaceAfterRightPar]
	append sql [nlAfterRightParDef]
}

body FormatStatement::handleLeftParDefFlat {sqlVar} {
	upvar $sqlVar sql
	append sql "[spaceBeforeLeftPar]([spaceAfterLeftPar]"
}

body FormatStatement::handleRightParDefFlat {sqlVar} {
	upvar $sqlVar sql
	append sql "[spaceBeforeRightPar])[spaceAfterRightPar]"
}

body FormatStatement::handleLeftParExpr {sqlVar {markNameToSet ""}} {
	upvar $sqlVar sql
	set endChar [string index $sql end]
	if {$endChar ni [list "\n" "\t" " " ""]} {
		append sql "[spaceBeforeLeftPar]"
	}
	if {$endChar != "\n"} {
		append sql "[nlBeforeLeftParExpr]"
	}
# 	append sql "[spaceBeforeLeftPar][nlBeforeLeftParExpr]"
	if {[cfg nl_before_open_parenthesis_expr]} {
		if {[parBlockIndent]} {incrIndent} ;# indent++
		append sql "[indent]"
	}
	append sql "("
	if {$markNameToSet != ""} {
		mark $markNameToSet $sql
	}
	append sql "[spaceAfterLeftPar][nlAfterLeftParExpr]"
	if {[parBlockContentsIndent]} {incrIndent} ;# indent++
}

body FormatStatement::handleLeftParExprFunc {sqlVar {markNameToSet ""}} {
	upvar $sqlVar sql
	append sql "[nlBeforeLeftParExpr]"
	if {[cfg nl_before_open_parenthesis_expr]} {
		if {[parBlockIndent]} {incrIndent} ;# indent++
		append sql "[indent]"
	}
	append sql "("
	if {$markNameToSet != ""} {
		mark $markNameToSet $sql
	}
	append sql "[spaceAfterLeftPar][nlAfterLeftParExpr]"
	if {[parBlockContentsIndent]} {incrIndent} ;# indent++
}

body FormatStatement::handleRightParExpr {sqlVar {markForIndent ""}} {
	upvar $sqlVar sql
	if {[parBlockContentsIndent]} {decrIndent} ;# indent--
	append sql "[spaceBeforeRightPar][nlBeforeRightParExpr]"
	if {[cfg nl_before_close_parenthesis_expr]} {
# 		append sql "[indent]"
		if {[parBlockIndent]} {decrIndent} ;# indent--
	}
	if {$markForIndent != ""} {
		append sql [indent $_lineupMark($markForIndent)]
	}
	append sql ")"
	append sql [spaceAfterRightPar]
	append sql [nlAfterRightParExpr]
}

body FormatStatement::handleSubStmt {sqlVar subStmtFmt defOrExpr} {
	upvar $sqlVar sql
	pushIndent
	set _indent 0
	set begin 0
	set end 0

	# Begin sql
	if {$defOrExpr == "def"} {
		handleLeftParDef sql
	} elseif {$defOrExpr == "defFlat"} {
		handleLeftParDefFlat sql
	} else {
		handleLeftParExpr sql
	}
	if {[regexp -- {\n\s*$} $sql]} {
		set begin 1
	}

	set indent $_indent
	# Middle sql
	set stmtSql [$subStmtFmt formatSql]

	# Ending sql
	set endSql ""
	if {$defOrExpr == "def"} {
		handleRightParDef endSql
	} elseif {$defOrExpr == "defFlat"} {
		handleRightParDefFlat endSql
	} else {
		handleRightParExpr endSql
	}
	if {[regexp -- {^\s*\n} $endSql]} {
		set end 1
	}

	# Indenting necessary lines
	set indentedSql [indentAllLinesSelectivelyBy $stmtSql $indent $begin $end]
	append sql $indentedSql
	append sql $endSql
	popIndent
}

body FormatStatement::handleSubStmtList {sqlVar subStmtFmtList defOrExpr} {
	upvar $sqlVar sql
	pushIndent
	set _indent 0
	if {$defOrExpr == "def"} {
		handleLeftParDef sql
	} elseif {$defOrExpr == "defFlat"} {
		handleLeftParDefFlat sql
	} else {
		handleLeftParExpr sql
	}
# 	if {$defOrExpr == "expr" && [cfg nl_after_open_parenthesis_expr] && [cfg ind_inside_of_parenthesis] || \
# 		$defOrExpr == "def" && [cfg nl_before_open_parenthesis_def] && [cfg ind_inside_of_parenthesis]} {
	# [string first "\n" $stmtSql] > -1 ||
# 	if {[string index [string trimright $sql " "] end] == "\n"} {
# 		append sql [indent]
# 	}
# 	}

	set sqls [list]
	foreach subStmtFmt $subStmtFmtList {
		lappend sqls [$subStmtFmt formatSql]
	}
	if {$defOrExpr == "defFlat"} {
		append sql [join $sqls "[spaceBeforeComma],[spaceAfterComma]"]
	} else {
		append sql [indentAllLinesBy [joinList $sqls $sql true] $_indent]
	}

	if {$defOrExpr == "def"} {
		handleRightParDef sql
	} elseif {$defOrExpr == "defFlat"} {
		handleRightParDefFlat sql
	} else {
		handleRightParExpr sql
	}
	popIndent
}

body FormatStatement::handleSubList {sqlVar subList doWrap defOrExpr} {
	upvar $sqlVar sql
	pushIndent
	set _indent 0
	if {$defOrExpr == "def"} {
		handleLeftParDef sql
	} else {
		handleLeftParExpr sql
	}
# 	if {$defOrExpr == "expr" && [cfg nl_after_open_parenthesis_expr] && [cfg ind_inside_of_parenthesis]} {
	# [string first "\n" $stmtSql] > -1 ||
# 	if {[string index [string trimright $sql " "] end] == "\n"} {
# 		append sql [indent]
# 	}
# 	}

	set sqla [list]
	foreach sub $subList {
		if {$doWrap} {
			lappend sqls [wrap $sub]
		} else {
			lappend sqls $sub
		}
	}
	append sql [indentAllLinesBy [joinList $sqls $sql true] $_indent]

	if {$defOrExpr == "def"} {
		handleRightParDef sql
	} else {
		handleRightParExpr sql
	}
	popIndent
}

body FormatStatement::joinList {list sql {insideOfParenthesis false}} {
	set doNlAfterComma [cfg nl_after_comma]
	set joinedList ""

	# Detecting mode
	if {$doNlAfterComma} {
		if {$insideOfParenthesis} {
			set mode "PAR_NL"
		} else {
			if {[lineup]} {
				set mode "NO_PAR_LU"
			} else {
				set mode "NO_PAR_NL"
			}
		}
	} else {
		set mode "NO_NL"
	}

	# Trimming items in list
	set tmpList [list]
	foreach item $list {
		lappend tmpList [string trim $item]
	}
	set list $tmpList
	unset tmpList

	# Joining
	switch -- $mode {
		"PAR_NL" {
			# \n after comma, indent lines
			append joinedList [join $list "[spaceBeforeComma],\n"]
		}
		"NO_PAR_LU" {
			# List outside of parenthesis, like columns for select - with lineup
			mark recentJoinMark $sql +1
			set joinStr "[spaceBeforeComma],\n[lineupFor {} recentJoinMark]"
			append joinedList [join $list $joinStr]
		}
		"NO_PAR_NL" {
			# List outside of parenthesis, like columns for select - with simple indent
			append joinedList [join $list "[spaceBeforeComma],\n[indent]"]
		}
		"NO_NL" {
			# indent lines, but no \n, so no indent
			append joinedList [join $list "[spaceBeforeComma],[spaceAfterComma]"]
		}
	}

	return $joinedList
}

body FormatStatement::listElementSql {markName sql} {
	if {[cfg ind_inside_of_parenthesis]} {
		if {[lineup]} {
			set spaces [lineupFor {} $markName]
		} else {
			set spaces [indent]
		}
		return "${spaces}[string trimleft $sql]"
	} else {
		return $sql
	}
}

body FormatStatement::logicalBlockIndent {markName lineupWord} {
	set sql ""
	if {[nlAfterLogicalBlock]} {
		append sql "\n"
		if {[lineup]} {
			append sql [lineupFor $lineupWord $markName]
		} else {
			append sql [indent]
		}
	} else {
		append sql " "
	}
	return $sql
}

###############################
# Naming
###############################

body FormatStatement::case {str} {
	if {[cfg nam_uppercase_keywords]} {
		return [string toupper $str]
	} else {
		return [string tolower $str]
	}
}

body FormatStatement::wrap {obj} {
	set originalObj $obj
	if {[isObjWrapped $obj]} {
		set obj [stripObjName $obj]
	}
	if {[cfg nam_force_wrapper] || [doObjectNeedWrapping $obj]} {
		if {[catch {
			set wrapperName [cfg nam_preffered_wrapper]
			set left [string index $wrapperName 0]
			set right [string index $wrapperName [string length [mc {name}]]]
			set favWrapper [list $left $right]
			set obj [wrapObjName $obj $_dialect $favWrapper]
		} err]} {
			if {$::DEBUG(global)} {
				puts "Couldn't wrap $obj. Error message was:\n$err"
			}
			set obj $originalObj
		}
	}
	return $obj
}

###############################
# White-spaces
###############################

body FormatStatement::spaceBeforOrAfter {varName} {
	if {[cfg $varName]} {
		return " "
	} else {
		return ""
	}
}

body FormatStatement::spaceBeforeDot {} {
	return [spaceBeforOrAfter sp_before_dot_oper]
}

body FormatStatement::spaceAfterDot {} {
	return [spaceBeforOrAfter sp_after_dot_oper]
}

body FormatStatement::spaceBeforeComma {} {
	return [spaceBeforOrAfter sp_before_comma]
}

body FormatStatement::spaceAfterComma {} {
	return [spaceBeforOrAfter sp_after_comma]
}

body FormatStatement::spaceBeforeLeftPar {} {
	return [spaceBeforOrAfter sp_before_open_parenthesis]
}

body FormatStatement::spaceAfterLeftPar {} {
	return [spaceBeforOrAfter sp_after_open_parenthesis]
}

body FormatStatement::spaceBeforeRightPar {} {
	return [spaceBeforOrAfter sp_before_close_parenthesis]
}

body FormatStatement::spaceAfterRightPar {} {
	return [spaceBeforOrAfter sp_after_close_parenthesis]
}

body FormatStatement::spaceBeforeMathOper {} {
	return [spaceBeforOrAfter sp_before_math_oper]
}

body FormatStatement::spaceAfterMathOper {} {
	return [spaceBeforOrAfter sp_after_math_oper]
}

body FormatStatement::spaceNeverBeforeSemicolon {} {
	return [cfg sp_never_before_semicolon]
}

body FormatStatement::spaceBeforeSql {sql {spaces " "}} {
	if {[string length $sql] == 0} {
		return ""
	}
	if {[regexp -- {[\s\(\,\+\-\*\/\=\%\<\>\|\&\!]} [string index $sql 0]]} {
		return ""
	}
	return $spaces
}

body FormatStatement::spaceAfterSql {sql {spaces " "}} {
	if {[string length $sql] == 0} {
		return ""
	}
	if {[regexp -- {[\s\)\,\+\-\*\/\=\%\<\>\|\&\!]} [string index $sql end]]} {
		if {[regexp -- {[\-\+][0-9]+} $sql]} {
			# Special case for expr: "xyz > -1" to avoid "abc >-1".
			return $spaces
		} else {
			return ""
		}
	}
	return $spaces
}

###############################
# New lines
###############################

body FormatStatement::nlBeforeOrAfter {varName} {
	if {[cfg $varName]} {
		return "\n"
	} else {
		return ""
	}
}

body FormatStatement::nlBeforeLeftParDef {} {
	return [nlBeforeOrAfter nl_before_open_parenthesis_def]
}

body FormatStatement::nlAfterLeftParDef {} {
	return [nlBeforeOrAfter nl_after_open_parenthesis_def]
}

body FormatStatement::nlBeforeRightParDef {} {
	return [nlBeforeOrAfter nl_before_close_parenthesis_def]
}

body FormatStatement::nlAfterRightParDef {} {
	return [nlBeforeOrAfter nl_after_close_parenthesis_def]
}

body FormatStatement::nlBeforeLeftParExpr {} {
	return [nlBeforeOrAfter nl_before_open_parenthesis_expr]
}

body FormatStatement::nlAfterLeftParExpr {} {
	return [nlBeforeOrAfter nl_after_open_parenthesis_expr]
}

body FormatStatement::nlBeforeRightParExpr {} {
	return [nlBeforeOrAfter nl_before_close_parenthesis_expr]
}

body FormatStatement::nlAfterRightParExpr {} {
	return [nlBeforeOrAfter nl_after_close_parenthesis_expr]
}

body FormatStatement::nlAfterLogicalBlock {} {
	return [cfg nl_after_logical_blocks_of_query]
}

body FormatStatement::nlAfterSemicolon {} {
	return [nlBeforeOrAfter nl_after_semicolon]
}

body FormatStatement::nlAfterComma {} {
	return [nlBeforeOrAfter nl_after_comma]
}

body FormatStatement::nlNeverBeforeSemicolon {} {
	return [cfg nl_never_before_semicolon]
}

###############################
# Indentation
###############################

body FormatStatement::indent {{value ""}} {
	if {$value != ""} {
		return [string repeat " " [expr {$_constantIndent + $value}]]
	} else {
		return [string repeat " " [expr {$_constantIndent + $_indent}]]
	}
}

body FormatStatement::incrIndent {} {
	incr _indent [cfg ind_tabsize]
}

body FormatStatement::decrIndent {} {
	incr _indent -[cfg ind_tabsize]
}

body FormatStatement::lineup {} {
	return [cfg ind_lineup]
}

body FormatStatement::parBlockIndent {} {
	return [cfg ind_parenthesis]
}

body FormatStatement::parBlockContentsIndent {} {
	return [cfg ind_inside_of_parenthesis]
}

body FormatStatement::mark {name sql {modifier 0}} {
	set line [lindex [split $sql \n] end]
	set _lineupMark($name) [string length $line]
	incr _lineupMark($name) $modifier
}

body FormatStatement::markWithIndent {name sql {modifier 0}} {
	set line [lindex [split $sql \n] end]
	set _lineupMark($name) [string length $line]
	incr _lineupMark($name) $modifier
	incr _lineupMark($name) $_indent
}

body FormatStatement::markExists {name} {
	return [info exists _lineupMark($name)]
}

body FormatStatement::lineupFor {str markName} {
	set indent [expr {$_lineupMark($markName) - [string length $str]}]
	if {$indent < 0} {
		set indent 0
	}
	return [indent $indent]
}

body FormatStatement::indentAfterOpenParDef {{value ""}} {
	if {[cfg nl_after_close_parenthesis_def]} {
		return [indent $value]
	} else {
		return ""
	}
}

body FormatStatement::indentAfterOpenParExpr {{value ""}} {
	if {[cfg nl_after_close_parenthesis_expr]} {
		return [indent $value]
	} else {
		return ""
	}
}

body FormatStatement::pushIndent {} {
	lappend _indentStack $_indent
}

body FormatStatement::popIndent {} {
	set _indent [lindex $_indentStack end]
	set _indentStack [lrange $_indentStack 0 end-1]
	if {$_indent == ""} {
		set _indent 0
	}
}

body FormatStatement::indentAllLinesToMark {sql markName} {
	return [indentAllLinesBy $sql $_lineupMark($markName)]
}

body FormatStatement::indentAllLinesBy {sql indentLength} {
	set lines [split $sql \n]
	set newSqls [list]
	foreach line $lines {
		lappend newSqls "[indent $indentLength]$line"
	}
	return [join $newSqls "\n"]
}

body FormatStatement::indentAllLinesSelectivelyBy {sql indentLength begin end} {
	set lines [split $sql \n]
	if {[llength $lines] < 2} {
		if {$begin || $end} {
			return "[indent $indentLength]$sql"
		} else {
			return $sql
		}
	}
	set newSqls [list]
	if {$begin} {
		lappend newSqls "[indent $indentLength][lindex $lines 0]"
	} else {
		lappend newSqls "[lindex $lines 0]"
	}
	foreach line [lrange $lines 1 end-1] {
		lappend newSqls "[indent $indentLength]$line"
	}
	if {$end} {
		lappend newSqls "[indent $indentLength][lindex $lines end]"
	} else {
		lappend newSqls "[lindex $lines end]"
	}
	return [join $newSqls "\n"]
}

body FormatStatement::indentAllLinesToMarkForExpr {sql markName} {
	return [indentAllLinesForExpr $sql $_lineupMark($markName)]
}

body FormatStatement::indentAllLinesForExpr {sql indentLength} {
	if {[regexp -- {^[\ \t]*\n{1}[\ \t]*.*$} $sql]} {
		set indentedLines [indentAllLinesBy $sql $indentLength]
		return [string trim $indentedLines " "]
	} else {
		set startingSpaces [lindex [regexp -inline {^\s*} $sql] 0]
		set indentedLines [indentAllLinesBy $sql $indentLength]
		return "$startingSpaces[string trimleft $indentedLines { }]"
	}
}
