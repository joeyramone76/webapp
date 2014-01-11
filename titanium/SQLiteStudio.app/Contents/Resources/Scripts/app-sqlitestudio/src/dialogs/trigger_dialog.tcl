use src/common/modal.tcl
use src/common/model_extractor.tcl
use src/common/ddl_dialog.tcl

class TriggerDialog {
	inherit Modal ModelExtractor DdlDialog

	constructor {args} {
		eval Modal::constructor $args -expandcontainer 1 -resizable 1
	} {}

	protected {
		variable _db ""
		variable _win ""
		variable _edit ""
		variable _widget
		variable _okLabel ""
		variable _preselectTable ""
		variable _condition ""
		variable _mode "tables"
		variable _tables [list]
		variable _views [list]
		variable _trigger ""
		variable _trigModel ""
		variable _similarModel ""
		variable _sqliteVersion 3
		variable _modelSqliteVersion 3
		variable _updateOfColumns [list]

		method parseInputModel {}
		method validateForSql {}
		method createSql {}
		method getDdlContextDb {}
	}

	public {
		variable checkState

		method okClicked {}
		method cancelClicked {}
		method grabWidget {}
		method formatSQL {}
		method updateTables {}
		method toggleConditionEntry {}
		method updateMode {}
		method updateColsButtonState {}
		method defineUpdateOfColumns {}
	}
}

body TriggerDialog::constructor {args} {
	parseArgs {
		-db {set _db $value}
		-trigger {set _trigger $value}
		-model {set _trigModel $value}
		-similarmodel {set _similarModel $value}
		-preselecttable {set _preselectTable $value}
		-oklabel {set _okLabel $value}
	}

	if {$_db != "" && [$_db getHandler] == "::Sqlite3"} {
		set _sqliteVersion 3
	} else {
		set _sqliteVersion 2
	}

	if {$_trigger != ""} {
		if {$_db != ""} {
			if {$_trigModel == ""} {
				set _trigModel [getModel $_db $_trigger "trigger"]
			}
		} else {
			error "Given -trigger to TriggerDialog but no -db."
		}
	}

	if {$_similarModel != "" && [$_similarModel isa Statement2CreateIndex]} {
		set _modelSqliteVersion 2
	} else {
		set _modelSqliteVersion 3
	}

# 	ttk::frame $top
# 	pack $top -side top -fill both -padx 3 -pady 5 -expand 1
	set _tabs [ttk::notebook $_root.tabs]
	set main [ttk::frame $_tabs.main]
	set top [ttk::frame $_tabs.main.top]
	set ddl [ttk::frame $_tabs.ddl]
	$_tabs add $main -text [mc {Trigger}]
	$_tabs add $ddl -text DDL
	pack $top -side top -fill both -padx 3 -pady 5 -expand 0
	pack $_tabs -side top -fill both -padx 3 -pady 5 -expand 1

	# Ddl tab
	set _ddlEdit [SQLEditor $ddl.editor -yscroll true]
	pack $_ddlEdit -side top -fill both -expand 1
	$_ddlEdit readonly

	# table, database
# 		action [mc {On action:}] ttk::combobox
	foreach {p label widget} [list \
		database [mc {Database:}] ttk::combobox \
		name [mc {Trigger name:}] ttk::entry \
		when [mc {When:}] ttk::combobox \
		table [mc {On table:}] ttk::combobox \
		for [mc {Execute code for:}] ttk::combobox
	] {
		ttk::frame $top.$p
		ttk::frame $top.$p.f
		ttk::label $top.$p.f.l -text $label -justify left
		set checkState($p) ""
		$widget $top.$p.e -textvariable [scope checkState]($p)
		pack $top.$p.f -side top -fill x
		pack $top.$p.f.l -side left
		pack $top.$p.e -side bottom -fill x
	}

	# Action
	set p action
	set checkState($p) ""
	ttk::frame $top.$p
	ttk::frame $top.$p.f
	ttk::label $top.$p.f.l -text [mc {Action:}] -justify left
	set checkState($p) ""
	ttk::frame $top.$p.bottom
	ttk::combobox $top.$p.bottom.e -textvariable [scope checkState]($p)
	set _widget(colsButton) [ttk::button $top.$p.bottom.cols -image img_list -command "$this defineUpdateOfColumns" -state disabled]
	pack $top.$p.f -side top -fill x
	pack $top.$p.f.l -side left
	pack $top.$p.bottom.e -side left -fill x
	pack $top.$p.bottom.cols -side right -padx 2
	pack $top.$p.bottom -side bottom -fill x
	if {$::ttk::currentTheme == "clam"} {
		$_widget(colsButton) configure -style TButtonThin
	}
	helpHint $_widget(colsButton) [mc "Defines column list for 'UPDATE OF' action.\nRequires trigger table to be already selected."]

	# Condition
	set p condition
	set checkState(condition) 0
	ttk::frame $top.$p
	ttk::frame $top.$p.f
	ttk::checkbutton $top.$p.f.c -text [mc {Execute code only when:}] -command "$this toggleConditionEntry" -variable [scope checkState(condition)]
	set _condition $top.$p.e
	SQLEditor $_condition -height 3 -wrap word
	$_condition disable
	pack $top.$p.f -side top -fill x
	pack $top.$p.f.c -side left
	pack $top.$p.e -side bottom -fill both -expand 1

	grid $top.database -column 0 -row 0 -columnspan 2 -padx 1 -sticky we
	grid $top.name -column 0 -row 1 -padx 1 -sticky we
	grid $top.when -column 1 -row 1 -padx 1 -sticky we
	grid $top.action -column 0 -row 2 -padx 1 -sticky we
	grid $top.table -column 1 -row 2 -padx 1 -sticky we
	grid $top.for -column 0 -row 3 -columnspan 2 -padx 1 -sticky we
	grid $top.condition -column 0 -row 4 -columnspan 2 -padx 1 -sticky nswe
	foreach w [list \
		$top.database \
		$top.when \
		$top.action.bottom \
		$top.table \
		$top.for \
	] {
		$w.e configure -state readonly
	}
	grid columnconfigure $top 0 -weight 1
	grid columnconfigure $top 1 -weight 1

	$top.when.e configure -values [list "" BEFORE AFTER "INSTEAD OF"]
	$top.action.bottom.e configure -values [list INSERT UPDATE DELETE "UPDATE OF"]

	if {$_sqliteVersion == 2} {
		set forVals [list "" "FOR EACH ROW" "FOR EACH STATEMENT"]
	} else {
		set forVals [list "" "FOR EACH ROW"]
	}
	$top.for.e configure -values $forVals -textvariable [scope checkState](for)
	$top.for.e set [lindex $forVals 0]

	foreach db [DBTREE dblist] {
		if {![$db isOpen]} continue
		lappend dblist [$db getName]
	}

	set middle [frame $main.middle]
	ttk::frame $middle.f
	ttk::label $middle.f.l -text [mc {Code executed for above configuration:}]
	pack $middle.f.l -side left
	pack $middle.f -side top -fill x

	set e $middle.edit
	set _edit [SQLEditor $e -wrap word]
	set edit [$_edit getWidget]
	$edit configure -width 40 -height 10
	pack $e -fill both -expand 1 -padx 3 -side top
	pack $middle -side top -fill both -expand 1
	bind $edit <${::Shortcuts::formatSql}> "$this formatSQL"

	ttk::frame $_root.d
	pack $_root.d -side bottom -fill x -padx 3 -pady 3

	ttk::button $_root.d.ok -text [mc {Create}] -command "$this clicked ok" -compound left -image img_ok
	pack $_root.d.ok -side left
	ttk::button $_root.d.cancel -text [mc {Cancel}] -command "$this clicked cancel" -compound left -image img_cancel
	pack $_root.d.cancel -side right

	if {$_okLabel != ""} {
		$_root.d.ok configure -text $_okLabel
	} elseif {$_trigModel != ""} {
		$_root.d.ok configure -text [mc {Change}]
	}

	$top.database.e configure -values $dblist
	bind $top.database.e <<ComboboxSelected>> "$this updateTables"
	bind $top.when.e <<ComboboxSelected>> "$this updateMode"
	bind $top.action.bottom.e <<ComboboxSelected>> "$this updateColsButtonState"
	bind $top.table.e <<ComboboxSelected>> "$this updateColsButtonState"

	parseInputModel
	initDdlDialog
}

body TriggerDialog::parseInputModel {} {
	set top $_tabs.main.top
	if {$_db != ""} {
		$top.database.e set [$_db getName]
		updateTables
	}
	if {$_preselectTable != ""} {
		$top.table.e set $_preselectTable
	}

	if {$_trigModel == "" && $_similarModel == ""} return
	$top.database.e configure -state disabled

	if {$_trigModel != ""} {
		set model $_trigModel
	} else {
		set model $_similarModel
	}

	# Reading model
	set checkState(name) [$model getValue trigName]
	set checkState(when) [$model getValue afterBefore]
	if {$_trigModel != ""} {
		set checkState(table) [$_trigModel getValue tableName]
	}
	if {[$model getValue forEachRow]} {
		set checkState(for) "FOR EACH ROW"
	} elseif {$_sqliteVersion == 2 && $_modelSqliteVersion == 2 && [$model getValue forEachStatement]} {
		set checkState(for) "FOR EACH STATEMENT"
	}
	set checkState(action) [$model getValue action]
	if {$checkState(action) == "UPDATE"} {
		set of [$model getValue ofKeyword]
		if {$of} {
			set checkState(action) "UPDATE OF"
			set _updateOfColumns [$model getListValue columnList]
		}
	}

	# WHEN condition
	set condition [$model getValue whenExpr]
	if {$condition != ""} {
		set checkState(condition) 1
		$_condition enable
		$_condition setContents [$condition toSql]
	}

	# Body
	set body [list]
	foreach bodyStmt [$model getListValue bodyStatements] {
		lappend body [$bodyStmt toSql]
	}
	$_edit setContents [join $body ";\n"]

	updateMode
	updateColsButtonState
}

body TriggerDialog::grabWidget {} {
	#focus $_tabs.main.top.name.e
	return $_tabs.main.top.name.e
}

body TriggerDialog::okClicked {} {
	set top $_tabs.main.top
	set closeWhenOkClicked 0
	set ok 0
	set ret [createSql]
	if {$ret == -1} return

	if {$ret != ""} {
		$_db begin
		if {[catch {
			if {$_trigModel != ""} {
				$_db eval "DROP TRIGGER [wrapObjName [$_trigModel getValue trigName] [$_db getDialect]]"
			}
			$_db eval [encode $ret]
			set ok 1
			set closeWhenOkClicked 1
		} err]} {
			catch {$_db rollback}
			cutOffStdTclErr err
			Error $err
		} else {
			$_db commit
		}
	}

	if {$ok} {
		TASKBAR signal TableWin [list REFRESH [$top.table.e get]]
		TASKBAR signal DBTree [list REFRESH DB_OBJ $_db]
	}
}

body TriggerDialog::validateForSql {} {
	if {$checkState(table) == ""} {
		if {$_mode == "views"} {
			return [mc {You have to specify view.}]
		} else {
			return [mc {You have to specify table.}]
		}
	}

	if {[string trim $checkState(name)] == ""} {
		return [mc {You have to specify trigger name.}]
	}

	if {$checkState(action) == ""} {
		return [mc {You have to specify 'action' condition.}]
	}

# 	set query [$_edit getContents]
# 	if {$query == ""} {
# 		Error [mc {You havn't wrote a code for the trigger.}]
# 	}
	return ""
}

body TriggerDialog::createSql {} {
	set top $_tabs.main.top
	set db [DBTREE getDBByName $checkState(database)]
	if {$db == ""} {
		Error [mc {You have to specify database.}]
		after 10 "focus [$_edit getWidget]"
		return -1
	}

	if {$checkState(table) ni $_tables} {
		if {$_mode == "views"} {
			Error [mc {You have to specify view.}]
		} else {
			Error [mc {You have to specify table.}]
		}
		after 10 "focus [$_edit getWidget]"
		return -1
	}

	if {[string trim $checkState(name)] == ""} {
		Error [mc {You have to specify trigger name.}]
		after 10 "focus $top.name.e"
		return -1
	}

	if {$checkState(action) == ""} {
		Error [mc {You have to specify 'action' condition.}]
		after 10 "focus [$_edit getWidget]"
		return -1
	}

	set query [$_edit getContents]
	if {$query == ""} {
		Error [mc {You havn't wrote a code for the trigger.}]
		after 10 "focus  [$_edit getWidget]"
		return -1
	}
	
	set dialect [$_db getDialect]
	set actionSql $checkState(action)
	if {$checkState(action) == "UPDATE OF"} {
		append actionSql " "
		append actionSql [join [wrapObjNames $_updateOfColumns $dialect] ", "]
	}

	set sql "CREATE TRIGGER [wrapObjName $checkState(name) $dialect] $checkState(when) $actionSql ON [wrapObjName $checkState(table) $dialect] "
	if {$checkState(for) != ""} {
		append sql "$checkState(for) "
	}
	if {$checkState(condition)} {
		append sql "WHEN [$_condition getContents 1] "
	}
	append sql "BEGIN "
	append sql "$query "
	if {![regexp {;\s*$} $query]} {
		append sql "; "
	}
	append sql "END"
	return $sql
}

body TriggerDialog::formatSQL {} {
	set query [$_edit getContents]
	set query [Formatter::format $query $_db]
	$_edit setContents $query
	$_edit reHighlight
}

body TriggerDialog::updateTables {} {
	set top $_tabs.main.top
	set _db [DBTREE getDBByName [$top.database.e get]]
	set _tables [$_db getTables]
	set _views [$_db getViews]
	updateMode
	$_edit setDB $_db
	$_condition setDB $_db
	$_ddlEdit setDB $_db
}

body TriggerDialog::updateMode {} {
	set top $_tabs.main.top
	set _mode [expr {$checkState(when) == "INSTEAD OF" ? "views" : "tables"}]
	if {$_mode == "views"} {
		$top.table.f.l configure -text [mc {On view:}]
		$top.table.e configure -values $_views
		if {[$top.table.e current] == -1} {
			$top.table.e set ""
		}
	} else {
		$top.table.f.l configure -text [mc {On table:}]
		$top.table.e configure -values $_tables
		if {[$top.table.e current] == -1} {
			$top.table.e set ""
		}
	}
}

body TriggerDialog::updateColsButtonState {} {
	$_widget(colsButton) configure -state [expr {
		$checkState(action) == "UPDATE OF" &&
		$checkState(table) != ""
		?
		"normal" : "disabled"
	}]
}

body TriggerDialog::toggleConditionEntry {} {
	#$top.condition.e configure -state [expr {$checkState(when) ? "normal" : "disabled"}]
	if {$checkState(condition)} {
		$_condition enable
	} else {
		$_condition disable
	}
}

body TriggerDialog::getDdlContextDb {} {
	return $_db
}

body TriggerDialog::defineUpdateOfColumns {} {
	catch {destroy .trigCols}
	set dialog [TriggerDialogColumns .trigCols -db $_db -triggerdialog $this -columns $_updateOfColumns \
		-table $checkState(table) -parent [string trimleft $this :]]
	lassign [$dialog exec] res cols
	if {$res} {
		set _updateOfColumns $cols
	}
}

body TriggerDialog::cancelClicked {} {
	return 0
}
