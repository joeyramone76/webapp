use src/plugins/plugin.tcl
use src/common/common.tcl

#>
# @class SqlFormattingPlugin
# Base class for all SQL formatting plugins.
# Take a look at {@class SqlUtils} - it's very useful for this kind of plugins.
#<
abstract class SqlFormattingPlugin {
	inherit Plugin

	constructor {} {}

	#>
	# @var defaultHandler
	# Default handler name (returned by {@method getName}) configured by user.
	#<
	common defaultHandler ""

	#>
	# @var handlers
	# Keeps list of installed formatting plugin classes.
	#<
	common handlers [list]

	public {
		#>
		# @method init
		# Initializes list of handlers. They should be already loaded by interpreter, this method just find their classes
		# and places them in {@var handlers} variable.
		#<
		proc init {}

		#>
		# @method formatSql
		# @param tokenizedQuery SQL query splitted into list of tokens. Each token is pair of two elements: first element is token type (SQL or STR), second is token contents. Basicly it's result of {@method SqlUtils::stringTokenize} call on original query. It is always single SQL query.
		# @param originalQuery Original SQL query as plain text, but excluding any comments (query processed with {@method SqlUtils::removeComments}). It is always single SQL query.
		# @param db Optional database to do formatting against specifict SQL dialect.
		# Implementation of this method should format query. This process is sometimes called 'pretty printing'.
		# @return Plain text which is SQL query after formatting.
		#<
		abstract method formatSql {tokenizedQuery originalQuery {db ""}}

		#>
		# @method getName
		# @return Name of formatter to display on interface.
		#<
		abstract proc getName {}

		#>
		# @method configurable
		# @return Boolean value defining if implemented populating engine supports configuration. If <code>true</code>, then methods {@method createConfigUI} and {@method applyConfig} implementations should not be empty.
		#<
		abstract proc configurable {}

		#>
		# @method createConfigUI
		# @param path Tk widget path to frame where configuration should be placed.
		# Implementation should create configuration widget in frame pointed by given path.
		# Can do nothing if {@method configurable} returns <code>false</code>.
		#<
		abstract proc createConfigUI {path}

		#>
		# @method applyConfig
		# @param path Tk widget path to frame where configuration is placed.
		# Implementation should extract necessary informations from configuration widget and store it in local variables,
		# so they can be used later, while populating by method {@method nextValue}.<br>
		# Configuration widget in path will be destroyed just after this method call is completed.
		# Can do nothing if {@method configurable} returns <code>false</code>.
		#<
		abstract proc applyConfig {path}
	}
}


body SqlFormattingPlugin::init {} {
	set handlers [lsort -command Plugin::sortCmd [findClassesBySuperclass "::SqlFormattingPlugin"]]
	if {$defaultHandler == ""} {
		set defaultHandler [[lindex $handlers 0]::getName]
	}
	foreach hnd $handlers {
		if {[catch {${hnd}::init} res]} {
			if {$::DEBUG(global)} {
				puts "Error while initializing $hnd plugin:"
				puts $::errorInfo
			}
		}
	}
}
