use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatement2Insert {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}
	
	public {
		method formatSql {}
	}
}

body FormatStatement2Insert::formatSql {} {
	set sql ""

	# INSERT OR action / REPLACE
	if {[get replaceKeyword]} {
		append sql [case "REPLACE"]
	} else {
		append sql [case "INSERT"]
		mark atUpdate $sql
		mark afterUpdate $sql +1
		if {[get orAction] != ""} {
			append sql " "
			append sql [case "OR"]
			append sql " "
			append sql [case [getValue orAction]]
		}
	}
	append sql " "
	append sql [case "INTO"]

	# Table name
	append sql " "
	if {[get databaseName] != ""} {
		append sql [wrap [getValue databaseName]]
		append sql "[spaceBeforeDot].[spaceAfterDot]"
	}
	append sql [wrap [getValue tableName]]
	
	# Col list
	set colNames [getListValue columnNames]
	if {[llength $colNames] > 0} {
		handleSubList sql $colNames true def
	}

	# Subselect or val list
	append sql [spaceAfterSql $sql]
	if {[get subSelect] != ""} {
		# Subselect
		set subSelect [getValue subSelect]
		set subSelectFmt [createFormatStatement $subSelect]
		append sql [$subSelectFmt formatSql]
	} else {
		# Values list
		append sql [case "VALUES"]

		set valList [getListValue columnValues]
		if {[llength $valList] > 0} {
			set valFmts [list]
			foreach val $valList {
				set valFmt [createFormatStatement $val]
				lappend valFmts $valFmt
			}
			handleSubStmtList sql $valFmts def
		} else {
			error "No subselect or values list during formatting INSERT. This should never happen. Please report it and include INSERT sql that you were trying to format."
		}
	}

	return $sql
}
