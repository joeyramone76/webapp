use src/common/modal.tcl

class PopulateTableDialog {
	inherit Modal

	constructor {args} {
		Modal::constructor {*}$args
	} {}

	opt db
	opt table

	private {
		variable _db ""
		variable _table ""
		variable _colFrameObj ""
		variable _colFrame ""
		variable _colWidgets
		variable _hndClass
		variable _handler
		variable _interrupted 0

		method configColumn {rowname}
		method populate {}
	}

	public {
		variable checkState

		method okClicked {}
		method grabWidget {}

		method refreshColumns {}
		method modeSelected {rowname}
		method updateState {rowname}
		method configColumnButtonEvent {rowname pressed}
		method configOk {rowname}
		method configCancel {rowname}
		method cancelExecution {}
	}
}

body PopulateTableDialog::constructor {args} {
	foreach {opt val} $args {
		switch -- $opt {
			"-db" {
				set _db $val
			}
			"-table" {
				set _table $val
			}
		}
	}

	ttk::frame $_root.top
	pack $_root.top -side top -fill both -padx 3 -pady 5

	set w table
	set checkState($w) ""
	ttk::frame $_root.top.$w
	ttk::frame $_root.top.$w.f
	ttk::label $_root.top.$w.f.l -text [mc {Table:}] -justify left
	ttk::combobox $_root.top.$w.e -width 40 -textvariable [scope checkState]($w)
	pack $_root.top.$w.f -side top -fill x
	pack $_root.top.$w.f.l -side left
	pack $_root.top.$w.e -side bottom -fill x
	pack $_root.top.$w -side top -fill x
	bind $_root.top.$w.e <<ComboboxSelected>> "$this refreshColumns"

	if {$_table != ""} {
		$_root.top.$w.e configure -values $_table
		$_root.top.$w.e set $_table
		$_root.top.$w.e configure -state disabled
	} else {
		set tables [list]
		if {$_db == ""} {
			set dblist [DBTREE getActiveDatabases]
		} else {
			set dblist $_db
		}
		foreach db $dblist {
			foreach tab [$db getTables] {
				lappend tables "$tab ([$db getName])"
			}
		}
		$_root.top.$w.e configure -values [lsort -dictionary $tables] -state readonly
		if {$_selecttable != ""} {
			$_root.top.$w.e set "$_selecttable ([$_db getName])"
			set _table $_selecttable
		}
	}

	# Number of rows to fill
	set w rows
	ttk::frame $_root.top.$w
	ttk::frame $_root.top.$w.f
	ttk::label $_root.top.$w.f.l -text [mc {Number of rows to insert:}] -justify left
	ttk::spinbox $_root.top.$w.e -width 40 -textvariable [scope checkState]($w) -increment 1 -from 1 \
					-to 999999999999999 -validatecommand "validateIntWithEmpty %S" \
					-validate key
	pack $_root.top.$w.f -side top -fill x
	pack $_root.top.$w.f.l -side left
	pack $_root.top.$w.e -side bottom -fill x
	pack $_root.top.$w -side top -fill x -pady 2
	set checkState($w) 100

	# On conflict
	set w conflict
	set algos [ldelete $::conflictAlgorithms ""]
	ttk::frame $_root.top.$w
	ttk::frame $_root.top.$w.f
	ttk::label $_root.top.$w.f.l -text [mc {On a constraint violation:}] -justify left
	ttk::combobox $_root.top.$w.e -state readonly -textvariable [scope checkState]($w) -values $algos
	pack $_root.top.$w.f -side top -fill x
	pack $_root.top.$w.f.l -side left
	pack $_root.top.$w.e -side bottom -fill x
	pack $_root.top.$w -side top -fill x -pady 2
	set checkState($w) "ROLLBACK"

	# List of columns
	set w fr
	ttk::frame $_root.top.$w -relief groove -borderwidth 2
	pack $_root.top.$w -side top -fill both -expand 1

	set w fr.cols
	ttk::frame $_root.top.$w -height 20
	ttk::label $_root.top.$w.column -text [mc {Column}]
	ttk::label $_root.top.$w.mode -text [mc {Mode}]
	pack $_root.top.$w -side top -fill x
	grid $_root.top.$w.column -row 0 -column 0 -sticky w
	grid $_root.top.$w.mode -row 0 -column 1 -sticky w
	grid columnconfigure $_root.top.$w 0 -minsize 160
	grid columnconfigure $_root.top.$w 1 -minsize 160

	set w fr.colsFrame
	set _colFrameObj [ScrolledFrame $_root.top.$w]
	set _colFrame [$_root.top.$w getFrame]
	pack $_root.top.$w -side left -fill both -expand 1
	ttk::frame $_colFrame.sep -width 320
	pack $_colFrame.sep -side top -fill x

	ttk::label $_colFrame.start -text [mc {Select table to display available columns}]
	pack $_colFrame.start -side top -pady 50

	set w fr.sep
	ttk::frame $_root.top.$w -height 150 -borderwidth 2 -relief raised
	pack $_root.top.$w -side right

	# Bottom part of dialog
	ttk::frame $_root.d
	pack $_root.d -side bottom -fill x
	ttk::frame $_root.d.f
	pack $_root.d.f -side bottom

	ttk::button $_root.d.f.ok -text [mc {Populate}] -command "$this clicked ok" -compound left -image img_ok
	pack $_root.d.f.ok -side left -pady 3 -padx 2
	ttk::button $_root.d.f.cancel -text [mc {Cancel}] -command "$this clicked cancel" -compound left -image img_cancel
	pack $_root.d.f.cancel -side left -pady 3 -padx 2

	# To avoid error when closing main populating window while plugin config window exists
	wm protocol $path WM_DELETE_WINDOW "destroy $_root.columnConfig; update; $this windowDestroyed"

	refreshColumns
}

body PopulateTableDialog::okClicked {} {
	set closeWhenOkClicked 0
	if {[catch {populate} res]} {
		Error [mc "Error occured while populating table:\n%s" $res]
	} elseif {$res != ""} {
		Warning $res
	} else {
		set closeWhenOkClicked 1
	}
}

body PopulateTableDialog::grabWidget {} {
	return $_root.top.table.e
}


body PopulateTableDialog::refreshColumns {} {
	set sel [$_root.top.table.e get]

	if {$sel == ""} return

	if {$_table != ""} {
		set table $_table
		set db $_db
	} else {
		regexp -- {(\w+)\s+\((\w+)\)} $sel dummy table dbname
		set db [DBTREE getDBByName $dbname]
	}

	catch {destroy $_canvas.f}
	catch {array unset checkState col_sort:*}
	catch {array unset checkState col_collate:*}
	catch {array unset checkState col_col:*}
	catch {array unset _colWidgets}

	foreach widg [winfo children $_colFrame] {
		if {[string match "*.sep" $widg]} continue
		destroy $widg
	}

	array set _hndClass {}
	foreach hnd $PopulatingPlugin::handlers {
		set name [${hnd}::getName]
		set _hndClass($name) $hnd
	}

	set defHnd ""
	if {$PopulatingPlugin::defaultHandler in [array names _hndClass]} {
		set defHnd $PopulatingPlugin::defaultHandler
	} elseif {[llength [array names _hndClass]] > 0} {
		set defHnd [lindex [lsort [array names _hndClass]] 0]
	}

	set i 1
	foreach row [$db getTableInfo [stripColName $table]] {
		set rowname [stripColName [dict get $row name]]

		ttk::frame $_colFrame.check$i
		pack $_colFrame.check$i -side top -fill x -pady 1

		ttk::checkbutton $_colFrame.check$i.c -variable [scope checkState](col:$rowname) \
			-command [list $this updateState $rowname] -text $rowname;# -justify left
		set checkState(col:$rowname) 0

		ttk::combobox $_colFrame.check$i.s -values [lsort [array names _hndClass]] -state readonly -width 20 -textvariable [scope checkState](col_mode:$rowname)
		bind $_colFrame.check$i.s <<ComboboxSelected>> [list $this modeSelected $rowname]
		set checkState(col_mode:$rowname) ""

		if {$defHnd != ""} {
			$_colFrame.check$i.s set $defHnd
		}

		ttk::label $_colFrame.check$i.cl -image img_more -relief raised -border 1 -state disabled
		bind $_colFrame.check$i.cl <ButtonPress-1> [list $this configColumnButtonEvent $rowname 1]
		bind $_colFrame.check$i.cl <ButtonRelease-1> [list $this configColumnButtonEvent $rowname 0]
		set checkState(col_config:$rowname) ""

		set _colWidgets($rowname) [list $_colFrame.check$i.s $_colFrame.check$i.cl]
		pack $_colFrame.check$i.c -side left -fill x -padx 1
		pack $_colFrame.check$i.cl -side right -padx 1
		pack $_colFrame.check$i.s -side right -padx 1
		updateState $rowname
		incr i
	}

	$_colFrameObj makeChildsScrollable
}

body PopulateTableDialog::configColumnButtonEvent {rowname pressed} {
	if {[[lindex $_colWidgets($rowname) 1] cget -state] == "disabled"} return
	if {$pressed} {
		[lindex $_colWidgets($rowname) 1] configure -relief sunken
		configColumn $rowname
	} else {
		[lindex $_colWidgets($rowname) 1] configure -relief raised
	}
}

body PopulateTableDialog::updateState {rowname} {
	set st $checkState(col:$rowname)
	set state [expr {$st ? "readonly" : "disabled"}]
	[lindex $_colWidgets($rowname) 0] configure -state $state
	modeSelected $rowname
}

body PopulateTableDialog::modeSelected {rowname} {
	set st $checkState(col:$rowname)
	set mode $checkState(col_mode:$rowname)
	if {!$st || ![info exists _hndClass($mode)]} {
		catch {delete object $_handler($rowname)}
		[lindex $_colWidgets($rowname) 1] configure -state disabled
		return
	}

	if {[$_hndClass($mode)::configurable]} {
		[lindex $_colWidgets($rowname) 1] configure -state normal
		set _handler($rowname) [$_hndClass($mode) ::#auto]
		$_handler($rowname) setDb $_db
	} else {
		catch {delete object $_handler($rowname)}
		catch {unset _handler($rowname)}
		[lindex $_colWidgets($rowname) 1] configure -state disabled
	}
}

body PopulateTableDialog::configColumn {rowname} {
	if {![info exists _handler($rowname)]} return

	set t $_root.columnConfig
	toplevel $t
	wm withdraw $t
	if {[os] == "win32"} {
		wm attributes $t -toolwindow 1
	}
	wm transient $t $_root
	wm title $t [mc {Configuration}]
	$t configure -background black
	pack [ttk::frame $t.root] -fill both -expand 1;# -padx 1 -pady 1

	bind $t <Return> [list $this configOk $rowname]
	bind $t <Escape> [list $this configCancel $rowname]

	pack [ttk::frame $t.root.top] -side top -fill both -padx 2 -expand 1
	pack [ttk::frame $t.root.bottom] -side bottom -fill x

	# Bottom buttons
	ttk::button $t.root.bottom.ok -text [mc {Ok}] -command [list $this configOk $rowname] -image img_ok -compound left
	ttk::button $t.root.bottom.cancel -text [mc {Cancel}] -command [list $this configCancel $rowname] -image img_cancel -compound left
	pack $t.root.bottom.ok -side left -padx 3 -pady 3
	pack $t.root.bottom.cancel -side right -padx 3 -pady 3

	# Plugin interface
	$_handler($rowname) createConfigUI $t.root.top

	# Positioning and setting up
	set w [lindex $_colWidgets($rowname) 1]
	set x [expr {[winfo rootx $w]+[winfo width $w]+1}]
	set y [expr {[winfo rooty $w]-50}]


	bind $t <Destroy> [list $this configColumnButtonEvent $rowname 0] ;# Config button goes back to raised state

	wm geometry $t +$x+$y
	update idletasks
	makeSureIsVisible $t ;# also makes update and deiconify
	wm transient $t $_root
	grab $t
	focus $t
	raise $t
}

body PopulateTableDialog::configOk {rowname} {
	if {[info exists _handler($rowname)]} {
		set t $_root.columnConfig
		$_handler($rowname) applyConfig $t.root.top
	}
	destroy $t

	focus $path
	bind $path <Return> [list $this clicked ok]
	bind $path <Escape> [list $this clicked cancel]
	refreshGrab
}

body PopulateTableDialog::configCancel {rowname} {
	set t $_root.columnConfig
	$this configColumnButtonEvent $rowname 0 ;# Config button goes back to raised state
	destroy $t

	focus $path
	bind $path <Return> [list $this clicked ok]
	bind $path <Escape> [list $this clicked cancel]
	refreshGrab
}

body PopulateTableDialog::populate {} {
	set colsToInsert [list]
	set generators [list]
	foreach idx [array names checkState col:*] {
		set rowname [string range $idx 4 end]
		set state $checkState(col:$rowname)
		if {!$state} continue ;# column is disabled
		if {![info exists _handler($rowname)]} {
			puts stderr "Handler for enabled column doesn't exist! Column name: $rowname"
			continue ;# Handler doesn't exist. Should never happen.
		}

		lappend colsToInsert "[wrapObjName $rowname [$_db getDialect]]"
		lappend generators $_handler($rowname)
	}
	if {[string trim $checkState(rows)] == "" || ![string is integer $checkState(rows)]} {
		return [mc {You have to type valid number of rows to insert.}]
	}
	if {[llength $colsToInsert] == 0} {
		return [mc {You have to select at least one column to populate.}]
	}

	set progress [BusyDialog::show [mc {Populating...}] [mc {Populating table '%s'.} $_table] true 100 false determinate]
	$progress configure -onclose [list $this cancelExecution]
	$progress setCloseButtonLabel [mc {Stop}]

	set conflictAlgo $checkState(conflict)

	set sql [string map [list %t $_table %c [join $colsToInsert ","] %C $conflictAlgo] {INSERT OR %C INTO [%t] (%c) VALUES (%v)}]

	$_db begin
	for {set i 0} {$i < $checkState(rows)} {incr i} {
		# Clearing values
		set vals [list]

		# Generating values
		set j 0
		foreach gen $generators {
			if {[catch {
				set val_$j [$gen nextValue]
			} res]} {
				catch {$_db rollback}
				BusyDialog::hide
				cutOffStdTclErr res
				Error $res
			}
			lappend vals \$val_$j
			incr j
		}

		# Inserting next row
		if {[catch {
			$_db eval [string map [list %v [join $vals ","]] $sql]
		} res]} {
			catch {$_db rollback}
			BusyDialog::hide
			cutOffStdTclErr res
			error $res
		}
		if {$checkState(rows) > 100} {
			if {$i % 100 == 0} {
				$progress setProgress [expr {$i * 100 / $checkState(rows)}]
			}
		} else {
			$progress setProgress [expr {$i * 100 / $checkState(rows)}]
		}
		if {$_interrupted} {
			break
		}
	}
	catch {$_db commit} ;# transaction could be already closed by "INSERT OR conflictAlgo" statement
	BusyDialog::hide
	TASKBAR signal "TableWin" [list REFRESH_DATA $_table]
	return ""
}

body PopulateTableDialog::cancelExecution {} {
	set _interrupted 1
}
