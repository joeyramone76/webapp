use src/trees/db_tree.tcl

# Debug in tree
proc showParserDebugWindow {} {
	set t .parserDebug
	toplevel $t
	wm minsize $t 400 300
	wm geometry $t 420x700
	wm title $t "SQLiteStudio parser debug window"
	Tree $t.tree
	pack $t.tree -side bottom -fill both -expand 1

	set opts [ttk::frame $t.options]
	set opts2 [ttk::frame $t.options2]
	ttk::checkbutton $opts.hideAllTokens -text "Hide allTokens" -variable ::PARSER_DEBUG_TREE_OPTS(hideAllTokens) \
		-command updateParserTree
	ttk::checkbutton $opts.hideEmpty -text "Hide empty values" -variable ::PARSER_DEBUG_TREE_OPTS(hideEmpty) \
		-command updateParserTree
	ttk::checkbutton $opts.hideZero -text "Hide zero values" -variable ::PARSER_DEBUG_TREE_OPTS(hideZero) \
		-command updateParserTree
	ttk::checkbutton $opts2.hideMetadata -text "Hide tokens metadata" -variable ::PARSER_DEBUG_TREE_OPTS(hideTokenMetadata) \
		-command updateParserTree

	pack $opts.hideAllTokens $opts.hideEmpty $opts.hideZero -side left -pady 5 -padx 10
	pack $opts2.hideMetadata -side left -pady 5 -padx 10
	pack $opts $opts2 -side top -fill x

	set exp [ttk::frame $t.expand]
	pack [ttk::button $exp.exp -text "Expand" -command "[$t.tree getTree] item expand root -recurse"] -side left -padx 20
	pack [ttk::button $exp.coll -text "Collapse" -command "[$t.tree getTree] item collapse root -recurse"] -side right -padx 20
	pack $exp -side top -fill x

	set ::PARSER_DEBUG_TREE .parserDebug.tree
}

proc showParserStepsDebugWindow {} {
	set t .parserStepsDebug
	toplevel $t
	wm minsize $t 400 300
	wm geometry $t 420x700
	wm title $t "SQLiteStudio parser steps debug window"
	Tree $t.tree
	pack $t.tree -side bottom -fill both -expand 1

	set exp [ttk::frame $t.expand]
	pack [ttk::button $exp.exp -text "Expand" -command "[$t.tree getTree] item expand root -recurse"] -side left -padx 20
	pack [ttk::button $exp.coll -text "Collapse" -command "[$t.tree getTree] item collapse root -recurse"] -side right -padx 20
	pack $exp -side top -fill x

	set ::PARSER_STEPS_DEBUG_TREE .parserStepsDebug.tree
}

proc updateParserTree {} {
	if {[catch {
		$::PARSER_DEBUG_TREE_ROOT_OBJ debugInTree
	}]} {
		$::PARSER_DEBUG_TREE delAll
	}
}

proc debugStepReset {} {
	if {$::PARSER_STEPS_DEBUG_TREE == ""} return
	$::PARSER_STEPS_DEBUG_TREE delAll
}

proc debugStepEnter {txt} {
	if {$::PARSER_STEPS_DEBUG_TREE == ""} return
	set parent [lindex $::PARSER_STEPS_DEBUG_OBJS end]
	lappend ::PARSER_STEPS_DEBUG_OBJS [$::PARSER_STEPS_DEBUG_TREE addItem $parent "" $txt]
}

proc debugStep {txt} {
	if {$::PARSER_STEPS_DEBUG_TREE == ""} return
	set parent [lindex $::PARSER_STEPS_DEBUG_OBJS end]
	$::PARSER_STEPS_DEBUG_TREE addItem $parent "" $txt
}

proc debugStepLeave {txt retCode} {
	if {$::PARSER_STEPS_DEBUG_TREE == ""} return
	set parent [lindex $::PARSER_STEPS_DEBUG_OBJS end]
	$::PARSER_STEPS_DEBUG_TREE addItem $parent "" $txt
	if {$retCode != 0} {
		$::PARSER_STEPS_DEBUG_TREE setNodeForeground $parent red
	}
	set ::PARSER_STEPS_DEBUG_OBJS [lrange $::PARSER_STEPS_DEBUG_OBJS 0 end-1]
}

array set ::PARSER_DEBUG_TREE_OPTS {
	hideAllTokens 1
	hideEmpty 1
	hideZero 1
	hideTokenMetadata 1
}

set ::PARSER_STEPS_DEBUG_OBJS [list root]
set ::PARSER_DEBUG_TREE_ROOT_OBJ ""
set ::PARSER_DEBUG_TREE ""
set ::PARSER_STEPS_DEBUG_TREE ""
if {$::DEBUG(parser_tree)} {
	showParserDebugWindow
	if {$::DEBUG(parser) >= 2} {
		showParserStepsDebugWindow
	}
}
