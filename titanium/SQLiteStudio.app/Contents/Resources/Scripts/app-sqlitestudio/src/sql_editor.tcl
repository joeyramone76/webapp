use src/common/ui.tcl
use src/common/panel.tcl
use src/dialogs/searchdialog.tcl
use src/shortcuts.tcl

#>
# @class SQLEditor
# Implementation of editor widget with rich support for SQL,
# such as syntax highlighting, syntax assistant (words guessing),
# formatting code, validating database table names and more.
#<
class SQLEditor {
	inherit UI Panel Shortcuts

	#>
	# @method constructor
	# @param args Option-value pairs. Valid option is: <code>-yscrollcommand</code>.
	# Supported are all options handled by <code>text</code> widget and additionaly the followings:
	# <code>-yscroll</code> - <code>true</code> to enable vertical scrollbar, <code>false</code> to hide it. Defaults to <code>true</code>,<br>
	# <code>-xscroll</code> - <code>true</code> to enable horizontal scrollbar, <code>false</code> to hide it. Defaults to <code>true</code>,<br>
	# <code>-mode</code> - can be empty or <code>entry</code>, in the second case widget looks like an <code>entry</code> (height equals 1 line), but still keeps all {@class SQLEditor} features,<br>
	# <code>-linenumbers</code> - <code>true</code> to show linue nubers in editor, or <code>false</code> otherwise.
	# <code>-selectionascontents</code> - <code>true</code> to treat selection as code to return from {@method getContents}.
	# <code>-validatesql</code> - <code>true</code> to enable additional thread to validate SQL contents. Default is <code>false</code>.
	#<
	constructor {args} {}

	destructor {}

	#>
	# @var brackets_color
	# Font color of brackets.<br>
	# Configured by {@class CfgWin}.
	#<
	common brackets_color "#222222"

	#>
	# @var square_brackets_color
	# Font color of square brackers.<br>
	# Configured by {@class CfgWin}.
	#<
	common square_brackets_color "black"

	#>
	# @var keywords_color
	# Font color of key words.<br>
	# Configured by {@class CfgWin}.
	#<
	common keywords_color "black"

	#>
	# @var tables_color
	# Font color of matched table names.<br>
	# Configured by {@class CfgWin}.
	#<
	common tables_color "blue"

	#>
	# @var variables_color
	# Font color of variables.<br>
	# Configured by {@class CfgWin}.
	#<
	common variables_color "blue"

	#>
	# @var comments_color
	# Font color of comments.<br>
	# Configured by {@class CfgWin}.
	#<
	common comments_color "#CCCCCC"

	#>
	# @var comments_color
	# Font color of strings.<br>
	# Configured by {@class CfgWin}.
	#<
	common strings_color "#007700"

	#>
	# @var font
	# Font family, size, etc.<br>
	# Configured by {@class CfgWin}.
	#<
	common font "SqlEditorFont"

	#>
	# @var boldFont
	# Bold kind of font.
	#<
	common boldFont "SqlEditorFontBold"

	#>
	# @var underlineFont
	# Underlined kind of font.
	#<
	common underlineFont "SqlEditorFontUnderline"

	#>
	# @var italicFont
	# Italic kind of font.
	#<
	common italicFont "SqlEditorFontItalic"

	#>
	# @var matched_bracket_bgcolor
	# Background color of matched parallel bracket.<br>
	# Configured by {@class CfgWin}.
	#<
	common matched_bracket_bgcolor "black"

	#>
	# @var matched_bracket_fgcolor
	# Font color of matched parallel bracket.<br>
	# Configured by {@class CfgWin}.
	#<
	common matched_bracket_fgcolor "white"

	#>
	# @var background_color
	# Editor background color.<br>
	# Configured by {@class CfgWin}.
	#<
	common background_color "white"

	#>
	# @var foreground_color
	# Default font color.<br>
	# Configured by {@class CfgWin}.
	#<
	common foreground_color "black"

	#>
	# @var selected_background
	# Selected area background color.<br>
	# Configured by {@class CfgWin}.
	#<
	common selected_background "#DDDDEE"

	#>
	# @var selected_foreground
	# Selected area font color.<br>
	# Configured by {@class CfgWin}.
	#<
	common selected_foreground "#442222"

	#>
	# @var disabled_background
	# Background color of editor in disabled state.<br>
	# Configured by {@class CfgWin}.
	#<
	common disabled_background "gray"

	#>
	# @var useBoldFontForKeywords
	# Variable name speaks for itself.
	# It's configurable in Settings dialog.
	#<
	common useBoldFontForKeywords 1

	#>
	# @var error_foreground
	# Font color of contents with incorrect syntax.
	# Configured by {@class CfgWin}.
	#<
	common error_foreground "red"

	#>
	# @var error_foreground
	# Whether or not to underline font of contents with incorrect syntax.
	# Configured by {@class CfgWin}.
	#<
	common error_underline 1

	#>
	# @var completeAfterDot
	# If true, then completion hint will appear automatically soon after dot character was typed in context
	# where it's part of SQLite object path.
	# Configured by {@class CfgWin}.
	#<
	common completeAfterDot true

	#>
	# @var delayedParserRunTime
	# Number of milliseconds to wait after las user input to autorun parser to check errors, etc.
	#<
	common delayedParserRunTime 300
	
	common maxLimitToRunParser 20000

	private {
		common errorCheckingPool ""

		#>
		# @var _parsingForCompletion
		# Since parsing is now done in separate thread, then current thread can process events,
		# and call for completion can happen multiple times. To avoid CPU overload we need to use only one
		# parser for completion at once. This variable is a semaphore for it.
		#<
		common _parsingForCompletion false
		
		#>
		# @var _parsingForErrors
		# This variable has similar purpose as {@var _parsingForCompletion}, except it keeps errors checking thread safe.
		#<
		common _parsingForErrors false

		#>
		# @method handleCompletionError
		# @param errorMsg Message of error to handle.
		# This is default handler for completion error. It's called when completion process failed
		# and there is some error (like when attaching sqlite2 file to sqlite3).
		# It displays error message. Use {@method setCompletionErrorHandler} to set other handler command.
		#<
		method handleCompletionError {errorMsg}
	}

	protected {
		#>
		# @var _root
		# Main frame that all components are placed in.
		#<
		variable _root ""

		#>
		# @var _edit
		# <code>ctext</code> widget, the core of {@class SQLEditor}.
		#<
		variable _edit ""

		#>
		# @var _db
		# {@class DB} object linked with the widget (tables list is read from it for highlighting).
		#<
		variable _db ""

		#>
		# @var _showYScrollbar
		# Contains <code>1</code> if Y scrollbal should be visible. It's set by <code>-yscroll</code> option passed value.
		#<
		variable _showYScrollbar 1

		#>
		# @var _showXScrollbar
		# Contains <code>1</code> if X scrollbal should be visible. It's set by <code>-xscroll</code> option passed value.
		#<
		variable _showXScrollbar 1

		#>
		# @var _mode
		# Keeps mode passed to <code>-mode</code> option.
		#<
		variable _mode ""

		#>
		# @var _validateSql
		# Keeps mode passed to <code>-validatesql</code> option.
		#<
		variable _validateSql 0

		#>
		# @var _additionalModes
		# List of additional code assistant modes that will always be included in assistant hint window.
		# Each two elements of the list are: the mode and the table for that mode.<br><br>
		# Currently supported assistant modes are: <code>table</code>, <code>column</code> and <code>keyword</code>.
		#<
		variable _additionalModes [list]

		#>
		# @var _validTables
		# List of valid table names read from {@var _db}. If any of table name is matched in editor, it's highlighted with {@var tables_color}.
		#<
		variable _validTables [list]

		#>
		# @var _showLineNumbers
		# Keeps value passed to <code>-linenumbers</code>.
		#<
		variable _showLineNumbers 0

		#>
		# @var _selectionAsContents
		# Keeps information if treat selection as code to return from {@method getContents}.
		#<
		variable _selectionAsContents 0

		#>
		# @arr _parser
		# Universal SQL parser. It's initialized in constructor.
		#<
 		variable _parser ""

		#>
		# @arr _lexer
		# Universal SQL lexer. It's initialized in constructor.
		#<
		variable _lexer ""

		#>
		# @method _completionErrorHandler
		# Keeps handler command to call when completion error occures.
		# @see method setCompletionErrorHandler
		#<
		variable _completionErrorHandler "handleCompletionError"

		#>
		# @var _parserRunDelayTimer
		# Keeps ID of [after] timer to run dlayed parse. It's stored here because we need to be able to cancel it,
		# so we can delay parsing process whenever we want.
		#<
		variable _parserRunDelayTimer ""

		variable _keywords [list]
		variable _linksEnabled 0
		variable _defaultCursor ""
		variable _pointer
		variable _wrap "none"

		#>
		# @method undoTabLine
		# @param lineIdx Line number to undo tab for. It's 1-based index (like in text widget).
		# Removes tab single indentation from given line. It's used internally used by {@method undoTab}.
		#<
		method undoTabLine {lineIdx}

		#>
		# @method parseContents
		# @param idx Index to parse statement at.
		# Parses statement at given index and returns 2 elements list.
		# @return 2 elements list. First is dictionary from standard parsing process and second is parsing for expected tokens.
		#<
		method parseContents {idx}
	}

	public {
		#>
		# @method getContents
		# @param whole <code>true</code> to get whole editor contents, no matter if there is any selected area. If it's <code>false</code> and there is selected area, only that area will be returned. If it's <code>false</code> and no area is selected, then whole area will be returned.
		# @return Editor contents.
		#<
		method getContents {{whole 0}}

		#>
		# @method setContents
		# @param txt New contents value.
		# Sets new editor contents to given value.
		#<
		method setContents {txt}

		#>
		# @method getWidget
		# @return Internal <code>text</code> widget of {@var _edit}.
		#<
		method getWidget {}

		#>
		# @method getCEdit
		# @return Value of {@var _edit}.
		#<
		method getCEdit {}

		#>
		# @method reHighlight
		# Refreshes syntax highlighting.
		#<
		method reHighlight {}

		#>
		# @method tab
		# Invoked by <b>tab</b> button push event. It changes behaviour of base <code>text</code> widget.
		#<
		method tab {}

		#>
		# @method undoTab
		# Invoked by <b>shift-tab</b> button push event, when at least 4 white-spaces are placed befor insertion cursor. It changes behaviour of base <code>text</code> widget.
		#<
		method undoTab {}

		#>
		# @method backspace
		# Invoked by <b>backspace</b> button push event. Normaly it behaves as always expected, but when exactly 4 white-spaces are placed befor insertion cursor, it deletes all of them.
		#<
		method backspace {}

		#>
		# @method enterPressed
		# Invoked by <b>enter/return</b> button push event. It changes behaviour of base <code>text</code> widget by keeping identation.
		#<
		method enterPressed {}

		#>
		# @method complete
		# Invoked by code completion shortcut.
		#<
		method complete {}

		#>
		# @method setDB
		# @param db New {@var DB} object to link with editor widget.
		# Sets new database object linked with the widget. It also refreshes valid table names from new database.
		#<
		method setDB {db}

		#>
		# @method getDB
		# @return Value of {@var _db}.
		#<
		method getDB {}

		#>
		# @method setValidTables
		# @param tables New valid table names list.
		# Sets new valid tables list (to be highlighted with {@var tables_color}).
		#<
		method setValidTables {tables}

		#>
		# @method updateUISettings
		# @overloaded UI
		#<
		method updateUISettings {}

		#>
		# @method configure
		# Overloades standard <code>configure</code> method. Adds some custom options.
		#<
		method configure {args}

		#>
		# @method paste
		# Pastes contents from clipboard to editor.
		#<
		method paste {}

		#>
		# @method getCompletionList
		# @param parsedDict Dict from {@method parseContents}. If empty, then {@method parseContents} will be called to get it.
		# @param expectedDict Dict from {@method parseContents}. If empty, then {@method parseContents} will be called to get it.
		# Detects completion (by calling {@method detectCompletionType}) and generates list
		# of completion candidates.
		# @return List of two elements. First element is another list with completion candidates
		# (each candidate is list of three elements: element type, label and string for completion),
		# the second element is string (a word) that completion entries starts with.
		#<
		method getCompletionList {{parsedDict ""} {expectedDict ""}}

		#>
		# @method appendHintMode
		# @param mode New constant mode.
		# @param table New constant table.
		# Adds constant mode to be applied for all code assistant invokes.<br>
		# <i>mode</i> can be one of: <code>table</code>, <code>column</code> or <code>keyword</code>.
		#<
		method appendHintMode {mode table}

		#>
		# @method getCurrentTokenPartialValue
		# @param ignoreEmptyPartialValue If true then allows the empty partial value which comes from outside of tokens range as correct value.
		# @return Partial value (can be empty string) of token that is under current cursor position.
		#<
		method getCurrentTokenPartialValue {{ignoreEmptyPartialValue false}}

		#>
		# @method filterCompletionList
		# @param completeList List of completion elements as received from {@method getCompletionList}.
		# @param partialValueDict Optionally the partial value dictionary may be passed here to avoid additional query for this value as received from {@method getCurrentTokenPartialValue}.
		# Filters given completion list agains current "token partial value".
		# It doesn't modify input list (since it's passed by value, not by variable name).
		# @return Filtered list.
		#>
		method filterCompletionList {completionList {partialValueDict ""}}

		#>
		# @method updateShortcuts
		# @overloaded Shortcuts
		#<
		method updateShortcuts {}

		#>
		# @method clearShortcuts
		# @overloaded Shortcuts
		#<
		method clearShortcuts {}

		#>
		# @method disable
		# Disables widget.
		#<
		method disable {}

		#>
		# @method enable
		# Enables widget.
		#<
		method enable {}

		#>
		# @method readonly
		# Makes widget readonly.
		#<
		method readonly {}

		# [ttk::entry] compatibility
		#>
		# @method get
		# Gets all contents of the editor. It gives limited compatibility to the <code>entry</code> widget.
		# @return Editor contents.
		#<
		method get {}

		#>
		# @method insert
		# @param idx Index to insert at.
		# @param str String to be inserted.
		# Inserts new string into editor at given index.
		#<
		method insert {idx str}

		#>
		# @method getHintPos
		# Calculates current position for completion hint window basing on current insertion cursor position.
		# @return X and Y coordinates as two-elements list.
		#<
		method getHintPos {}

		#>
		# @method searchDialog
		# @param replace If <code>true</code> dialog will contain replacing options, otherwise only finding options will be displayed.
		# Opens search and/or replace dialog for the current editor widget.
		#<
		method searchDialog {{replace false}}

		#>
		# @method setCompletionErrorHandler
		# @param command New handler command to use.
		# Assigns new handler command to use when completion error occurres.
		# The command parameter will be expanded before execution, so it might be a method of some object.
		# Handler command will be called with single argument - the error message.
		#<
		method setCompletionErrorHandler {command}

		#>
		# @method handleUserInput
		# @param key Key that was pressed.
		# @param state Event state (see %s tag description in Tk 'bind' command manual).
		# Invokes proper actions for user input. It handles "after dot" completion for example.
		# Also updates timer for checking SQL syntax errors.
		#<
		method handleUserInput {key state}

		#>
		# @method delayParserRun
		# Resets parser running timer, because user provided some new input.
		#<
		method delayParserRun {}

		#>
		# @method runDelayedParser
		# Runs parser for current input. Marks errors and shows completion window if needed.
		#<
		method runDelayedParser {}

		#>
		# @method cancelParserRun
		# Cancels delayed parsing timer.
		#<
		method cancelParserRun {}

		#>
		# @method addErrorTag
		# Adds error tag for given range. Used by error checking thread.
		#<
		method addErrorTag {begin end}
		method getCurrentLexer {}
		method enableLinks {}
		method disableLinks {}
		method handleKeyEvent {pressOrRelease key state}
		method handleLinkClick {x y}
		method tracePointer {x y}
		method setFocus {}
		method removeHighlighting {}
		method deleteKey {}
		method homeKey {{modifiers ""}}
		method seeInsert {}
		method checkForParenthesisPair {{index ""}}
		method buttonClicked {button x y}

		proc isParserLimitExceeded {sql}
		proc init {}
	}
}

body SQLEditor::constructor {args} {
	set _root $path
	ttk::frame $_root.top
	pack $_root.top -fill both -expand 1
	itk_component add edit {
		ctext $_root.top.text -borderwidth 1 \
			-background $background_color -foreground $foreground_color -linemap 0 -insertborderwidth 1 \
			-selectbackground $selected_background -selectforeground $selected_foreground \
			-font $font -selectborderwidth 0 -wrap $_wrap -undo true \
			-width 5 -height 3 -linemap_markable 0 -linemapbg $background_color
	}
	set _edit $itk_component(edit)
	$_edit.l configure -borderwidth 1
	set _defaultCursor [$_edit cget -cursor]

	eval configure $args
	if {$_showYScrollbar} {
		itk_component add scroll {
			ttk::scrollbar $_root.top.s -command "$_edit yview" -orient vertical
		}
		$_edit configure -yscrollcommand "$_root.top.s set"
	}

	if {$_showXScrollbar} {
		itk_component add xscroll {
			ttk::scrollbar $_root.s -command "$_edit xview" -orient horizontal
		}
		$_edit configure -xscrollcommand "$_root.s set"
	}

	if {$_showLineNumbers} {
		$_edit configure -linemap 1
	}

	if {$_mode == "entry"} {
		$_edit configure -height 1
	}

	# Universal parser
	set _parser [UniversalParser ::#auto]
	$_parser configure -sameThread false

	# Lexers
	set _lexer [UniversalLexer ::#auto]

	# Enabling hacked strings and comments highlighting
	ctext::getAr $_edit config ar
	set ar(ext_strings) 1
	set ar(ext_comments) 1

	# Initial keywords, default for SQLite3
	array set keywords $::PARSABLE_KEYWORDS_SQLite3
	set _keywords [array names keywords]

	# Global look&feel
	updateShortcuts
	updateUISettings

	# Autoscroll
	pack $_edit -side left -fill both -expand 1
	if {$_showYScrollbar} {
		pack $itk_component(scroll) -side right -fill y
		autoscroll $itk_component(scroll)
	}
	if {$_showXScrollbar} {
		pack $itk_component(xscroll) -side bottom -fill x
		autoscroll $itk_component(xscroll)
	}

	# Tracking user input
	bind $_edit <Any-Key> "if {\[$this handleUserInput %K %s]} break"

	bind $_edit <Any-KeyPress> "+$this handleKeyEvent press %K %s"
	bind $_edit <Any-KeyRelease> "+$this handleKeyEvent release %K %s"
	bind $_edit <Motion> "+$this tracePointer %x %y"
	bind $_edit <Button-1> "+$this buttonClicked 1 %x %y"
	bind $_edit <Control-Button-1> "break"
	bind $_edit <FocusOut> "$this disableLinks"
	bind $_edit.t <Control-v> "$this paste; break"
	bind $_edit.t <Control-a> {
		%W tag remove sel 1.0 end
		%W tag add sel 1.0 {end -1 chars}
		break
	}
	bind $_edit.t <Tab> "$this tab; break"
	bind $_edit.t <<PrevWindow>> "$this undoTab; break"
	bind $_edit.t <BackSpace> "$this backspace; break"
	bind $_edit.t <Delete> "$this deleteKey; break"
	bind $_edit.t <Home> "if {\[$this homeKey]} {break}"
	bind $_edit.t <Shift-Home> "if {\[$this homeKey shift]} {break}"
	bind $_edit.t <Control-Home> "if {\[$this homeKey control]} {break}"
	bind $_edit.t <Control-Shift-Home> "if {\[$this homeKey control]} {break}"
	bind $_edit.t <Control-z> "catch {$_edit edit undo; $_edit edit separator}; $this reHighlight; $this delayParserRun; break"
	bind $_edit.t <Control-y> "catch {$_edit edit redo}; $this reHighlight; $this delayParserRun; break"
	bind $_edit.t <Control-f> "$this searchDialog; break"
	bind $_edit.t <Control-r> "$this searchDialog true; break"
	bind $_edit.t <Control-Shift-Z> "$_edit edit redo; $this reHighlight; $this delayParserRun; break"
	bind $_edit.t <Control-x> "+$this delayParserRun"
	bind $_edit.t <Return> "$this enterPressed; break"
	bind $_edit.t <Control-Shift-Left> {
		tk::TextKeySelect %W [%W index [tk::TextPrevPos %W insert tcl_startOfPreviousWord]]
		break
	}
	bind $_edit.t <Control-Shift-Right> {
		tk::TextKeySelect %W [%W index {insert +1 chars wordend}]
		break
	}
	bind $_edit.t <Control-Left> {
	    tk::TextSetCursor %W [tk::TextPrevPos %W insert tcl_startOfPreviousWord]
		break
	}
	bind $_edit.t <Control-Right> {
    	tk::TextSetCursor %W [tk::TextNextWord %W insert]
		break
	}
	bind $_edit.t <Prior> {
		set oldIdx [%W index insert]
		tk::TextSetCursor %W [tk::TextScrollPages %W -1]
		if {[%W index insert] == $oldIdx} {
			tk::TextSetCursor %W 1.0
		}
		break
	}
	bind $_edit.t <Next> {
		set oldIdx [%W index insert]
		tk::TextSetCursor %W [tk::TextScrollPages %W +1]
		if {[%W index insert] == $oldIdx} {
			tk::TextSetCursor %W end
		}
		break
	}
	bind $_edit.t <Shift-Prior> {
		set oldIdx [%W index insert]
	    tk::TextKeySelect %W [tk::TextScrollPages %W -1]
		if {[%W index insert] == $oldIdx} {
			tk::TextKeySelect %W 1.0
		}
		break
	}
	bind $_edit.t <Shift-Next> {
		set oldIdx [%W index insert]
		tk::TextKeySelect %W [tk::TextScrollPages %W +1]
		if {[%W index insert] == $oldIdx} {
			tk::TextKeySelect %W end
		}
		break
	}
	bind $_edit.t <Control-BackSpace> "
		%W delete \[tk::TextPrevPos %W insert tcl_startOfPreviousWord] insert
		$this delayParserRun
		break
	"
	bind $_edit.t <Control-Delete> "
		%W delete insert \[tk::TextNextWord %W insert]
		$this delayParserRun
		break
	"

	#focus $_edit.t ;# we don't wont to focus this widget anywhere it's created
}

body SQLEditor::destructor {} {
	catch {after cancel $_parserRunDelayTimer}
	set _parserRunDelayTimer ""
	delete object $_parser
	delete object $_lexer
}

body SQLEditor::init {} {
	set errorCheckingPool [tpool::create -minworkers 1 -maxworkers 2 -idletime 60 \
		-initcmd [string map [list %APP_DIR% [list $::applicationDir]] {
			set ::SQL_EDITOR ""
			cd [file nativename %APP_DIR%]
			if {[catch {
				source src/syntax_checking_thread.tcl
			} err]} {
				error "Error while starting error checking thread: $err\n"
			}
		}]]
}

body SQLEditor::setFocus {} {
	focus $_edit.t
}

body SQLEditor::handleKeyEvent {pressOrRelease key state} {
	if {$key in [list "Control_L" "Control_R"]} {
		if {$pressOrRelease == "press"} {
			enableLinks
		} else {
			disableLinks
		}
	}
}

body SQLEditor::tracePointer {x y} {
	set _pointer(x) $x
	set _pointer(y) $y
}

body SQLEditor::handleLinkClick {x y} {
	set tags [$_edit tag names @$x,$y]
	if {"tables" in $tags} {
		set content ""
		foreach {left right} [$_edit tag ranges tables] {
			if {[$_edit.t compare @$x,$y > $left] && [$_edit.t compare @$x,$y < $right]} {
				set content [$_edit.t get $left $right]
				break
			}
		}

		set db [getDB]
		if {$content != "" && $db != ""} {
			DBTREE openTableWindow $db $content
		}
	}
}

body SQLEditor::paste {} {
	tk_textPaste $_edit.t
	seeInsert
	delayParserRun
}

body SQLEditor::tab {} {
	set linesToSel [list]
	set sel [$_edit.t tag ranges sel]
	if {[llength $sel] > 0} {
		foreach {begin end} $sel {
			set beginLine [lindex [split $begin .] 0]
			set endLine [lindex [split $end .] 0]
			if {[lindex [split $end .] 1] == 0} {
				incr endLine -1
			}
			if {$beginLine != $endLine} {
				for {set i $beginLine} {$i <= $endLine} {incr i} {
					lappend linesToSel $i
					$_edit.t insert $i.0 {    }
				}
			} else {
				lappend linesToSel [lindex [split $begin .] 0]
				$_edit.t insert $begin {    }
			}
		}
	} else {
		$_edit.t insert insert {    }
	}
	reHighlight
	seeInsert
	foreach line $linesToSel {
		$_edit.t tag add sel $line.0 [expr {$line+1}].0
	}
}

body SQLEditor::undoTab {} {
	set linesToSel [list]
	set sel [$_edit.t tag ranges sel]
	if {[llength $sel] > 0} {
		foreach {begin end} $sel {
			set beginLine [lindex [split $begin .] 0]
			set endLine [lindex [split $end .] 0]
			if {[lindex [split $end .] 1] == 0} {
				incr endLine -1
			}
			if {$beginLine != $endLine} {
				for {set i $beginLine} {$i <= $endLine} {incr i} {
					lappend linesToSel $i
					undoTabLine $i
				}
			} else {
				lappend linesToSel $beginLine
				undoTabLine $beginLine
			}
		}
	} else {
		set lineIdx [lindex [split [$_edit.t index insert] .] 0]
		undoTabLine $lineIdx
	}
	reHighlight
	foreach line $linesToSel {
		$_edit.t tag add sel $line.0 [expr {$line+1}].0
	}
}

body SQLEditor::undoTabLine {lineIdx} {
	set idx ""
	regexp -indices -- {^\s{1,4}} [$_edit.t get $lineIdx.0 "$lineIdx.0 lineend"] idx
	if {$idx != ""} {
		$_edit.t delete $lineIdx.[lindex $idx 0] $lineIdx.[expr {[lindex $idx 1]+1}]
	}
}

body SQLEditor::backspace {} {
	set sel [$_edit.t tag ranges sel]
	if {[llength $sel] > 0} {
		foreach {begin end} $sel {
			$_edit.t delete $begin $end
		}
		reHighlight
		seeInsert
		return
	}
	set idx [$_edit.t index "insert -4 chars"]
	set str [$_edit.t get $idx insert]
	if {[string equal $str "    "]} {
		$_edit.t delete $idx insert
	} else {
		set idx [$_edit.t index insert]
		if {[string match "*.0" $idx]} {
			if {[lindex [split $idx .] 0] > 1} {
				$_edit.t delete "$idx -1 chars"
			}
			reHighlight
			seeInsert
			return
		}
		$_edit.t delete "insert -1 chars"
	}
	seeInsert
	reHighlight
}

body SQLEditor::deleteKey {} {
	set sel [$_edit.t tag ranges sel]
	if {[llength $sel] > 0} {
		foreach {begin end} $sel {
			$_edit.t delete $begin $end
		}
	} else {
		$_edit.t delete insert
	}
	reHighlight
}

body SQLEditor::homeKey {{modifiers ""}} {
	if {$modifiers != ""} {
		return false
	}

	# Executing "smart home key"
	set str [$_edit get "insert linestart" "insert lineend"]
	set idx [$_edit index "insert"]

	lassign [split $idx .] line currIdx

	regexp -indices -- {\S} $str subIndices
	if {![info exists subIndices]} {
		return false
	}
	set firstWordIdx [lindex $subIndices 0]

	if {$currIdx > $firstWordIdx || $currIdx == 0} {
		set newIdx $line.$firstWordIdx
	} else {
		set newIdx $line.0
	}
	if {$idx == $newIdx} {
		return false
	}
	set sels [$_edit tag ranges sel]
	if {[llength $sels] > 0} {
		$_edit tag remove sel {*}$sels
	}
	$_edit mark set insert $newIdx
	seeInsert
	return true
}

body SQLEditor::getWidget {} {
	return $_edit.t
}

body SQLEditor::getCEdit {} {
	return $_edit
}

body SQLEditor::get {} {
	return [getContents 1]
}

body SQLEditor::getContents {{whole 0}} {
	if {$_selectionAsContents} {
		set sel [$_edit tag ranges sel]
		if {$sel != "" && !$whole} {
			set buf ""
			foreach {idx1 idx2} $sel {
				append buf [$_edit get $idx1 $idx2]
			}
			return $buf
		} else {
			return [$_edit get 1.0 {end -1 chars}]
		}
	} else {
		return [$_edit get 1.0 {end -1 chars}]
	}
}

body SQLEditor::insert {idx str} {
	setContents $str
}

body SQLEditor::setContents {txt} {
	set wasDisabled 0
	if {[$_edit cget -state] == "disabled"} {
		set wasDisabled 1
		$_edit configure -state normal
	}
	$_edit edit separator
	$_edit replace 1.0 end $txt ;# using 'replace' makes undo sometimes to forget previous value, don't know why.

	# The old way, that was breaking undo mechanism
# 	$_edit delete 1.0 end
# 	$_edit insert end $txt

	if {$wasDisabled} {
		$_edit configure -state disabled
	}
	reHighlight
	seeInsert
}

body SQLEditor::reHighlight {} {
	foreach t [$_edit.t tag names] {
		$_edit.t tag remove $t 1.0 end
	}
	after cancel [list ctext::highlight $_edit 1.0 end]
	after idle [list ctext::highlight $_edit 1.0 end]
}

body SQLEditor::enterPressed {} {
	set spaces [lindex [regexp -inline -- {^\s*} [$_edit.t get "insert linestart" "insert lineend"]] 0]
	$_edit.t insert insert "\n$spaces"
	seeInsert
}

body SQLEditor::seeInsert {} {
	$_edit.t see insert
}

body SQLEditor::appendHintMode {mode table} {
	lappend _additionalModes $mode $table
}

body SQLEditor::parseContents {idx} {
	set str [$_edit.t get 1.0 end]
	$_parser setDb [getDB]
	$_parser configure -tolerateLacksForStdParsing true
	set results [$_parser parseSql $str $idx]
	$_parser configure -tolerateLacksForStdParsing false
	return $results
}

body SQLEditor::getCurrentLexer {} {
	if {$_db != ""} {
		$_lexer setDb $_db
	}
	return $_lexer
}

body SQLEditor::getCompletionList {{parsedDict ""} {expectedDict ""}} {
	if {$_db == ""} return

	# Getting SQL and cursor position
	set idx [string length [$_edit.t get 1.0 insert]]

	if {$parsedDict == "" && $expectedDict == ""} {
		set contents [$_edit.t get 1.0 end]
		lassign [parseContents $idx] parsedDict expectedDict
	}
	set obj [dict get $parsedDict object]

	# If parsing was successful, then we can get names of tables used in SQL.
	if {[dict get $parsedDict returnCode] == 0} {
		set contextStatement [$obj getStatementForPosition $idx]
		if {$contextStatement != ""} {
			set tablesInContext [$contextStatement getContextInfo "TABLE_NAMES"]
			set columnsInContext [$contextStatement getContextInfo "COLUMN_NAMES"]
		} else {
			set tablesInContext [list]
			set columnsInContext [list]
		}
	} else {
		set tablesInContext [list]
		set columnsInContext [list]
	}

	# Expected tokens are always present after checkForExpectedTokens method call,
	# but they might be empty.
	set expectedTokens [dict get $expectedDict expectedTokens]

	# Token partial value is always present after checkForExpectedTokens method call.
	set partialValue [dict get $expectedDict tokenPartialValue]

	# List of tokens before cursor position is also always present.
	set tokensSoFar [dict get $expectedDict allTokens]

	# Now we have everything we need, so lets get the completion list
	set completionList [CompletionRoutines::getCompletionList $_db $tablesInContext $columnsInContext $expectedTokens $tokensSoFar $partialValue]
	$_parser freeObjects
	return [list $completionList $partialValue]
}

body SQLEditor::getCurrentTokenPartialValue {{ignoreEmptyPartialValue false}} {
	if {$_db == ""} {
		return [dict create returnCode 1]
	}

	# Getting SQL and cursor position
	set str [$_edit.t get 1.0 end]
	set idx [string length [$_edit.t get 1.0 insert]]

	set partialDict [$_lexer getLastTokenPartialValueFromSql $str $idx]
	if {$ignoreEmptyPartialValue} {
		dict set partialDict returnCode 0
	}
	return $partialDict
}

body SQLEditor::handleCompletionError {errorMsg} {
	Error $errorMsg
}

body SQLEditor::setCompletionErrorHandler {command} {
	set _completionErrorHandler $command
}

body SQLEditor::isParserLimitExceeded {sql} {
	expr {[string length $sql] > $maxLimitToRunParser}
}

body SQLEditor::complete {} {
	if {$_parsingForCompletion} return
	set _parsingForCompletion true

	set contentsLength [string length [$_edit get 1.0 end]]
	if {$contentsLength > $maxLimitToRunParser} {
		debug "Maximum SQL contents length exceeded ($contentsLength). Cannot run parser."
		{*}$_completionErrorHandler [mc {Maximum SQL length for the parser exceeded (%s characters, while the limit is %s). Cannot assist with code completion.} $contentsLength $maxLimitToRunParser]
		return
	}


	set hintPos [getHintPos]
	if {$hintPos == ""} return
	lassign $hintPos x y
	set hint [HintWin::create $_edit.t $this [list] $x $y 100]

	if {[catch {
		lassign [getCompletionList] completionList partialValueOnly
		set partialValueDict [getCurrentTokenPartialValue true]
	} err]} {
		set _parsingForCompletion false
		if {[winfo exists $_root]} {
			{*}$_completionErrorHandler $err
		}
		catch {destroy $hint}
		return
	}
	set _parsingForCompletion false

	if {![winfo exists $hint]} {
		return
	}

	if {![info exists completionList] || ![info exists partialValueOnly]} {
		# No completion proposals, so nothing to do here
		return
	}

# 	dict set partialValueDict returnCode 0 ;# enforce code 0, becuase this is called by ctrl+space,
# 	                                        # so we need to show completion hint no matter what
#
	set filteredList [filterCompletionList $completionList $partialValueDict]
	if {[llength $filteredList] == 0} {
		catch {destroy $hint}
		set _parsingForCompletion false
		return
	}
	if {[llength $filteredList] == 1} {
		catch {destroy $hint}
		set leaveChars [string length $partialValueOnly]
		$_edit delete "insert -$leaveChars chars" insert
		$_edit insert insert [lindex $filteredList 0 2]
		delayParserRun
	} else {
		# Catch errors, because hint can already be closed by "Esc" or sth similar.
		catch {$hint updateList $completionList}
	}
}

body SQLEditor::filterCompletionList {completionList {partialValueDict ""}} {
	set newList [list]
	if {$partialValueDict == ""} {
		# No partial dict given, getting one
		set partialValueDict [getCurrentTokenPartialValue]
	}
	if {[dict get $partialValueDict returnCode] != 0} {
		return $newList
	}

	set partialValue [dict get $partialValueDict value]
	set partialSize [string length $partialValue]
	set matched 0
	set uniqProtectingList [list]
	foreach it $completionList {
		lassign $it img el data addLabel context
		set data [stripObjName $data]
		if {[string toupper [string range $data 0 [expr {${partialSize}-1}]]] != [string toupper $partialValue]} continue
		set uniqItem [list $img $el $data $addLabel]
		if {$uniqItem in $uniqProtectingList} continue
		lappend uniqProtectingList $uniqItem
		lappend newList $it
	}
	return $newList
}

body SQLEditor::setDB {db} {
	set _db $db

	switch -- [$db getDialect] {
		"sqlite3" {
			array set keywords $::PARSABLE_KEYWORDS_SQLite3
		}
		"sqlite2" {
			array set keywords $::PARSABLE_KEYWORDS_SQLite2
		}
	}
	set _keywords [array names keywords]
	updateUISettings

	delayParserRun
}

body SQLEditor::getDB {} {
	return $_db
}

body SQLEditor::setValidTables {tables} {
	set _validTables [string toupper $tables]
	updateUISettings
}

body SQLEditor::searchDialog {{replace false}} {
	if {$replace} {
		set title [mc {Replace dialog}]
	} else {
		set title [mc {Search dialog}]
	}
	set dlg [SearchDialog $_edit.t.#auto -edit $_edit.t -replace $replace -modal 0 -title $title]
	$dlg exec
}

body SQLEditor::enableLinks {} {
	$_edit.t tag configure tables -underline 1
	set _linksEnabled 1
	$_edit.t tag bind tables <Enter> "$_edit configure -cursor $::CURSOR(link)"
	$_edit.t tag bind tables <Leave> "$_edit configure -cursor $_defaultCursor"
	$_edit.t tag bind tables <Control-Button-1> "$this handleLinkClick %x %y; break"

	if {[info exists _pointer(x)]} {
		if {"tables" in [$_edit.t tag names @$_pointer(x),$_pointer(y)]} {
			$_edit configure -cursor $::CURSOR(link)
		}
	}
}

body SQLEditor::disableLinks {} {
	$_edit.t tag configure tables -underline 0
	set _linksEnabled 0
	$_edit.t tag bind tables <Enter> ""
	$_edit.t tag bind tables <Leave> ""
	$_edit.t tag bind tables <Control-Button-1> ""

	if {[info exists _pointer(x)]} {
		if {"tables" in [$_edit.t tag names @$_pointer(x),$_pointer(y)]} {
			$_edit configure -cursor $_defaultCursor
		}
	}
}

body SQLEditor::configure {args} {
	foreach {opt val} $args {
		switch -- $opt {
			"-yscroll" {
				set _showYScrollbar $val
			}
			"-xscroll" {
				set _showXScrollbar $val
			}
			"-mode" {
				if {$val == "entry"} {
					set _showYScrollbar 0
					set _mode $val
				}
			}
			"-wrap" {
				set _wrap $val
				$_edit configure -wrap $_wrap
			}
			"-linenumbers" {
				set _showLineNumbers $val
				$_edit configure -linemap $val
			}
			"-selectionascontents" {
				set _selectionAsContents $val
			}
			"-validatesql" {
				set _validateSql $val
			}
			default {
				$_edit configure $opt $val
			}
		}
	}
}

body SQLEditor::updateShortcuts {} {
	bind $_edit.t <${::Shortcuts::editorComplete}> "$this complete; break"
	bind $_edit.t <${::Shortcuts::nextTask}> "TASKBAR nextTask; break"
	bind $_edit.t <${::Shortcuts::nextTaskAlt}> "TASKBAR nextTask; break"
	bind $_edit.t <${::Shortcuts::prevTask}> "TASKBAR prevTask; break"
	bind $_edit.t <${::Shortcuts::prevTaskAlt}> "TASKBAR prevTask; break"

# 	bind $_edit.t <Control-p> [string map [list \$this $this] {
# 		set res [tokenizeSql [$this getContents]]
# 		splitStatements [dict get $res tokens]
# 	}]
}

body SQLEditor::clearShortcuts {} {
	bind $_edit.t <${::Shortcuts::editorComplete}> ""
	bind $_edit.t <${::Shortcuts::nextTask}> ""
	bind $_edit.t <${::Shortcuts::nextTaskAlt}> ""
	bind $_edit.t <${::Shortcuts::prevTask}> ""
	bind $_edit.t <${::Shortcuts::prevTaskAlt}> ""

# 	bind $_edit.t <Control-v> ""
# 	bind $_edit.t <Control-a> ""
# 	bind $_edit.t <<PrevWindow>> ""
# 	bind $_edit.t <BackSpace> ""
# 	bind $_edit.t <Control-z> ""
# 	bind $_edit.t <Control-y> ""
# 	bind $_edit.t <Control-f> ""
# 	bind $_edit.t <Control-r> ""
# 	bind $_edit.t <Control-Shift-z> ""
# 	bind $_edit.t <F5> ""
# 	bind $_edit.t <Return> ""
# 	bind $_edit.t <Control-Shift-Left> ""
# 	bind $_edit.t <Control-Shift-Right> ""
# 	bind $_edit.t <Control-Left> ""
# 	bind $_edit.t <Control-Right> ""
# 	bind $_edit.t <Prior> ""
# 	bind $_edit.t <Next> ""
# 	bind $_edit.t <Shift-Prior> ""
# 	bind $_edit.t <Shift-Next> ""
# 	bind $_edit.t <Control-BackSpace> ""
# 	bind $_edit.t <Control-Delete> ""
}

body SQLEditor::disable {} {
	$_edit configure -state disabled -background $disabled_background -readonly 0
}

body SQLEditor::enable {} {
	$_edit configure -state normal -background $background_color -readonly 0
}

body SQLEditor::readonly {} {
	$_edit configure -state normal -background $background_color -readonly 1
}

body SQLEditor::getHintPos {} {
	set geom [$_edit.t bbox insert]
	if {[llength $geom] < 2} {
		return [list]
	}
	set x [lindex $geom 0]
	set y [lindex $geom 1]
	incr x [winfo rootx $_edit.t]
	incr y [winfo rooty $_edit.t]
	incr y 15
	return [list $x $y]
}

body SQLEditor::buttonClicked {button x y} {
	if {$button == 1} {
		after idle [list catch [list $this checkForParenthesisPair]] ;# catch, becase after closing window this won't find the window.
	}
}

body SQLEditor::handleUserInput {key state} {
	#puts "key=$key state=$state"
	set ignoreKeys [list "Left" "Right" "Up" "Down" "Prior" "Next" "Home" "End" "Control_L" "Alt_L" \
		"Super_L" "Control_R" "Alt_R" "Super_R" "Menu" "Insert" "Shift_L" "Shift_R" "Caps_Lock" \
		"Num_Lock" "Scroll_Lock" "Print" "Escape" \
	]
	# "BackSpace" "space" "Delete"
	if {$key ni $ignoreKeys && $state in [list 0 8 16 17 144]} { ;# 8, 16, 17 ans 144 are NO_MODS, SHIFT and ALT_R
		delayParserRun
	}

	after idle [list catch [list $this checkForParenthesisPair]] ;# catch, becase after closing window this won't find the window.

	return 0
}

body SQLEditor::checkForParenthesisPair {{index ""}} {
	set ranges [$_edit tag ranges matched_brackets]
	if {$ranges != ""} {
		$_edit tag remove matched_brackets {*}$ranges
	}

	if {$index == "previous"} {
		set char [$_edit get "insert -1 chars" insert]
	} else {
		set char [$_edit get insert "insert +1 chars"]
	}

	switch -- $char {
		"(" {
			set oper(PAR_LEFT) 1
			set oper(PAR_RIGHT) -1
		}
		")" {
			set oper(PAR_LEFT) -1
			set oper(PAR_RIGHT) 1
		}
		default {
			if {$index == ""} {
				checkForParenthesisPair "previous"
			}
			return
		}
	}

	if {$index == "previous"} {
		set startIdx [string length [$_edit get 1.0 "insert -1 chars"]]
	} else {
		set startIdx [string length [$_edit get 1.0 insert]]
	}

	# Tokenize contents
	set contents [$_edit get 1.0 end]
	set tokenizeResults [$_lexer tokenize $contents]
	if {[dict get $tokenizeResults returnCode] != 0} {
		debug "Error tokenizing: [dict get $tokenizeResults errorMessage]"
		return
	}
	set tokens [dict get $tokenizeResults tokens]

	# Locate char in tokens
	set types [list "PAR_LEFT" "PAR_RIGHT"]
	set startToken ""
	foreach token $tokens {
		lassign $token type value start end
		if {$start == $startIdx && $end == $startIdx && $type in $types} {
			set startToken $token
			break
		}
	}

	if {$startToken == ""} return

	# Reverse to look backwards
	if {$char == ")"} {
		set tokens [lreverse $tokens]
	}

	# Cut off tokens before starting one
	set tokens [lrange $tokens [expr {[lsearch -exact $tokens $startToken]+1}] end]

	# Count opening and closing brackets.
	set count 1
	set stopToken ""
	foreach token $tokens {
		lassign $token type value start end
		if {$type ni $types} continue
		incr count $oper($type)
		if {$count == 0} {
			set stopToken $token
			break
		}
	}

	if {$stopToken == ""} return

	foreach token [list $startToken $stopToken] {
		lassign $token type value start end
		$_edit tag add matched_brackets "1.0 +$start chars" "1.0 +[expr {$start+1}] chars"
	}
}

body SQLEditor::cancelParserRun {} {
	if {$_parserRunDelayTimer != ""} {
		set r [catch {after cancel $_parserRunDelayTimer} res]
		set _parserRunDelayTimer ""
	}
}

body SQLEditor::delayParserRun {} {
	cancelParserRun
	set contentsLength [string length [$_edit get 1.0 end]]
	if {$contentsLength > $maxLimitToRunParser} {
		debug "Maximum SQL contents length exceeded ($contentsLength). Cannot run parser."
		return
	}
	set ratio 1.0
	if {$contentsLength > 150} {
		set ratio [expr { $ratio + ( double($contentsLength) / 1000 ) }]
	}

	set delay [expr {int($ratio * double($delayedParserRunTime))}]
	#puts "ratio: $ratio / delay: $delay"
	set _parserRunDelayTimer [after $delay [list $this runDelayedParser]]
}


body SQLEditor::runDelayedParser {} {
	set _parserRunDelayTimer ""

	# Showing completion hint if necessary
	if {$_db != "" && !$_parsingForCompletion && ![catch {$_db isOpen} open] && $open} {
		set hintPos [getHintPos]
		if {$hintPos == ""} {
			lassign $hintPos x y

			set _parsingForCompletion true
			set idx [string length [$_edit.t get 1.0 "insert + 1 chars"]]

			set lexer [getCurrentLexer]
			set contents [$_edit get 1.0 insert]
			set tokensSoFar [dict get [$lexer tokenize $contents] tokens]
			set lastToken [lindex $tokensSoFar end]
			lassign $lastToken tokenType tokenValue tokenBegin tokenEnd
			if {$lastToken != "" && $tokenType == "OPERATOR" && $tokenValue == "."} {
				set hint [HintWin::create $_edit.t $this [list] $x $y]

				set indexBefore [$_edit.t index insert]
				set valueBefore [$_edit.t get 1.0 end]
				lassign [getCompletionList] completionList partialValueOnly
				set indexAfter [$_edit.t index insert]
				set valueAfter [$_edit.t get 1.0 end]

				if {$indexBefore == $indexAfter && [string equal $valueBefore $valueAfter]} {
					set filteredList [filterCompletionList $completionList ""]
					if {[llength $filteredList] > 0} {
						# Catch errors, because hint can already be closed by "Esc" or sth similar.
						catch {$hint updateList $completionList}
					} else {
						catch {destroy $hint}
					}
				} else {
					catch {destroy $hint}
				}
			}

			$_parser freeObjects
			set _parsingForCompletion false
		}
	}

	# Check for SQL syntax errors
	if {$_validateSql && !$_parsingForErrors} {
		set _parsingForErrors true
		set id [tpool::post $errorCheckingPool [string map [list %EDITOR% $this] {
			set ::SQL_EDITOR %EDITOR%
			parseAllStatementsForErrorChecking
		}]]
		tpool::wait $errorCheckingPool $id
		set _parsingForErrors false
	}
}

body SQLEditor::addErrorTag {begin end} {
	$_edit tag add error $begin $end
}

body SQLEditor::updateUISettings {} {
	set keywordFont $boldFont
	if {!$useBoldFontForKeywords} {
		set keywordFont $font
	}

	set speed [expr {$::CfgWin::insCurSpeed / 2}]
	
	# Refreshing configuration
	$_edit configure -background $background_color -foreground $foreground_color \
		-selectbackground $selected_background -selectforeground $selected_foreground \
		-font $font -insertontime $speed -insertofftime $speed

	ctext::clearHighlightClasses $_edit
	ctext::disableComments $_edit
	ctext::addHighlightClassForSpecialChars $_edit brackets $brackets_color {()}
	ctext::addHighlightClassForSpecialChars $_edit square_brackets $square_brackets_color {[]}
	ctext::addHighlightClass $_edit keywords $keywords_color $_keywords
	ctext::addHighlightClass $_edit tables $tables_color $_validTables
	ctext::addHighlightClassWithOnlyCharStart $_edit vars $variables_color "\$"
	ctext::addHighlightClassForRegexp $_edit line_comments $comments_color {(?:\-\-.*)}
	if {[os] == "macosx"} {
		# A nasty workaround for font-related bug in Tk causing application crash
		$_edit.t tag configure matched_brackets -background $matched_bracket_bgcolor -foreground $matched_bracket_fgcolor
		$_edit.t tag configure string -foreground $SQLEditor::strings_color
		$_edit.t tag configure comments -foreground $SQLEditor::comments_color
		$_edit.t tag configure line_comments -foreground $SQLEditor::comments_color
	} else {
		$_edit.t tag configure keywords -font $keywordFont
		$_edit.t tag configure brackets -font $boldFont
		$_edit.t tag configure tables -font $underlineFont
		$_edit.t tag configure square_brackets -font $boldFont
		$_edit.t tag configure matched_brackets -background $matched_bracket_bgcolor -foreground $matched_bracket_fgcolor
		$_edit.t tag configure string -foreground $SQLEditor::strings_color -font $italicFont
		$_edit.t tag configure comments -foreground $SQLEditor::comments_color -font $italicFont
		$_edit.t tag configure line_comments -foreground $SQLEditor::comments_color -font $italicFont
	}

	ctext::getAr $_edit config ar
	set ar(ext_strings) 1
	set ar(ext_comments) 1

	reHighlight

	# Errors
	$_edit tag configure error -underline $error_underline -foreground $error_foreground
	$_edit tag raise error
}

body SQLEditor::removeHighlighting {} {
	ctext::getAr $_edit config ar
	set ar(ext_strings) 0
	set ar(ext_comments) 0
	ctext::clearHighlightClasses $_edit
}
