use src/common/common.tcl
use src/plugins/plugin.tcl

#>
# @class PopulatingPlugin
# Base class for all populating plugins.
#<
abstract class PopulatingPlugin {
	inherit Plugin

	#>
	# @var defaultHandler
	# Default handler configured by user.
	#<
	common defaultHandler ""

	#>
	# @var handlers
	# Keeps list of installed populating plugin classes.
	#<
	common handlers [list]

	protected {
		variable _db ""
	}

	public {
		#>
		# @method init
		# Initializes list of handlers. They should be already loaded by interpreter, this method just find their classes
		# and places them in {@var handlers} variable.
		#<
		proc init {}

		method setDb {db}

		#>
		# @method getName
		# @return Symbolic name of table population engine. Must be unique for all populating plugins. It's good idea for it to be uppercase name.
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
		abstract method createConfigUI {path}

		#>
		# @method applyConfig
		# @param path Tk widget path to frame where configuration is placed.
		# Implementation should extract necessary informations from configuration widget and store it in local variables,
		# so they can be used later, while populating by method {@method nextValue}.<br>
		# Configuration widget in path will be destroyed just after this method call is completed.
		# Can do nothing if {@method configurable} returns <code>false</code>.
		#<
		abstract method applyConfig {path}

		#>
		# @method nextValue
		# Implementation should generate next value to fill table cell.
		# @return Next value to use to populate table.
		#<
		abstract method nextValue {}

		#>
		# @method sortCmd
		# Used for sorting handlers by name.
		#<
		proc sortCmd {arg1 arg2}
	}
}

body PopulatingPlugin::init {} {
	set handlers [lsort -command PopulatingPlugin::sortCmd [findClassesBySuperclass "::PopulatingPlugin"]]
	if {$defaultHandler == ""} {
		set defaultHandler [[lindex $handlers 0]::getName]
	}
}

body PopulatingPlugin::sortCmd {arg1 arg2} {
	return [string compare [${arg1}::getName] [${arg2}::getName]]
}

body PopulatingPlugin::setDb {db} {
	set _db $db
}

