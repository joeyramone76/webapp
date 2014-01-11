use src/common/modal.tcl

class AssocDialog {
	inherit Modal
	
	constructor {args} {
		Modal::constructor {*}$args -resizable 1 -expandcontainer 1
	} {}

	common winAssocManualUrl "http://sqlitestudio.pl/docs/html/manual.html#fileAssoc"

	private {
		variable _assocList [dict create]
	}
	
	protected {
		method getSize {}
	}
	
	public {
		variable checkState

		method okClicked {}
		method grabWidget {}
	}
}

body AssocDialog::constructor {args} {
	parseArgs {
		-list {set _assocList $value}
	}

	set top [ttk::frame $_root.u]
	pack $top -side top -fill both -expand 1 -pady 5
	set bottom [ttk::frame $_root.d]
	pack $bottom -side bottom -fill x -padx 2 -pady 2

	set w $top.msgTop
	ttk::frame $w
	SLabel $w.l -wrap word -justify left -text [mc {SQLiteStudio detected following file extensions associated to previous installation(s) of SQLiteStudio:}]
	pack $w.l -side top
	pack $w -side top -fill x
	
	set w $top.main
	ttk::labelframe $w -text [mc {Current associations}]
	pack $w -side top -fill both -expand 1 -pady 5 -padx 20
	
	set w $top.main.sf
	ScrolledFrame $w
	set main [$w getFrame]
	pack $w -side top -fill both -expand 1

	set i 0
	dict for {ext listDicts} $_assocList {
		set listDict [lindex $listDicts 0]
		#set ext [dict get $listDict ext]
		set app [dict get $listDict app]
		ttk::frame $main.row$i
		set checkState(assoc:$ext) 1
		ttk::checkbutton $main.row$i.c -variable [scope checkState(assoc:$ext)] -text "$ext -> $app"
		pack $main.row$i.c -side left -fill x
		pack $main.row$i -side top -fill x -padx 10
		incr i
	}

	$w makeChildsScrollable

	set w $top.msgBottom
	ttk::frame $w
	SLabel $w.l -wrap word -justify left -text [mc {Please select file extensions you would like to associate to currently running version of SQLiteStudio and click OK.}]
	pack $w.l -side top
	pack $w -side top -fill x

	ttk::button $bottom.ok -text [mc {Ok}] -command "$this clicked ok" -compound left -image img_ok
	pack $bottom.ok -side left
	ttk::button $bottom.cancel -text [mc {Cancel}] -command "$this clicked cancel" -compound left -image img_cancel
	pack $bottom.cancel -side right
	
	wm geometry $path [join [getSize] x]

}

body AssocDialog::okClicked {} {
	# Filter extensions with checkState(assoc:*) set to 1.
	return [dict filter $_assocList script {ext listDicts} {set checkState(assoc:$ext)}]
}

body AssocDialog::grabWidget {} {
	return $_root.d.ok
}

body AssocDialog::getSize {} {
	return [list 400 200]
}
