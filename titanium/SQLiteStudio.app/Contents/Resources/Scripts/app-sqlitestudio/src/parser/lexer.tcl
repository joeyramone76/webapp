#>
# @class Lexer
# Lexer is also known as tokenizer. Produces set o tokens using internal rules and passed data.
# There's no need to use it manually for parsing SQL. The {@class Parser2} and {@class Parser3} create proper
# lexer instance by itself.
#<
class Lexer {
	#>
	# @method constructor
	# @param dialect SQL dialect. Currently <code>sqlite3</code> or <code>sqlite2</code>.
	#<
	constructor {dialect} {}

	protected {
		#>
		# @var _dialect
		# Given in constructor. Currently <code>sqlite3</code> or <code>sqlite2</code>.
		#<
		variable _dialect ""

		#>
		# @method tokenizerAppendBuffer
		# @param char Character to append.
		# Appends given character to tokenizer internal buffer.
		# Takes care about defining token begin index.
		#<
		method tokenizerAppendBuffer {char}

		#>
		# @method flushTokenizerBuffer
		# Flushed current tokenizer buffer determinating buffer content type.
		#<
		method flushTokenizerBuffer {}
	}

	public {
		variable supportNewLines 0

		#>
		# @method splitStatements
		# @param tokens Set of tokens from {@class Lexer}.
		# @param index Unsigned integer, or empty string. It's optional (default empty).
		# Splits list of tokens into list of lists. Each list represents single statement.
		# Operator '\;' tokens which splits statements are removed from tokens.
		# <br>
		# <br>
		# If <i>index</i> is given, then only one statement is returned, which the index is enclosed in.
		# @return List of statements (0 or more). Each statement is a list of tokens.
		#<
		proc splitStatements {tokens {index ""}}

		#>
		# @method tokenizeSql
		# @param sql SQL code to tokenize.
		# @param index Unsigned integer or empty. It's optional (default empty).
		# Takes SQL code and converts it to set of tokens so they can be used with SQL parser.
		# Each token is list of 2 elements:
		# {token_type value}
		# Token types: <code>KEYWORD, STRING, INTEGER, FLOAT, PAR_LEFT, PAR_RIGHT, OPERATOR, OTHER, BIND_PARAM, COMMENT</code>.<br>
		# <code>PAR_LEFT</code> and <code>PAR_RIGHT</code> steands for parenthesis like '(', ')'.<br>
		# <code>OPERATOR</code> includes math operators and a semi-colon, a dot, a period, and a quote.
		# <br><br>
		# If <i>index</i> is given, then only one statement is tokenized and returned in results -the one which <i>index</i> is enclosed in.
		# <br><br>
		# Tokenizing process is done by tools formally known as lexers.
		# @return Dictionary with keywords:
		# <ul>
		# <li><code>returnCode</code> - 0 on success, other on error.
		# <li><code>errorMessage</code> - message of error in case of <code>returnCode != 0</code>.
		# <li><code>errorPosition</code> - Character position in given <i>sql</i> that error occured on.
		# <li><code>tokens</code> - empty in case of error
		# </ul>
		#<
		method tokenizeSql {sql {index ""}}

		#>
		# @method getLastTokenPartialValueFromSql
		# @param sql SQL code to tokenize.
		# @param index Unsigned integer.
		# Tokenizes SQL, then looks for last token until <i>index</i>, then extracts the part of this token
		# from start to character at <i>index</i>.<br>
		# It supports multiple statements as SQL, since it uses {@method tokenizeSql} for initial tokenization.
		# @return Dictionary with 2 keys: returnCode and value. Return code equal to 0 means that value contains partial value. Code equal to 1 means that no token was matched against given index.
		#<
		method getLastTokenPartialValueFromSql {sql index}

		#>
		# @method detokenize
		# @param tokens Token list, as from {@method tokenizeSql}.
		# Goes back from tokens to plain SQL.
		# @return SQL from tokens.
		#<
		proc detokenize {tokens}
	}
}

#>
# @class Lexer3
# Shortcut class for {@class Lexer} with <code>sqlite3</code> dialect.
#<
class Lexer3 {
	inherit Lexer
	constructor {} {Lexer::constructor sqlite3} {}
}

#>
# @class Lexer2
# Shortcut class for {@class Lexer} with <code>sqlite2</code> dialect.
#<
class Lexer2 {
	inherit Lexer
	constructor {} {Lexer::constructor sqlite2} {}
}

body Lexer::constructor {dialect} {
	set _dialect $dialect
}

body Lexer::tokenizeSql {sql {index ""}} {
	set string 0 ;# true/false is currently buffered token is string
	set buf "" ;# buffer for current, unflushed token
	set number 0 ;# true/false - if buffered token looks like number so far
	set comment 0 ;# Value 1 means it's "/* c-like comment */", number 2 means it's "-- sql like comment"
	set tokens [list] ;# list of tokens already flushed
	set tokenBegin "" ;# contains begin index for buffered token
	set tokenEnd "" ;# contains end index for buffered token
	set quotedObject 0 ;# SQLite names enclosed in [] or "". Value 1 means [], value 2 means "".

	set result [dict create returnCode 0 errorMessage "" errorPosition 0 tokens ""]

	set lgt [string length $sql]
	for {set i 0} {$i < $lgt} {incr i} {
		set c [string index $sql $i]
		if {$string} {
			# In STRING mode.
			if {$c == "'"} {
				set next [string index $sql [expr {$i+1}]]
				if {$next == "'"} {
					# Just quoting '
					tokenizerAppendBuffer "''"
					incr i
				} else {
					# End of string
					tokenizerAppendBuffer "'"
					lappend tokens [list "STRING" $buf $tokenBegin $i]
					set buf ""
					set string 0

					set tokenBegin ""
					set tokenEnd ""
				}
			} else {
				tokenizerAppendBuffer $c
			}
		} elseif {$comment} {
			# In COMMENT quoting mode
			tokenizerAppendBuffer $c
			switch -- $comment {
				"1" {
					# C-like comment
					set next [string index $sql [expr {$i+1}]]
					if {$c == "*" && $next == "/"} {
						# End of comment.
						tokenizerAppendBuffer $next
						lappend tokens [list "COMMENT" $buf $tokenBegin $i]
						set buf ""
						set comment 0

						set tokenBegin ""
						set tokenEnd ""
						incr i
					}
				}
				"2" {
					# SQL-like comment
					if {$c == "\n"} {
						# End of comment.
						#
						# Ignoring \n - it's useless for comment token
						# Since \n was already added, we need to remove it now
						set buf [string range $buf 0 end-1]
						lappend tokens [list "COMMENT" $buf $tokenBegin $i]
						set buf ""
						set comment 0

						set tokenBegin ""
						set tokenEnd ""
					}
				}
				default {
					error "Unsupported comment mode: $comment"
				}
			}
		} elseif {$quotedObject > 0} {
			# In OBJECT NAME quoting mode
			tokenizerAppendBuffer $c
			if {$quotedObject == 1 && $c == "\]" || $quotedObject == 2 && $c == "\"" || $quotedObject == 3 && $c == "`"} {
				set next [string index $sql [expr {$i+1}]]
				if {$quotedObject in [list 2 3] && $next == $c} {
					# Quoted quote character (BUG 1649)
					incr i
				} else {
					# End of object name quoting
					lappend tokens [list "OTHER" $buf $tokenBegin $i]
					set buf ""
					set quotedObject 0

					set tokenBegin ""
					set tokenEnd ""
				}
			}
		} else {
			# Occurs only in non-objectquoting mode (which is handled at begining) and non-string (above, as well).
			switch -- $c {
				"'" {
					if {$buf != ""} {
						# We are starting string mode, so any contents in buffer have to be flushed
						flushTokenizerBuffer
					}
					set string 1
					tokenizerAppendBuffer $c
					set number 0
				}
				" " - "\t" - "\r" {
					flushTokenizerBuffer
				}
				"\n" {
					flushTokenizerBuffer
					if {$supportNewLines} {
						lappend tokens [list "NEW_LINE" "\n" $i $i]
						set tokenBegin ""
						set tokenEnd ""
						set number 0
					}
				}
				"(" {
					flushTokenizerBuffer
					lappend tokens [list "PAR_LEFT" "(" $i $i]
					set tokenBegin ""
					set tokenEnd ""
					set number 0
				}
				")" {
					flushTokenizerBuffer
					lappend tokens [list "PAR_RIGHT" ")" $i $i]
					set tokenBegin ""
					set tokenEnd ""
					set number 0
				}
				"\[" {
					flushTokenizerBuffer
					set buf ""
					tokenizerAppendBuffer $c
					set quotedObject 1
					set number 0
				}
				"\"" {
					flushTokenizerBuffer
					tokenizerAppendBuffer $c
					set quotedObject 2
					set number 0
				}
				"`" {
					if {$_dialect == "sqlite3"} {
						# SQLite3 allows to use `word` as identifiers
						flushTokenizerBuffer
						tokenizerAppendBuffer $c
						set quotedObject 3
					} else {
						# For SQLite2 it's just another character
						tokenizerAppendBuffer $c
					}
					set number 0
				}
				"+" - "-" {
					set next [string index $sql [expr {$i+1}]]
					if {[string equal $c "-"] && [string equal $next "-"]} {
						# Begin of comment
						flushTokenizerBuffer
						set number 0
						set comment 2
						set tokenBegin $i
						set tokenEnd ""
						tokenizerAppendBuffer $c
						tokenizerAppendBuffer $next
						incr i
					} else {
						# Regular operator
						flushTokenizerBuffer
						lappend tokens [list "OPERATOR" $c $i $i]
						set tokenBegin ""
						set tokenEnd ""
						set number 0
					}
				}
				"." {
					set next [string index $sql [expr {$i+1}]]
					if {$number} {
						# Next char in number token
						tokenizerAppendBuffer $c
					} elseif {$next != "" && [string is integer $next]} {
						set number 1
						tokenizerAppendBuffer $c
					} else {
						# Starndard operator
						flushTokenizerBuffer
						lappend tokens [list "OPERATOR" $c $i $i]
						set tokenBegin ""
						set tokenEnd ""
					}
				}
				"/" {
					flushTokenizerBuffer
					set number 0
					set next [string index $sql [expr {$i+1}]]
					if {$next =="*"} {
						# Start of comment
						set comment 1
						set tokenBegin $i
						set tokenEnd ""
						tokenizerAppendBuffer $c
						tokenizerAppendBuffer $next
						incr i
					} else {
						# Starndard operator
						lappend tokens [list "OPERATOR" $c $i $i]
						set tokenBegin ""
						set tokenEnd ""
					}
				}
				"*" - "," - ";" - "%" - "~" - "&" {
					flushTokenizerBuffer
					lappend tokens [list "OPERATOR" $c $i $i]
					set tokenBegin ""
					set tokenEnd ""
					set number 0
				}
				"<" {
					flushTokenizerBuffer
					set next [string index $sql [expr {$i+1}]]
					if {$next == "<" || $next == ">" || $next == "="} {
						# << or <> or <=
						lappend tokens [list "OPERATOR" $c$next $i [incr i]]
					} else {
						# Just <
						lappend tokens [list "OPERATOR" $c $i $i]
					}
					set tokenBegin ""
					set tokenEnd ""
					set number 0
				}
				">" {
					flushTokenizerBuffer
					set next [string index $sql [expr {$i+1}]]
					if {$next == ">" || $next == "="} {
						# >> or >=
						lappend tokens [list "OPERATOR" $c$next $i [incr i]]
					} else {
						# Just >
						lappend tokens [list "OPERATOR" $c $i $i]
					}
					set tokenBegin ""
					set tokenEnd ""
					set number 0
				}
				"|" {
					flushTokenizerBuffer
					set next [string index $sql [expr {$i+1}]]
					if {$next == "|"} {
						# ||
						lappend tokens [list "OPERATOR" $c$next $i [incr i]]
					} else {
						# |
						lappend tokens [list "OPERATOR" $c $i $i]
					}
					set tokenBegin ""
					set tokenEnd ""
					set number 0
				}
				"!" {
					flushTokenizerBuffer
					set next [string index $sql [expr {$i+1}]]
					if {$next == "="} {
						# !=
						lappend tokens [list "OPERATOR" $c$next $i [incr i]]
					} else {
						# !
						lappend tokens [list "OPERATOR" $c $i $i]
					}
					set tokenBegin ""
					set tokenEnd ""
					set number 0
				}
				"=" {
					flushTokenizerBuffer
					set next [string index $sql [expr {$i+1}]]
					if {$next == "="} {
						# ==
						lappend tokens [list "OPERATOR" $c$next $i [incr i]]
					} else {
						# =
						lappend tokens [list "OPERATOR" $c $i $i]
					}
					set tokenBegin ""
					set tokenEnd ""
					set number 0
				}
				"0" - "1" - "2" - "3" - "4" - "5" - "6" - "7" - "8" - "9" {
					if {$buf != ""} {
						# Checking what's in buffer
						set bufferBackup $buf
						set tokenBeginBackup $tokenBegin
						set tokenEndBackup $tokenEnd
						flushTokenizerBuffer
						if {[lindex $tokens end 0] ni [list "PAR_LEFT" "PAR_RIGHT" "OPERATOR"]} {
							# Not an operator before number, so we treat number as continuation of OTHER
							set tokens [lrange $tokens 0 end-1]
							set buf $bufferBackup
							set tokenBegin $tokenBeginBackup
							set tokenEnd $tokenEndBackup
						}
					}

					if {$buf == ""} {
						# We can decide if token is number only if it's not already decided = buffer is empty
						set number 1
					}
					tokenizerAppendBuffer $c
				}
				default {
					set number 0
					tokenizerAppendBuffer $c
				}
			}
		}
	}

	if {$buf != ""} {
		flushTokenizerBuffer
	}

	# Getting single statement if index was given
	if {$index != ""} {
		set tokens [splitStatements $tokens $index]
	}

	set tokens [string map [list \r \n] $tokens]
	#puts "tokens: $tokens\n\n"
	dict set result tokens $tokens
	return $result
}

body Lexer::tokenizerAppendBuffer {char} {
	upvar buf buf i i tokenBegin tokenBegin
	if {$buf == ""} {
		set tokenBegin $i
	}
	append buf $char
}

body Lexer::flushTokenizerBuffer {} {
	uplevel {
		if {$buf != ""} {
			set tokenEnd [expr {$i-1}]
			if {$string} {
				# lexer is in STRING mode and this method is called as last flush of buffer
				lappend tokens [list "STRING" $buf $tokenBegin $tokenEnd]
			} elseif {$comment} {
				# lexer is in COMMENT mode and this method is called as last flush of buffer
				lappend tokens [list "COMMENT" $buf $tokenBegin $tokenEnd]
			} elseif {[string toupper $buf] in [set ::${_dialect}::KEYWORDS]} {
				# token is in list of keywords for given dialect, so it's a KEYWORD
				lappend tokens [list "KEYWORD" [string toupper $buf] $tokenBegin $tokenEnd]
			} elseif {$number} {
				# It's number, we just need to decide if it's float or integer.
				if {[string first . $buf] > -1 && [string range $buf 0 [expr {[string first . $buf]-1}]] != $buf} {
					# Contains dot, so it's float.
					lappend tokens [list "FLOAT" $buf $tokenBegin $tokenEnd]
				} else {
					# It's integer
					lappend tokens [list "INTEGER" $buf $tokenBegin $tokenEnd]
				}
			} elseif {$_dialect == "sqlite3" && [regexp -- {^[@:$]{1}\S{1,4}} $buf] || [regexp -- {^[?]{1}\d{0,3}} $buf]} {
				# Fits for name of bind parameter for SQLite3 (?NNN, ?, :AAAA, @AAAA, $AAAA).
				lappend tokens [list "BIND_PARAM" $buf $tokenBegin $tokenEnd]
			} elseif {$_dialect == "sqlite2" && $buf == "?"} {
				# Fits for name of bind parameter for SQLite2 (?).
				lappend tokens [list "BIND_PARAM" $buf $tokenBegin $tokenEnd]
			} else {
				# Any other is database object name
				lappend tokens [list "OTHER" $buf $tokenBegin $tokenEnd]
			}
			set buf ""
			set tokenBegin ""
			set tokenEnd ""
		}
	}
}

body Lexer::getLastTokenPartialValueFromSql {sql index} {
	set resultDict [tokenizeSql $sql $index]
	if {[dict get $resultDict returnCode] != 0} {
		error "Cannot tokenize SQL for extracting token partial value!"
	}

	#incr index -1
	set tokens [dict get $resultDict tokens]
	foreach token $tokens {
		lassign $token tokenType tokenValue tokenBegin tokenEnd
		incr tokenEnd
		if {$index == $tokenEnd} {
			if {$tokenType in [list "KEYWORD" "OTHER" "STRING" "INTEGER" "FLOAT"]} {
				set val [string range $sql $tokenBegin [expr {${index}-1}]]
				return [dict create returnCode 0 value $val]
			} else {
				return [dict create returnCode 0 value ""]
			}
		} elseif {$tokenBegin <= $index && $index <= $tokenEnd} {
			set val [string range $sql $tokenBegin [expr {${index}-1}]]
			return [dict create returnCode 0 value $val]
		}
	}

	return [dict create returnCode 1 value ""]
}

body Lexer::splitStatements {tokens {index ""}} {
	if {$index != "" && (![string is integer $index] || $index < 0)} {
		error "Invalid index parameter for splitStatements: $index. Expected unsigned integer."
	}

	set statements [list]
	set currentTokens [list]
	set depth 0
	foreach token $tokens {
		lassign $token tokenType tokenValue tokenBegin tokenEnd
		if {$depth > 0} {
			lappend currentTokens $token
			if {$tokenType == "KEYWORD" && [string toupper $tokenValue] == "END"} {
				incr depth -1
			} elseif {$tokenType == "KEYWORD" && [string toupper $tokenValue] == "CASE"} {
				incr depth
			}
		} else {
			if {$tokenType == "KEYWORD" && [string toupper $tokenValue] == "BEGIN" && [llength $currentTokens] > 0} {
				lappend currentTokens $token
				incr depth
			} elseif {$tokenType == "KEYWORD" && [string toupper $tokenValue] == "CASE"} {
				lappend currentTokens $token
				incr depth
			} elseif {$tokenType == "OPERATOR" && $tokenValue == ";"} {
				if {$index != ""} {
					if {$index <= $tokenBegin} {
						# given index is placed in this statement
						return $currentTokens
					}
				}

				lappend statements $currentTokens
				set currentTokens [list]
			} else {
				lappend currentTokens $token
			}
		}
	}
	if {[llength $currentTokens] > 0} {
		if {$index != ""} {
			# given index is placed in this statement
			# There is no need to check it. If it was not found before, then it MUST be here.
			return $currentTokens
		}
		lappend statements $currentTokens
	}

	if {$index != ""} {
		return [list]
	}

	return $statements
}

body Lexer::detokenize {tokens} {
	set result ""
	foreach token $tokens {
		lassign $token type value begin end
		if {$result != "" && [string index $result end] ni [list \t \n " "]} {
			append result " "
		}
		#if {$type == "STRING" || $type == "OTHER"} ;# Removed string, because it doesn't
		# seem to make sense for string and causes bug 1916.
		if {$type == "OTHER"} {
			set c [string index $value 0]
			if {$c in [list \" ' `] && $c == [string index $value end]} {
				if {[string first $c [string range $value 1 end-1]] > -1} {
					set value "$c[string map [list $c $c$c] [string range $value 1 end-2]]$c"
				}
			}
		}
		append result $value
		if {$type == "COMMENT" && [string first "--" $value] == 0} {
			append result "\n"
		}
	}
	return $result
}
