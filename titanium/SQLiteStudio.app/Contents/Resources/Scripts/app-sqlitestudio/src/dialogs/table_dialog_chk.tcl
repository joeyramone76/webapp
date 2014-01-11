use src/dialogs/table_dialog_constr.tcl

class TableDialogChk {
	inherit TableDialogConstr

	constructor {args} {
		TableDialogConstr::constructor {*}$args -title [mc {Check condition}]
	} {}
	destructor {}

	protected {
		variable _editor ""
	
		method parseInputModel {}
		method storeInModel {{model ""}}
		method getSize {}
	}

	public {
		method grabWidget {}
		method updateUiState {}
		method isInvalid {}
		proc validate {model {skipWarnings false}}
	}
}

class TableDialogChkModel {
	public {
		variable named 0
		variable name ""
		variable expr ""
		variable conflict "" ;# only for Sqlite2
		variable sqliteVersion 3
		
		method validate {{skipWarnings false}}
		method getLabelForDisplay {}
		method delColumn {colName}
		method tableNameChanged {from to} {}
		method columnNameChanged {from to actualTableName} {}
	}
}

body TableDialogChkModel::delColumn {colName} {
}

body TableDialogChkModel::validate {{skipWarnings false}} {
	return [TableDialogChk::validate $this $skipWarnings]
}

body TableDialogChkModel::getLabelForDisplay {} {
	return $expr
}

body TableDialogChk::constructor {args} {
	# Condition
	ttk::frame $mainFrame.editFrame
	set _editor [SQLEditor $mainFrame.editFrame.edit]
	pack $_editor -side top -fill both -expand 1
	pack $mainFrame.editFrame -side top -fill both -expand 1

	# Named constraint
	if {$_sqliteVersion == 3} {
		ttk::frame $mainFrame.name
		ttk::checkbutton $mainFrame.name.lab -text [mc {Named constraint:}] -variable [scope uiVar](named) -command "$this updateUiState"
		set _widget(constrName) [ttk::entry $mainFrame.name.edit -textvariable [scope uiVar](name)]
		set uiVar(named) 0
		set uiVar(name) ""
		pack $mainFrame.name.lab -side left
		pack $mainFrame.name.edit -side right -fill x -expand 1
		pack $mainFrame.name -side top -fill x -padx 3 -pady 2
	}

	if {$_sqliteVersion == 2} {
		# Conflict clause
		ttk::frame $mainFrame.conflict
		ttk::label $mainFrame.conflict.lab -text [mc {On conflict:}]
		set uiVar(conflict) ""
		ttk::combobox $mainFrame.conflict.combo -width 12 -values $::conflictAlgorithms_v2 -state readonly -textvariable [scope uiVar](conflict)
		pack $mainFrame.conflict.combo -side right
		pack $mainFrame.conflict.lab -side right
		pack $mainFrame.conflict -side top -fill x -padx 3 -pady 10
	}
}

body TableDialogChk::destructor {args} {
}

body TableDialogChk::getSize {} {
	return [list 400 200]
}

body TableDialogChk::grabWidget {} {
	return [$_editor getWidget]
}

body TableDialogChk::updateUiState {} {
	if {$_sqliteVersion == 3} {
		$_widget(constrName) configure -state [expr {$uiVar(named) ? "normal" : "disabled"}]
	}
}

body TableDialogChk::parseInputModel {} {
	$_editor setContents [$_model cget -expr]

	if {$_sqliteVersion == 3} {
		set uiVar(named) [$_model cget -named]
		set uiVar(name) [$_model cget -name]
	}
	if {$_sqliteVersion == 2} {
		set uiVar(conflict) [$_model cget -conflict]
	}
}

body TableDialogChk::storeInModel {{model ""}} {
	if {$model == ""} {
		set model $_model
	}

	$model configure -expr [$_editor getContents true]
	if {$_sqliteVersion == 3} {
		$model configure -named $uiVar(named) -name $uiVar(name)
	}
	if {$_sqliteVersion == 2} {
		$model configure -conflict $uiVar(conflict)
	}
}

body TableDialogChk::isInvalid {} {
	set tempModel [TableDialogChkModel ::#auto]
	storeInModel $tempModel
	set valid [validate $tempModel]
	delete object $tempModel
	return $valid
}

body TableDialogChk::validate {model {skipWarnings false}} {
	set expr [$model cget -expr]
	if {$expr == ""} {
		if {!$skipWarnings} {
			Error [mc {Condition expression cannot be empty.}]
		}
		return 1
	}
	return 0
}
