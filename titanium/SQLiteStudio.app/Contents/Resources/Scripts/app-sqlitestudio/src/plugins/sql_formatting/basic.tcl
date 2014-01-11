class BasicSqlFormattingPlugin {
	inherit SqlFormattingPlugin

	common keywords [string tolower $::KEYWORDS]
	common reduceWhitespaces 1
	common uppercaseKeywords 1
	common whiteSpaceAfterBracket 1
	common keepNewLines 1

	common checkState

	private {
		method formatCreateTableDdl {txt}
	}

	public {
		method formatSql {tokenizedQuery originalQuery {db ""}}
		proc getName {}
		proc createConfigUI {path}
		proc applyConfig {path}
		proc configurable {}
		proc init {} {}
	}
}


body BasicSqlFormattingPlugin::formatSql {tokenizedQuery originalQuery {db ""}} {
	set queries [SqlUtils::splitSqlQueries $originalQuery]
	set sqls [list]
	foreach query $queries {
		set out ""

		# CREATE TABLE DDL
# 		if {[regexp -- {CREATE\s+(TEMP\s+|TEMPORARY\s+)?TABLE.*} $query]} {
# 			return [formatCreateTableDdl $query]
# 		}

		# Default formatting
		foreach token [SqlUtils::stringTokenize $query] {
			lassign $token type contents
			if {$reduceWhitespaces && $type == "SQL"} {
				set tokenOut $contents
				if {!$keepNewLines} {
					regsub -all -- {\n} $tokenOut " " tokenOut
				}
				regsub -all -- {[ \t]+} $tokenOut " " tokenOut
			} else {
				set tokenOut $contents
			}

			# Keywords
			if {$uppercaseKeywords} {
				set validChars {\s\(\)\[\]\<\>\.\+\=\"\/\*\%\-\r\n,\;}
				set tokenOut [string tolower $tokenOut]
				foreach w $keywords {
					set indices ""
					regsub -all -- "(\[$validChars]{1})${w}(\[$validChars]{1})" $tokenOut "\\1[string toupper $w]\\2" tokenOut
					regsub -all -- "^${w}(\[$validChars]{1})" $tokenOut "[string toupper $w]\\1" tokenOut
					regsub -all -- "^${w}$" $tokenOut "[string toupper $w]" tokenOut
					regsub -all -- "(\[$validChars]{1})${w}\$" $tokenOut "\\1[string toupper $w]" tokenOut
				}
			}
			lappend out $tokenOut
		}

		if {$whiteSpaceAfterBracket} {
			#regsub -all {(\w)\(} $out {\1 (} out - SQL function calls shouldn't be splitted by space
			regsub -all {\)(\w)} $out {) \1} out
		}
		lappend sqls [join $out " "]
	}
	return [join $sqls "\n"]
}

body BasicSqlFormattingPlugin::getName {} {
	return "Basic"
}

body BasicSqlFormattingPlugin::formatCreateTableDdl {txt} {
	set indent 0
	set buf ""
	set wasN 0
	set apo 0
	set remSpace 0
	regsub -all -- {\n} $txt "" txt
	regsub -all -- {(\s)\s+} $txt {\1} txt
	foreach c [split $txt ""] {
		switch -- $c {
			"(" {
				if {$apo} {
					append buf "("
				} else {
					set i [string repeat " " [expr {$indent*4}]]
					append buf "\n$i\(\n"
					incr indent
					set i [string repeat " " [expr {$indent*4}]]
					append buf "$i"
					set remSpace 1
				}
			}
			")" {
				if {$apo} {
					append buf ")"
				} else {
					incr indent -1
					set i [string repeat " " [expr {$indent*4}]]
					append buf "\n$i\)"
					set remSpace 1
				}
			}
			"'" {
				set apo [expr {!$apo}]
				append buf "'"
			}
			"," {
				if {$apo} {
					append buf ","
				} else {
					set i [string repeat " " [expr {$indent*4}]]
					append buf ",\n$i"
					set remSpace 1
				}
			}
			default {
				if {[string index $buf end] == ")"} {
					set i [string repeat " " [expr {$indent*4}]]
					append buf "\n$i"
				}
				if {!$remSpace || $c != " "} {
					append buf $c
				}
				set remSpace 0
			}
		}
	}
	return $buf
}

body BasicSqlFormattingPlugin::createConfigUI {path} {
	ttk::frame $path.reduce
	ttk::checkbutton $path.reduce.c -text [mc {Reduce group of whitespaces into one whitespace.}] -variable ::BasicSqlFormattingPlugin::checkState(reduce)
	pack $path.reduce.c -side left
	pack $path.reduce -side top -fill x

	ttk::frame $path.upper
	ttk::checkbutton $path.upper.c -text [mc {Uppercase keywords.}] -variable ::BasicSqlFormattingPlugin::checkState(upper)
	pack $path.upper.c -side left
	pack $path.upper -side top -fill x

	ttk::frame $path.whitespace
	ttk::checkbutton $path.whitespace.c -text [mc {Separate ")" and after contents with single whitespace.}] -variable ::BasicSqlFormattingPlugin::checkState(whitespace)
	pack $path.whitespace.c -side left
	pack $path.whitespace -side top -fill x

	foreach realVar {reduceWhitespaces uppercaseKeywords whiteSpaceAfterBracket} arrIdx {reduce upper whitespace} {
		set checkState($arrIdx) [set $realVar]
	}
}

body BasicSqlFormattingPlugin::applyConfig {path} {
	foreach realVar {reduceWhitespaces uppercaseKeywords whiteSpaceAfterBracket} arrIdx {reduce upper whitespace} {
		set $realVar $checkState($arrIdx)
	}
	set lst [list]
	foreach var {reduceWhitespaces uppercaseKeywords whiteSpaceAfterBracket} {
		lappend lst ::BasicSqlFormattingPlugin::$var
		lappend lst [set ::BasicSqlFormattingPlugin::$var]
	}
	CfgWin::save $lst
}

body BasicSqlFormattingPlugin::configurable {} {
	return true
}
