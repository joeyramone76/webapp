# This code is send to newly created thread which parses SQL
###########################
# Preparing interpreter
###########################
package require Itcl
namespace import ::itcl::*

set ::DEBUG(parser) [tsv::get ::allThreads debug_parser]
set ::DEBUG(parser_tree) [tsv::get ::allThreads debug_parser_tree]
set ::DEBUG(re) [tsv::get ::allThreads debug_re]

source src/common/use.tcl

use src/keywords.tcl
use src/common/common.tcl
use src/common/common_sql.tcl
use src/common/thread_class_proxy.tcl

set filesToOmmit {
	src/parser/debug_tree.tcl
	src/parser/parser_pool.tcl
	src/parser/parsing_routines_in_thread.tcl
	src/parser/universal_parser.tcl
	src/parser/universal_lexer.tcl
}

foreach f [glob -directory src/parser *.tcl] {
	if {$f in $filesToOmmit} continue
	use $f
}
foreach f [glob -directory src/containers *.tcl] {
	if {$f in $filesToOmmit} continue
	use $f
}

########################
# Proxy classes
########################
class DbProxy {
	inherit ThreadClassProxy
	constructor {thread realObject} {
		ThreadClassProxy::constructor $thread $realObject
	} {}
	public {
		ThreadClassProxy::makeProxy getHandler
		ThreadClassProxy::makeProxy getName
		ThreadClassProxy::makeProxy getDialect
		ThreadClassProxy::makeProxy getNativeDatabaseObjects
	}
}

class DbTreeProxy {
	inherit ThreadClassProxy
	constructor {thread realObject} {
		ThreadClassProxy::constructor $thread $realObject
	} {}
	private {
		variable _proxiedDb
	}
	public {
		method getRegisteredDatabaseList {} {
			set dbList [call getRegisteredDatabaseList]
			set resultList [list]
			foreach db $dbList {
				if {![info exists _proxiedDb($db)]} {
					set proxied [DbProxy ::#auto $_thread $db]
					set _proxiedDb($db) $proxied
				}
				lappend result $_proxiedDb($db)
			}
			return $resultList
		}
	}
}

class WInfoProxy {
	inherit ThreadClassProxy
	constructor {thread realObject} {
		ThreadClassProxy::constructor $thread $realObject
	} {}
	public {
		ThreadClassProxy::makeProxy exists
	}
}

if {$::DEBUG(parser_tree)} {
	class DebugTreeProxy {
		inherit ThreadClassProxy
		constructor {thread realObject} {
			ThreadClassProxy::constructor $thread $realObject
		} {}
		public {
			ThreadClassProxy::makeProxy addItem
			ThreadClassProxy::makeProxy delItem
			ThreadClassProxy::makeProxy expand
		}
	}
	
	DebugTreeProxy ::$::PARSER_DEBUG_TREE [tsv::get ::allThreads MAIN_THREAD] $::PARSER_DEBUG_TREE
}

DbTreeProxy ::DBTREE [tsv::get ::allThreads MAIN_THREAD] "DBTREE"
WInfoProxy ::winfo [tsv::get ::allThreads MAIN_THREAD] "winfo"

############################
# Lexer objects and procs
############################

# Parsers
set ::lexer(sqlite2) [Lexer2 ::#auto]
set ::lexer(sqlite3) [Lexer3 ::#auto]

proc lexer {dialect args} {
	return [$::lexer($dialect) {*}$args]
}

proc tokenize {sql {db ""}} {
	set dialect "sqlite3"
	if {$db != ""} {
		set db [::DbProxy ::#auto [tsv::get ::allThreads MAIN_THREAD] $db]
		set dialect [$db getDialect]
	}
	set lexer $::lexer($dialect)
	set tokens [$lexer tokenizeSql $sql]
	if {$db != ""} {
		delete object $db
	}
	return $tokens
}

############################
# Parsing objects and procs
############################

# Parsers
set ::parser(sqlite2) [SqlParser2 ::#auto]
set ::parser(sqlite3) [SqlParser3 ::#auto]

proc parseSqlContents {contents db {idx 0} {stdParsing true} {expectedTokenParsing true} {tolerateLacksForStdParsing false}} {
	return [parseSqlContentsOrTokens $contents "" $db $idx $stdParsing $expectedTokenParsing $tolerateLacksForStdParsing]
}

proc parseSqlTokens {tokens db {idx 0} {stdParsing true} {expectedTokenParsing true} {tolerateLacksForStdParsing false}} {
	return [parseSqlContentsOrTokens "" $tokens $db $idx $stdParsing $expectedTokenParsing $tolerateLacksForStdParsing]
}

#>
# @method parseSqlContentsOrTokens
# @param contents SQL code to parse. Pass empty to use <i>tokens</i>.
# @param tokens Tokens to parse. Pass empty to use <i>contents</i>.
# @param db Instance of {@class DB}. Can be empty if <i>parser</i> is provided.
# @param idx Position to parse statement for. For single statement can be ommited.
# @param stdParsing Deciedes whether or not to process standard parsing. If disabled, the first element of result will be empty.
# @param expectedTokenParsing Deciedes whether or not to process parsing for expected token. If disabled, the second element of result will be empty.
# @param tolerateLacksForStdParsing Deciedes whether to tolerate lacking tokens for standard parsing, just like for expected token parsing process.
# Parses statement which includes given position (<i>contents</i> can contain more statements).
# The <code>object</code> key in result dict depends on external parser usage. When internal parser is used, then the parser is deleted right away and <code>object</code> is deleted automatically.
# @return List of 2 elements, each of them is Tcl dict. First dict comes from regular parsing process, second comes from parsing with checking for expected token.
#<
proc parseSqlContentsOrTokens {contents tokens db {idx 0} {stdParsing true} {expectedTokenParsing true} {tolerateLacksForStdParsing false}} {
	# Determinating parser
	set dialect "sqlite3"
	if {$db != ""} {
		set db [::DbProxy ::#auto [tsv::get ::allThreads MAIN_THREAD] $db]
		set dialect [$db getDialect]
	}
	set parser $::parser($dialect)

	# Parse SQL with full parsing (but also with lacks tolerantion),
	# then parse for expected tokens
	if {$tokens != ""} {
		if {$stdParsing} {
			$parser setLacksTolerantion $tolerateLacksForStdParsing
			set parsedDict [$parser parseTokens $tokens $idx]
		} else {
			set parsedDict ""
		}
		if {$expectedTokenParsing} {
			$parser setLacksTolerantion true
			set expectedDict [$parser checkForExpectedTokensInTokens $tokens $idx]
		} else {
			set expectedDict ""
		}
	} else {
		if {$stdParsing} {
			$parser setLacksTolerantion $tolerateLacksForStdParsing
			set parsedDict [$parser parse $contents $idx]
		} else {
			set parsedDict ""
		}
		if {$expectedTokenParsing} {
			$parser setLacksTolerantion true
			set expectedDict [$parser checkForExpectedTokens $contents $idx]
		} else {
			set expectedDict ""
		}
	}

	if {$stdParsing} {
		# Extracting toplevel statement object
		set obj [dict get $parsedDict object]

		# Resolving all informations that requires db object
		if {$db != ""} {
			$obj setBaseDatabase $db
			$obj callAfterParsing
		}

		# Show statements tree if debug is enabled
		if {$::DEBUG(parser_tree)} {
			$obj debugInTree
		}
	}
	
	if {$::DEBUG(parser)} {
		puts "Parsed dict: $parsedDict"
	}

	# Serialize to string
	if {$parsedDict != "" && [dict exists $parsedDict object]} {
		set obj [dict get $parsedDict object]
		dict set parsedDict object [$obj serialize]
	}

	# Cleanup
	if {$db != ""} {
		delete object $db
	}

	# We can also cleanup parsed objects, as they are serialized at this stage
	$parser freeParserObjects

	return [list $parsedDict $expectedDict]
}
