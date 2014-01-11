class QueryExecutor {
	constructor {db {resultsPerPage 9223372036854775000} {page 0}} {
		set _db $db
		set _resultsPerPage $resultsPerPage
		set _page $page
	}

	# infinity, it's almost 2^63 (signed 64-bit), but for some reason it has to me a little smaller
	common limitInfinity 9223372036854775000
	common userManualEditableResults "2.1.d \"Editing data\""
	common visibleDataLimit 30720

	private {
		variable _db ""
		variable _dialect ""
		variable _resultsPerPage ""
		variable _page ""
		variable _interrupted 0
		variable _varName ""
		variable _script ""
		variable _sqliteVersion 3

		variable _colSeq 0
		variable _extractionTableAliases [dict create]
		variable _extractionAllAliases [list]
		variable _tempTableSeq 0
		variable _tempTables [list]
		variable _attachedDatabasesMap [dict create]
		variable _attachedCache [dict create]
		variable _cachedTableColumns [dict create]
		variable _usedDataSourceAliases [list]

		#>
		# @var _namesMap
		# Map structure:
		# {
		#   {
		#     columnMap {
		#       <columnId> {
		#         externalDatabase <0/1>
		#         database <name>
		#         table <name>
		#         column <name>
		#         useAlias 0
		#         alias <name>
		#         displayName <name>
		#         type <column|other|rowid>
		#       }
		#       ...
		#     }
		#     tableAliases {
		#       {
		#         database <name>
		#         table <name>
		#         alias <name>
		#       } ;# where database and alias are optional
		#       ...
		#     }
		#   }
		#   ... ;# for each selectCore
		# }
		#<
		variable _namesMap [dict create]

		#>
		# @var _tokenActions
		# Token actions is used by [execSmart].
		# It is dict in format:
		#
		# {queryIndex routineName1} { ;# routine name is like "attachDb" or "addRowIds"
		#   tokensToAdd {
		#     {token1 {token2 token3 ... tokenN}} ;# token1 is the token that other tokens will be inserted before it, or can be "end"
		#     ...
		#   }
		#   tokensToReplace {
		#     {{token1 token2} {token3 token4 ... tokenN}} ;# token1 and token2 is first and last of token sequence to replace
		#     ...
		#   }
		#   tokensToRemove {
		#     token1
		#     token2
		#     ...
		#     tokenN
		#   }
		# }
		# {queryIndex routineName2} {
		#   ...
		# }
		#
		# The queryIndex is 0-based index of query that routine applies to.
		#<
		variable _tokenActions [dict create]

		##
		# @method applyTokenActions {allTokens actionList queryIndex {ignoreErrors false}}
		# @param allTokens List of tokens to apply actions to.
		# @param actionList List of action names, like "attachDb", or "addRowIds".
		# @param queryIndex 0-based index of query that the actions apply to.
		# @param ignoreErrors If true, errors about missing tokens will be suppressed.
		# @return List of tokens with actions applied.
		method applyTokenActions {allTokens actionList queryIndex {ignoreErrors false}}
		method setTokenAction {queryIndex action tokens}
		method getTokenAction {queryIndex action}

		method preprocessQueries {executionResults parsedDicts tokenizedStatements}
		method attachDatabases {}
		method detachDatabases {}
		method getTableColumns {table database {forceReload false}}
		method getTempTable {}
		method calculateTime {startTime stopTime}
		method registerSqlFunctionsInThread {thread}
		method handleFkPragma {parsedObject}
		method handleRecTrigPragma {parsedObject}
		method attachUsedDatabases {parsedDict queryIndex}
		method addRowIdsToQuery {parsedDict queryIndex}
		method countResults {parsedDict queryIndex}
		method handleLimit {parsedDict queryIndex}
		method handleLimitInSelect {select limit offset queryIndex}
		method transformTransactionType {parsedDict transactionIds queryIndex}
# 		method prepareMaskedColumnsMap {allTokensButResultCols resultsIdx resultColumn tableAliases}
# 		method prepareColumnMap {resultColumn tableAliases}
# 		method prepareNamesMap {lastParsedDict}

		method resolveTableAndDatabase {colName tableProvided {queriedTable ""}}
		method generateResultColumnTokens {virtualName colDict}
		method substituteColumnSource {colMap newAlias}
		method extractColumnMapFromJoinSource {joinSourceStmt depth {useStarTable 0} {starTable ""}}
		method generateDataSourceAlias {allTokens}
		method extractColumnMapFromSingleSource {singleSourceStmt depth}
		method extractColumnMapFromTable {singleSourceStmt}
		method extractColumnMapFromSelect {selectStmt depth}
		method extractColumnMapFromResultColumnStmt {resultColumnStmt}
		method prepareNamesMap {lastParsedDict queryIndex originalQuery}
		method threadExec {query executionResults}

		method execSmart {executionResults query tokenizedStatements parsedDicts}
		method execSmartInternal {executionResults queries}
		method execSimple {executionResults query stmts}

		proc staticSimpleExec {db query async}
	}

	public {
		variable noBounds 0 ;# if true, then no "results per page" bounds are applied
		variable limitedData 0 ;# limits the maximum length of single cell
		variable forceSimpleExecutor 0 ;# forces to use simple executor (it's just faster, but not so powerful)
		variable resultsLimit -1 ;# if 0 or positive, then applies configured LIMIT, ignoring the one in the query
		variable resultsOffset -1 ;# same as above, but with OFFSET
		variable noTransaction 0 ;# if true, forces to skip BEGIN/COMMIT/ROLLBACK
		
		#>
		# @var execInThread
		# Executing in thread makes results of execution automatically ignored
		# and the method for execution is straight - no attaches, neither any other extra features.
		#<
		variable execInThread 0

		#>
		# @method exec {query {varName ""} {script ""}}
		# @param query SQL query to execute.
		# @param varName Name of variable to store dictionary of data (see details below) from single row. Passing this parameter makes query executor to run on main thread.
		# @param script Script to execute for each row. Passing this parameter makes query executor to run on main thread.
		# The varName variable has following format for each executed row:
		# <pre>
		#	{
		#		{
		#			value <value>
		#			rowid <id>			;# this is optional
		#			database <name>		;# this is optional
		#			table <name>		;# this is optional
		#			column <name>		;# this is optional
		#			displayName <name>
		#		}
		#		...
		#	}
		# </pre>
		# If rowid is given, then at least column name is given and maybe table and database names too.
		#
		# The result dict has following keys:
		# <li> returnCode,
		# <li> warnings,
		# <li> errors,
		# <li> allowSwitchingPages,
		# <li> totalRows,
		# <li> affectedRows,
		# <li> time,
		# <li> tableAliases,
		# <li> columnAliases,
		# <li> queryForResults,
		# <li> attachSqlsForResults,
		# <li> rawResults,
		# <li> extensionsToLoad.
		# @return Results dict.
		#<
		method exec {query {varName ""} {script ""}}
		method directExec {query {async false}}
		method interrupt {}
		proc execSync {db query}
		proc execAsync {db query}
	}
}

body QueryExecutor::constructor {db {resultsPerPage 9223372036854775000} {page 0}} {
	set _db $db
	set _resultsPerPage $resultsPerPage
	set _page $page
	set _dialect [$_db getDialect]

	switch -- [$_db getHandler] {
		"::Sqlite2" {
			set _sqliteVersion 2
		}
		"::Sqlite3" {
			set _sqliteVersion 3
		}
		deault {
			error "Unsupported database handler: [$_db getHandler]"
		}
	}

	set _tempTables [$_db getAllTables]
}

body QueryExecutor::staticSimpleExec {db query async} {
	set queryExecutor [QueryExecutor ::#auto $db]
	set res [$queryExecutor directExec $query $async]
	delete object $queryExecutor
	return $res
}

body QueryExecutor::execSync {db query} {
	return [staticSimpleExec $db $query false]
}

body QueryExecutor::execAsync {db query} {
	return [staticSimpleExec $db $query true]
}

body QueryExecutor::directExec {query {async false}} {
	set prevAsync $execInThread
	set execInThread $async
	set results [exec $query]
	set execInThread $prevAsync

	if {[dict get $results returnCode] != 0} {
		error [join [dict get $results errors] \n]
	}

	return [dict get $results rawResults]
}

body QueryExecutor::exec {query {varName ""} {script ""}} {
	set executionResults [dict create returnCode 0 warnings [list] errors [list] allowSwitchingPages 0 rows [list] cols [list] \
		totalRows 0 affectedRows 0 time 0 tableAliases [list] columnAliases [list] queryForResults [list] \
		attachSqlsForResults [list] columnList [list] extensionsToLoad [list] transactionType "" rawResults ""]

	if {$execInThread} {
		# Provides 'rawResults'.
		set executionResults [threadExec $query $executionResults]
		return $executionResults
	}

	# Determinating parser
	set parser [local UniversalParser #auto $_db]
	set lexer [local UniversalLexer #auto $_db]
	
	if {$varName != "" && $script != ""} {
		set _varName $varName
		set _script $script
	}

	# Tokenize all statements
	set lexingDict [$lexer tokenize $query]

	# Removing comments
	set allTokens [list]
	foreach token [dict get $lexingDict tokens] {
		if {[lindex $token 0] == "COMMENT"} continue
		lappend allTokens $token
	}
	
	if {[llength $allTokens] == 0} {
		return $executionResults
	}

	# List of statements
	set stmts [Lexer::splitStatements $allTokens]

	# Parse all tokenized statements
	set allStatementsParsedCorrectly false
	if {!$forceSimpleExecutor} {
		set allStatementsParsedCorrectly true ;# first failed parsing process sets it to false
		set parsedDicts [list]
		set expectedDicts [list]
		set outputStmts [list]
		foreach stmt $stmts {
			if {[llength $stmt] == 0} continue
			lassign [$parser parseTokens $stmt 0] parsedDict expectedDict

			if {[dict get $parsedDict returnCode] != 0} {
				# We need all statements to be parsed correctly to do smart execution
				set allStatementsParsedCorrectly false
				break
			}

			lappend parsedDicts $parsedDict
			lappend expectedDicts $expectedDict
			lappend outputStmts $stmt
		}
		set stmts $outputStmts
		unset outputStmts
	}

	$_db progress 1000000 update

	# Execute query including parsins informations
	if {!$allStatementsParsedCorrectly || $forceSimpleExecutor} {
		# Simple, direct execution
		dict lappend executionResults warnings [mc {Query couldn't be parsed correctly by internal SQLiteStudio parser, so it was passed directly to SQLite, without any substitution or other modification.}]
		set executionResults [execSimple $executionResults $query $stmts]
	} else {
		# Smart execution
		set resultsBeforeExecution $executionResults ;# for reset before simple execution
		set executionResults [execSmart $executionResults $query $stmts $parsedDicts]
		set retCode [dict get $executionResults returnCode]
		if {$retCode == 2} {
			# Smart execution failed, so simple execution is needed
			set smartExecutionResults $executionResults ;# to use if simple execution fails
			set executionResults $resultsBeforeExecution
			set executionResults [execSimple $executionResults $query $stmts]
			set retCode [dict get $executionResults returnCode]
			if {$retCode != 0} {
				# Simple exection failed as well, so we want only results from smart execution
				# to avoid misleading error messages (one from smart execution, one from simple).
				set simpleErrors [dict get $executionResults errors]
				set executionResults $smartExecutionResults
				dict set executionResults returnCode 1
				if {[llength [dict get $executionResults errors]] == 0} {
					# When smart executor failed ad [countResults], then it won't have any error messages.
					# In this case we have to get errors from simple executor.
					dict lappend executionResults errors {*}$simpleErrors
				}
			}
		}
		if {$retCode != 0} {
			# Error during execution
			$_db progress 0 ""
			return $executionResults
		}
	}
	$_db progress 0 ""

	# Processing results
	if {[dict get $executionResults totalRows] > $_resultsPerPage} {
		dict set executionResults allowSwitchingPages 1
	}

	# Setting FK from executed query (maybe the PRAGMA) if it was sqlite3
	if {[dict exists $executionResults fk]} {
		$_db eval "PRAGMA foreign_keys = [dict get $executionResults fk];"
	}

	# Setting RecursiveTriggers from executed query (maybe the PRAGMA) if it was sqlite3
	if {[dict exists $executionResults recTrig]} {
		$_db eval "PRAGMA recursive_triggers = [dict get $executionResults recTrig];"
	}

	# Returning results
	return $executionResults
}

body QueryExecutor::execSmart {executionResults query tokenizedStatements parsedDicts} {
	###########################################
	# Finding out which statement provides results
	#

	# We always use last statement for results. If it's "ROLLBACK", well it doesn't return results then.
	# We can safely use simpleExecutor for that.
	set resStmtIdx "end"

	# Defining statement with results
	set lastParsedDict [lindex $parsedDicts $resStmtIdx]
	set lastParsedObj [dict get $lastParsedDict object]
	set lastQueryIndex [expr {[llength $parsedDicts] - 1}]

	# If this is not select or if it's EXPLAIN, then use simple executor.
	if {[$lastParsedObj cget -branchName] ni [list "deleteStmt" "insertStmt" "updateStmt" "selectStmt"]} {
		dict set executionResults returnCode 2
		return $executionResults
	}
	if {[$lastParsedObj cget -explainKeyword]} {
		dict set executionResults returnCode 2
		return $executionResults
	}
	
	set expectResults 1
	if {[$lastParsedObj cget -branchName] != "selectStmt"} {
		set expectResults 0
	}

	# Avoid sqlite_* tables in smart execution
	foreach tableDict [$lastParsedObj getContextInfo "TABLE_NAMES"] {
		if {[string match "sqlite_*" [dict get $tableDict table]]} {
			dict set executionResults returnCode 2
			return $executionResults
		}
	}

	###########################################
	# Reseting smart execution variables
	#
	set _colSeq 0
	set _tempTableSeq 0
	set _tempTables [list]
	set _cachedTableColumns [dict create]
	set _namesMap [dict create]
	set _extractionTableAliases [dict create]
	set _extractionAllAliases [dict create]
	set _attachedDatabasesMap [dict create]
	set _attachedCache [dict create]
	set _usedDataSourceAliases [list]

	###########################################
	# Local variables
	#
	set attachedDatabases [list] ;# list of databases to detach later
	set attachSqls [list]
	set totalStatements [llength $tokenizedStatements]
	
	###########################################
	# Main routines
	#
	set executionResults [preprocessQueries $executionResults $parsedDicts $tokenizedStatements]
	if {[dict get $executionResults returnCode] != 0} {
		return $executionResults
	}

	###########################################
	# Rest of operations will require attached databases
	#
	attachDatabases

	if {$expectResults} {
		# This is only for SELECT

		###########################################
		# Remember sql for page switching
		#
		set resultsStmt [$lastParsedObj cget -allTokens]
		dict set executionResults queryForResults [Lexer::detokenize $resultsStmt]

		###########################################
		# Count results
		#
		if {[catch {countResults $lastParsedDict $lastQueryIndex} countingResults]} {
			dict lappend executionResults errors $countingResults
			dict set executionResults returnCode 1
			detachDatabases
			return $executionResults
		}

		if {[dict get $countingResults returnCode] == 2} {
			dict set executionResults returnCode 2
			dict lappend executionResults errors {*}[dict get $countingResults errors]
			detachDatabases
			return $executionResults
		}

		if {$_interrupted} {
			dict set executionResults returnCode 3
			detachDatabases
			return $executionResults
		}

		###########################################
		# Create columns and tables map
		#
		if {[catch {prepareNamesMap $lastParsedDict $lastQueryIndex $query} namesResults]} {
			dict lappend executionResults errors $namesResults
			dict set executionResults returnCode 1
			detachDatabases
			return $executionResults
		}

		if {[dict get $namesResults errors] != ""} {
			dict lappend executionResults errors {*}[dict get $namesResults errors]
			dict set executionResults returnCode 1
			detachDatabases
			return $executionResults
		}

		if {[dict get $namesResults warnings] != ""} {
			dict lappend executionResults warnings {*}[dict get $namesResults warnings]
		}

		set _namesMap [dict get $namesResults map]

		if {$_interrupted} {
			dict set executionResults returnCode 3
			detachDatabases
			return $executionResults
		}

		###########################################
		# Add ROWID to results
		#
		set addingRowIdsResults [addRowIdsToQuery $lastParsedDict $lastQueryIndex]

		if {$_interrupted} {
			dict set executionResults returnCode 3
			detachDatabases
			return $executionResults
		}

		if {[dict get $addingRowIdsResults warnings] != ""} {
			dict lappend executionResults warnings {*}[dict get $addingRowIdsResults warnings]
		}

		# Update global names map with ROWID columns
		set newMap [list]
		foreach map $_namesMap addRowMap [dict get $addingRowIdsResults columnMap] {
			set globalColumnsMap [dict get $map columnMap]
			set globalColumnsMap [dict merge $globalColumnsMap $addRowMap]
			dict set map columnMap $globalColumnsMap
			lappend newMap $map
		}
		set _namesMap $newMap

		# Remember attach sqls for page switching
		dict set executionResults attachSqlsForResults $attachSqls

		###########################################
		# Next step, handle limit, offset
		#
		set limitSubstitutionResults [handleLimit $lastParsedDict $lastQueryIndex]
	}

	###########################################
	# Get back from list of tokens to plain queries
	#
	set queries [list]

	# Update list of statements with modified last statement
	set queryIndex 0
	set initialStatementsActions [list "attachDb" "transformTransactionType"]
	set lastStatementActions [list "prepareNamesMap" "dataSourceAliases" "addRowIds" "attachDb" "limit" "transformTransactionType"]
	foreach stmt $tokenizedStatements {
		if {$queryIndex == $lastQueryIndex} {
			set actions $lastStatementActions
		} else {
			set actions $initialStatementsActions
		}
		set stmt [applyTokenActions $stmt $actions $queryIndex]
		lappend queries [Lexer::detokenize $stmt]
		incr queryIndex
	}

	if {$_interrupted} {
		dict set executionResults returnCode 3
		detachDatabases
		return $executionResults
	}

	###########################################
	# Executing on separated (or same) thread
	#
	set executionResults [execSmartInternal $executionResults $queries]

	if {$expectResults} {
		# Get total rows from counting results, not from execution rows
		dict set executionResults totalRows [dict get $countingResults totalRows]
	} else {
		dict set executionResults totalRows 0
	}

	detachDatabases
	return $executionResults
}

body QueryExecutor::preprocessQueries {executionResults parsedDicts tokenizedStatements} {
	set transactionIds [local Stack #auto]
	set queryIndex 0
	foreach parsedDict $parsedDicts stmt $tokenizedStatements {
		if {![dict exists $parsedDict object]} {
			# This can happen when SQL is empty (blank between two semicolons).
			# Such SQL is parsable but doesn't provide "object" in dict.
			# We can just skip it.
			incr queryIndex
			continue
		}
		set obj [dict get $parsedDict object]

		###########################################
		# Handling PRAGMAs
		#
		handleFkPragma $obj
		handleRecTrigPragma $obj

		###########################################
		# Attach used databases
		#
		set attachingResults [attachUsedDatabases $parsedDict $queryIndex]

		# Checking invalid db names
		foreach dbName [dict get $attachingResults invalidDatabaseNames] {
			dict lappend executionResults errors [mc {Invalid database name: %s} $dbName]
			dict set executionResults returnCode 1
		}

		# Checking attaching errors
		if {[dict get $attachingResults errors] != ""} {
			dict lappend executionResults errors {*}[dict get $attachingResults errors]
			dict set executionResults returnCode 1
		}

		# In case of any error - break execution
		if {[llength [dict get $attachingResults errors]] > 0} {
			return $executionResults
		}

		lappend attachedDatabases {*}[dict get $attachingResults attachedDatabases]
		lappend attachSqls {*}[dict get $attachingResults attachSqls]

		###########################################
		# Transforming BEGIN to SAVEPOINT, etc
		#
		set transformationResults [transformTransactionType $obj $transactionIds $queryIndex]
		
		# Transformation errors?
		if {[dict get $transformationResults errors] != ""} {
			dict lappend executionResults errors {*}[dict get $transformationResults errors]
			dict set executionResults returnCode 1
			return $executionResults
		}
		
		if {[dict get $executionResults transactionType] == "" && [dict get $transformationResults transactionType] != ""} {
			dict set executionResults transactionType [dict get $transformationResults transactionType]
		}

		###########################################
		# Extensions to load
		#
		foreach funcPair [$obj getFunctionsWithArgs] {
			lassign $funcPair funcName funcArgs
			if {[string tolower $funcName] == "load_extension"} {
				dict lappend executionResults extensionsToLoad $funcArgs
			}
		}

		incr queryIndex
	}
	if {[$transactionIds size] > 0} {
		dict lappend executionResults errors [mc {Imbalanced 'BEGIN' ocurrence in query.}]
		dict set executionResults returnCode 1
		return $executionResults
	}
	return $executionResults
}

body QueryExecutor::getTempTable {} {
	set table "tempTable_$_tempTableSeq"
	while {[lsearch -nocase -exact $_tempTables $table] > -1} {
		incr _tempTableSeq
		set table "tempTable_$_tempTableSeq"
	}
	incr _tempTableSeq
	return $table
}

body QueryExecutor::getTableColumns {table database {forceReload false}} {
	if {!$forceReload && [dict exists $_cachedTableColumns [list $database $table]]} {
		return [dict get $_cachedTableColumns [list $database $table]]
	}
	set db [DBTREE getDBByName $database]
	set tableInfo [$_db getTableInfo $table $db]
	set cols [list]
	foreach colDict $tableInfo {
		lappend cols [dict get $colDict name]
	}

	dict set _cachedTableColumns [list $database $table] $cols
	return $cols
}

body QueryExecutor::resolveTableAndDatabase {colName tableProvided {queriedTable ""}} {
	# colName is ignored if table is provided.
	foreach tableAlias $_extractionTableAliases {
		set extDb 0
		set database ""
		set table [dict get $tableAlias table]
		if {[dict exists $tableAlias database]} {
			set extDb 1
			set database [dict get $tableAlias database]
		}

		if {$tableProvided} {
			if {[dict exists $tableAlias alias]} {
				# If alias is given, then matching against original table name is not possible.
				# We have to check only against alias name and if it doesn't match, then skip it.
				# This is why these two conditions are not in single "if" connected with "&&".
				set alias [dict get $tableAlias alias]
				if {[string equal -nocase $alias $queriedTable]} {
					return [list true $extDb $database $table]
				}
			} elseif {!$extDb && [string equal -nocase $table $queriedTable]} {
				return [list true $extDb $database $table]
			}
		} else {
			#if {![dict exists $tableAlias alias]} {
				# Searching by columns is necessary in case of query like:
				# SELECT col1, otherCol FROM table1, table2;
				# where col1 is in table1 and othercol in table2.
				# SQLite doesn't allow to use column that appears in both tables with no table prefix.
				# Such column is ambiguous. Therefore we can assume first match as correct.
				# 27.12.2011, above is not true.
				# 25.12.2012, commented out the [if] around this code, because it looks like
				#             when table was not provided, then it doesn't matter if we operate on
				#             alias or on table itself (or even empty = default table).
				#             Although added an [if] inside this code to return different values
				#             depending on alias being present or not.
				set cols [getTableColumns $table $database]
				if {[lsearch -exact -nocase $cols $colName] > -1 || [string toupper $colName] in $::ROWID_KEYWORDS} {
					if {[dict exists $tableAlias alias]} {
						return [list true $extDb $database [dict get $tableAlias alias]]
					} else {
						return [list true $extDb $database $table]
					}
				}
			#}
		}
	}

	debug "Could not resolveTableAndDatabase for '$queriedTable' (tableProvided=$tableProvided). Probably column from subselect or something like that."
	return [list false 0 "" ""]
}

body QueryExecutor::substituteColumnSource {colMap newAlias} {
	dict for {virtualName colDict} $colMap {
		if {[dict get $colDict type] == "column"} {
			# Use real column name prefixed with alias
			dict set colDict displayName "$newAlias.[dict get $colDict column]"
		} else {
			# Just prepend alias.
			dict set colDict displayName "$newAlias.[dict get $colDict displayName]"
		}
		dict set colDict aliasedTable 1
		dict set colDict tableAlias $newAlias
		dict set colMap $virtualName $colDict
	}
	return $colMap
}

body QueryExecutor::extractColumnMapFromJoinSource {joinSourceStmt depth {useStarTable 0} {starTable ""}} {
	upvar queryIndex queryIndex originalQuery originalQuery

	# colMap - a map of virtualName to column description dict
	set colMap [dict create]

	foreach singleSourceStmt [$joinSourceStmt getSingleSources] {
		# Filter by starTable if used
		if {$useStarTable} {
			set branch [$singleSourceStmt getValue branchIndex]
			set aliasToken [$singleSourceStmt cget -tableAlias]
			set aliasName [$singleSourceStmt getValue tableAlias]
			set tableToken [$singleSourceStmt cget -tableName]
			set tableName [$singleSourceStmt getValue tableName]

			# First condition is for all branches, because all branches can have an alias. #1893
			set invalidAlias [expr {$aliasToken != "" && ![string equal $aliasName $starTable]}]

			if {$branch in [list 1 2] || $branch == 0 && $aliasToken != ""} {
				if {$aliasToken == "" || $invalidAlias} {
					# StarTable not matched. Skip.
					continue
				}
			} elseif {$branch == 0} { ;# only when real table name is used, not an alias
				if {$tableToken == "" || $tableToken != "" && ![string equal $tableName $starTable]} {
					# StarTable not matched. Skip.
					continue
				}
			} else {
				error "Unsupported branchIndex: [$singleSourceStmt getValue branchIndex]"
			}
		}

		# Now get colMap to merge it with final colMap
		set resultColMap [extractColumnMapFromSingleSource $singleSourceStmt $depth]

		# Optional displayName substitution
		if {$useStarTable} {
			# We need to substitute display name prefix with current starTable
			dict for {virtualName colDict} $resultColMap {
				if {[dict get $colDict type] == "column"} {
					# Use real column name prefixed with current starTable
					dict set colDict displayName "$starTable.[dict get $colDict column]"
				} else {
					# Just prepend starTable.
					dict set colDict displayName "$starTable.[dict get $colDict displayName]"
				}
				dict set resultColMap $virtualName $colDict
			}
		}

		set colMap [dict merge $colMap $resultColMap]
	}
	return $colMap
}

body QueryExecutor::generateDataSourceAlias {allTokens} {
	upvar queryIndex queryIndex originalQuery originalQuery

	set alias [genUniqueSeqName $_usedDataSourceAliases "dataSource_"]
	lappend _usedDataSourceAliases $alias
	set tokens [list [list KEYWORD AS 0 0] [list OTHER $alias 0 0]]
	set positionToken [lindex $allTokens end]
	set tokens [linsert $tokens 0 $positionToken]

	set tokenActions [getTokenAction $queryIndex "dataSourceAliases"]
	dict lappend tokenActions tokensToReplace [list [list $positionToken $positionToken] $tokens]
	setTokenAction $queryIndex "dataSourceAliases" $tokenActions
	return $alias
}

body QueryExecutor::extractColumnMapFromSingleSource {singleSourceStmt depth} {
	upvar queryIndex queryIndex originalQuery originalQuery

	switch -- [$singleSourceStmt getValue branchIndex] {
		0 {
			set resultColMap [extractColumnMapFromTable $singleSourceStmt]
			set aliased 0
			if {[$singleSourceStmt cget -tableAlias] != ""} {
				set alias [$singleSourceStmt getValue tableAlias]
				set aliased 1
			} elseif {$depth > 0} {
				set alias [generateDataSourceAlias [$singleSourceStmt cget -allTokens]]
				set aliased 1
			}
			if {$aliased} {
				set resultColMap [substituteColumnSource $resultColMap $alias]
			}

			return $resultColMap
		}
		1 {
			set resultColMap [extractColumnMapFromSelect [$singleSourceStmt getValue selectStmt] [expr {$depth+1}]]
			if {[$singleSourceStmt cget -tableAlias] != ""} {
				set alias [$singleSourceStmt getValue tableAlias]
			} else {
				# Here (in oppose to case 0) is no checking for depth,
				# because we always need alias for "(subselect)".
				set alias [generateDataSourceAlias [$singleSourceStmt cget -allTokens]]
			}
			set resultColMap [substituteColumnSource $resultColMap $alias]
			
			return $resultColMap
		}
		2 {
			return [extractColumnMapFromJoinSource [$singleSourceStmt getValue joinSource]]
		}
		default {
			error "Unsupported branchIndex: [$singleSourceStmt getValue branchIndex]"
		}
	}
}

body QueryExecutor::extractColumnMapFromTable {singleSourceStmt} {
	upvar queryIndex queryIndex originalQuery originalQuery

	set database [$singleSourceStmt getValue databaseName]
	set table [$singleSourceStmt getValue tableName]
	set alias [$singleSourceStmt getValue tableAlias]

	set extDb 0
	if {[$singleSourceStmt cget -databaseName] != ""} {
		set extDb 1
	} else {
		set database [$_db getName]
	}
	set aliasedTable 0
	if {[$singleSourceStmt cget -tableAlias] != ""} {
		set aliasedTable 1
	}
	set columns [getTableColumns $table $database]

	set colMap [dict create]
	foreach colName $columns {
		# Virtual name
		set virtualName "Col_$_colSeq"
		incr _colSeq

		set colDict [dict create externalDatabase $extDb database $database table $table column $colName aliasedTable $aliasedTable tableAlias $alias useAlias 0 alias "" displayName $colName type "column"]
		dict set colMap $virtualName $colDict
	}
	return $colMap
}

body QueryExecutor::extractColumnMapFromSelect {selectStmt depth} {
	upvar queryIndex queryIndex originalQuery originalQuery

	set coreList [$selectStmt cget -selectCores]

	if {[llength $coreList] > 1} {
		# This has to be checked at top level, so here we're sure we have only 1 core.
		error "Multiple cores in extractColumnMapFromSelect!"
	}

	# Doing substitution for the only core
	set core [lindex $coreList 0]
	set colMap [dict create]

	# JoinSource statement for "*" case of result columns
	set joinSourceStmt [$core getValue from]

	set resultObjects [$core getListValue resultColumns]
	foreach resultColumn $resultObjects {
		if {[$resultColumn cget -star]} {
			# Masked selection
			if {$joinSourceStmt == ""} {
				# Star result column and no "from"? Probably an error in query syntax, but we just skip it here.
				continue
			}
			# Was there table.* ?
			set useStarTable 0
			set starTable ""
			if {[$resultColumn cget -tableName] != ""} {
				set starTable [$resultColumn getValue tableName]
				set useStarTable 1
			}
			set resultColMap [extractColumnMapFromJoinSource $joinSourceStmt $depth $useStarTable $starTable]
		} else {
			# Full column definition
			set resultColMap [extractColumnMapFromResultColumnStmt $resultColumn]
		}
		set colMap [dict merge $colMap $resultColMap]
	}

	return $colMap
}

body QueryExecutor::extractColumnMapFromResultColumnStmt {resultColumnStmt} {
	upvar queryIndex queryIndex originalQuery originalQuery

	# Creating column map
	# Column alias
	set colDict [dict create externalDatabase 0 database "" table "" column "" aliasedTable 0 tableAlias "" useAlias 0 alias "" displayName "" type "column"]
	if {[$resultColumnStmt cget -columnAlias] != ""} {
		dict set colDict useAlias 1
		set alias [$resultColumnStmt getValue columnAlias]
		dict set colDict alias $alias
		dict set colDict displayName $alias
	} else {
		#dict set colDict displayName [Lexer::detokenize [$resultColumnStmt cget -allTokens]]
		set allTokens [$resultColumnStmt cget -allTokens]
		dict set colDict displayName [string range $originalQuery [lindex $allTokens 0 2] [lindex $allTokens end 3]]
	}

	# db.table.column or expression?
	set expr [$resultColumnStmt getValue expr]
	if {[$expr getBranchIndex] == 2} {
		# db.table.column
		set exprOnly [$expr getValue exprOnly]

		set extDb 0
		set database ""
		set table ""
		set colName [$exprOnly getValue columnName]
		
		set aliasedTable 0
		set tableAlias ""
		if {[$exprOnly cget -tableName] != ""} {
			# Table provided
			set origTable [$exprOnly getValue tableName]
			if {[$exprOnly cget -databaseName] != ""} {
				# Database provided
				set extDb 1
				set database [$exprOnly getValue databaseName]
				set table $origTable
			} else {
				# Table provided, but not database. Might be alias to table.
				lassign [resolveTableAndDatabase "" true $origTable] resolveSuccessed extDb database table
				if {$resolveSuccessed} {
					if {![string equal $origTable $table]} {
						set aliasedTable 1
						set tableAlias $origTable
					}
				} elseif {$origTable in $_extractionAllAliases} {
					set aliasedTable 1
					set tableAlias $origTable
# 					set table $origTable
				}
			}
		} else {
			# No table, just column. Lookup for default table.
			lassign [resolveTableAndDatabase $colName false] resolveSuccessed extDb database table
		}
		dict set colDict externalDatabase $extDb
		dict set colDict database $database
		dict set colDict table $table
		dict set colDict column $colName
		dict set colDict aliasedTable $aliasedTable
		dict set colDict tableAlias $tableAlias
	} else {
		# Some expression, not simple column
		set resultTokens [$resultColumnStmt cget -allTokens]
		
		# Excluding alias tokens from column definition
		if {[$resultColumnStmt cget -columnAlias] != ""} {
			set resultTokens [lrange $resultTokens 0 end-1]
			if {[$resultColumnStmt getValue asKeyword]} {
				set resultTokens [lrange $resultTokens 0 end-1]
			}
		}

		#dict set colDict column [Lexer::detokenize $resultTokens]
		dict set colDict column [string range $originalQuery [lindex $resultTokens 0 2] [lindex $resultTokens end 3]]
		dict set colDict type "other"
	}

	# Virtual name
	set virtualName "Col_$_colSeq"
	incr _colSeq

	set colMap [dict create $virtualName $colDict]
	return $colMap
}

body QueryExecutor::prepareNamesMap {lastParsedDict queryIndex originalQuery} {
	set results [dict create errors [list] map [list] warnings [list]]
	set tokenActions [dict create tokensToReplace [list]]
	set obj [dict get $lastParsedDict object]

	set select [$obj getValue subStatement]
	set coreList [$select cget -selectCores]
	
	setTokenAction $queryIndex "prepareNamesMap" ""

	if {[llength $coreList] > 1} {
		# Compound selects cannot be mapped properly, because we don't know where new "UNION" starts,
		# and we cannot use "special marker row" for that, because of "EXECPT".
		dict lappend results warnings [mc {Results are not editable, because compound SELECT was used. For more details see paragraph %s of User Manual.} $userManualEditableResults]
		return $results
	}

	# Doing substitution for each core
	set core [lindex $coreList 0]
	set map [dict create columnMap "" tableAliases "" displayColumns [list]]
	set colMap [dict create]

	# Get list of table aliases
	$core configure -checkParentForContext false
	set _extractionTableAliases [$core getContextInfo "TABLE_NAMES"]
	set _extractionAllAliases [$core getContextInfo "ALIASES"]
	$core configure -checkParentForContext true
	dict set map tableAliases $_extractionTableAliases

	# The extraction essence
	set colMap [extractColumnMapFromSelect $select 0]
	
	# Creating list of displayable columns and new result column tokens
	set newResultColumns [list]
	dict for {virtualName colDict} $colMap {
		dict lappend map displayColumns [dict get $colDict displayName]
		lappend newResultColumns [generateResultColumnTokens $virtualName $colDict]
	}

	dict set map columnMap $colMap
	dict lappend results map $map

	# Creating new result columns
	set joinToken [list [list OPERATOR "," 0 0]]
	set joinToken " $joinToken "
	set resultTokens [join $newResultColumns $joinToken]

	# Preparing tokens without result columns so we can query every masked select.
	set resultObjects [$core getListValue resultColumns]
	set firstResultToken [lindex [[lindex $resultObjects 0] cget -allTokens] 0]
	set lastResultToken [lindex [[lindex $resultObjects end] cget -allTokens] end]

	# Substituting result columns
	dict lappend tokenActions tokensToReplace [list [list $firstResultToken $lastResultToken] $resultTokens]

	setTokenAction $queryIndex "prepareNamesMap" $tokenActions
	
	# Done
	return $results
}

body QueryExecutor::generateResultColumnTokens {virtualName colDict} {
	set type [dict get $colDict type]
	switch -- $type {
		"other" {
			set column [dict get $colDict column]
			return [list [list OTHER $column 0 0] [list KEYWORD "AS" 0 0] [list OTHER $virtualName 0 0]]
		}
		"column" {
			set dialect [$_db getDialect]
			set colName [dict get $colDict column]
			if {[dict get $colDict aliasedTable]} {
				# alias.column
				set tableAlias [dict get $colDict tableAlias]
				return [list [list OTHER $tableAlias 0 0] [list OPERATOR "." 0 0] [list OTHER [wrapObjIfNeeded $colName $dialect] 0 0] [list KEYWORD "AS" 0 0] [list OTHER $virtualName 0 0]]
			}

			# Direct column, not aliased.
			set table [dict get $colDict table]
			if {[dict get $colDict externalDatabase]} {
				set database [dict get $colDict database]
				return [list [list OTHER [wrapObjIfNeeded $database $dialect] 0 0] [list OPERATOR "." 0 0] [list OTHER [wrapObjIfNeeded $table $dialect] 0 0] [list OPERATOR "." 0 0] [list OTHER [wrapObjIfNeeded $colName $dialect] 0 0] [list KEYWORD "AS" 0 0] [list OTHER $virtualName 0 0]]
			} else {
				return [list [list OTHER [wrapObjIfNeeded $table $dialect] 0 0] [list OPERATOR "." 0 0] [list OTHER [wrapObjIfNeeded $colName $dialect] 0 0] [list KEYWORD "AS" 0 0] [list OTHER $virtualName 0 0]]
			}
		}
		default {
			error "Unsupported colDict type: $type"
		}
	}
}

body QueryExecutor::addRowIdsToQuery {parsedDict queryIndex} {
	set results [dict create errors [list] warnings [list] columnMap [list]]
	set tokenActions [dict create tokensToAdd [list]]
	set obj [dict get $parsedDict object]
	set select [$obj getValue subStatement]
	set coreList [$select cget -selectCores]
	set allTokens [$select cget -allTokens]
	setTokenAction $queryIndex "addRowIds" ""

	if {[llength $coreList] > 1} {
		# compound selects cannot have row id columns, because every select core can use different number
		# of tables, therefore there would be different number of columns because of ROWID columns.
		return $results
	}

	# Doing substitution for each core
	set core [lindex $coreList 0]
	# DISTINCT and GROUP BY cannot add rowid to result columns, because it breaks their logic
	if {[string toupper [$core getValue allOrDistinct]] == "DISTINCT"} {
		dict lappend results warnings [mc {Results are not editable, because DISTINCT keyword was used. For more details see paragraph %s of User Manual.} $userManualEditableResults]
		return $results
	}
	if {[llength [$core cget -groupBy]] > 0} {
		dict lappend results warnings [mc {Results are not editable, because GROUP BY was used. For more details see paragraph %s of User Manual.} $userManualEditableResults]
		return $results
	}

	set columnMap [dict create]

	# Getting list of tables or their aliases
	set from [$core getValue from]
	if {$from == ""} {
		return $results
	}

	set firstResultToken [lindex [[lindex [$core getListValue resultColumns] 0] cget -allTokens] 0]

	# Tokens are used instead of plain values,
	# because this way we use original database token,
	# so it will get replaced by attachDb replace actions.
	$from configure -checkParentForContext false
	$from setContextTokensMode true
	set tableAliases [$from getContextInfo "TABLE_NAMES"]
	$from setContextTokensMode false
	$from configure -checkParentForContext true

	# Adding list of aliases from columns map processing
# 	set aliasedDataSources [list]
# 	foreach alias $_usedDataSourceAliases {
# 		lappend aliasedDataSources [dict create database "" table "" alias [list "" $alias]]
# 	}

	foreach tableDict $tableAliases {
		set virtualName "Col_$_colSeq"
		incr _colSeq

		set table [lindex [dict get $tableDict table] 1]
		set colMap [dict create externalDatabase 0 database "" table $table column "" aliasedTable 0 useAlias 0 alias "" displayName "" type "rowid"]
		if {[dict exists $tableDict database]} {
			dict set colMap database [stripObjName [lindex [dict get $tableDict database] 1]]
			dict set colMap externalDatabase 1
		}

		set tokens [list]
		if {[dict exists $tableDict alias]} {
			set alias [lindex [dict get $tableDict alias] 1]
			dict set colMap tableAlias $alias
			dict set colMap aliasedTable 1
			lappend tokens [list OTHER $alias 0 0]
		} else {
			if {[dict exists $tableDict database]} {
				lappend tokens [dict get $tableDict database] ;# using original database token
				lappend tokens [list OPERATOR "." 0 0]
				lappend tokens [list OTHER $table 0 0]
			} else {
				lappend tokens [list OTHER $table 0 0]
			}
		}
		lappend tokens [list OPERATOR "." 0 0]
		lappend tokens [list OTHER "ROWID" 0 0]
		lappend tokens [list KEYWORD "AS" 0 0]
		lappend tokens [list OTHER $virtualName 0 0]
		lappend tokens [list OPERATOR "," 0 0]

		dict set columnMap $virtualName $colMap
		dict lappend tokenActions tokensToAdd [list $firstResultToken $tokens]
	}
	dict lappend results columnMap $columnMap

	setTokenAction $queryIndex "addRowIds" $tokenActions
	return $results
}

body QueryExecutor::transformTransactionType {parsedObject transactionIds queryIndex} {
	set stmt [$parsedObject getValue subStatement]
	set modifiedTokens [list]
	set results [dict create modifiedTokens "" errors [list] transactionType ""]
	set tokenActions [dict create tokensToReplace [list]]

	if {[$_db getDialect] == "sqlite3"} {
		set cls [$stmt info class]
		switch -- $cls {
			"::StatementBeginTransaction" - "::Statement2BeginTransaction" {
				if {![$transactionIds isEmpty]} {
					dict lappend results errors [mc {Cannot use more than one 'BEGIN'.}]
					return $results
				}

				set id [randcrap 20]
				$transactionIds push $id

				lappend modifiedTokens [list "KEYWORD" "SAVEPOINT" 0 1]
				lappend modifiedTokens [list "STRING" "'$id'" 3 4]

				if {$cls == "::StatementBeginTransaction"} {
					dict set results transactionType [$stmt getValue type]
				}

				set doReplace true
			}
			"::StatementCommit" - "::Statement2Commit" {
				if {[$transactionIds isEmpty]} {
					dict lappend results errors [mc {Imbalanced 'COMMIT' ocurrence in query.}]
					return $results
				}

				set id [$transactionIds pop]

				lappend modifiedTokens [list "KEYWORD" "RELEASE" 0 1]
				lappend modifiedTokens [list "STRING" "'$id'" 3 4]

				set doReplace true
			}
			"::StatementRollback" - "::Statement2Rollback" {
				if {[$transactionIds isEmpty]} {
					dict lappend results errors [mc {Imbalanced 'ROLLBACK' ocurrence in query.}]
					return $results
				}

				set id [$transactionIds pop]

				lappend modifiedTokens [list "KEYWORD" "ROLLBACK" 0 1]
				lappend modifiedTokens [list "KEYWORD" "TO" 3 4]
				lappend modifiedTokens [list "KEYWORD" "SAVEPOINT" 6 7]
				lappend modifiedTokens [list "STRING" "'$id'" 9 10]

				set doReplace true
			}
			default {
				set doReplace false
			}
		}

		if {$doReplace} {
			set allTokens [$stmt cget -allTokens]
			set firstToken [lindex $allTokens 0]
			set lastToken [lindex $allTokens end]
			dict lappend tokenActions tokensToReplace [list [list $firstToken $lastToken] $modifiedTokens]
		}
	}

	setTokenAction $queryIndex "transformTransactionType" $tokenActions
	return $results
}

body QueryExecutor::handleFkPragma {parsedObject} {
	set stmt [$parsedObject getValue subStatement]
	if {![$stmt isa ::StatementPragma]} return

	set pragmaName [string tolower [$stmt getValue pragmaName]]
	if {$pragmaName != "foreign_keys"} return

	set pragmaValue [$stmt getValue pragmaValue]
	if {$pragmaValue == ""} return

	set value [$pragmaValue getValue signedNumber]
	if {$value == "" || ![string is boolean $value]} return

	$_db eval "PRAGMA foreign_keys = $value;"
}

body QueryExecutor::handleRecTrigPragma {parsedObject} {
	set stmt [$parsedObject getValue subStatement]
	if {![$stmt isa ::StatementPragma]} return

	set pragmaName [string tolower [$stmt getValue pragmaName]]
	if {$pragmaName != "recursive_triggers"} return

	set pragmaValue [$stmt getValue pragmaValue]
	if {$pragmaValue == ""} return

	set value [$pragmaValue getValue signedNumber]
	if {$value == "" || ![string is boolean $value]} return

	$_db eval "PRAGMA recursive_triggers = $value;"
}

body QueryExecutor::execSmartInternal {executionResults queries} {
	set tableAliases [dict get $executionResults tableAliases]

	# Executing query
	set row 1
	set changes 0
	set rows [list]
	set cols [list]
	set stopTime ""
	set startTime [clock microseconds]

	# Names map can be empty (for example for compond selects).
	# In that case we cannot provide column description.
	if {[llength $_namesMap] > 0} {
		set namesMap [lindex $_namesMap 0]
		set allColsMap [dict get $namesMap columnMap]

		# Collect row id columns
		set rowIdCols [dict filter $allColsMap script {colName colDict} {
			string equal [dict get $colDict type] "rowid"
		}]
	} else {
		set namesMap ""
		set allColsMap [dict create]

		# Collect row id columns
		set rowIdCols [dict create]
	}

	# We take last query no matter if it's the one with results.
	# If user puts "ROLLBACK" or "COMMIT" as last query, or any other query,
	# then we will just execute it and take no results, just like we should.
	set allExceptLast [lrange $queries 0 end-1]
	set lastQuery [lindex $queries end]

	if {[catch {
		if {$_sqliteVersion == 3} {
			set beginChanges [$_db total_changes]
		}

		# Transaction
		set transactionType [dict get $executionResults transactionType]
		if {!$noTransaction} {
			$_db eval "BEGIN $transactionType"
		}

		# Executing all queries except for last one, which might return results
		if {[llength $allExceptLast] > 0} {
			$_db eval [join $allExceptLast ";"]
			if {$_sqliteVersion == 2} {
				incr changes [$_db changes]
			}
		}

		set limitedDataRange [expr {$visibleDataLimit - 1}]

		# Executing last query
		#puts $lastQuery
		if {$_varName != ""} {
			# Custom variable
			upvar 3 $_varName customVar_$_varName
			
			# Execute
# 			puts "X: $lastQuery"
			$_db eval $lastQuery R {
# 				puts "row:"
# 				parray R
				if {$row == 1} {
					set stopTime [clock microseconds]
				}
			
				set customVar_$_varName [list]
				set rowids [dict create]
				foreach id $R(*) {
					if {[dict exists $rowIdCols $id]} {
						set colDict [dict get $rowIdCols $id]
						set key [list]
						if {[dict get $colDict externalDatabase]} {
							lappend key [dict get $colDict database]
						}
						lappend key [dict get $colDict table]
						if {[dict get $colDict aliasedTable]} {
							lappend key [dict get $colDict tableAlias]
						}
						dict set rowids $key $R($id)
					}
				}
				#puts "rowids: $rowids"

				# Going through all cells in row
				foreach id $R(*) {
					if {[dict exists $rowIdCols $id]} {
						# RowIds are already processed.
						continue
					}

					set cellValue $R($id)
				
					# Apply data limit
					if {[string length $cellValue] > $visibleDataLimit && $limitedData} {
						set cellValue [string range $cellValue 0 $limitedDataRange]
					}

					# Preparing full described value of cell
					# TODO: most of this can be cached and refreshed only for each next selectCore
					if {[dict exists $allColsMap $id]} {
						set colDict [dict get $allColsMap $id]
						set cell [dict create value $cellValue displayName [dict get $colDict displayName]]
					} else {
						set colDict [dict create]
						set cell [dict create value $cellValue displayName $id]
					}

					if {[dict exists $colDict column]} {
						# Column is always available for regular result column
						dict set cell column [dict get $colDict column]
						if {[dict exists $colDict table]} {
							# Table can be in column
							set table [dict get $colDict table]
							set database [dict get $colDict database]
							dict set cell table $table
							dict set cell database $database

							set rowIdKey [list]
							if {[dict get $colDict externalDatabase]} {
								lappend rowIdKey $database
							}
							lappend rowIdKey $table
							if {[dict get $colDict aliasedTable]} {
								lappend rowIdKey [dict get $colDict tableAlias]
							}

							if {[dict exists $rowids $rowIdKey]} {
								dict set cell rowid [dict get $rowids $rowIdKey]
							}
						}
					}

					# Adding cell value to the row
					lappend customVar_$_varName $cell
				}

				# Executing script for a row
				uplevel 3 $_script

				incr row
				if {$_interrupted} {
					break
				}
			}
		} else {
			# No varName provided. Execution with no results expected.
			dict set executionResults rawResults [$_db eval $lastQuery]
		}

		if {$_interrupted} {
			if {!$noTransaction} {
				$_db eval {ROLLBACK}
			}
		} else {
			if {$_sqliteVersion == 2} {
				incr changes [$_db changes]
			}
			if {!$noTransaction} {
				$_db eval {COMMIT}
			}
			if {$_sqliteVersion == 3} {
				set changes [expr {[$_db total_changes] - $beginChanges}]
			}
		}
	} err]} {
		if {$::DEBUG(global)} {
			puts "Query execution error:"
			puts $::errorInfo
		}
		# Failed execution
		if {!$noTransaction} {
			catch {$_db eval {ROLLBACK}}
		}
		if {!$_interrupted} {
			dict lappend executionResults errors $err
			dict set executionResults returnCode 1
		}
	} else {
		# Execution successful.
		# If no there was no results, then we have to put stopTime here
		if {$stopTime == ""} {
			set stopTime [clock microseconds]
		}

		dict set executionResults time [calculateTime $startTime $stopTime]
		dict set executionResults affectedRows $changes
	}

	if {$_interrupted} {
		dict lappend executionResults errors "interrupted"
		dict set executionResults returnCode 3
	}

	return $executionResults
}

body QueryExecutor::attachUsedDatabases {parsedDict queryIndex} {
	set results [dict create attachedDatabases [list] invalidDatabaseNames [list] errors [list] attachSqls [list]]

	setTokenAction $queryIndex "attachDb" ""
	set tokenActions [dict create tokensToReplace [list]]

	set obj [dict get $parsedDict object]
	$obj setContextTokensMode true
	$obj setForceRecurentContextChecking true
	set databaseNames [$obj getContextInfo "DATABASE_NAMES"]
	$obj setContextTokensMode false
	$obj setForceRecurentContextChecking false
	set nativeDatabases [$_db getNativeDatabaseObjects]
	set treeDatabases [DBTREE dblist]
	set treeDatabaseNames [list]
	foreach dbObj $treeDatabases {
		lappend treeDatabaseNames [$dbObj getName]
	}

	# Check if there is any invalid dbName, so we won't even try to attach any db
	foreach dbDict $databaseNames {
		set dbNameToken [dict get $dbDict database]
		set dbName [stripObjName [lindex $dbNameToken 1]]
		if {$dbName ni $nativeDatabases && $dbName ni $treeDatabaseNames} {
			dict lappend results invalidDatabaseNames $dbName
		}
	}
	if {[dict get $results invalidDatabaseNames] != ""} {
		debug "Attaching interrupted. Invalid database names: [dict get $results invalidDatabaseNames]"
		return $results
	}

	foreach dbDict $databaseNames {
		set dbNameToken [dict get $dbDict database]
		set dbName [stripObjName [lindex $dbNameToken 1]]
		if {$dbName in $nativeDatabases} continue
#		if {$dbName == [$_db getName]} continue

		if {$dbName in $treeDatabaseNames} {
			set treeDb [DBTREE getDBByName $dbName]

			# Attach db, but only if it wasn't already attached or it's not same as our main db
			if {![dict exists $_attachedCache $treeDb]} {
				if {[catch {
					set dbObject [$_db attach $treeDb]
				} err]} {
					# Add error message
					dict lappend results errors $err ;# message is already translated in [attach]

					# Detach databases attached so far
					foreach dbObject [dict get $results attachedDatabases] {
						$_db detach $dbObject
					}

					# Break this loop and method
					return $results
				}

				dict lappend results attachedDatabases $dbObject
				dict set _attachedCache $treeDb $dbObject
				dict set _attachedDatabasesMap $treeDb $dbObject
				dict lappend results attachSqls "ATTACH DATABASE '[$treeDb getPath]' AS $dbObject"
			}

			# Substitute the name token
			# BUG 1655: added "0" minReplaces, because after resultColumns are replaced with rowid, etc,
			# then all columns with database prefix have now dbName with {0 0} indexes and replacing
			# dbName with real indexes might not happen at all, only with zero indexes will get replaced.
			set newToken [lreplace $dbNameToken 1 1 [dict get $_attachedCache $treeDb]]
			dict lappend tokenActions tokensToReplace [list [list $dbNameToken $dbNameToken] [list $newToken] 0] ;# last 0 is minReplaces
			
			# Add artifical token with "0 0" indexes, so we can use this database with "0 0" tokens
			# anywhere later and be sure that it gets replaced anyway by this action. This is required by
			# "prepareColumnMap", because it produces single columns that might have db token like this.
			set dbNameToken [lreplace $dbNameToken 2 3 0 0] ;# replace startIdx and endIdx with "0" and "0".
			dict lappend tokenActions tokensToReplace [list [list $dbNameToken $dbNameToken] [list $newToken] 0] ;# last 0 is minReplaces
		}
	}

	# Detaching for now.
	foreach dbObject [dict get $results attachedDatabases] {
		$_db detach $dbObject
	}

	setTokenAction $queryIndex "attachDb" $tokenActions
	return $results
}

body QueryExecutor::handleLimit {parsedDict queryIndex} {
	set results [dict create errors [list]]

	if {$noBounds} {
		return $results
	}

	set obj [dict get $parsedDict object]
	if {[$obj cget -branchName] != "selectStmt"} {
		# Not a SELECT
		return $results
	}

	set select [$obj cget -subStatement]

	# Offset and limit for pages browsing
	if {$resultsOffset >= 0} {
		set offset $resultsOffset
	} else {
		set offset [expr {$_resultsPerPage * $_page}]
	}
	if {$resultsLimit >= 0} {
		set limit $resultsLimit
	} else {
		set limit $_resultsPerPage
	}

	handleLimitInSelect $select $limit $offset $queryIndex

	#dict set results modifiedTokens $stmt
	return $results
}

body QueryExecutor::handleLimitInSelect {select limit offset queryIndex} {
	#set stmt [$select cget -allTokens]
	set tokenActions [dict create tokensToAdd [list] tokensToReplace [list]]

	set limitMethod "replace"
	set offsetMethod "replace"

	# Offset and limit from query
	set queryOffsetExpr [$select cget -offset]
	set queryLimitExpr [$select cget -limit]
	if {$queryOffsetExpr != ""} {
		set allTokens [$queryOffsetExpr cget -allTokens]
		if {[llength $allTokens] == 1} {
			set queryOffsetToken [lindex $allTokens 0]
			set queryOffsetReplaceRange [list $queryOffsetToken $queryOffsetToken]
		} else {
			set expr [escapeSqlString [$queryOffsetExpr toSql]]
			set queryOffsetToken [list INTEGER [$_db onecolumn "SELECT $expr"] 0 0]
			set queryOffsetReplaceRange [list [lindex $allTokens 0] [lindex $allTokens end]]
		}
	} else {
		set queryOffsetToken ""
		set offsetMethod "add"
	}
	if {$queryLimitExpr != ""} {
		set allTokens [$queryLimitExpr cget -allTokens]
		if {[llength $allTokens] == 1} {
			set queryLimitToken [lindex $allTokens 0]
			set queryLimitReplaceRange [list $queryLimitToken $queryLimitToken]
		} else {
			set expr [escapeSqlString [$queryLimitExpr toSql]]
			set queryLimitToken [list INTEGER [$_db onecolumn "SELECT $expr"] 0 0]
			set queryLimitReplaceRange [list [lindex $allTokens 0] [lindex $allTokens end]]
		}
	} else {
		set queryLimitToken ""
		set limitMethod "add"
	}
	set queryLimit [lindex $queryLimitToken 1]
	set queryOffset [lindex $queryOffsetToken 1]

	# Defining defaults for missing query bounds
	if {$queryLimit == ""} {
		set queryLimit $limitInfinity
		set queryLimitToken [list INTEGER $queryLimit -1 0] ;# index -1 should be unique enough for replacing
	}
	if {$queryOffset == ""} {
		set queryOffset 0
		set queryOffsetToken [list INTEGER $queryOffset -1 0] ;# index -1 should be unique enough for replacing
	}

	# Final bounds
	set finalOffset [expr {$offset + $queryOffset}]
	if {($offset + $limit) > $queryLimit} {
		set finalLimit [expr {$queryLimit - $offset}]
	} else {
		set finalLimit $limit
	}

	# Token actions
	if {$limitMethod == "add"} {
		set tokens [list [list KEYWORD LIMIT 0 0]  [list INTEGER $finalLimit 0 0]]
		dict lappend tokenActions tokensToAdd [list end $tokens]
	} else {
		set newLimitToken [lreplace $queryLimitToken 1 1 $finalLimit]
		dict lappend tokenActions tokensToReplace [list $queryLimitReplaceRange [list $newLimitToken]]
	}
	if {$offsetMethod == "add"} {
		set tokens [list [list KEYWORD OFFSET 0 0]  [list INTEGER $finalOffset 0 0]]
		dict lappend tokenActions tokensToAdd [list end $tokens]
	} else {
		set newOffsetToken [lreplace $queryOffsetToken 1 1 $finalOffset]
		dict lappend tokenActions tokensToReplace [list $queryOffsetReplaceRange [list $newOffsetToken]]
	}

	setTokenAction $queryIndex "limit" $tokenActions
}

body QueryExecutor::countResults {parsedDict queryIndex} {
	set results [dict create totalRows 0 returnCode 0 errors [list]]

	set isSelect ""
	set obj [dict get $parsedDict object]

	set allTokens [$obj cget -allTokens]
	set allTokens [applyTokenActions $allTokens [list "attachDb"] $queryIndex]
	set query [Lexer::detokenize $allTokens]

	set totalRows 0

	if {[catch {
		# Executing query
		$_db eval {BEGIN}
		set totalRows [$_db onecolumn "SELECT count(*) FROM ($query)"]
		$_db eval {ROLLBACK}
	} res]} {
		catch {$_db eval {ROLLBACK}}
		if {$_interrupted} {
			dict lappend results errors "interrupted"
			dict set results returnCode 3
		} else {
			debug "QueryExecutor::countResults: $res\nQuery was: SELECT count(*) FROM ($query)"
			dict set results returnCode 2
			dict lappend results errors $res
		}
	} else {
		dict set results returnCode 0
	}

	dict set results totalRows $totalRows

	return $results
}

body QueryExecutor::execSimple {executionResults query stmts} {
	dict set executionResults returnCode 0
	set lastStmt [lindex $stmts end]

	# NOTE:
	# Auto-LIMIT for simpleExec is not introduced, because we don't have parsed object
	# and LIMIT keyword may appear in any of subqueries, etc.

	# Executing query
	if {[catch {
		set row 1
		set changes 0
		if {$_sqliteVersion == 3} {
			set beginChanges [$_db total_changes]
		}
		set stopTime ""
		set startTime [clock microseconds]

		$_db eval $query R {
			if {$stopTime == ""} {
				set stopTime [clock microseconds]
			}
			set data [list]
			foreach id $R(*) {
				set colDict [dict create displayName $id value $R($id)]
				lappend data $colDict
			}

			# Executing script
			upvar 2 $_varName customVar_$_varName
			set customVar_$_varName $data
			uplevel 2 $_script

			incr row
			if {$_interrupted} {
				break
			}
		}
		if {$_sqliteVersion == 2} {
			incr changes [$_db changes]
		} elseif {$_sqliteVersion == 3} {
			set changes [expr {[$_db total_changes] - $beginChanges}]
		}
	} err]} {
		if {$_interrupted} {
			dict lappend executionResults errors "interrupted"
			dict set executionResults returnCode 3
		} else {
			# Failed execution
			dict set executionResults returnCode 1
			dict lappend executionResults errors "$err\n<simple query executor>"
		}
	} else {
		# Execution successful.

		# If no there was no results, then we have to put stopTime here
		if {$stopTime == ""} {
			set stopTime [clock microseconds]
		}

		dict set executionResults time [calculateTime $startTime $stopTime]
		dict set executionResults affectedRows $changes
	}

	return $executionResults
}

body QueryExecutor::attachDatabases {} {
	dict for {db attachName} $_attachedDatabasesMap {
		$_db attach $db $attachName
	}
}

body QueryExecutor::detachDatabases {} {
	dict for {db attachName} $_attachedDatabasesMap {
		catch {$_db detach $attachName}
	}
}

body QueryExecutor::calculateTime {startTime stopTime} {
	set value [expr {double($stopTime - $startTime) / 1000000}]
	return [format "%.6f" $value]
}

body QueryExecutor::interrupt {} {
	set _interrupted 1
	if {$_sqliteVersion == 3} {
		if {[catch {$_db interrupt} err]} {
			debug "interrupt error: $err"
		}
	}
}

body QueryExecutor::setTokenAction {queryIndex action tokens} {
	dict set _tokenActions [list $queryIndex $action] $tokens
}

body QueryExecutor::getTokenAction {queryIndex action} {
	if {[dict exists $_tokenActions [list $queryIndex $action]]} {
		return [dict get $_tokenActions [list $queryIndex $action]]
	} else {
		return [list]
	}
}

body QueryExecutor::applyTokenActions {allTokens actionList queryIndex {ignoreErrors false}} {
	set addActions [list]
	set replaceActions [list]
	set removeActions [list]

	# Sorting all actions in order: add, replace, remove.
	foreach actionName $actionList {
		if {![dict exists $_tokenActions [list $queryIndex $actionName]]} continue
		set actions [dict get $_tokenActions [list $queryIndex $actionName]]
		if {[dict exists $actions tokensToAdd]} {
			lappend addActions {*}[dict get $actions tokensToAdd]
		}
		if {[dict exists $actions tokensToReplace]} {
			lappend replaceActions {*}[dict get $actions tokensToReplace]
		}
		if {[dict exists $actions tokensToRemove]} {
			lappend removeActions {*}[dict get $actions tokensToRemove]
		}
	}
	
	# Adding
	foreach action $addActions {
		lassign $action positionToken tokensToAdd
		if {$positionToken == "end"} {
			set idx $positionToken
		} else {
			set idx [lsearch -exact $allTokens $positionToken]
			if {$idx == -1 && !$ignoreErrors} {
				error "Cannot find token $positionToken while trying to insert tokens: $tokensToAdd. All tokens:\n$allTokens"
			}
		}
		set allTokens [linsert $allTokens $idx {*}$tokensToAdd]
	}

	# Replacing
	foreach action $replaceActions {
		if {[llength $action] == 3} {
			lassign $action rangeTokens newTokens minReplaces
		} else {
			lassign $action rangeTokens newTokens
			set minReplaces 1
		}
		lassign $rangeTokens fromToken toToken
		set replaced 0
		set fromIdx [lsearch -exact $allTokens $fromToken]
		set toIdx [lsearch -exact $allTokens $toToken]
		while {$fromIdx > -1 && $toIdx > -1} {
			set allTokens [lreplace $allTokens $fromIdx $toIdx {*}$newTokens]

			set nextIdx [expr {$fromIdx + [llength $newTokens]}]
			set fromIdx [lsearch -exact -start $nextIdx $allTokens $fromToken]
			set toIdx [lsearch -exact -start $nextIdx $allTokens $toToken]
			incr replaced
		}
		if {$replaced < $minReplaces && !$ignoreErrors} {
			debug "AllTokens: $allTokens"
			error "Cannot find enough occurrences of $fromToken or $toToken to replace it with tokens: $newTokens. Required number of occurrences: $minReplaces"
		}
	}

	# Removing
	foreach token $removeActions {
		set idx [lsearch -exact $allTokens $token]
		while {$idx > -1} {
			set allTokens [lreplace $allTokens $idx $idx]
			set idx [lsearch -exact $allTokens $token]
		}
	}

	return $allTokens
}

body QueryExecutor::threadExec {query executionResults} {
	# Creating execution thread
	set thread [thread::create]

	# SQLite 2 or 3
	set handler [$_db getHandler]

	# Db handler for thread
	thread::send $thread [list set ::auto_path $::auto_path]
	thread::send $thread [list set ::noTransaction $noTransaction]
	thread::send $thread [list set ::DEBUG(sql) $::DEBUG(sql)]
	switch -- $handler {
		"::Sqlite2" {
			thread::send $thread [list package require sqlite 2.0]
			thread::send $thread [list set sqliteVersion 2]
			set sqliteCmd [list sqlite db [$_db getPath]]
		}
		"::Sqlite3" {
			thread::send $thread [list package require sqlite3]
			thread::send $thread [list set sqliteVersion 3]
			set sqliteCmd [list sqlite3 db [$_db getPath]]
		}
	}

	if {[catch {thread::send $thread $sqliteCmd} err]} {
		catch {thread::release $thread}
		cutOffStdTclErr err
		dict set executionResults returnCode 1
		dict lappend executionResults errors $err
		return $executionResults
	}

	switch -- $handler {
		"::Sqlite3" {
			thread::send $thread [list catch [list db nullvalue [set ${handler}::nullValue]]]
			thread::send $thread [list catch [list db enable_load_extension true]]
		}
	}

	# Converting BEGIN/COMMIT to SAVEPOINT/RELEASE
	# Disabled for now, because it causes about 40secs delay when used against
	# 400KB sql file. Currently executing SQL file with transactions inside
	# will simply cause regular error message to appear with accurate message
	# about trying to start transaction within a transaction.
	# set query [convertTransactionsToSavepoints $query [$_db getDialect] true]

	thread::send $thread [list set query $query]
	thread::send -async $thread {
		set code [catch {
			if {!$::noTransaction} {
				if {$::DEBUG(sql)} {puts "db -> BEGIN"}
				db eval {BEGIN}
			}

			if {$::DEBUG(sql)} {puts "db -> $query"}
			db eval $query
		} res]
		list $res $code
	} ::threadExecutionResults($thread)
	
	# Waiting for results
	# The ::threadExecutionResults($thread) variable must be global scope, becuase [vwait] requires it.
	vwait ::threadExecutionResults($thread)
	lassign $::threadExecutionResults($thread) results code

	if {$code == 0} {
		# Commit
		if {!$noTransaction} {
			thread::send -async $thread {
				catch {
					if {$::DEBUG(sql)} {puts "db -> COMMIT"}
					db eval {COMMIT}
				}
			} ::threadExecutionResults($thread)
			vwait ::threadExecutionResults($thread)
			set code $::threadExecutionResults($thread)
		} else {
			set code 0
		}
	} else {
		# Rollback
		if {!$noTransaction} {
			thread::send -async $thread {
				catch {
					if {$::DEBUG(sql)} {puts "db -> ROLLBACK"}
					db eval {ROLLBACK}
				}
			} ::threadExecutionResults($thread)
			vwait ::threadExecutionResults($thread)
		} else {
			set code 0
		}
	}

	thread::send $thread {db close}
	catch {thread::release $thread}

	if {$code == 0} {
		dict set executionResults rawResults $results
	} else {
		dict lappend executionResults errors $results
	}
	
	dict set executionResults returnCode $code
	unset ::threadExecutionResults($thread)

	return $executionResults
}
