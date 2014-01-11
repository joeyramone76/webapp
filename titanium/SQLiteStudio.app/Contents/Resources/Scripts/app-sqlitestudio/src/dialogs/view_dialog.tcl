use src/common/modal.tcl
use src/common/model_extractor.tcl
use src/common/ddl_dialog.tcl

class ViewDialog {
	inherit Modal ModelExtractor DdlDialog

	constructor {args} {
		eval Modal::constructor $args -resizable 1 -expandcontainer 1
	} {}

	protected {
		variable _viewModel ""
		variable _view ""
		variable _db ""
		variable _edit ""
		variable _name ""
		variable _code ""

		method parseInputModel {}
		method validateForSql {}
		method createSql {}
		method getDdlContextDb {}
		method getSize {}
	}

	public {
		variable checkState

		method okClicked {}
		method cancelClicked {}
		method grabWidget {}
		method formatSQL {}
		method updateDB {}
	}
}

body ViewDialog::constructor {args} {
	parseArgs {
		-db {set _db $value}
		-view {set _view $value}
		-model {set _viewModel $value}
		-code {set _code $value}
		-name {set _name $value}
	}

	if {$_db != "" && [$_db getHandler] == "::Sqlite3"} {
		set _sqliteVersion 3
	} else {
		set _sqliteVersion 2
	}

	if {$_view != ""} {
		if {$_db != ""} {
			if {$_viewModel == ""} {
				set _viewModel [getModel $_db $_view "view"]
			}
		} else {
			error "Given -view to ViewDialog but no -db."
		}
	}

# 	ttk::frame $top
# 	pack $top -side top -fill both -padx 3 -pady 5
	set _tabs [ttk::notebook $_root.tabs]
	set main [ttk::frame $_tabs.main]
	set top [ttk::frame $_tabs.main.top]
	set ddl [ttk::frame $_tabs.ddl]
	$_tabs add $main -text [mc {View}]
	$_tabs add $ddl -text DDL
	pack $_tabs -side top -fill both -padx 3 -pady 5 -expand 1
	pack $top -side top -fill both -padx 3 -pady 5 -expand 0

	# table, database
	foreach {p label widget} [list \
		database [mc {Database:}] ttk::combobox \
		name [mc {View name:}] ttk::entry \
	] {
		ttk::frame $top.$p
		ttk::frame $top.$p.f
		ttk::label $top.$p.f.l -text $label -justify left
		$widget $top.$p.e -textvariable [scope checkState($p)]
		pack $top.$p.f -side top -fill x
		pack $top.$p.f.l -side left
		pack $top.$p.e -side bottom -fill x
	}
	bind $top.database.e <<ComboboxSelected>> "$this updateDB"

	grid $top.database -column 0 -row 0 -padx 1 -sticky we
	grid $top.name -column 1 -row 0 -padx 1 -sticky we

	set middle [frame $main.middle]
	ttk::frame $middle.f
	ttk::label $middle.f.l -text [mc {Code executed to get view data:}]
	pack $middle.f.l -side left
	pack $middle.f -side top -fill x

	if {[string first "Basic" ${::SqlFormattingPlugin::defaultHandler}] > -1} {
		# Basic formatter, so no xscroll in edit
		set _edit [SQLEditor $middle.edit -xscroll false -wrap word]
	} else {
		set _edit [SQLEditor $middle.edit]
	}
	if {$_db != ""} {
		$_edit setDB $_db
	}
	set edit [$_edit getWidget]
	pack $_edit -fill both -expand 1
	pack $middle -side top -fill both -expand 1
	bind $edit <${::Shortcuts::formatSql}> "$this formatSQL"

	# Ddl tab
	set _ddlEdit [SQLEditor $ddl.editor -yscroll true]
	pack $_ddlEdit -side top -fill both -expand 1
	$_ddlEdit readonly

	ttk::frame $_root.d
	pack $_root.d -side bottom -fill x -padx 3 -pady 3

	ttk::button $_root.d.ok -text [mc {Create}] -command "$this clicked ok" -compound left -image img_ok
	pack $_root.d.ok -side left
	ttk::button $_root.d.cancel -text [mc {Cancel}] -command "$this clicked cancel" -compound left -image img_cancel
	pack $_root.d.cancel -side right

	if {$_viewModel != ""} {
		$_root.d.ok configure -text [mc {Change}]
	}

	if {$_code != ""} {
		$_edit setContents [string trim $_code]
	}
	if {$_name != ""} {
		set checkState(name) $_name
	}

	parseInputModel
	initDdlDialog
}

body ViewDialog::parseInputModel {} {
	set top $_tabs.main.top
	foreach db [DBTREE dblist] {
		if {![$db isOpen]} continue
		lappend dblist [$db getName]
	}
	$top.database.e configure -values $dblist -state readonly
	if {$_db != ""} {
		$top.database.e set [$_db getName]
	} else {
		$top.database.e set [lindex $dblist 0]
	}

	if {$_viewModel == ""} return

	set checkState(name) [$_viewModel getValue viewName]
	set selectStmt [$_viewModel getValue subSelect]
	if {$selectStmt == ""} {
		error "No subSelect in parsed View model!"
	}

	set ddl [getObjectDdl $_db $checkState(name)]
	set allTokens [$selectStmt cget -allTokens]
	set firstToken [lindex $allTokens 0]
	set lastToken [lindex $allTokens end]
	set beginIndex [lindex $firstToken 2]
	set endIndex [lindex $lastToken 3]

	$_edit setContents [string range $ddl $beginIndex $endIndex]
	updateDB
}

body ViewDialog::grabWidget {} {
	return $_tabs.main.top.name.e
}

body ViewDialog::okClicked {} {
	set closeWhenOkClicked 0
	set ok 0
	set ret -1
	set ret [createSql]
	if {$ret == -1} return

	if {$ret != ""} {
		$_db begin
		if {[catch {
			if {$_viewModel != ""} {
				$_db eval "DROP VIEW [wrapObjName [$_viewModel getValue viewName] [$_db getDialect]]"
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
		TASKBAR signal DBTree [list REFRESH DB_OBJ $_db]
	}
}

body ViewDialog::validateForSql {} {
	set top $_tabs.main.top
	set db [DBTREE getDBByName [$top.database.e get]]
	if {$db == ""} {
		return [mc {You have to specify database.}]
	}

	set name [$top.name.e get]
	if {[string trim $name] == ""} {
		return [mc {You have to specify view name.}]
	}

	set query [$_edit getContents]
	if {[string trim $query] == ""} {
		return [mc {You havn't wrote a code for the view.}]
	}

	return ""
}

body ViewDialog::createSql {} {
	set top $_tabs.main.top
	set db [DBTREE getDBByName [$top.database.e get]]
	if {$db == ""} {
		Error [mc {You have to specify database.}]
		after 10 "focus [$_edit getWidget]"
		return -1
	}

	set name [$top.name.e get]
	if {[string trim $name] == ""} {
		Error [mc {You have to specify view name.}]
		after 10 "focus $top.name.e"
		return -1
	}

	set query [$_edit getContents]
	if {[string trim $query] == ""} {
		Error [mc {You havn't wrote a code for the view.}]
		after 10 "focus [$_edit getWidget]"
		return -1
	}

	set sql "CREATE VIEW [wrapObjName $name [$_db getDialect]] AS "
	append sql "$query "
	return $sql
}

body ViewDialog::formatSQL {} {
	set query [$_edit getContents]
	set query [Formatter::format $query]
	$_edit setContents $query
	$_edit reHighlight
}

body ViewDialog::updateDB {} {
	set top $_tabs.main.top
	set _db [DBTREE getDBByName [$top.database.e get]]
	$_edit setDB $_db
}

body ViewDialog::getDdlContextDb {} {
	return $_db
}

body ViewDialog::cancelClicked {} {
	return 0
}

body ViewDialog::getSize {} {
	list 400 300
}
