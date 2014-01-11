use src/common/modal.tcl

class TriggerDialogColumns {
	inherit Modal

	constructor {args} {
		Modal::constructor {*}$args -modal 1 -resizable 1 -expandcontainer 1 -title [mc {Trigger columns}]
	} {}
	destructor {}

	protected {
		variable _db ""
		variable _triggerDialog ""
		variable _columns ""
		variable _table ""
		variable _widget
		variable _height 200
	}

	public {
		variable uiVar

		method grabWidget {}
		method getSize {}
		method okClicked {}
		method cancelClicked {}
	}
}

body TriggerDialogColumns::constructor {args} {
	parseArgs {
		-db {set _db $value}
		-triggerdialog {set _triggerDialog $value}
		-columns {set _columns $value}
		-table {set _table $value}
	}

	ScrolledFrame $_root.sf
	set _widget(frame) [$_root.sf getFrame]
	pack $_root.sf -side top -fill both -expand 1
	
	ttk::frame $_root.d
	pack $_root.d -side bottom -fill x -padx 3 -pady 3

	ttk::button $_root.d.ok -text [mc {Ok}] -command "$this clicked ok" -compound left -image img_ok
	pack $_root.d.ok -side left
	ttk::button $_root.d.cancel -text [mc {Cancel}] -command "$this clicked cancel" -compound left -image img_cancel
	pack $_root.d.cancel -side right
	
	set f $_widget(frame)
	set allColumns [$_db getColumns $_table]
	set i 0
	set added [list]
	foreach col $allColumns {
		set uiVar(col:$col) [expr {$col in $_columns}]
		ttk::checkbutton $f.c$i -text $col -variable [scope uiVar](col:$col)
		pack $f.c$i -side top -fill x -pady 1
		lappend added $col
		incr i
	}
	
	# Adding columns theoretically not existing in table/view (trigger allows to define any columns in UPDATE OF)
	foreach col $_columns {
		if {$col ni $added} {
			set uiVar(col:$col) 1
			ttk::checkbutton $f.c$i -text $col -variable [scope uiVar](col:$col)
			pack $f.c$i -side top -fill x -pady 1
			incr i
		}
	}
}

body TriggerDialogColumns::destructor {} {
}

body TriggerDialogColumns::grabWidget {} {
	return $_widget(frame)
}

body TriggerDialogColumns::getSize {} {
	return [list 260 $_height]
}

body TriggerDialogColumns::okClicked {} {
# 	set closeWhenOkClicked 1
	set cols [list]
	foreach col [array names uiVar col:*] {
		if {$uiVar($col)} {
			lappend cols [string range $col 4 end]
		}
	}
	return [list 1 $cols]
}

body TriggerDialogColumns::cancelClicked {} {
	return [list 0 ""]
}
