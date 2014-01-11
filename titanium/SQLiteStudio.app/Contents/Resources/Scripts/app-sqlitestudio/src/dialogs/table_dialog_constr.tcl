use src/common/modal.tcl
use src/common/ui_state_handler.tcl

class TableDialogConstr {
	inherit Modal UiStateHandler

	constructor {args} {
		Modal::constructor {*}$args -modal 1 -resizable 1 -expandcontainer 1
	} {}
	destructor {}

	protected {
		variable _db ""
		variable _model ""
		variable _tableDialog ""
		variable _sqliteVersion 3
		variable _widget
		variable mainFrame ""

		method getColumns {}
		abstract method parseInputModel {}
		abstract method storeInModel {{model ""}}
		abstract method isInvalid {}
		abstract proc validate {model {skipWarnings false}}
	}

	public {
		variable uiVar

		method exec {}
		method okClicked {}
		method cancelClicked {}
		method destroyed {}
	}
}

body TableDialogConstr::constructor {args} {
	parseArgs {
		-db {set _db $value}
		-model {set _model $value}
		-tabledialog {set _tableDialog $value}
	}

	if {[$_db getHandler] == "::Sqlite3"} {
		set _sqliteVersion 3
	} else {
		set _sqliteVersion 2
	}

	set mainFrame [ttk::frame $_root.mainFrame]
	pack $mainFrame -side top -fill both -expand 1

	# MacOS X appearance fix
	if {[tk windowingsystem] == "aqua"} {
		ttk::frame $_root.mac_bottom
		ttk::label $_root.mac_bottom.l -text " "
		pack $_root.mac_bottom.l -side top
		pack $_root.mac_bottom -side bottom -fill x
	}

	# Bottom buttons
	ttk::frame $_root.bottom
	ttk::button $_root.bottom.ok -text [mc {Ok}] -image img_ok -compound left -command "$this clicked ok"
	ttk::button $_root.bottom.cancel -text [mc {Cancel}] -image img_cancel -compound left -command "$this clicked cancel"
	pack $_root.bottom.ok -side left -pady 3 -padx 2
	pack $_root.bottom.cancel -side right -pady 3 -padx 2
	pack $_root.bottom -side bottom -fill x
}

body TableDialogConstr::exec {} {
	if {$_model != ""} {
		parseInputModel
	}
	updateUiState
	return [Modal::exec]
}

body TableDialogConstr::okClicked {} {
	set closeWhenOkClicked 1

	if {[isInvalid]} {
		set closeWhenOkClicked 0
		return 0
	}

	storeInModel
	return 1
}

body TableDialogConstr::cancelClicked {} {
	return 0
}

body TableDialogConstr::destroyed {} {
	return 0
}

body TableDialogConstr::getColumns {} {
	return [$_tableDialog getColumns]
}
