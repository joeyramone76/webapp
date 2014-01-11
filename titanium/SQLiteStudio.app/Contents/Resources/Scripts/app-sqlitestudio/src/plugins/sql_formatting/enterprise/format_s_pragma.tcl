use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatementPragma {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

class FormatStatementPragmaValue {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}

	public {
		method formatSql {}
	}
}

body FormatStatementPragma::formatSql {} {
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

body FormatStatementPragmaValue::formatSql {} {
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
