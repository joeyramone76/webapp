#set ::RE(table_or_column) {(\S+|'[^']+'|[\[\"][^\]\(\)]+[\]\"]|[^\s\(\)]+)}
set ::RE(table_or_column) [string map [list " " "" "\n" "" "\t" ""] {
	(
		\S+
	|
		\"[^\"]+\"
	|
		\[[^\]]+\]
	|
		\'[^\']+\'
	|
		[^\s]+
	)
}]

set ::RE(table_or_column_only) [string range $::RE(table_or_column) 0 end-1]
append ::RE(table_or_column_only) [string map [list " " "" "\n" "" "\t" ""] {
	|
		[^\.]+
	)
}]

set ::RE(sql_string) {('[^']+'|\S+)}
set ::RE(sql_number) {[\-\+]?(\d+(\.\d+)?|\.\d+)([eE][\+\-]\d+)?}

set ::RE(pk) {(?i)(CONSTRAINT\s+}
append ::RE(pk) $::RE(table_or_column)
append ::RE(pk) {\s+)?PRIMARY\s+KEY\s*\((.*)\)(\s*ON\s+CONFLICT\s+(\S+))?}

set ::RE(uniq) {(?i)(CONSTRAINT\s+}
append ::RE(uniq) $::RE(table_or_column)
append ::RE(uniq) {\s+)?UNIQUE\s*\((.*)\)(\s*ON\s+CONFLICT\s+(\S+))?}

set ::RE(fk) {(?i)(CONSTRAINT\s+}
append ::RE(fk) $::RE(table_or_column)
append ::RE(fk) {\s+)?FOREIGN\s+KEY\s*\((.*)\)\s*REFERENCES\s+}
append ::RE(fk) $::RE(table_or_column)
append ::RE(fk) {\s*\((.*)\)}
append ::RE(fk) {(\s*(ON\s+DELETE|ON\s+UPDATE|ON\s+INSERT)\s*(SET\s+NULL|SET\s+DEFAULT|CASCADE|RESTRICT)|.{0})}
append ::RE(fk) {(\s*(ON\s+DELETE|ON\s+UPDATE|ON\s+INSERT)\s*(SET\s+NULL|SET\s+DEFAULT|CASCADE|RESTRICT)|.{0})}

set ::RE(check) {(?i)(CONSTRAINT\s+}
append ::RE(check) $::RE(table_or_column)
append ::RE(check) {\s+)?CHECK\s*\((.*)\)}

set ::RE(trigger) {(?i)CREATE\s+TRIGGER\s+(IF\s+NOT\s+EXISTS\s+)?}
append ::RE(trigger) $::RE(table_or_column)
append ::RE(trigger) {\s*(BEFORE|AFTER|INSTEAD\s+OF)?\s+}
append ::RE(trigger) {\s*(DELETE|INSERT|UPDATE|UPDATE\s+OF\s+.*)\s+}
append ::RE(trigger) {\s*ON\s+%COL%\s+.*}
set ::RE(trigger) [string map [list %COL% $::RE(table_or_column)] $::RE(trigger)]

# This one requires (?x)
set ::RE(function) {
	\S+ \s* \(
		# First argument
		(
			[^\)\s]+ |
			\[[^\]]+\] |
			\'(\'\'|[^\']*)*\' |
			\"(\"\"|[^\"]*)*\"
		)?
		# More arguments
		(
			\s* \, \s*
			(
				[^\)\s]+ |
				\[[^\]]+\] |
				\'(\'\'|[^\']*)*\' |
				\"(\"\"|[^\"]*)*\"
			)
		)*
	\)
}


if {$::DEBUG(re)} {
	parray ::RE
}

proc isSqlNumber {value} {
	regexp -- "^$::RE(sql_number)\$" $value
}

proc parseSqlColumns {sql} {
	return [SqlUtils::splitSqlArgs $sql]
}

#>
# @proc stripColName
# @deprecated
#<
proc stripColName {colName} {
	return [stripObjName $colName]
}

proc stripObjName {objName} {
	set bounds "[string index $objName 0][string index $objName end]"
	if {$bounds in [list \[\] \"\" '' ``]} {
		return [string range $objName 1 end-1]
	} else {
		return $objName
	}
}

proc stripSqlString {str} {
	set bounds "[string index $str 0][string index $str end]"
	if {$bounds in [list '']} {
		return [string range $str 1 end-1]
	} else {
		return $str
	}
}

proc isObjWrapped {objName} {
	set bounds "[string index $objName 0][string index $objName end]"
	if {$bounds in [list \[\] \"\" '' ``]} {
		return true
	} else {
		return false
	}
}

#>
# @proc stripColListNames
# @deprecated
#<
proc stripColListNames {colList} {
	return [stripObjListNames $colList]
}

proc stripObjListNames {objList} {
	set res [list]
	foreach c $objList {
		lappend res [stripObjName $c]
	}
	return $res
}

proc getQuoteCharacter {obj dialect {favWrapper ""}} {
	switch -- $dialect {
		"sqlite3" {
			set charList [list \[\] \" ` ']
			set quoteList [list [list \[ \]] [list \" \"] [list ` `] [list ' ']]
		}
		"sqlite2" {
			set charList [list \[\] \" ']
			set quoteList [list [list \[ \]] [list \" \"] [list ' ']]
		}
		default {
			error "Unsupported dialect: $dialect"
		}
	}

	if {$favWrapper != ""} {
		set idx [lsearch -exact $quoteList $favWrapper]
		if {$idx > -1} {
			# Putting favourized wrapper in front of list
			set char [lindex $charList $idx]
			set quote [lindex $quoteList $idx]
			set charList [linsert [lreplace $charList $idx $idx] 0 $char]
			set quoteList [linsert [lreplace $quoteList $idx $idx] 0 $quote]
		}
	}

	foreach chars $charList quote $quoteList {
		set found 0
		foreach char [split $chars ""] {
			if {[string first $char $obj] > -1} {
				set found 1
				break
			}
		}
		if {!$found} {
			return $quote
		}
	}
	return ""
}

proc wrapObjName {obj dialect {favWrapper ""}} {
	set quote [getQuoteCharacter $obj $dialect $favWrapper]
	if {$quote == ""} {
		error "No quote character possible for object name: $obj" $obj $::ERRORCODE(noQuoteCharacterPossible)
	}
	lassign $quote open close
	return "$open$obj$close"
}

proc wrapColNames {colList dialect} {
	return [wrapObjNames $colList $dialect]
}

proc wrapObjNames {objList dialect} {
	set res [list]
	foreach o $objList {
		lappend res [wrapObjName $o $dialect]
	}
	return $res
}

proc wrapString {str} {
	return "'[string map [list ' ''] $str]'"
}

proc wrapStringIfNeeded {str} {
	if {[string index $str 0] == "'" && [string index $str end] == "'"} {
		return $str
	}
	return [wrapString $str]
}

proc wrapObjIfNeeded {obj dialect {favWrapper ""}} {
	if {[doObjectNeedWrapping $obj]} {
		return [wrapObjName $obj $dialect $favWrapper]
	} else {
		return $obj
	}
}

proc getObjectFromPath {dbAndObject} {
	set apo 0
	set quot 0
	set brac 0
	set hasSecond 0
	foreach c [split $dbAndObject ""] {
		switch -- $c {
			"'" {
				set apo [expr {!$apo}]
			}
			"\"" {
				set quot [expr {!$quot}]
			}
			"\[" {
				set brac 1
			}
			"]" {
				set brac 0
			}
			"." {
				if {!$apo} {
					set hasSecond 1
				}
			}
		}
	}
	if {!$hasSecond} {
		return $dbAndObject
	} else {
		set buf ""
		set apo 0
		set quot 0
		set brac 0
		set second 0
		foreach c [split $dbAndObject ""] {
			switch -- $c {
				"'" {
					set apo [expr {!$apo}]
					if {$second} {
						append buf $c
					}
				}
				"\"" {
					set quot [expr {!$quot}]
					if {$second} {
						append buf $c
					}
				}
				"\[" {
					set brac 1
					if {$second} {
						append buf $c
					}
				}
				"]" {
					set brac 0
					if {$second} {
						append buf $c
					}
				}
				"." {
					if {!$apo && !$quot && !$brac} {
						set second 1
					} elseif {$second} {
						append buf $c
					}
				}
				default {
					if {$second} {
						append buf $c
					}
				}
			}
		}
		return $buf
	}
}

#>
# @proc splitSqlObjectsFromPath
# @path path Objects path, like dbName.table.column.
# @return Splitted path, like dbName table column.
#<
proc splitSqlObjectsFromPath {path} {
	set resList [list]
	set buf ""
	set apo 0
	set quot 0
	set brac 0
	foreach c [split $path ""] {
		switch -- $c {
			"'" {
				set apo [expr {!$apo}]
				append buf $c
			}
			"\"" {
				set quot [expr {!$quot}]
				append buf $c
			}
			"\[" {
				set brac 1
				append buf $c
			}
			"]" {
				set brac 0
				append buf $c
			}
			"." {
				if {!$apo && !$quot && !$brac} {
					lappend resList [stripColName [string trim $buf]]
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
		lappend resList [stripColName [string trim $buf]]
	}
	return $resList
}

proc doObjectNeedWrapping {object} {
	set upper [string toupper $object]
	return [expr {
		[regexp -- {[\s\[\]\(\)\$\"\'\@\*\.\,\+\-\=\/\%\&\|\:]{1}} $object]
		||
		[string is digit [string index $object 0]]
		||
		$upper in $::PARSABLE_KEYWORDS_SQLite2
		||
		$upper in $::PARSABLE_KEYWORDS_SQLite3
	}]
}

#>
# @proc encode
# @param str String to encode.
# Encodes string to be stored in database to proper charset.
# Currently does nothing. It's just a socket to plug in some routines, for future.
# @return Unchanged string.
# @see method decode
#<
proc encode {str} {
	return $str
}

#>
# @proc decode
# @param str String to decode.
# Decodes string read from database.
# Currently does nothing. It's just a socket to plug in some routines, for future.
# @return Unchanged string.
# @see method encode
#<
proc decode {str} {
	return $str
}

#>
# @proc encodeExport
# @param str String to encode.
# Encodes string to be used in exported HTML or other format that uses unified charset.
# String is encoded into UTF-8.
# @return UTF-8 encoded string.
#<
proc encodeExport {str} {
	return [encoding convertto utf-8 $str]
}

proc checkDialogSupport {parsedDict sql} {
	if {[dict get $parsedDict returnCode] != 0} {
		Error [mc "Cannot open dialog, because requested object DDL code is not supported by this version of SQLiteStudio. Details:\n" [join [dict get $parsedDict errors] "\n"]]
		error "Unsupported DDL: $sql"
	}
}

proc collation_needed {db collationName} {
	$db collate $collationName no_collate
}
proc no_collate {1 2} {
	return [string compare -nocase $1 $2]
}

proc escapeSqlString {str} {
	string map [list "'" "''"] $str
}

proc convertTransactionsToSavepoints {sql dialect {async false}} {
	if {$async} {
		set id [tpool::post $::PARSER_POOL [list convertTransactionsToSavepoints $sql $dialect]]
		tpool::wait $::PARSER_POOL $id
		return [tpool::get $::PARSER_POOL $id]
	}

	set lexer [Lexer ::#auto $dialect]
	set tokens [dict get [$lexer tokenizeSql $sql] tokens]
	delete object $lexer
	
	set transName "SQLiteStudio_transaction"

	set newStatements [list]
	set tokenizedStatements [Lexer::splitStatements $tokens]
	foreach stmt $tokenizedStatements {
		set firstToken [lindex $stmt 0]
		set type [lindex $firstToken 0]
		if {$type != "KEYWORD"} continue
		set value [lindex $firstToken 1]
		set newStmt ""
		switch -- [string toupper $value] {
			"BEGIN" {
				set newStmt [list [list KEYWORD SAVEPOINT 0 0] [list STRING '$transName' 0 0]]
			}
			"END" - "COMMIT" {
				set newStmt [list [list KEYWORD RELEASE 0 0] [list STRING '$transName' 0 0]]
			}
			"ROLLBACK" {
				set lgt [llength $stmt]
				if {$lgt <= 2} {
					set newStmt [list [list KEYWORD ROLLBACK 0 0] [list KEYWORD TO 0 0] [list STRING '$transName' 0 0]]
				}
			}
		}
		if {$newStmt != ""} {
			lappend newStmt [list OPERATOR ";" 0 0]
			lappend newStatements $newStmt
		} else {
			lappend stmt [list OPERATOR ";" 0 0]
			lappend newStatements $stmt
		}
	}
	set tokens [join $newStatements " "]
	set sql [Lexer::detokenize $tokens]
	return $sql
}
