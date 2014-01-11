#>
# @class Shortcuts
# Shortcuts handling. Any class that uses shortcuts should inherit this
# class and implement its abstract methods, so any changes to shortucts
# configuration can be applied on the fly.
#<
class Shortcuts {
	#>
	# @var openEditor
	# Contains shortcut combination. Can be changed by {@class CfgWin}.
	#<
	common openEditor "Alt-e"

	#>
	# @var closeSelectedTask
	# Contains shortcut combination. Can be changed by {@class CfgWin}.
	#<
	common closeSelectedTask "Control-w"

	#>
	# @var nextTask
	# Contains shortcut combination. Can be changed by {@class CfgWin}.
	#<
	common nextTask "Control-Right"

	#>
	# @var nextTaskAlt
	# Contains shortcut combination. Can be changed by {@class CfgWin}.
	#<
	common nextTaskAlt "Control-Next"

	#>
	# @var prevTask
	# Contains shortcut combination. Can be changed by {@class CfgWin}.
	#<
	common prevTask "Control-Left"

	#>
	# @var prevTaskAlt
	# Contains shortcut combination. Can be changed by {@class CfgWin}.
	#<
	common prevTaskAlt "Control-Prior"

	#>
	# @var openSettings
	# Contains shortcut combination. Can be changed by {@class CfgWin}.
	#<
	common openSettings "F2"

	#>
	# @var editorComplete
	# Contains shortcut combination. Can be changed by {@class CfgWin}.
	#<
	common editorComplete "Control-space"

	#>
	# @var executeSql
	# Contains shortcut combination. Can be changed by {@class CfgWin}.
	#<
	common executeSql "F9"

	#>
	# @var explainSql
	# Contains shortcut combination. Can be changed by {@class CfgWin}.
	#<
	common explainSql "F8"

	#>
	# @var formatSql
	# Contains shortcut combination. Can be changed by {@class CfgWin}.
	#<
	common formatSql "Alt-f"

	#>
	# @var nextTab
	# Contains shortcut combination. Can be changed by {@class CfgWin}.
	#<
	common nextTab "Alt-Right"

	#>
	# @var prevTab
	# Contains shortcut combination. Can be changed by {@class CfgWin}.
	#<
	common prevTab "Alt-Left"

	#>
	# @var nextSubTab
	# Contains shortcut combination. Can be changed by {@class CfgWin}.
	#<
	common nextSubTab "Control-period"

	#>
	# @var prevSubTab
	# Contains shortcut combination. Can be changed by {@class CfgWin}.
	#<
	common prevSubTab "Control-comma"

	#>
	# @var refresh
	# Contains shortcut combination. Can be changed by {@class CfgWin}.
	#<
	common refresh "F5"

	#>
	# @var deleteRow
	# Contains shortcut combination. Can be changed by {@class CfgWin}.
	#<
	common deleteRow "Delete"

	#>
	# @var insertRow
	# Contains shortcut combination. Can be changed by {@class CfgWin}.
	#<
	common insertRow "Insert"

	#>
	# @var eraseRow
	# Contains shortcut combination. Can be changed by {@class CfgWin}.
	#<
	common eraseRow "BackSpace"

	#>
	# @var prevDatabase
	# Contains shortcut combination. Can be changed by {@class CfgWin}.
	#<
	common prevDatabase "Control-Up"

	#>
	# @var nextDatabase
	# Contains shortcut combination. Can be changed by {@class CfgWin}.
	#<
	common nextDatabase "Control-Down"

	#>
	# @var commitFormView
	# Contains shortcut combination. Can be changed by {@class CfgWin}.
	#<
	common commitFormView "Control-Return"

	#>
	# @var commitFormView
	# Contains shortcut combination. Can be changed by {@class CfgWin}.
	#<
	common rollbackFormView "Control-BackSpace"

	#>
	# @var formViewFirstRow
	# Contains shortcut combination. Can be changed by {@class CfgWin}.
	#<
	common formViewFirstRow "Control-Shift-Prior"

	#>
	# @var formViewPrevRow
	# Contains shortcut combination. Can be changed by {@class CfgWin}.
	#<
	common formViewPrevRow "Control-Shift-Left"

	#>
	# @var formViewNextRow
	# Contains shortcut combination. Can be changed by {@class CfgWin}.
	#<
	common formViewNextRow "Control-Shift-Right"

	#>
	# @var formViewLastRow
	# Contains shortcut combination. Can be changed by {@class CfgWin}.
	#<
	common formViewLastRow "Control-Shift-Next"

	common loadSqlFile "Control-o"
	common saveSqlFile "Control-s"
	common execFromFile "Control-e"
	common setNullInForm "Alt-n"
	common restoreLastWindow "Control-Shift-T"
	common editInBlobEditor "Shift-Return"


	public {
		#>
		# @method updateShortcuts
		# Updates shorcuts bindings in accordance with configuration changes.<br>
		# Class that implements this method should bind all configured shortcuts.
		#<
		abstract method updateShortcuts {}
		#>
		# @method clearShortcuts
		# Clears old shorcuts bindings.<br>
		# Class that implements this method should unbind all configured shortcuts.
		# It's called just before all shortcut combinations is changed by {@class CfgWin},
		# so it contains old combinations.
		#<
		abstract method clearShortcuts {}

		#>
		# @method updateAllShortcuts
		# Calls {@method updateShortcuts} for all instances of this class (derived classes objects).
		#<
		proc updateAllShortcuts {}

		#>
		# @method clearAllShortcuts
		# Calls {@method clearShortcuts} for all instances of this class (derived classes objects).
		#<
		proc clearAllShortcuts {}
	}
}

body Shortcuts::updateAllShortcuts {} {
	foreach obj [itcl::find objects * -isa Shortcuts] {
		$obj updateShortcuts
	}
}

body Shortcuts::clearAllShortcuts {} {
	foreach obj [itcl::find objects * -isa Shortcuts] {
		$obj clearShortcuts
	}
}