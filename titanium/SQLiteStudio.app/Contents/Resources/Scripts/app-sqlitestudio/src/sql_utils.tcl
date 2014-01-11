#>
# @class SqlUtils
# This class contains various useful utils to process SQLs.
#<
class SqlUtils {
	public {
		#>
		# @method removeComments
		# @param str SQL query to be modified.
		# @param idx Cursor index.
		# Removes any comments from SQL query. Result is tidy SQL query.
		# @return If <i>idx</i> is given, then returns list of two elements: first is SQL query without comments,
		# second is new index caluculated after excluding any comments. If no <i>idx</i> is given,
		# then returns only SQL query without comments (not in list, just one element).
		#<
		proc removeComments {str {idx -1}}

		#>
		# @method stringTokenize
		# @param str SQL string to tokenize.
		# Create tokens from given SQL string. Each token has type, one of <code>STR</code> or <code>SQL</code>,
		# which defines if the token contains pure SQL code, or ordinary string used in SQL.
		# @return List, where each element is a sublist with 2 elements: type and contents.
		#<
		proc stringTokenize {str}

		#>
		# @method splitSqlQueries
		# @param str SQL string to split into list.
		# Splits input SQL string in to list of SQL query strings. This method doesn't support comments,
		# so input MUST be processed by {@method removeComments} before calling this method.
		# @return List of queries.
		#<
		proc splitSqlQueries {str {dialect "sqlite3"}}

		#>
		# @method splitSqlArgs
		# @param str String with parameters to split.
		# Splits SQL arguments (list of columns, list of values, etc) into list. Separator (,) is removed.
		# @return List of arguments.
		#<
		proc splitSqlArgs {str}
	}
}

body SqlUtils::removeComments {str {idx -1}} {
	set res ""         ;# results buffer
	set minus 0         ;# -- detection switch
	set quot 0         ;# '' quotes switch
	set commentStart 0   ;# /* detection switch
	set commentEnd 0   ;# */ detection switch
	set minusCmnt 0      ;# -- comments switch
	set cmnt 0         ;# /**/ comments switch
	set cidx 0         ;# Current character index
	set foundIdx 0      ;# new index found switch
	foreach c [split $str ""] {
		switch -- $c {
			"'" {
				if {!$cmnt && !$minusCmnt} {
					set quot [expr {!$quot}]
					set minus 0
					set commentStart 0
					set commentEnd 0
					append res $c
				}
			}
			"-" {
				if {!$cmnt && !$minusCmnt} {
					if {$quot} {
						append res $c
					} else {
						if {$minus == 0} {
							incr minus
							append res $c
						} else {
							set minusCmnt 1
							set res [string range $res 0 end-1]
						}
						set commentStart 0
						set commentEnd 0
					}
				}
			}
			"/" {
				if {!$minusCmnt} {
					if {$quot} {
						append res $c
					} else {
						if {$cmnt && $commentEnd == 1} {
							set cmnt 0
							set commentStart 0
							set commentEnd 0
						} elseif {!$cmnt && $commentStart == 0} {
							set commentStart 1
							set commentEnd 0
							append res $c
						} else {
							append res $c
						}
					}
				}
			}
			"*" {
				if {!$minusCmnt} {
					if {$quot} {
						append res $c
					} else {
						if {$cmnt && $commentEnd == 0} {
							set commentStart 0
							set commentEnd 1
						} elseif {!$cmnt && $commentStart == 1} {
							set cmnt 1
							set commentStart 0
							set commentEnd 0
							set res [string range $res 0 end-1]
						} else {
							append res $c
						}
					}
				}
			}
			"\n" {
				if {$quot} {
					append res $c
				} else {
					set minus 0
					set minusCmnt 0
					set commentStart 0
					set commentEnd 0
					append res $c
				}
			}
			default {
				if {!$cmnt && !$minusCmnt} {
					append res $c
				}
				set minus 0
				set commentStart 0
				set commentEnd 0
			}
		}
		if {$idx > -1 && $idx == $cidx && !$foundIdx} {
			set idx [string length $res]
			set foundIdx 1
		}
		incr cidx
	}
	if {$idx > -1} {
		return [list $res $idx]
	} else {
		return $res
	}
}

body SqlUtils::stringTokenize {str} {
	set tokens [list]
	set quot 0
	set buff ""
	foreach c [split $str ""] {
		if {$c == "'"} {
			if {$quot} {
				append buff $c
				lappend tokens [list STR $buff]
				set buff ""
				set quot 0
			} else {
				lappend tokens [list SQL $buff]
				set buff $c
				set quot 1
			}
		} else {
			append buff $c
		}
	}
	if {$buff != ""} {
		if {$quot} {
			lappend tokens [list STR $buff]
		} else {
			lappend tokens [list SQL $buff]
		}
	}

	return $tokens
}

body SqlUtils::splitSqlArgs {str} {
	set apo 0
	set buf ""
	set depth 0
	set depthSquare 0
	set args [list]
	foreach c [split $str ""] {
		switch -- $c {
			"'" {
				set apo [expr {!$apo}]
				append buf $c
			}
			"(" {
				if {!$apo} {
					incr depth
				}
				append buf $c
			}
			")" {
				if {!$apo} {
					incr depth -1
				}
				append buf $c
			}
			"[" {
				if {!$apo} {
					incr depthSquare
				}
				append buf $c
			}
			"]" {
				if {!$apo} {
					incr depthSquare -1
				}
				append buf $c
			}
			"," {
				if {!$apo && $depth == 0 && $depthSquare == 0} {
					lappend args [string trim $buf]
					set buf ""
				} else {
					append buf $c
				}
			}
			default {
				append buf $c
			}
		}
	}
	if {[string trim $buf] != ""} {
		lappend args [string trim $buf]
	}
	return $args
}

body SqlUtils::splitSqlQueries {str {dialect "sqlite3"}} {
	set sqls [list]
	set lexer [Lexer ::#auto $dialect]
	$lexer configure -supportNewLines 1
	set out [$lexer tokenizeSql $str]
	if {[dict get $out returnCode] != 0} {
		error "Cannot tokenize sql: $str"
	}
	set tokens [dict get $out tokens]
	delete object $lexer
	foreach tokenList [Lexer::splitStatements $tokens] {
		lappend sqls [Lexer::detokenize $tokenList]
	}
	return $sqls
}
