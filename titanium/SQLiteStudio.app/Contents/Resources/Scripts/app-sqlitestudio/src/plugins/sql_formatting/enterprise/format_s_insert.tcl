use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatStatementInsert {
	inherit FormatStatement

	constructor {obj} {
		FormatStatement::constructor $obj
	} {}
	
	public {
		method formatSql {}
	}
}

body FormatStatementInsert::formatSql {} {
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
	
	if {[get defaultValues]} {
		append sql " "
		append sql [case "DEFAULT VALUES"]
	} else {
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
			mark beforeValues $sql
			append sql [case "VALUES"]

			set valList [getListValue columnValues]
			if {[llength $valList] > 0} {
				set cnt 0
				foreach singleValList $valList {
					if {$cnt > 0} {
						set sql [string trimright $sql] ;# there's no "nl before comma" option, so this seems to be right for now
						append sql "[spaceBeforeComma],[spaceAfterComma][nlAfterComma]"
						if {[cfg nl_after_comma]} {
							append sql [listElementSql beforeValues ""]
						}
					}

					set valFmts [list]
					foreach val $singleValList {
						set valFmt [createFormatStatement $val]
						lappend valFmts $valFmt
					}
					handleSubStmtList sql $valFmts def
					incr cnt
				}
			} else {
				error "No subselect or values list during formatting INSERT. This should never happen. Please report it and include INSERT sql that you were trying to format."
			}
		}
	}

	return $sql
}
