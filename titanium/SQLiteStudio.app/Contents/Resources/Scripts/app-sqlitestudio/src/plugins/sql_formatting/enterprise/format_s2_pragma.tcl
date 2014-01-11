use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatement2Pragma {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

class FormatStatement2PragmaValue {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

body FormatStatement2Pragma::formatSql {} {
	set sql ""

	append sql [case "PRAGMA "]
	if {[get databaseName] != ""} {
		append sql [wrap [getValue databaseName]]
		append sql "[spaceBeforeDot].[spaceAfterDot]"
	}
	append sql [wrap [getValue pragmaName]]

	set pragmaVal [getValue pragmaValue]

	if {$pragmaVal != ""} {
		set pragmaFmt [createFormatStatement $pragmaVal]
		set pragmaSql [$pragmaFmt formatSql]
	} else {
		set pragmaSql ""
	}

	if {[get equalOperator]} {
		# pragma = val
		append sql [spaceBeforeMathOper]
		append sql "="
		append sql [spaceAfterMathOper]
		append sql $pragmaSql
	} elseif {[get parenthesis]} {
		# pragma(val)

		# Left par
		pushIndent
		set _indent 0
		handleLeftParExprFunc sql

		if {[cfg nl_after_open_parenthesis_expr]} {
			append sql [indent]
		}
		append sql $pragmaSql

		# Right par
		handleRightParExpr sql
		popIndent
	}

	return $sql
}

body FormatStatement2PragmaValue::formatSql {} {
	set sql ""

	if {[get signedNumber] != ""} {
		append sql [getValue signedNumber]
	} elseif {[get stringLiteral] != ""} {
		append sql [getValue stringLiteral]
	} else {
		append sql [wrap [getValue name]]
	}

	return $sql
}
