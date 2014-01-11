class CompletionRoutines {
	private {
		#>
		# @method getObjectsForContext
		# @return List in format: valueList contextLabel type contextObjects ?valueList contextLabel type contextObjects ?...??
		#<
		proc getObjectsForContext {db specificObjectCompletion {forceType ""}}
		proc getTriggersForCompletion {db specificObjectCompletion}
		proc getIndexesForCompletion {db specificObjectCompletion}
		proc getViewsForCompletion {db specificObjectCompletion}

		proc getDatabasesForCompletion {db}
		proc getFunctionsForCompletion {}
		proc getOtherObjectsForCompletion {db specificObjectCompletion method type}
		proc checkForCompletionForSpecifiedObject {tokensSoFar}
		proc filterNotExistingTables {db tablesInContext}
		proc getLabelForExpr {expr}
		proc getObjectNamesForExpr {expr}
	}

	public {
		#>
		# @return List of 5-word elements: 1st is a type, 2nd is main completion label, 3 is actual value to use for completion, 4 is additional info label and 5 is context information to use while sorting with priorites.
		#<
		proc getCompletionList {db tablesInContext columnsInContext expectedTokens tokensSoFar partialTokenValue}

		# Sorting routines used with [lsort]
		proc sortCompletionList {sortingModifiers e1 e2}
		proc sortExpectedTokens {t1 t2}
		proc sortIgnoringLastWord {e1 e2}
	}
}

body CompletionRoutines::getCompletionList {db tablesInContext columnsInContext expectedTokens tokensSoFar partialTokenValue} {
	set sortedExpectedTokens [lsort -command sortExpectedTokens $expectedTokens]
	set dialect [$db getDialect]

	set specificObjectCompletion [checkForCompletionForSpecifiedObject $tokensSoFar]
	set specificObjects [llength $specificObjectCompletion]
	# Don't know why this was here, but it caused bug #516.
# 	if {$specificObjects == 1} {
# 		set specificObjectCompletion [lindex $specificObjectCompletion end]
# 	}

	# Creating array mapping table aliases to tables
	set tableAliases [dict create]
	set lowerTableAliases [dict create]
	foreach elem $tablesInContext {
		if {![dict exists $elem alias]} continue
		set alias [dict get $elem alias]
		dict set tableAliases $alias $elem
		dict set lowerTableAliases [string tolower $alias] $elem
	}
	
	set tablesInContext [filterNotExistingTables $db $tablesInContext]

	# Creating array mapping column aliases to columns
	set columnNames [list]
	set columnAliases [dict create]
	set lowerColumnAliases [dict create]
	foreach elem $columnsInContext {
		set value [dict get $elem column]
		set type [dict get $elem type]
		if {$type == "LITERAL"} {
			lappend columnNames $value
		} elseif {$type == "OBJECT" && [string match "::*Expr*" $value]} {
			set objects [getObjectNamesForExpr $value]
			if {[llength $objects] > 0} {
				lappend columnNames {*}$objects
			}
		}
		if {![dict exists $elem alias]} continue
		set alias [dict get $elem alias]
		lappend columnNames $alias
		dict set columnAliases $alias [dict create type $type value $value]
		dict set lowerColumnAliases [string tolower $alias] [list $type $value]
	}
	set columnNames [lsort -unique $columnNames]

	# Main processing
	set resultList [list]
	foreach expectedToken $sortedExpectedTokens {
		lassign $expectedToken tokenType tokenValue tokenBegin tokenEnd
		switch -glob -- $tokenType {
			"*OTHER*" {
				set lookFor [list]
				if {[string match -nocase "*column*" $tokenValue] && ![string match -nocase "*alias*" $tokenValue]} {
					lappend lookFor column table database
				} elseif {[string match -nocase "*table*" $tokenValue] && ![string match -nocase "*alias*" $tokenValue]} {
					lappend lookFor table view database
				} elseif {[string match -nocase "*database*" $tokenValue] && ![string match -nocase "*alias*" $tokenValue]} {
					lappend lookFor database
				} elseif {[string match -nocase "*function*" $tokenValue]} {
					lappend lookFor function
				} elseif {[string match -nocase "*index*" $tokenValue]} {
					lappend lookFor index database
				} elseif {[string match -nocase "*trig*" $tokenValue]} {
					lappend lookFor trigger database
				} elseif {[string match -nocase "*view*" $tokenValue]} {
					lappend lookFor view database
				} else {
					# No completion
				}

				set objects [list]
				if {[llength $lookFor] > 0} {
					if {"table" in $lookFor || "column" in $lookFor} {
						set objects [getObjectsForContext $db $specificObjectCompletion]
						if {"view" in $lookFor} {
							set views [getViewsForCompletion $db $specificObjectCompletion]
							set objects [concat $objects $views]
						}
					} elseif {"index" in $lookFor} {
						set objects [getIndexesForCompletion $db $specificObjectCompletion]
					} elseif {"trigger" in $lookFor} {
						set objects [getTriggersForCompletion $db $specificObjectCompletion]
					} elseif {"view" in $lookFor} {
						set objects [getViewsForCompletion $db $specificObjectCompletion]
					} elseif {"database" in $lookFor} {
						set objects [getDatabasesForCompletion $db]
					} elseif {"function" in $lookFor} {
						set objects [getFunctionsForCompletion]
					}
					foreach {objs contextLabel type context} $objects {
						if {$type ni $lookFor} continue
						foreach obj $objs {
							if {$type in [list "trigger" "view" "database" "table" "column" "index"] && [doObjectNeedWrapping $obj]} {
								set value "[wrapObjName $obj $dialect]"
							} else {
								set value "$obj"
							}

							if {$contextLabel != ""} {
								lappend resultList [list $type "$obj" $value "$contextLabel" $context]
							} else {
								lappend resultList [list $type "$obj" $value "" $context]
							}
						}
					}
				}
			}
			"KEYWORD" {
				if {$specificObjects == 0} {
					lappend resultList [list keyword $tokenValue $tokenValue ""]
				}
			}
			"OPERATOR" {
				# No completion
				#puts "expected token: $tokenValue ($tokenType)"
			}
			"*INTEGER*" {
				# No completion
			}
			"*FLOAT*" {
				# No completion
			}
			"PAR_*" {
				# No completion
				if {$specificObjects == 0} {
					lappend resultList [list keyword $tokenValue $tokenValue ""]
				}
				#puts "expected token: $tokenValue ($tokenType)"
			}
			"BIND_PARAM" {
				# No completion
			}
		}
	}

	# Tables in context for priority sorting
	set tablesInContext [concat {*}$tablesInContext]
	lremove_all tablesInContext {}
	set sortingModifiers [dict create tableSymbols $tablesInContext columnSymbols $columnNames]

	set resultList [lsort -unique $resultList]
	set resultList [lsort -command CompletionRoutines::sortIgnoringLastWord $resultList]
	set resultList [lsort -command [list CompletionRoutines::sortCompletionList $sortingModifiers] $resultList]
	return $resultList
}

body CompletionRoutines::getObjectsForContext {db specificObjectCompletion {forceType ""}} {
	upvar tableAliases tableAliases
	upvar lowerTableAliases lowerTableAliases
	upvar columnAliases columnAliases
	upvar lowerColumnAliases lowerColumnAliases

	set allTableAliases [dict keys $tableAliases]
	set allColumnAliases [dict keys $columnAliases]

	set lgt [llength $specificObjectCompletion]
	set resultList [list]
	if {$lgt > 0} {
		if {$lgt == 2} {
			# User used "database.table."
			set dbName [lindex $specificObjectCompletion 0]
			set tableName [lindex $specificObjectCompletion 1]

			# Lets find out if database is a real database name from tree or at least name of already attached db
			set databaseObject [DBTREE getDBByName $dbName]
			if {[string tolower $dbName] == "main"} {
				set databaseObject $db
			}
			set nativeDatabases [$db getNativeDatabaseObjects]
			if {$databaseObject != ""} {
				# Database name is listed in db tree, so lets try to attach it to get access to it
				set dbName [$db attach $databaseObject]

				# Now we need to check if given table exists in this database.
				set allDbTables [concat [$db getTables $dbName] [$db getViews $dbName]]
				if {[string tolower $tableName] in [string tolower $allDbTables]} {
					# Ok, so table really exists in that database. Lets extract columns from it.
					set columns [$db getColumns $tableName $dbName]
					set context [list [lindex $specificObjectCompletion 0] $tableName]
					set resultList [list $columns "[lindex $specificObjectCompletion 0].$tableName" column $context] ;# second element for context info
				}

				# Finally detach database, since we don't need it anymore.
				$db detach $databaseObject
			} elseif {[string tolower $dbName] ni [string tolower $nativeDatabases]} {
				# Database is already attached, so we just need to ask for tables in it
				set allDbTables [$db getTables $dbName]
				if {[string tolower $tableName] in [string tolower $allDbTables]} {
					# Table exists, so lets get columns
					set columns [$db getColumns $tableName $dbName]
					set context [list $dbName $tableName]
					set resultList [list $columns "${dbName}.$tableName" column $context] ;# second element for context info
				}
			}
		} else {
			# User used "*." prefix
			set tableOrDbName [lindex $specificObjectCompletion 0]

			set databaseObject [DBTREE getDBByName $tableOrDbName]
			set nativeDatabases [$db getNativeDatabaseObjects]
			set allDbTables [concat [$db getTables] [$db getViews]]

			if {$databaseObject != "" && "table" ni $forceType} {
				# This is database name listed in tree
				set dbName [$db attach $databaseObject]

				# Now we need to check if given table exists in this database.
				set allDbTables [concat [$db getTables $dbName] [$db getViews $dbName]]

				# Finally detach database, since we don't need it anymore.
				$db detach $databaseObject

				set context [list $tableOrDbName]
				set resultList [list $allDbTables $tableOrDbName table $context]
			} elseif {[string tolower $tableOrDbName] in [string tolower $allTableAliases] && "table" ni $forceType} {
				# Alias for table has been used. It can be just table from local database,
				# but it also can be database.table, so we need to call this method recursively
				set aliasedDict [dict get $lowerTableAliases [string tolower $tableOrDbName]]
				set newSpecificObjectCompletion [list [dict get $aliasedDict table]]
				if {[dict exists $aliasedDict database]} {
					set newSpecificObjectCompletion [linsert $newSpecificObjectCompletion 0 [dict get $aliasedDict database]]
				}
				set context [list $tableOrDbName]
				set columnsResult [getObjectsForContext $db $newSpecificObjectCompletion "table"]
				set columns [list]
				if {$columnsResult != ""} {
					lassign $columnsResult crColumns crLabel crType crContext
					lappend columns {*}$crColumns
					set context $crContext
					set tableOrDbName "$tableOrDbName = $crLabel"
					set resultList [list $columns "$tableOrDbName" column $context] ;# second element for context info
				} else {
					set resultList [list]
				}
			} elseif {[string tolower $tableOrDbName] in [string tolower $allDbTables]} { ;# Checking if given table name exists in main database, or if it's database name
				# It exists, so get columns
				set columns [$db getColumns $tableOrDbName]
				set context [list $tableOrDbName]
				set resultList [list $columns "$tableOrDbName" column $context] ;# second element for context info
			} elseif {[string tolower $tableOrDbName] in [string tolower $nativeDatabases]} {
				# This is name of attached database
				set allDbTables [concat [$db getTables $tableOrDbName] [$db getViews $tableOrDbName]]

				set context [list $tableOrDbName]
				set resultList [list $allDbTables $tableOrDbName table $context]
			} else {
				# Checking if given table name exists in any of attached databases
				foreach dbName $nativeDatabases {
					if {$dbName in [list "main"]} continue
					set allDbTables [concat [$db getTables $dbName] [$db getViews $dbName]]
					if {[string tolower $tableOrDbName] in [string tolower $allDbTables]} {
						set columns [$db getColumns $tableOrDbName $dbName]
						set context [list $tableOrDbName $dbName]
						set resultList [list $columns "${tableOrDbName}.$dbName" column $context] ;# second element for context info
						break
					}
				}
			}
		}
	} else {
		# No *.*. or *. prefix, so we need to find out all possibilities
		set nativeDatabases [$db getNativeDatabaseObjects]
		foreach dbName $nativeDatabases {
			set allDbTables [concat [$db getTables $dbName] [$db getViews $dbName]]
			foreach table $allDbTables {
				# Columns in table
				set newElement [list]
				lappend resultList [$db getColumns $table $dbName]
				if {$dbName in [list "main" "temp"]} {
					lappend resultList "$table"
				} else {
					lappend resultList "${dbName}.$table"
				}
				lappend resultList column
				lappend resultList [list $dbName $table]
			}

			# Column aliases
			dict for {alias typeAndValueDict} $columnAliases {
				set type [dict get $typeAndValueDict type]
				set value [dict get $typeAndValueDict value]
				if {$type == "OBJECT"} {
					set name [getLabelForExpr $value]
				} else {
					set name $value
				}
				if {$name != ""} {
					set label "= $name"
				} else {
					set label ""
				}
				lappend resultList $alias $label column ""
			}

			# Tables in database
			lappend resultList $allDbTables
			if {$dbName in [list "main" "temp"]} {
				lappend resultList ""
			} else {
				lappend resultList "$dbName"
			}
			lappend resultList table
			lappend resultList [list $dbName]
		}

		# Table aliases
		dict for {alias tableWithDbDict} $tableAliases {
			set table [dict get $tableWithDbDict table]
			if {[dict exists $tableWithDbDict database]} {
				set database [dict get $tableWithDbDict database]
				lappend resultList $alias "$alias = $database.$table" table ""
			} else {
				lappend resultList $alias "$alias = $table" table ""
			}
		}

		# Databases
		set treeDatabases [DBTREE getDatabaseNames]
		if {[llength $treeDatabases] > 0} {
			lappend resultList $treeDatabases "" database ""
		}
		lremove nativeDatabases "main"
		lremove nativeDatabases "temp"
		if {[llength $nativeDatabases] > 0} {
			lappend resultList $nativeDatabases "" database ""
		}
	}
	return $resultList
}

body CompletionRoutines::getLabelForExpr {expr} {
	set name ""

	set exprOnly [$expr cget -exprOnly]
	if {[$exprOnly cget -columnName] != ""} {
		set name [$exprOnly getValue columnName]
		if {[$exprOnly cget -tableName] != ""} {
			set name "[$exprOnly getValue tableName].$name"
			if {[$exprOnly cget -databaseName] != ""} {
				set name "[$exprOnly getValue databaseName].$name"
			}
		}
	} else {
		set name [$expr toSql]
	}
	return $name
}

body CompletionRoutines::getObjectNamesForExpr {expr} {
	set objs [list]
	set exprOnly [$expr cget -exprOnly]
	if {[$exprOnly cget -columnName] != ""} {
		lappend objs [$exprOnly getValue columnName]
	}
	return $objs
}

body CompletionRoutines::getDatabasesForCompletion {db} {
	set resultList [list]
	set nativeDatabases [$db getNativeDatabaseObjects]
	set treeDatabases [DBTREE getDatabaseNames]
	lappend resultList $treeDatabases "" database
	lremove nativeDatabases "main"
	lremove nativeDatabases "temp"
	lappend resultList $nativeDatabases "" database
	return $resultList
}

body CompletionRoutines::getFunctionsForCompletion {} {
	set functions $::SQL_FUNCTIONS
	set resultList [list $functions "" function ""]

	unset functions
	array set functions {}
	set customFunctions [CfgWin::getFunctions]
	foreach f $customFunctions {
		lassign $f name type code
		lappend functions($type) "$name\()"
	}
	foreach type [array names functions] {
		lappend resultList $functions($type) $type function ""
	}
	return $resultList
}

body CompletionRoutines::getTriggersForCompletion {db specificObjectCompletion} {
	return [getOtherObjectsForCompletion $db $specificObjectCompletion getTriggers trigger]
}

body CompletionRoutines::getIndexesForCompletion {db specificObjectCompletion} {
	return [getOtherObjectsForCompletion $db $specificObjectCompletion getIndexes index]
}

body CompletionRoutines::getViewsForCompletion {db specificObjectCompletion} {
	return [getOtherObjectsForCompletion $db $specificObjectCompletion getViews view]
}

body CompletionRoutines::getOtherObjectsForCompletion {db specificObjectCompletion method type} {
	set resultList [list]
	set nativeDatabases [$db getNativeDatabaseObjects]
	set treeDatabases [DBTREE getDatabaseNames]

	if {$specificObjectCompletion != ""} {
		# Prefix: *.
		set dbName $specificObjectCompletion
		if {$dbName in $nativeDatabases} {
			# Prefix database is one of locals, so just get objects
			set objects [$db $method $dbName]
			if {[llength $objects] == 0} {
				return [list]
			}
			lappend resultList $objects
			if {$dbName in [list "main" "temp"]} {
				lappend resultList ""
			} else {
				lappend resultList $dbName
			}
			lappend resultList $type $dbName
		} elseif {$dbName in $treeDatabases} {
			# Database listed in tree, so we need to attach it.
			set dbObject [DBTREE getDBByName $dbName]
			set attachedDb [$db attach $dbObject]
			lappend resultList [$db $method $attachedDb] $dbName $type $dbName

			# Detaching tree database
			$db detach $dbObject
		} else {
			return [list]
		}
	} else {
		# No *. prefix
		# Objects from locally visible databases
		foreach dbName $nativeDatabases {
			set objects [$db $method $dbName]
			if {[llength $objects] == 0} {
				continue
			}
			lappend resultList $objects
			if {$dbName in [list "main" "temp"]} {
				lappend resultList ""
			} else {
				lappend resultList $dbName
			}
			lappend resultList $type $dbName
		}

		# Other databases
		if {[llength $treeDatabases] > 0} {
			lappend resultList $treeDatabases "" database ""
		}
		lremove nativeDatabases "main"
		lremove nativeDatabases "temp"
		if {[llength $nativeDatabases] > 0} {
			lappend resultList $nativeDatabases "" database ""
		}
	}
	return $resultList
}

body CompletionRoutines::sortCompletionList {sortingModifiers e1 e2} {
	lassign $e1 type1 contextLabel1 value1 label1 context1
	lassign $e2 type2 contextLabel2 value2 label2 context2
	set prio1 0
	set prio2 0

	set usedTablesWithDatabases [dict get $sortingModifiers tableSymbols]
	set usedColumns [dict get $sortingModifiers columnSymbols]

	# Splitting databases from tables
	set usedTables [list]
	set usedDatabases [list]
	foreach tableWithDb $usedTablesWithDatabases {
		set objects [splitSqlObjectsFromPath $tableWithDb]
		switch -- [llength $objects] {
			1 {
				lappend usedTables [lindex $objects 0]
			}
			default {
				lappend usedDatabases [lindex $objects 0]
				lappend usedTables [join [lrange $objects 1 end] "."]
			}
		}
	}

	foreach var {prio1 prio2} type [list $type1 $type2] val [list $value1 $value2] ctx [list $context1 $context2] {
		switch -- $type {
			"column" {
				set $var 10
			}
			"function" {
				set $var 4
			}
			"table" {
				set $var 8
			}
			"index" {
				set $var 7
			}
			"trigger" {
				set $var 6
			}
			"view" {
				set $var 5
			}
			"database" {
				set $var 3
			}
			"keyword" {
				set $var 2
			}
			default {
				set $var 0
			}
		}

		# Raising priority for tables used in context
		foreach ctxElement $ctx {
			set idx1 [lsearch -exact $usedTables $ctxElement]
			if {$idx1 > -1} {
				# Value context found in used tables, so we need to increment priority,
				# but priority is higher if element is found closer to begining (it's closer in objects context).
				incr $var [expr {100000 - $idx1 * 15}]
				break
			}
		}
		# Raising priority for databases used in context
		foreach ctxElement $ctx {
			set idx2 [lsearch -exact $usedDatabases $ctxElement]
			if {$idx2 > -1} {
				# Value context found in used daatabases, so we need to increment priority,
				# but priority is higher if element is found closer to begining (it's closer in objects context).
				incr $var [expr {100000 - $idx2 * 15}]
				break
			}
		}
		# Raising for columns
		set idx3 [lsearch -exact $usedColumns $val]
		if {$idx3 > -1} {
			# Value found in used columns, so we need to increment priority,
			# but priority is higher if element is found closer to begining (it's closer in objects context).
			incr $var [expr {1000000 - $idx3 * 15}]
		}
	}
	if {$prio1 > $prio2} {
		return -1
	} elseif {$prio1 < $prio2} {
		return 1
	} else {
		return [string compare [lindex $e1 1] [lindex $e2 1]]
	}
}

body CompletionRoutines::checkForCompletionForSpecifiedObject {tokensSoFar} {
	set lastToken [lindex $tokensSoFar end]
	if {$lastToken == ""} {
		return [list]
	}
	lassign $lastToken tokenType tokenValue tokenBegin tokenEnd
	if {!($tokenType == "OPERATOR" && $tokenValue == ".")} return

	set lastToken [lindex $tokensSoFar end-1]
	lassign $lastToken tokenType tokenValue tokenBegin tokenEnd
	if {!($tokenType == "OTHER" || $tokenType == "STRING")} return

	set resultList [list [stripObjName $tokenValue]]

	set lastToken [lindex $tokensSoFar end-2]
	lassign $lastToken tokenType tokenValue tokenBegin tokenEnd
	if {!($tokenType == "OPERATOR" && $tokenValue == ".")} {
		return $resultList
	}

	set lastToken [lindex $tokensSoFar end-3]
	lassign $lastToken tokenType tokenValue tokenBegin tokenEnd
	if {!($tokenType == "OTHER" || $tokenType == "STRING")} {
		return $resultList
	}

	set resultList [linsert $resultList 0 [stripObjName $tokenValue]]
	return $resultList
}

body CompletionRoutines::sortExpectedTokens {t1 t2} {
	set prio1 0
	set prio2 0
	foreach v {prio1 prio2} t [list $t1 $t2] {
		lassign $t tokenType tokenValue tokenBegin tokenEnd
		switch -- $tokenType {
			"OTHER" - "OTHER|STRING" - "STRING|OTHER" {
				if {[string match -nocase "*column*" $tokenValue]} {
					set $v 9
				} elseif {[string match -nocase "*table*" $tokenValue]} {
					set $v 8
				} elseif {[string match -nocase "*database*" $tokenValue]} {
					set $v 7
				} elseif {[string match -nocase "*function*" $tokenValue]} {
					set $v 3
				} else {
					set $v 6
				}
			}
			"KEYWORD" {
				set $v 5
			}
			"OPERATOR" {
				set $v 2
			}
			"PAR_LEFT" - "PAR_RIGHT" {
				set $v 1
			}
			"BIND_PARAM" {
				set $v 0
			}
			default {
				set $v 0
			}
		}
	}
	if {$prio1 < $prio2} {
		return 1
	} elseif {$prio1 > $prio2} {
		return -1
	} else {
		return 0
	}
}

body CompletionRoutines::filterNotExistingTables {db tablesInContext} {
	# Getting plain Tcl list of tables
	# Remove empty elements from list (they're empty aliases) and split aliases from real tables
	set newList [list]
	set tableAliases [dict create]
	foreach elem $tablesInContext {
		set realTable [dict get $elem table]
		if {[dict exists $elem database]} {
			set tableDatabase [dict get $elem database]
			lappend newList [list $tableDatabase $realTable]
		} else {
			lappend newList $realTable
		}
		if {![dict exists $elem alias]} continue
		dict append tableAliases $realTable [dict get $elem alias]
	}
	set tablesInContext $newList
	unset newList

	# Result list
	set existingTablesList [list]

	# List of objects we already know
	set allLocalTables [concat [$db getTables] [$db getTables "temp"] [$db getViews] [$db getViews "temp"]]
	set alreadyAttachedDatabases [$db getNativeDatabaseObjects]

	# Prepare arrays
	array set attachedDatabases {}
	array set tablesInAttachedDb {}

	# Append tables from already attached databases to known local tables
	foreach attachedDb $alreadyAttachedDatabases {
		lappend allLocalTables {*}[$db getTables $attachedDb] {*}[$db getViews $attachedDb]
	}

	# Looking for tables
	set errorMsg ""
	if {[catch {
		foreach objects $tablesInContext {
			switch -- [llength $objects] {
				1 {
					set table $objects
					if {$table in $allLocalTables} {
						set alias ""
						if {[dict exists $tableAliases $table]} {
							set alias [dict get $tableAliases $table]
						}
						lappend existingTablesList [list $table $alias]
					}
				}
				2 {
					lassign $objects table dbOnly
					if {$dbOnly in [concat $alreadyAttachedDatabases [list "main" "temp"]]} {
						if {$table in $allLocalTables} {
							lappend existingTablesList [list $table ""]
						}
					} else {
						if {![info exists attachedDatabases($dbOnly)]} {
							set dbObject [DBTREE getDBByName $dbOnly]
							if {$dbObject != ""} {
								if {[catch {$db attach $dbObject} res]} {
									Error [mc "Problem with attaching database:\n%s" $res]
								} else {
									set attachedDatabases($dbOnly) $res
								}
							}
						}
						if {[info exists attachedDatabases($dbOnly)]} {
							set tablesInAttachedDb($dbOnly) [$db getTables $attachedDatabases($dbOnly)]
							if {$table in $tablesInAttachedDb($dbOnly)} {
								lappend existingTablesList [list $table ""]
							}
						}
					}
				}
			}
		}
	} err]} {
		set errorMsg $err
	}

	# Detaching databases attached during processing
	foreach idx [array names attachedDatabases] {
		$db detach [DBTREE getDBByName $idx]
	}

	# If there was an error - now it's time to throw it
	if {$errorMsg != ""} {
		error $errorMsg
	}

# 	dict for {key val} $tableAliases {
# 		lappend existingTablesList [list $key $val]
# 	}
	return $existingTablesList
}

body CompletionRoutines::sortIgnoringLastWord {e1 e2} {
	set newE1 [lrange $e1 0 2]
	set newE2 [lrange $e2 0 2]
	return [string compare $newE1 $newE2]
}
