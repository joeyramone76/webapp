use src/common/modal.tcl

#>
# @class ImportDialog
# Dialog for importing data into table.
#<
class ImportDialog {
	inherit Modal

	#>
	# @method constructor
	# @param args Option-value pairs.
	# Valid options are all applicable for {@class Modal} and additionaly:
	# <ul>
	# <li><code>-db</code> - database containing table that data will be imported to.
	# <li><code>-existingtable</code> - table that data will be imported to. It's one of existing tables.
	# <li><code>-newtable</code> - table that data will be imported to. It's inexisting table that will be created.
	# </ul>
	#<
	constructor {args} {
		eval Modal::constructor $args -title {[mc {Import data}]}
	} {}

	destructor {}

	protected {
		#>
		# @var _table
		# Table preset by <code>-table</code> option.
		#<
		variable _table ""

		#>
		# @var _db
		# {@class DB} object preset by <code>-db</code> option. It's overwritten by each change in databases drop-down list.
		#<
		variable _db ""

		#>
		# @var _tableMode
		# Defines if table should be created or it's existing one.
		#<
		variable _tableMode "new"

		#>
		# @arr _importHandlers
		# List of exporting handlers (class names).
		#<
		variable _importHandlers

		#>
		# @var _handler
		# Currently chosen handler. It's instance of chosen handler class.
		#<
		variable _handler ""

		variable _configWindow ""
		variable _interrupted 0
		variable _widget
	}

	public {
		variable uiVar

		#>
		# @method okClicked
		# @overloaded Modal
		#<
		method okClicked {}

		#>
		# @method grabWidget
		# @overloaded Modal
		#<
		method grabWidget {}

		#>
		# @method updateTables
		# Called ach time when new database is selected in databases drop-down list. Updates list of tables
		# for tabls drop-down list.
		#<
		method updateTables {}

		#>
		# @method updateConfigButton
		# Enables or disables import configuration button depending on value returned by {@method ImportPlugin::configurable} method of chosen plugin.
		#<
		method updateConfigButton {}

		#>
		# @method handlerSelected
		# Called when import plugin has been changed.
		#<
		method handlerSelected {}

		#>
		# @method configHandler
		# Called when 'Configure' button was pressed to configure import plugin.
		#<
		method configHandler {}

		method configOk {}
		method configCancel {}
		method cancelExecution {}
		method updateTableMode {}
		method validate {}
	}
}

body ImportDialog::constructor {args} {
	set _configWindow $_root.configWindow
	foreach {opt val} $args {
		switch -- $opt {
			"-db" {
				set _db $val
			}
			"-existingtable" {
				set _table $val
				set _tableMode "existing"
			}
			"-newtable" {
				set _table $val
				set _tableMode "new"
			}
		}
	}

	# Import from
	ttk::labelframe $_root.format -text [mc {Import from:}]
	ttk::combobox $_root.format.formatlist -state readonly
	ttk::button $_root.format.config -text [mc {Configure}] -image img_small_more_opts -compound right -command [list $this configHandler]
	pack $_root.format.formatlist -side left -fill x -expand 1 -pady 3 -padx 2
	pack $_root.format.config -side right -pady 3 -padx 5
	pack $_root.format -side top -fill x -padx 2 -pady 8

	# Import to
	set _widget(importTo) [ttk::labelframe $_root.importTo -text [mc {Import to:}]]
	pack $_widget(importTo) -side top -fill x -padx 2 -pady 8

	# Database
	set dblist [list]
	foreach db [DBTREE dblist] {
		if {![$db isOpen]} continue
		lappend dblist [$db getName]
	}
	ttk::labelframe $_widget(importTo).db -text [mc {Database}]
	ttk::frame $_widget(importTo).db.list
	set _widget(dbList) [ttk::combobox $_widget(importTo).db.list.e -state readonly -values $dblist -width 40]
	pack $_widget(dbList) -side left -fill x -expand 1
	pack $_widget(importTo).db.list -side top -fill x -padx 1 -pady 1
	pack $_widget(importTo).db -side top -fill x -padx 3 -pady 8
	if {$_db != ""} {
		$_widget(dbList) set [$_db getName]
	}
	bind $_widget(dbList) <<ComboboxSelected>> "$this updateTables"

	# Table
	set uiVar(tableMode) $_tableMode
	ttk::labelframe $_widget(importTo).table -text [mc {Table}]
	set _widget(existing) [ttk::frame $_widget(importTo).table.existing]
	set _widget(new) [ttk::frame $_widget(importTo).table.new]
	pack $_widget(existing) -side top -fill x -padx 2 -pady 3
	pack $_widget(new) -side top -fill x -padx 2 -pady 3
	pack $_widget(importTo).table -side top -fill x -padx 3 -pady 8

	ttk::radiobutton $_widget(existing).r -text [mc {Existing}] -variable [scope uiVar](tableMode) -value "existing" -command [list $this updateTableMode]
	set _widget(tableList) [ttk::combobox $_widget(existing).e -width 16 -state readonly]
	pack $_widget(existing).r -side top -fill x
	pack $_widget(existing).e -side top -fill x -expand 1

	ttk::radiobutton $_widget(new).r -text [mc {Create new table}] -variable [scope uiVar](tableMode) -value "new" -command [list $this updateTableMode]
	ttk::entry $_widget(new).e -width 16 -textvariable [scope uiVar](newTableName)
	pack $_widget(new).r -side top -fill x
	pack $_widget(new).e -side top -fill x -expand 1
	set uiVar(newTableName) ""

	if {$_db != ""} {
		updateTables
		if {$_table != ""} {
			switch -- $_tableMode {
				"existing" {
					$_widget(existing).e set $_table
				}
				"new" {
					$_widget(new).e insert end $_table
				}
			}
		}
	}
	updateTableMode

	# Export format plugins
	array set _exportHandlers {}
	foreach hnd ${ImportPlugin::handlers} {
		set _importHandlers([${hnd}::getName]) $hnd
	}
	set names [lsort -dictionary [array names _importHandlers]]
	$_root.format.formatlist configure -values $names
	bind $_root.format.formatlist <<ComboboxSelected>> [list $this handlerSelected]
	if {[llength $names] > 0} {
		set idx 0
		if {"CSV" in $names} {
			set idx [lsearch -exact $names "CSV"]
		}
		$_root.format.formatlist set [lindex $names $idx]
		set _handler [$_importHandlers([lindex $names $idx]) ::#auto]
	}
	updateConfigButton

	# Bottom buttons
	ttk::frame $_root.btn
	ttk::button $_root.btn.import -text [mc {Import}] -command [list $this clicked ok] -compound left -image img_ok
	ttk::button $_root.btn.cancel -text [mc {Cancel}] -command [list $this clicked cancel] -compound left -image img_cancel
	pack $_root.btn.import $_root.btn.cancel -side left -padx 1
	pack $_root.btn -side top -pady 2

}

body ImportDialog::destructor {} {
	if {$_handler != ""} {
		catch {$_handler closeDataSource}
		catch {delete object $_handler}
	}
}

body ImportDialog::grabWidget {} {
	return $_widget(dbList)
}

body ImportDialog::validate {} {
	if {$_handler == ""} {
		Error [mc {Import method is not selected.}]
		return 0
	}
	
	if {$_db == ""} {
		Error [mc {You have to choose database.}]
		return 0
	}

	switch -- $uiVar(tableMode) {
		"existing" {
			if {[$_widget(tableList) get] == ""} {
				Error [mc {No existing table is selected.}]
				return 0
			}
		}
		"new" {
			set tableName $uiVar(newTableName)
			set tables [$_db getTables]
			if {[string tolower $tableName] in [string tolower $tables]} {
				Error [mc {Table typed to create already exists. Please change table name.}]
				return 0
			}
			if {$uiVar(newTableName) == ""} {
				set dialog [YesNoDialog .#auto -message [mc {Are you sure you want to create table with empty name?}] -title [mc {Empty table name}]]
				if {![$dialog exec]} {
					return 0
				}
			}
		}
	}
	return 1
}

body ImportDialog::okClicked {} {
	set _interrupted 0
	set closeWhenOkClicked 0
	
	set _db [DBTREE getDBByName [$_widget(dbList) get]]
	if {![validate]} {
		return
	}

	switch -- $uiVar(tableMode) {
		"existing" {
			set table [$_widget(tableList) get]
		}
		"new" {
			set table $uiVar(newTableName)
		}
		default {
			error "Unsupported tableMode: $uiVar(tableMode)"
		}
	}

	if {![$_handler import $_db $table $uiVar(tableMode)]} {
		# Everything went ok, so lets update rest of GUI.
		TASKBAR signal DBTree [list REFRESH DB_OBJ $_db]
		TASKBAR signal TableWin [list REFRESH_DATA $table]

		set closeWhenOkClicked 1
	}
}

body ImportDialog::updateTables {} {
	$_widget(tableList) set ""
	set _db [DBTREE getDBByName [$_widget(dbList) get]]
	if {$_db != ""} {
		$_widget(tableList) configure -values [$_db getTables]
	}
}

body ImportDialog::updateConfigButton {} {
	set chosen [$_root.format.formatlist get]
	if {$chosen == ""} {
		$_root.format.config configure -state disabled
		return
	}
	set hnd $_importHandlers($chosen)

	if {[${hnd}::configurable]} {
		$_root.format.config configure -state normal
	} else {
		$_root.format.config configure -state disabled
	}
}

body ImportDialog::handlerSelected {} {
	catch {$_handler closeDataSource}
	catch {delete object $_handler}
	set chosen [$_root.format.formatlist get]
	if {$chosen == ""} {
		updateConfigButton
		return
	}
	set _handler [$_importHandlers($chosen) ::#auto]
	updateConfigButton
}

body ImportDialog::configHandler {} {
	set t $_configWindow
	toplevel $t
	wm withdraw $t
	if {[os] == "win32"} {
		wm attributes $t -toolwindow 1
	} else {
		wm resizable $t 0 0
	}
	wm transient $t $_root
	wm title $t [mc {Configuration}]
	$t configure -background black
	pack [ttk::frame $t.root] -fill both -expand 1 -padx 1 -pady 1

	bind $t <Return> [list $this configOk]
	bind $t <Escape> [list $this configCancel]

	pack [ttk::frame $t.root.top] -side top -fill both -padx 2 -expand 1
	pack [ttk::frame $t.root.bottom] -side bottom -fill x

	# Bottom buttons
	ttk::button $t.root.bottom.ok -text [mc {Ok}] -command [list $this configOk] -image img_ok -compound left
	ttk::button $t.root.bottom.cancel -text [mc {Cancel}] -command [list $this configCancel] -image img_cancel -compound left
	pack $t.root.bottom.ok -side left -padx 3 -pady 3
	pack $t.root.bottom.cancel -side right -padx 3 -pady 3

	# Plugin interface
	$_handler createConfigUI $t.root.top

	# Positioning and setting up
	set w $_root.format.config
	set x [expr {[winfo rootx $w]+[winfo width $w]+1}]
	set y [expr {[winfo rooty $w]-50}]

	wm geometry $t +$x+$y
	update idletasks

	wm deiconify $t
	wm transient $t $_root
	grab $t
	focus $t
	raise $t
}

body ImportDialog::configOk {} {
	set t $_configWindow
	$_handler applyConfig $t.root.top
	destroy $t

	focus $path
	bind $path <Return> [list $this clicked ok]
	bind $path <Escape> [list $this clicked cancel]
}

body ImportDialog::configCancel {} {
	set t $_configWindow
	destroy $t

	focus $path
	bind $path <Return> [list $this clicked ok]
	bind $path <Escape> [list $this clicked cancel]
}

body ImportDialog::updateTableMode {} {
	switch -- $uiVar(tableMode) {
		"existing" {
			$_widget(existing).e configure -state readonly
			$_widget(new).e configure -state disabled
		}
		"new" {
			$_widget(existing).e configure -state disabled
			$_widget(new).e configure -state normal
		}
	}
}
