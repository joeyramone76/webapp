use src/common/modal.tcl

class BugHistoryDialog {
	inherit Modal

	constructor {args} {
		Modal::constructor {*}$args
	} {}

	private {
		variable _grid ""
	}

	public {
		method okClicked {}
		method grabWidget {}
		method clear {}
	}
}

body BugHistoryDialog::constructor {args} {
	ttk::frame $_root.u
	pack $_root.u -side top -fill both

	set _grid $_root.u.rg
	RichGrid $_grid -yscroll true -xscroll false -width 600 -height 300 -basecol 0 -selectable 0
	pack $_grid -side left -fill both -expand 1

	# Bottom button
	ttk::frame $_root.d
	pack $_root.d -side bottom -fill x
	ttk::frame $_root.d.f
	pack $_root.d.f -side bottom -fill x
	ttk::button $_root.d.f.ok -text [mc "Close"] -command "$this clicked ok" -compound left -image img_ok
	pack $_root.d.f.ok -side left -pady 3 -padx 3
	ttk::button $_root.d.f.clear -text [mc "Clear"] -command "$this clear" -compound left -image img_clear
	pack $_root.d.f.clear -side left -pady 3 -padx 10

	eval itk_initialize $args

	set col(1) [$_grid addColumn [mc {Type}]]
	set col(2) [$_grid addColumn [mc {Reported on}]]
	set col(3) [$_grid addColumn [mc {Brief}]]
	set col(4) [$_grid addColumn [mc {URL}] "link"]
	$_grid columnsEnd

	$_grid columnConfig $col(1) -width 80 -maxwidth 80
	$_grid columnConfig $col(2) -width 160 -maxwidth 160
	$_grid columnConfig $col(3) -width 250 -maxwidth 250
	$_grid columnConfig $col(4) -maxwidth 110

	foreach it [CfgWin::getReportedBugs] {
		lassign $it createdOn brief url type
		$_grid addRow [list $type [clock format $createdOn -format {%Y-%m-%d   %H:%M:%S}] $brief [list $url [mc {Discussion}]]]
	}
}

body BugHistoryDialog::clear {} {
	YesNoDialog .yesno -title [mc {Clear reports}] -message [mc {Do you want to clear whole bug reports history?}]
	if {![.yesno exec]} return

	CfgWin::clearReportedBugs
	$_grid delRows
}

body BugHistoryDialog::okClicked {} {
}

body BugHistoryDialog::grabWidget {} {
	return $_root.u.rg
}
