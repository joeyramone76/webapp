class SqlConverter {
	protected {
		proc toVersion {db stmt version stmtJobScript}
		proc returnSame {stmt}

		# CREATE TABLE
		proc convertStatementCreateTableTo2 {stmt}
		proc convertStatement2CreateTableTo3 {stmt}

		# CREATE INDEX
		proc convertStatementCreateIndexTo2 {stmt}
		proc convertStatement2CreateIndexTo3 {stmt}

		# CREATE TRIGGER
		proc convertStatementCreateTriggerTo2 {stmt}
		proc convertStatement2CreateTriggerTo3 {stmt}

		# CREATE VIEW
		proc convertStatementCreateViewTo2 {stmt}
		proc convertStatement2CreateViewTo3 {stmt}
	}
	
	public {
		#>
		# @method toSqlite2
		# @param db Context database to parse object.
		# @param sql SQL to be converted.
		# @param stmtJobScript Optional script to be executed in the middle of conversion (after SQL is parsed). It's executed with statement object as argument.
		# Converts given SQL statement into SQLite2 complient syntax. Proper convert* protected method must be implemented in order for this to work.
		# @return Converted SQL.
		#<
		proc toSqlite2 {db sql {stmtJobScript ""}}

		#>
		# @method toSqlite3
		# Similar method as {@method toSqlite2}, except that target syntax is SQLite3.
		#<
		proc toSqlite3 {db sql {stmtJobScript ""}}

		proc replaceNameField {field newName stmt}
	}
}

body SqlConverter::toVersion {db sql version stmtJobScript} {
	set parser [UniversalParser ::#auto $db]
	$parser parseSql $sql
	set parsedDict [$parser get]
	if {[dict get $parsedDict returnCode] != 0} {
		debug "Could not parse object while converting SQL:\n[dict get $parsedDict errorMessage]"
		delete object $parser
		return ""
	}
	set obj [dict get $parsedDict object]
	set stmt [$obj getValue subStatement]
	set cls [string trimleft [$stmt info class] :]

	if {$stmtJobScript != "" && [catch {eval $stmtJobScript $stmt} res]} {
		debug "SQL conversion error in stmtJobScript: $res"
		delete object $parser
		return ""
	}

	if {[string first "Statement2" $cls] == 0 && $version == 2 || [string first "Statement2" $cls] == -1 && $version == 3} {
		return [returnSame $stmt]
	}

	set method convert${cls}To${version}

	if {[catch {$method $stmt} res]} {
		debug "SQL conversion error: $res"
		delete object $parser
		return ""
	}

	delete object $parser
	return $res
}

body SqlConverter::toSqlite2 {db sql {stmtJobScript ""}} {
	return [toVersion $db $sql 2 $stmtJobScript]
}

body SqlConverter::toSqlite3 {db sql {stmtJobScript ""}} {
	return [toVersion $db $sql 3 $stmtJobScript]
}

body SqlConverter::returnSame {stmt} {
	return [Lexer::detokenize [$stmt cget -allTokens]]
}

body SqlConverter::replaceNameField {field newName stmt} {
	set allTokens [$stmt cget -allTokens]

	set token [$stmt cget -$field]
	set tokenIdx [lsearch -exact $allTokens $token]
	set newToken [lreplace $token 1 1 $newName]
	
	# Replacing
	set allTokens [lreplace $allTokens $tokenIdx $tokenIdx $newToken]
	$stmt configure -$field $newName -allTokens $allTokens
}

#####################
# CREATE TABLE
body SqlConverter::convertStatementCreateTableTo2 {stmt} {
	set allTokens [$stmt cget -allTokens]

	# Table constraints
	foreach constr [$stmt cget -tableConstraints] {
		switch -- [$constr cget -branchIndex] {
			0 - 1 {
				# PK and UNIQUE
				foreach idxCol [$constr cget -indexedColumns] {
					set collationNameIdx [lsearch -exact $allTokens [$idxCol cget -collationName]]
					set collateIdx [expr {$collationNameIdx - 1}]
					set allTokens [lreplace $allTokens $collateIdx $collationNameIdx]
				}
			}
			3 {
				# FK
				set allFkTokens [$constr cget -allTokens]
				set firstIdx [lsearch -exact $allTokens [lindex $allFkTokens 0]]
				set lastIdx [expr {$firstIdx + [llength $allFkTokens] - 1}]
				set allTokens [lreplace $allTokens $firstIdx $lastIdx]
			}
		}
	}

	# Columns
	foreach col [$stmt cget -columnDefs] {
		foreach constr [$col cget -columnConstraints] {
			switch -- [$constr cget -branchIndex] {
				0 {
					if {[$constr cget -autoincrement]} {
						set allConstrTokens [$constr cget -allTokens]
						set idx [lsearch -exact $allTokens [lindex $allConstrTokens end]]
						set allTokens [lreplace $allTokens $idx $idx]
					}
				}
				4 {
					set expr [$constr cget -expr]
					set allExprTokens [$expr cget -allTokens]

					set leftIdx [expr {[lsearch -exact $allTokens [lindex $allExprTokens 0]] - 1}]
					set allTokens [lreplace $allTokens $leftIdx $leftIdx]

					set rightIdx [expr {[lsearch -exact $allTokens [lindex $allExprTokens end]] + 1}]
					set allTokens [lreplace $allTokens $rightIdx $rightIdx]
				}
				5 - 6 {
					# COLLATE and FK
					set allConstrTokens [$constr cget -allTokens]
					set firstIdx [lsearch -exact $allTokens [lindex $allConstrTokens 0]]
					set lastIdx [expr {$firstIdx + [llength $allConstrTokens] - 1}]
					set allTokens [lreplace $allTokens $firstIdx $lastIdx]
				}
			}
		}
	}
	# Note:
	# There's also a "IF NOT EXIST" clause, but it's not used now, no need to slow this down.
	return [Lexer::detokenize $allTokens]
}

body SqlConverter::convertStatement2CreateTableTo3 {stmt} {
	set allTokens [$stmt cget -allTokens]

	# Table constraints
	foreach constr [$stmt cget -tableConstraints] {
		switch -- [$constr cget -branchIndex] {
			2 {
				# CHECK
				set allConstrTokens [$constr cget -allTokens]
				set allExprTokens [[$constr cget -expr] cget -allTokens]
				set firstIdx [expr {[lsearch -exact $allTokens [lindex $allExprTokens end]] + 2}]
				set lastIdx [lsearch -exact $allTokens [lindex $allConstrTokens end]]
				set allTokens [lreplace $allTokens $firstIdx $lastIdx]
			}
		}
	}

	# Columns
	foreach col [$stmt cget -columnDefs] {
		foreach constr [$col cget -columnConstraints] {
			switch -- [$constr cget -branchIndex] {
				3 {
					# CHECK
					set allConstrTokens [$constr cget -allTokens]
					set allExprTokens [[$constr cget -expr] cget -allTokens]
					set firstIdx [expr {[lsearch -exact $allTokens [lindex $allExprTokens end]] + 2}]
					set lastIdx [lsearch -exact $allTokens [lindex $allConstrTokens end]]
					set allTokens [lreplace $allTokens $firstIdx $lastIdx]
				}
			}
		}
	}

	# Note:
	# There's also a "IF NOT EXIST" clause, but it's not used now, no need to slow this down.
	return [Lexer::detokenize $allTokens]
}

#####################
# CREATE INDEX

body SqlConverter::convertStatementCreateIndexTo2 {stmt} {
	set allTokens [$stmt cget -allTokens]
	foreach idxCol [$stmt cget -indexColumns] {
		if {[$idxCol cget -collation]} {
			set collationNameIdx [lsearch -exact $allTokens [$idxCol cget -collationName]]
			set collateIdx [expr {$collationNameIdx - 1}]
			set allTokens [lreplace $allTokens $collateIdx $collationNameIdx]
		}
	}
	# Note:
	# There's also a "IF NOT EXIST" clause, but it's not used now, no need to slow this down.
	return [Lexer::detokenize $allTokens]
}

body SqlConverter::convertStatement2CreateIndexTo3 {stmt} {
	set allTokens [$stmt cget -allTokens]
	if {[$stmt cget -onConflict] != ""} {
		set onConflict [$stmt cget -onConflict]
		set conflictTokens [$onConflict cget -allTokens]
		set firstIdx [lsearch -exact $allTokens [lindex $conflictTokens 0]]
		set lastIdx [expr {$firstIdx + [llength $conflictTokens] - 1}]
		set allTokens [lreplace $allTokens $firstIdx $lastIdx]
	}
	return [Lexer::detokenize $allTokens]
}

#####################
# CREATE TRIGGER

body SqlConverter::convertStatementCreateTriggerTo2 {stmt} {
	set allTokens [$stmt cget -allTokens]
	if {[$stmt getValue forEachStatement]} {
		set tableNameIdx [lsearch -exact $allTokens [$stmt cget -tableName]]
		set firstIdx [expr {$tableNameIdx + 1}]
		set lastIdx [expr {$firstIdx + 2}]
		set allTokens [lreplace $allTokens $firstIdx $lastIdx]
	}
	return [Lexer::detokenize $allTokens]
}

body SqlConverter::convertStatement2CreateTriggerTo3 {stmt} {
	return [returnSame $stmt]
}

#####################
# CREATE VIEW
body SqlConverter::convertStatementCreateViewTo2 {stmt} {
	return [returnSame $stmt]
}

body SqlConverter::convertStatement2CreateViewTo3 {stmt} {
	return [returnSame $stmt]
}
