use src/common/serializable.tcl

#>
# @class Statement
# Base class for all SQL statement container objects.
# Provides common interface to build statements tree and to process some basic
# operations on the prepared tree.
#<
class Statement {
	inherit Serializable

	constructor {} {}
	destructor {}

	private {
		#>
		# @var _baseDatabase
		# Keeps {@class DB} object of database connection, where the statement is executed.
		#<
		variable _baseDatabase ""

		#>
		# @var _registeredDatabases
		# Contains list of database objects registered in application.
		#<
		variable _registeredDatabases [list]

		#>
		# @method _nativeDatabases
		# Contains list of native SQLite database objects for current statement context.
		#<
		variable _nativeDatabases [list]

		#>
		# @method _useTokensForContext
		# If true, then {@method getContextInfo} will return values as tokens.
		# If false, then it will return values as plain literal values.
		#<
		common _useTokensForContext false

		#>
		# @var _forceRecurentContextChecking
		# If true, then all objects are checked by {@method getContextInfo} recurently,
		# despite the {@var checkRecurentlyForContext} value.
		# If false, the {@var checkRecurentlyForContext} value of each object is respected.
		# This setting is used by QueryExecutor to attach all databases in subqueries,
		# but also QueryExecutor sets it later to false, so no ROWIDs are generated for tables from subqueries.
		#<
		common _forceRecurentContextChecking false
	}

	protected {
		#>
		# @var _listTypeVariableForDebug
		# Keeps list of variable names of current container, that represents some kind of list, not a single value.
		# It's required for list of plain text values, cause there's no other way to determinate that kind of variables.
		# Example usage is in {@class StatementTypeName}.
		#<
		variable _listTypeVariableForDebug [list]

		#>
		# @method resolveDatabase
		# @param symbolicDatabaseName Symbolic database name used in SQL. Might refer to database name from objects tree or to already attached database.
		# This method is used by derived classes to resolve name of database used in SQL. User can put either symbolic database name
		# from objects tree (on the left side of window), or name of already attached database (name from ATTACH statement).<br>
		# It's expected that {@method setBaseDatabase} was already called.<br>
		# Type element in returned value is one of <code>SYMBOLIC</code> or <code>NATIVE</code>.
		# <code>SYMBOLIC</code> stands for database from objects tree (on the left) and <code>NATIVE</code> stands for SQLite native
		# database object attached by <code>ATTACH</code> statement or the <code>main</code> database.
		# The value element from return list is the {@class DB} object matched to given (in parameters) name for case when it's
		# <code>SYMBOLIC</code> type. For <code>NATIVE</code> type the value is same name as passed in arguments.
		# @return Dictionary with 2 keys: TYPE and VALUE. The dictionary is empty in case when no database was found for given name.
		#<
		method resolveDatabase {symbolicDatabaseName}

		#>
		# @method getDatabaseNames
		# Derived statement class should return any database names if they occur in the statement.
		# @return List of database names.
		#<
		method getDatabaseNames {} {return [list]}

		#>
		# @method getTableNames
		# Derived statement class should return any table names if they occur in the statement. This should return table name only if the occurance means the table is a source of data to the query in this statement.
		# @return List of elements, where each of them contains 2 values: real table name and its alias. Second value can be empty.
		#<
		method getTableNames {} {return [list]}

		#>
		# @method getTableNames
		# Derived statement class should return any table names if they occur in the statement.
		# @return List of elements, where each of them contains 2 values: real table name and its alias. Second value can be empty.
		#<
		method getAllTableNames {} {$this getTableNames}

		#>
		# @method getAllAliases
		# Derived statement class should return any aliases if they occur in the statement.
		# @return List of alias names, no matter if column alias, or table alias.
		#<
		method getAllAliases {} {return [list]}

		#>
		# @method getColumnNames
		# Derived statement class should return list of column names or definitions and their aliases.
		# @return List of elements with 3 values - column definition (name or some other expression enclosed in statement object),
		# type (<code>LITERAL</code> or <code>OBJECT</code>) and alias, where alias can be empty.
		#<
		method getColumnNames {} {return [list]}

		method getFunctions {} {return [list]}
		method getContextValue {varName}
		method getContextValueFromToken {token}
	}

	public {
		#>
		# @var checkRecurentlyForContext
		# Decides if current statement will accept call to {@method getContextInfo} from parent statement.
		#<
		variable checkRecurentlyForContext true
		#>
		# @var checkParentForContext
		# Decides if current statement will call to {@method getContextInfo} on parent statement.
		#<
		variable checkParentForContext true

		#>
		# @var allTokens
		# List of all tokens for this statement. It's filled for all statements and can be used
		# to custom analysis of syntax.
		#<
		variable allTokens [list]

		#>
		# @var _childStatements
		# Used only for parsing process. Doesn't provide true list of children statement objects!
		# Don't use it externally.
		# Currently it has to be public because of a way how {@class Serialize} works. To be fixed in future.
		#<
		variable _childStatements [list]

		#>
		# @var _parentStatement
		# Used only for parsing process. Doesn't provide true parent statement object!
		# Don't use it externally.
		# Currently it has to be public because of a way how {@class Serialize} works. To be fixed in future.
		#<
		variable _parentStatement ""

		#>
		# @method afterParsing
		# Processes collected statement data to get final output.
		# It includes translating database symbolic names to real names, etc.
		#<
		method afterParsing {} {}

		#>
		# @method debugPrint
		# @param ommitParams List of keywords to define what elements to ommit while displaying object. Currently supported keywords are: <code>EMPTY</code>, <code>ZERO</code>, <code>ALL_TOKENS</code>.
		# @param depth Depth of spaces to indent.
		# Used for debugging parser. Prints out all public members of the object.
		#<
		method debugPrint {{ommitParams "EMPTY ZERO CHILDS"} {depth 0}}

		#>
		# @method appendToken
		# @param token Token element (just as received from {@class Lexer}).
		# Adds token element to list of tokens used to complete current (this) statement.
		# @see var allTokens
		#<
		method appendToken {token}

		#>
		# @method addChildStatement
		# @param stmt Statement (or derived class) object.
		# Adds given statement object to list of children statements. It helps to build hierarchy of statements,
		# so methods like {@method setBaseDatabase} can work recursively.
		# @see var _childStatements
		#<
		method addChildStatement {stmt}

		#>
		# @method setParentStatement
		# @param setParentStatement Statement (or derived class) object.
		# Assigns parent statement. Root statement doesn't have parent.
		# @see var _childStatements
		#<
		method setParentStatement {stmt}

		#>
		# @method setBaseDatabase
		# @param db Database object (instance of {@class DB}).
		# @param nativeDatabases List of native SQLite database objects to remember. Empty value will cause to read it from {@var _baseDatabase}.
		# @param registeredDatabases List of database objects registered in application to remember. Empty value will cause to read it from {@var _baseDatabase}.
		# Assigns base statement execution database. Calls it's children with same arguments (parent statement resolves empty arguments first).
		# @see var _baseDatabase
		#<
		method setBaseDatabase {db {nativeDatabases ""} {registeredDatabases ""}}

		#>
		# @method callAfterParsing
		# Recurently calls {@method afterParsing} routine.
		# @see method afterParsing
		#<
		method callAfterParsing {}

		#>
		# @method searchForTokenContainer
		# @param token Token (as from tokenizer) to look for.
		# Searches recursively for token in statement objects.
		# @return Statement object which contains given token or empty string if no statement contains it.
		#<
		method searchForTokenContainer {token}

		#>
		# @method debugInTree
		# @param parent Parent node from treeview for recurent calls.
		# This method is used while debugging parser to show parsed objects hierarchy as a tree.
		#<
		method debugInTree {{parent "root"}}

		#>
		# @method getStatementForPosition
		# @param index Position index.
		# @param topAllTokens When called externally - it should be ommited. This parameter is passed by top-level statement to childs.
		# Looks for statement enclosing given index. Does it recursively.
		# @return Deepest statement enclising given position.
		#<
		method getStatementForPosition {index {topAllTokens ""}}

		#>
		# @method getContextInfo
		# @param type Currently supported: <code>TABLE_NAMES</code>, <code>COLUMN_NAMES</code>.
		# @param ommit This parameter is used when method is called from child on parent or vice versa, so parent/child won't call caller, which would cause infinite recursion.
		# For <code>TABLE_NAMES</code> it collects list of real table names and their aliases (if defined). Makes this command
		# to return list of elements with 2 values - table name and alias, where alias can be empty.
		# <br>
		# For <code>COLUMN_NAMES</code> it collects list of column names or definitions and their aliases. Makes this command
		# to return list of elements with 3 values - column definition (name or some other expression enclosed in statement object),
		# type (<code>LITERAL</code> or <code>OBJECT</code>) and alias, where alias can be empty.
		# @return Returned contents depend on value passed as <i>type</i>.
		#<
		method getContextInfo {type {ommit ""}}

		method setContextTokensMode {enabled}
		method setForceRecurentContextChecking {enabled}
		method getValue {varName {strip true}}
		method setValue {varName value}
		method getListValue {varName {strip true}}
		method getType {varName}
		method fieldExists {name}
		method toSql {{doStripping false}}
		method toSqlWithoutComments {}
		method getFunctionsWithArgs {}
	}
}

body Statement::constructor {} {
	#puts "Creating $this"
}

body Statement::destructor {} {
	#puts "Deleting $this"
}

body Statement::setContextTokensMode {enabled} {
	set _useTokensForContext $enabled
}

body Statement::getValue {varName {strip true}} {
	set value [$this cget -$varName]
	if {[string first "::" [lindex $value 0]] != 0 && [llength $value] == 4} {
		if {$strip} {
			return [stripObjName [lindex $value 1]]
		} else {
			return [lindex $value 1]
		}
	} else {
		return $value
	}
}

body Statement::setValue {varName value} {
	set value [$this cget -$varName]
	if {[string first "::" [lindex $value 0]] != 0 && [llength $value] == 4} {
		$this configure -$varName [lreplace $value 1 1 $value]
	} else {
		$this configure -$varName $value
	}
}

body Statement::getListValue {varName {strip true}} {
	set values [$this cget -$varName]
	set results [list]
	foreach value $values {
		if {[string first "::" [lindex $value 0]] != 0 && [llength $value] == 4} {
			if {$strip} {
				lappend results [stripObjName [lindex $value 1]]
			} else {
				lappend results [lindex $value 1]
			}
		} else {
			lappend results $value
		}
	}
	return $results
}

body Statement::getType {varName} {
	return [lindex [$this cget -$varName] 0]
}

body Statement::getContextValue {varName} {
	if {$_useTokensForContext} {
		set value [$this cget -$varName]
		if {[string first "::" [lindex $value 0]] != 0 && [llength $value] == 4} {
			return [stripObjName [$this cget -$varName]]
		} else {
			return $value
		}
	} else {
		return [getValue $varName]
	}
}

body Statement::getContextValueFromToken {token} {
	if {$_useTokensForContext} {
		return $token
	} else {
		return [lindex $token 1]
	}
}

body Statement::appendToken {token} {
	lappend allTokens $token
	if {$_parentStatement != ""} {
		$_parentStatement appendToken $token
	}
}

body Statement::addChildStatement {stmt} {
	lappend _childStatements $stmt
}

body Statement::setParentStatement {stmt} {
	set _parentStatement $stmt
}

body Statement::resolveDatabase {symbolicDatabaseName} {
	# Input parameter is whole token, so we need to extract name only
	set symbolicDatabaseName [lindex $symbolicDatabaseName 1]

	# First look in native databases, in case that some database was attached with name XYZ
	# and then new database was registered with same name. This is allowed, but user will only
	# be able to detach such database and he could not attach it with that name again.
	if {$symbolicDatabaseName in $_nativeDatabases} {
		return [dict create TYPE "NATIVE" VALUE $symbolicDatabaseName]
	}

	# Then look in registered databases
	foreach db $_registeredDatabases {
		if {[$db getName] == $symbolicDatabaseName} {
			return [dict create TYPE "SYMBOLIC" VALUE $db]
		}
	}
	return [dict create]
}

body Statement::setBaseDatabase {db {nativeDatabases ""} {registeredDatabases ""}} {
	set _baseDatabase $db
	if {$nativeDatabases == ""} {
		# This is case when parent statement is called. We need to resolve all objects from base database.
		if {$_baseDatabase != ""} {
			set _nativeDatabases [$_baseDatabase getNativeDatabaseObjects]
		} else {
			set _nativeDatabases [list]
		}
		set _registeredDatabases [DBTREE getRegisteredDatabaseList]
	} else {
		# This is case for children call. Everything is given in parameters.
		set _nativeDatabases $nativeDatabases
		set _registeredDatabases $registeredDatabases
	}
	# ...and call childrens
	foreach child $_childStatements {
		$child setBaseDatabase $db $_nativeDatabases $_registeredDatabases
	}
}

body Statement::debugPrint {{ommitParams "EMPTY ZERO CHILDS"} {depth 0}} {
	set spaces [string repeat { } [expr {8*$depth}]]
	if {"CHILDS" in $ommitParams} {
		puts "$spaces$this"
	} else {
		puts "$spaces$this (childs: $_childStatements)"
	}
	foreach var [$this info variable] {
		if {[$this info variable $var -protection] == "public"} {
			set varName [string range $var [expr {[string first "::" $var 2]+2}] end]
			set value [$this cget -$var]
			if {$varName in [list "_parentStatement" "_childStatements"]} continue
			if {("EMPTY" in $ommitParams) && $value == ""} continue
			if {("ALL_TOKENS" in $ommitParams) && $varName == "allTokens"} continue
			if {("ZERO" in $ommitParams) && $value == "0"} continue
			if {"MEMBERS" ni $ommitParams} {
				puts "$spaces    $varName = $value"
			}
			catch {
				foreach it $value {
					$it debugPrint $ommitParams [expr {$depth+1}]
				}
			}
		}
	}
	puts ""
}

body Statement::debugInTree {{parent "root"}} {
	if {![winfo exists $::PARSER_DEBUG_TREE]} return
	if {!$::DEBUG(parser_tree)} return
	if {$parent == "root"} {
		$::PARSER_DEBUG_TREE delItem root
		set ::PARSER_DEBUG_TREE_ROOT_OBJ $this
	}
	set thisNode [$::PARSER_DEBUG_TREE addItem $parent "" "$this"]
	foreach var [$this info variable] {
		if {[$this info variable $var -protection] == "public"} {
			set varName [string range $var [expr {[string first "::" $var 2]+2}] end]
			set value [$this cget -$var]
			if {$varName in [list "_parentStatement" "_childStatements"]} continue
			if {$::PARSER_DEBUG_TREE_OPTS(hideTokenMetadata) && [string first "::" [lindex $value 0]] != 0 && [llength $value] == 4} {
				# It's an object and we need to get rid of metadata
				set value [lindex $value 1]
			} elseif {$::PARSER_DEBUG_TREE_OPTS(hideTokenMetadata) && [lindex [wsplit $var "::"] end] in $_listTypeVariableForDebug} {
				# It's list of plain values and we need to extract only the values
				set valTemp [list]
				foreach val $value {
					lappend valTemp [lindex $val 1]
				}
				set value $valTemp
			}
			if {$varName in [list "checkRecurentlyForContext" "checkParentForContext"]} continue
			if {$::PARSER_DEBUG_TREE_OPTS(hideEmpty) && $value == ""} continue
			if {$::PARSER_DEBUG_TREE_OPTS(hideAllTokens) && $varName == "allTokens"} continue
			if {$::PARSER_DEBUG_TREE_OPTS(hideZero) && $value == "0"} continue
			set id [$::PARSER_DEBUG_TREE addItem $thisNode "" "$varName = $value"]
			catch {
				foreach it $value {
					$it debugInTree $id
				}
			}
		}
	}
	if {$parent == "root"} {
		$::PARSER_DEBUG_TREE expand root true
	}
}

body Statement::callAfterParsing {} {
	afterParsing
	foreach child $_childStatements {
		$child callAfterParsing
	}
}

body Statement::getStatementForPosition {index {topAllTokens ""}} {
	#
	# Firstly go into child statements - they have priority
	#
	foreach obj $_childStatements {
		if {$topAllTokens == ""} {
			set resToken [$obj getStatementForPosition $index $allTokens]
		} else {
			set resToken [$obj getStatementForPosition $index $topAllTokens]
		}
		if {$resToken != ""} {
			# Token is in child object
			return $resToken
		}
	}

	#
	# Secondly self-check
	#
	if {[llength $allTokens] == 0} {
		# This statement is empty so far
		return ""
	}

	if {$topAllTokens == ""} {
		# This is top level statement, so it's easy to find end.
		set end [lindex [lindex $allTokens end] 3]
		incr end 99999999;# for toplevel statement we allow for position+infinity (end of sql)
	} else {
		# This is some child statement, so we need to find end token for this statement first
		set endToken [lindex $allTokens end]

		# Then look for token after it in toplevel tokens, so find endToken in toplevel tokens.
		set tokenAfterEndIndex [lsearch -exact $topAllTokens $endToken]
		if {$tokenAfterEndIndex == -1} {
			error "Cannot find token of child statement in allTokens of top statement! Looking for token $endToken of object $this in top statement allTokens: $topAllTokens"
		}

		# Then find next token
		incr tokenAfterEndIndex
		set tokenAfterEnd [lindex $topAllTokens $tokenAfterEndIndex]
		if {$tokenAfterEnd != ""} {
			# Getting begin position of next token and decrementing it by 1 to get our end position
			set beginPositionOfTokenAfterEnd [lindex $tokenAfterEnd 2]
			set end [expr {$beginPositionOfTokenAfterEnd - 1}]

			# If next token is a ')' character, then we need to make a little hack to correctly detect context
			lassign $tokenAfterEnd tokenType tokenValue tokenBegin tokenEnd
			if {$tokenType == "PAR_RIGHT" && $tokenValue == ")"} {
				# This is hack to support position "just before right parenthesis" as context inside of it
				incr end
			}
		} else {
			# If there is no next token, then we can assume that this is last token (even this is substatement)
			# and we need to enlarge end position by 1 to support last cursor position.
			set end [lindex [lindex $allTokens end] 3]
			incr end
		}
	}

	set begin [lindex [lindex $allTokens 0] 2]
	if {$begin == "" || $end == ""} {
		# No tokens - it should not happend, since allTokens are checked before,
		# but this is just in case
		return ""
	}

	if {$begin <= $index && $index <= $end} {
		# Token is in this object
		return $this
	}

	if {$topAllTokens == "" && $index < $begin} {
		# There are some whitespaces before statement and cursor is placed in there,
		# so statement containing is the toplevel one.
		return $this
	}

	# Token is not in this object, neither in any of child objects
	return ""
}

body Statement::getContextInfo {type {ommit ""}} {
	set results [list]
	switch -- $type {
		"COLUMN_NAMES" {
			lappend results {*}[getColumnNames]
		}
		"TABLE_NAMES" {
			lappend results {*}[getTableNames]
		}
		"ALL_TABLE_NAMES" {
			lappend results {*}[getAllTableNames]
		}
		"DATABASE_NAMES" {
			lappend results {*}[getDatabaseNames]
		}
		"ALIASES" {
			lappend results {*}[getAllAliases]
		}
	}
	foreach obj $_childStatements {
		if {![$obj cget -checkRecurentlyForContext] && !$_forceRecurentContextChecking && ![$this isa ::StatementSql] && ![$this isa ::Statement2Sql]} continue
		if {$obj == $ommit} continue
		lappend results {*}[$obj getContextInfo $type $this]
	}
	if {$_parentStatement != "" && $_parentStatement != $ommit && $checkParentForContext} {
		lappend results {*}[$_parentStatement getContextInfo $type $this]
	}
	return $results
}

body Statement::fieldExists {name} {
	return [expr {![catch {$this info variable $name}]}]
}

body Statement::toSql {{doStripping false}} {
	set sql [list]
	foreach token $allTokens {
		lassign $token type value begin end
		if {$doStripping && [isObjWrapped $value] && ![doObjectNeedWrapping [string range $value 1 end-1]]} {
			lappend sql [stripObjName $value]
		} else {
			lappend sql $value
		}
		if {$type == "COMMENT" && [string first "--" $value] == 0} {
			lappend sql "\n"
		}
	}
	return [join $sql " "]
}

body Statement::toSqlWithoutComments {} {
	set sql [list]
	foreach token $allTokens {
		lassign $token type value begin end
		if {$type == "COMMENT"} continue
		lappend sql $value
	}
	return [join $sql " "]
}

body Statement::getFunctionsWithArgs {} {
	set funcList [$this getFunctions]
	foreach child $_childStatements {
		set childFuncList [$child getFunctionsWithArgs]
		if {[llength $childFuncList] > 0} {
			lappend funcList {*}$childFuncList
		}
	}
	return $funcList
}

body Statement::setForceRecurentContextChecking {enabled} {
	set _forceRecurentContextChecking $enabled
}
