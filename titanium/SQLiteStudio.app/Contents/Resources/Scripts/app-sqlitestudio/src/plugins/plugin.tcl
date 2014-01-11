#>
# @class Plugin
# Base class for all plugins. All plugins have to inherit it.
# Currently it does nothing, but when it will start doing something,
# all plugins should be ready by inheriting it.
#<
abstract class Plugin {
	public {
		#>
		# @method sortCmd
		# Used for sorting handlers by name.
		#<
		proc sortCmd {arg1 arg2}
	}
}

body Plugin::sortCmd {arg1 arg2} {
	return [string compare [${arg1}::getName] [${arg2}::getName]]
}
