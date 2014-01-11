# This code is send to newly created thread which checks for syntax errors in SQLEditor
###########################
# Preparing interpreter
###########################
package require Itcl
namespace import ::itcl::*

set ::DEBUG(parser) [tsv::get ::allThreads debug_parser]
set ::DEBUG(parser_tree) [tsv::get ::allThreads debug_parser_tree]
set ::PARSER_DEBUG_TREE_ROOT_OBJ ""
set ::PARSER_DEBUG_TREE ""

source src/common/use.tcl

use src/keywords.tcl
use src/common/common.tcl
use src/parser/lexer.tcl
use src/common/thread_class_proxy.tcl

set filesToOmmit {
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
		ThreadClassProxy::makeProxy eval
		ThreadClassProxy::makeProxy info
		ThreadClassProxy::makeProxy getHandler
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

DbTreeProxy ::DBTREE [tsv::get ::allThreads MAIN_THREAD] "DBTREE"
WInfoProxy ::winfo [tsv::get ::allThreads MAIN_THREAD] "winfo"

############################
# Error checking procs
############################
proc parseAllStatementsForErrorChecking {} {
	set mainThread [tsv::get ::allThreads MAIN_THREAD]

	set result [thread::send $mainThread [list $::SQL_EDITOR getCEdit] edit]
	if {$result} return ;# Error evaluating in main thread

	set result [thread::send $mainThread [list $edit tag ranges error] ranges]
	if {$result} return ;# Error evaluating in main thread

	if {[llength $ranges] > 0} {
		set result [thread::send $mainThread [list $edit tag remove error {*}$ranges] tmp]
		if {$result} return ;# Error evaluating in main thread
	}

	set result [thread::send $mainThread [list $::SQL_EDITOR getDB] db]
	if {$result} return ;# Error evaluating in main thread

	set result [thread::send $mainThread [list $edit get 1.0 end] contents]
	if {$result} return ;# Error evaluating in main thread

	set lexingDict [thread::send $mainThread [list UniversalLexer::tokenizeStatic $contents $db]]
	set allTokens [dict get $lexingDict tokens]
	set stmts [Lexer::splitStatements $allTokens]

	foreach stmt $stmts {
		if {[llength $stmt] == 0} continue
		set firstToken [lindex $stmt 0]
		lassign $firstToken type value begin end
		set res [parsePositionForErrorChecking $edit $db $contents $mainThread $begin]
		if {$res != 0} {
			break ;# problem occured while checking errors, so do not continue it for now
		}
	}
}

proc parsePositionForErrorChecking {edit db contents mainThread index} {
	set parsedDict [thread::send $mainThread [list UniversalParser::parseForErrorChecking $contents $db $index]]

	set result [thread::send $mainThread [list $edit get 1.0 end] contentsAfter]
	if {$result} {
		return 1 ;# Error evaluating in main thread
	}

	if {![string equal $contents $contentsAfter]} {
		return 1 ;# Contents have changed.
	}

	return [parseForErrorChecking $edit $mainThread $parsedDict]
}

proc parseForErrorChecking {edit mainThread parsedDict} {
	set allTokens [dict get $parsedDict allTokens]
	set lastValidTokenIndex [dict get $parsedDict lastValidTokenIndex]
	set errorToken [lindex $allTokens [expr {$lastValidTokenIndex+1}]]
	if {$errorToken == ""} {return 0}

	lassign $errorToken type value begin end
	set result [thread::send $mainThread [list $edit index "1.0 +$begin chars"] errorBegin]
	if {$result} return ;# Error evaluating in main thread

	set lastToken [lindex $allTokens end]
	lassign $lastToken type value begin end
	set result [thread::send $mainThread [list $edit index "1.0 +$end chars +1 chars"] errorEnd]
	if {$result} return ;# Error evaluating in main thread

	set result [thread::send $mainThread [list $::SQL_EDITOR addErrorTag $errorBegin $errorEnd] tmp]
	if {$result} return ;# Error evaluating in main thread

	return 0
}
