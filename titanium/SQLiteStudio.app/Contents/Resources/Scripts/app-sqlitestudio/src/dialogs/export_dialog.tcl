use src/common/modal.tcl

#>
# @class ExportDialog
# Common dialog for all export types (databases, tables, query results).
#<
class ExportDialog {
	inherit Modal

	#>
	# @method constructor
	# @param args Option-value pairs.
	# Valid options are all applicable for {@class Modal} and additionaly:
	# <ul>
	# <li><code>-db</code> - database that data will be exported from. Used to refresh tables list, required only for table exporting mode.
	# <li><code>-table</code> - table that will be exported. Used for table exporting mode.
	# <li><code>-readonly</code> - <code>true</code> if database and table lists should be readonly - used to export preselected table from preselected database.
	# <li><code>-showtable</code> - <code>true</code> if tables list should be displayed. Required for table exporting mode.
	# <li><code>-showdb</code> - <code>true</code> if databases list should be displayed. Required for table and database exporting modes.
	# <li><code>-type</code> - determinates exporting mode. Valid values are: <code>table</code>, <code>database</code> and <code>results</code>.
	# <li><code>-query</code> - SQL query used to retrieve results. Required for results exporting mode.
	# </ul>
	#<
	constructor {args} {
		eval Modal::constructor $args -title {[mc {Export data}]}
	} {}

	destructor {}

	protected {
		#>
		# @var _outFile
		# Output file path.
		#<
		variable _outFile ""

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
		# @var _type
		# Exporting mode preset by <code>-type</code> option.
		#<
		variable _type ""

		#>
		# @var _readonly
		# Readonly mode preset by <code>-readonly</code> option.
		#<
		variable _readonly 0

		#>
		# @var _showTable
		# Showing tables list preset by <code>-showtable</code> option.
		#<
		variable _showTable 0

		#>
		# @var _showDB
		# Showing databases list preset by <code>-showdb</code> option.
		#<
		variable _showDB 0

		#>
		# @var _query
		# SQL query used to retrieve results. Preset by <code>-query</code> option.
		#<
		variable _query ""

		#>
		# @arr _exportHandlers
		# List of exporting handlers (class names).
		#<
		variable _exportHandlers

		#>
		# @var _handler
		# Currently chosen handler. It's instance of chosen handler class.
		#<
		variable _handler ""

		variable _configWindow ""

		#>
		# @var _columns
		# List of {columnId columnName columnType columnTable} sublists from results grid, so datatypes can be used in exporting columns.
		# ColumnId is unused in export dialog.
		#<
		variable _columns [list]

		variable _outFileWidgets [list]
		variable _useFile 1
		variable _interrupted 0
		variable _queryExecutor ""

		method getContext {}
		method getSchemaSteps {schema}
		method exportTable {db table structureOnly}
		method exportIndex {db name sql}
		method exportTrigger {db name sql}
		method exportView {db name sql}
		method exportResultsData {db query}
		method setFileWidgets {state}
	}

	public {
		#>
		# @arr checkState
		# Various values linked with widgets in the dialog, such as choosen specific format options.
		#<
		variable checkState

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
		# @method browseOutputFile
		# Called when users pushes <i>Browse</i> button placed next to output fil field.
		# Opens file dialog. After users chooses file, the method fills output file field with it.
		#<
		method browseOutputFile {}

		#>
		# @method databasePicked
		# Called ach time when new database is selected in databases drop-down list. Updates list of tables
		# for tabls drop-down list.
		#<
		method databasePicked {}

		#>
		# @method updateConfigButton
		# Enables or disables export configuration button depending on value returned by {@method ExportPlugin::configurable} method of chosen plugin.
		#<
		method updateConfigButton {}

		#>
		# @method handlerSelected
		# Called when export plugin has been changed.
		#<
		method handlerSelected {}

		#>
		# @method configHandler
		# Called when 'Configure' button was pressed to configure export plugin.
		#<
		method configHandler {}

		method configOk {}
		method configCancel {}
		method exportDatabase {db}
		method exportTableOnly {db table structureOnly}
		method exportResults {db query}
		method sortTablesByFk {db tablesToExport}
		method sortViewsByCrossUsage {db viewsToExport}
		method cancelExecution {}
	}
}

body ExportDialog::constructor {args} {
	set _configWindow $_root.configWindow
	foreach {opt val} $args {
		switch -- $opt {
			"-db" {
				set _db $val
			}
			"-table" {
				set _table $val
			}
			"-readonly" {
				set _readonly $val
			}
			"-showtable" {
				set _showTable $val
			}
			"-showdb" {
				set _showDB $val
			}
			"-type" {
				set _type $val
			}
			"-query" {
				set _query $val
			}
			"-columns" {
				set _columns $val
			}
		}
	}

	if {$_showDB} {
		# Database
		set dblist [list]
		foreach db [DBTREE dblist] {
			if {![$db isOpen]} continue
			lappend dblist [$db getName]
		}
		ttk::labelframe $_root.db -text [mc {Database}]
		ttk::frame $_root.db.list
		ttk::combobox $_root.db.list.e -state readonly -values $dblist -width 40
		pack $_root.db.list.e -side left -fill x -expand 1
		pack $_root.db.list -side top -fill x -padx 1 -pady 1
		pack $_root.db -side top -fill x -padx 2 -pady 8
		if {$_showTable} {
			bind $_root.db.list.e <<ComboboxSelected>> "$this databasePicked"
		} else {
			ttk::frame $_root.db.only
			ttk::checkbutton $_root.db.only.c -text [mc {Only structure, without data}] -variable [scope checkState(dbonly)]
			pack $_root.db.only.c -side left
			pack $_root.db.only -side top -fill x -padx 1 -pady 1
			set checkState(dbonly) 0
		}
		if {$_db != ""} {
			$_root.db.list.e set [$_db getName]
		}

		if {$_showTable} {
			# Table
			ttk::labelframe $_root.table -text [mc {Table or view}]
			ttk::combobox $_root.table.e -state readonly
			pack $_root.table.e -side left -fill x -expand 1 -pady 1 -padx 1
			pack $_root.table -side top -fill x -padx 2 -pady 8
			if {$_db != ""} {
				databasePicked
				if {$_table != ""} {
					$_root.table.e set $_table
				}
			}
		}

		if {$_readonly} {
			if {$_showTable} {
				$_root.table.e configure -state disabled
			}
			$_root.db.list.e configure -state disabled
		}
	}

	# File
	ttk::labelframe $_root.file -text [mc {Output file}]
	set _outFile [ttk::entry $_root.file.e]
	ttk::button $_root.file.b -text [mc {Browse}] -command [list $this browseOutputFile] -compound left -image img_open
	pack $_root.file.e -side left -fill x -expand 1
	pack $_root.file.b -side right -padx 1
	pack $_root.file -side top -fill x -padx 2 -pady 8
	set _outFileWidgets [list $_root.file.b $_root.file.e]

	# Export format
	ttk::labelframe $_root.format -text [mc {Export format}]
	ttk::combobox $_root.format.formatlist -state readonly
	ttk::button $_root.format.config -text [mc {Configure}] -image img_small_more_opts -compound right -command [list $this configHandler]
	pack $_root.format.formatlist -side left -fill x -expand 1 -pady 3 -padx 2
	pack $_root.format.config -side right -pady 3 -padx 5
	pack $_root.format -side top -fill x -padx 2 -pady 8

	# Export format plugins
	array set _exportHandlers {}
	set context [getContext]
	foreach hnd ${ExportPlugin::handlers} {
		if {![${hnd}::isContextSupported $context]} continue
		set _exportHandlers([${hnd}::getName]) $hnd
	}
	set names [lsort -dictionary [array names _exportHandlers]]
	$_root.format.formatlist configure -values $names
	bind $_root.format.formatlist <<ComboboxSelected>> [list $this handlerSelected]
	if {[llength $names] > 0} {
		set idx 0
		if {"CSV" in $names} {
			set idx [lsearch -exact $names "CSV"]
		}
		$_root.format.formatlist set [lindex $names $idx]
		set _handler [$_exportHandlers([lindex $names $idx]) ::#auto]
	}
	updateConfigButton

	# Bottom buttons
	ttk::frame $_root.btn
	ttk::button $_root.btn.export -text [mc {Export}] -command [list $this clicked ok] -compound left -image img_ok
	ttk::button $_root.btn.cancel -text [mc {Cancel}] -command [list $this clicked cancel] -compound left -image img_cancel
	pack $_root.btn.export $_root.btn.cancel -side left -padx 1
	pack $_root.btn -side top -pady 2
}

body ExportDialog::destructor {} {
	if {$_handler != ""} {
		catch {delete object $_handler}
	}

	if {$_queryExecutor != ""} {
		delete object $_queryExecutor
		set _queryExecutor ""
	}
}

body ExportDialog::grabWidget {} {
	if {!$_useFile} {
		return $_root.format.formatlist
	} else {
		return $_root.file.e
	}
}

body ExportDialog::okClicked {} {
	set _interrupted 0
	set closeWhenOkClicked 0
	
	set file [$_outFile get]
	if {$_useFile} {
		if {$file == ""} {
			Error [mc {You have to choose file.}]
			return
		}

		if {[file pathtype $file] == "relative"} {
			set file [file join $::startingDir $file]
		}

		if {[file exists $file] && ![file writable $file]} {
			Error [mc {Can't write to file: %s} $file]
			return
		}
	}

	set db ""
	if {$_showDB} {
		set db [DBTREE getDBByName [$_root.db.list.e get]]
		if {$db == ""} {
			Error [mc {You have to choose database.}]
			return
		}
	} else {
		set db $_db
	}
	if {$_showTable} {
		set tab [$_root.table.e get]
		if {$tab == ""} {
			Error [mc {You have to choose table.}]
			return
		}
	} elseif {$_query == "" && !$_showDB} {
		error "No table or query to export."
	}

	set context [getContext]
	if {[catch {$_handler validateConfig $context} err]} {
		cutOffStdTclErr err
		Error $err
		return
	}

	set enc [$_handler getEncoding]

	switch -- $_type {
		"database" {
			set progressLabel [mc {Exporting database '%s'.} [$db getName]]
		}
		"table" {
			set progressLabel [mc {Exporting table '%s'.} $tab]
		}
		"view" {
			set progressLabel [mc {Exporting view '%s'.} $tab]
		}
		"results" {
			set progressLabel [mc {Exporting results.} [$db getName]]
		}
		default {
			error "Unknown export type: $_type"
		}
	}

	set progress [BusyDialog::show [mc {Exporting...}] $progressLabel true 50 false]
	BusyDialog::autoProgress 20
	$progress configure -onclose [list $this cancelExecution]
	$progress setCloseButtonLabel [mc {Cancel}]

	if {$_useFile} {
		if {[$_handler manageFile]} {
			if {![$_handler setFile $file]} {
				BusyDialog::hide
				return
			}
		} else {
			# Auto extension
			if {[file extension $file] == "" && [$_handler autoFileExtension] != ""} {
				append file [$_handler autoFileExtension]
			}

			# Writing to file
			if {[catch {open $file w+} fd]} {
				Error [mc "Cannot write to file: %s\nPlease select other file." $file]
				if {[info exists fd]} {
					catch {close $fd}
				}
				BusyDialog::hide
				return
			}
			if {$enc != "" && ($enc in [encoding names] || $enc == "binary")} {
				fconfigure $fd -encoding $enc
			}
			$_handler setFileDescriptor $fd
		}
	}

	if {![$_handler beforeStart]} {
		BusyDialog::hide
		return
	}

	switch -- $_type {
		"database" {
			set results [exportDatabase $db]
		}
		"table" {
			set results [exportTableOnly $db $tab false]
		}
		"results" {
			set results [exportResults $db $_query]
		}
		default {
			error "Unknown export type: $_type"
		}
	}

	$_handler finished

	update idletasks
	# If something went wrong, or exporting was interrupted - break this method
	if {$_interrupted || [dict get $results rescode]} {
		BusyDialog::hide
		set closeWhenOkClicked 0
		return
	}

	if {![$_handler manageFile] && $_useFile} {
		catch {close $fd}
	}
	update idletasks

	# After successfly export, call afterExport
	$_handler afterExport $file

	BusyDialog::hide
}

body ExportDialog::browseOutputFile {} {
	set dir $::startingDir
	set dir [getPathForFileDialog $dir]

	if {$_query != ""} {
		set dir [file dirname [$_db getPath]]
	} elseif {$_showDB} {
		set db [DBTREE getDBByName [$_root.db.list.e get]]
		if {$db != ""} {
			set dir [file dirname [$db getPath]]
		}
	}

	set file [GetSaveFile -title [mc {Output file}] -initialdir $dir -parent [winfo toplevel $_root]]
	if {[winfo exists $path]} {
		raise $path
		focus $_root.file.e
		if {$file == ""} return
		$_outFile delete 0 end
		$_outFile insert end $file
		$_outFile icursor end
		$_outFile selection range 0 end
		$_outFile xview [$_outFile index end]
	}
}

body ExportDialog::databasePicked {} {
	if {$_queryExecutor != ""} {
		delete object $_queryExecutor
		set _queryExecutor ""
	}
	$_root.table.e set ""
	set _db [DBTREE getDBByName [$_root.db.list.e get]]
	if {$_db != ""} {
		$_root.table.e configure -values [concat [$_db getTables] [$_db getViews]]
		set _queryExecutor [QueryExecutor ::#auto $_db]
	}
}

body ExportDialog::updateConfigButton {} {
	set chosen [$_root.format.formatlist get]
	if {$chosen == ""} {
		$_root.format.config configure -state disabled
		return
	}
	set hnd $_exportHandlers($chosen)

	if {[${hnd}::configurable [getContext]]} {
		$_root.format.config configure -state normal
	} else {
		$_root.format.config configure -state disabled
	}

	if {[catch {${hnd}::useFile} useFile]} {
		set useFile [ExportPlugin::useFile]
	}

	if {$useFile} {
		setFileWidgets normal
	} else {
		setFileWidgets disabled
	}
}

body ExportDialog::setFileWidgets {state} {
	foreach w $_outFileWidgets {
		$w configure -state $state
	}
	if {$state == "disabled"} {
		set _useFile 0
	} else {
		set _useFile 1
	}
}

body ExportDialog::handlerSelected {} {
	catch {delete object $_handler}
	set chosen [$_root.format.formatlist get]
	if {$chosen == ""} {
		updateConfigButton
		return
	}
	set _handler [$_exportHandlers($chosen) ::#auto]
	$_handler setContext [getContext]
	updateConfigButton
}

body ExportDialog::configHandler {} {
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

	# Initial geometry
	set size [$_handler configSize]
	if {[llength $size] == 2} {
		lassign $size cfgWidth cfgHeight
		wm geometry $t ${cfgWidth}x$cfgHeight
		update idletasks
	}

	# Plugin interface
	set context [getContext]
	$_handler createConfigUI $t.root.top $context

	# Auto geometry
	if {[llength $size] != 2} {
		update idletasks
		set cfgWidth [winfo reqwidth $t]
		set cfgHeight [winfo reqheight $t]
	}

	# Positioning and setting up
	set w $_root.format.config
	set width [winfo width $w]
	set x [expr {[winfo rootx $w] + $width + 1}]
	set y [expr {[winfo rooty $w] - $cfgHeight / 2}]

	wm geometry $t +$x+$y
	update idletasks

	wm deiconify $t
	wm transient $t $_root
	grab $t
	focus $t
	raise $t
}

body ExportDialog::configOk {} {
	set t $_configWindow
	$_handler applyConfig $t.root.top [getContext]
	destroy $t

	focus $path
	bind $path <Return> [list $this clicked ok]
	bind $path <Escape> [list $this clicked cancel]
}

body ExportDialog::configCancel {} {
	set t $_configWindow
	destroy $t

	focus $path
	bind $path <Return> [list $this clicked ok]
	bind $path <Escape> [list $this clicked cancel]
}

body ExportDialog::getContext {} {
	switch -- $_type {
		"database" {
			return "DATABASE"
		}
		"table" {
			return "TABLE"
		}
		"results" {
			return "QUERY"
		}
		deault {
			error "Unsupported export dialog type: $_type"
		}
	}
}

body ExportDialog::getSchemaSteps {schema} {
	set markers [list %BEGIN% %TABLES% %INDEXES% %TRIGGERS% %VIEWS% %END% %DATABASE_NAME% \
		%TABLE% %TABLE_NAME% %RESULT% %QUERY%]
	set schemaSteps [list]
	set lastIdx 0
	foreach marker $markers {
		set idx [string first $marker $schema]
		if {$idx == -1} continue
		lappend schemaSteps [list $marker $idx]
	}
	return [lsort -dictionary -index 1 $schemaSteps]
}

body ExportDialog::exportDatabase {db} {
	set results [dict create rescode 0]

	set sql [string trim {
		SELECT * FROM SQLITE_MASTER WHERE TYPE ='table' UNION ALL
		SELECT * FROM SQLITE_MASTER WHERE TYPE ='index' UNION ALL
		SELECT * FROM SQLITE_MASTER WHERE TYPE ='trigger' UNION ALL
		SELECT * FROM SQLITE_MASTER WHERE TYPE ='view'
	}] ;# thanks to unions we have required order

	$_handler setDb $db

	set tablesToExport [list]
	set indexesToExport [list]
	set viewsToExport [list]
	set trigsToExport [list]
	set mode [$db mode]
	$db short
	$db eval $sql row {
		if {[string match "sqlite_*" $row(name)]} continue
		if {$_interrupted} {
			$db $mode
			dict set results rescode 2
			return $results
		}

		switch -- $row(type) {
			"table" {
				lappend tablesToExport $row(name)
			}
			"index" {
				lappend indexesToExport [list $row(name) $row(sql)]
			}
			"trigger" {
				lappend trigsToExport [list $row(name) $row(sql)]
			}
			"view" {
				lappend viewsToExport [list $row(name) $row(sql)]
			}
		}
	}
	$db $mode

	update idletasks
	if {$_interrupted} {
		dict set results rescode 2
		return $results
	}

	# Sorting tables against their Foreign Key dependencies
	set tablesToExport [sortTablesByFk $db $tablesToExport]

	# Sorting views against their cross dependencies
	set viewsToExport [sortViewsByCrossUsage $db $viewsToExport]

	update idletasks
	if {$_interrupted} {
		dict set results rescode 2
		return $results
	}

	set schema [$_handler exportFileSchema [getContext]]
	set schemaSteps [getSchemaSteps $schema]

	set lastIdx 0
	set idx 0
	foreach step $schemaSteps {
		lassign $step marker idx

		if {$idx > 0} {
			$_handler write [string range $schema $lastIdx [expr {$idx - 1}]]
		}
		set lastIdx [expr {$idx + [string length $marker]}]

		switch -- $marker {
			"%BEGIN%" {
				if {[catch {
					$_handler databaseExportBegin [$db getName] [[$db getHandler]::getHandlerLabel] [$db getPath]
				} err]} {
					dict set results rescode 1
					cutOffStdTclErr err
					Error $err
					return $results
				}
			}
			"%TABLES%" {
				# Exporting tables after they're sorted
				foreach table $tablesToExport {
					if {$_interrupted} {
						dict set results rescode 2
						return $results
					}
					set res [exportTable $db $table $checkState(dbonly)]
					if {[dict get $res rescode]} {
						dict set results rescode 1
					}
				}
			}
			"%INDEXES%" {
				foreach index $indexesToExport {
					lassign $index name sql
					set res [exportIndex $db $name $sql]
					if {[dict get $res rescode]} {
						dict set results rescode 1
					}
				}
			}
			"%TRIGGERS%" {
				foreach trig $trigsToExport {
					lassign $trig name sql
					set res [exportTrigger $db $name $sql]
					if {[dict get $res rescode]} {
						dict set results rescode 1
					}
				}
			}
			"%VIEWS%" {
				foreach view $viewsToExport {
					lassign $view name sql
					set res [exportView $db $name $sql]
					if {[dict get $res rescode]} {
						dict set results rescode 1
					}
				}
			}
			"%END%" {
				if {[catch {
					$_handler databaseExportEnd
				} err]} {
					dict set results rescode 1
					cutOffStdTclErr err
					Error $err
					return $results
				}
			}
			"%DATABASE_NAME%" {
				$_handler write [$db getName]
			}
		}

		if {$_interrupted} {
			dict set results rescode 2
			return $results
		}
	}

	if {$idx > 0} {
		$_handler write [string range $schema $lastIdx end]
	}


	if {[dict get $results rescode] == 1} {
		set closeWhenOkClicked 0
	}
	return $results
}

body ExportDialog::exportTableOnly {db table structureOnly} {
	set results [dict create rescode 1]

	if {$_interrupted} {
		dict set results rescode 2
		return $results
	}

	set schema [$_handler exportFileSchema [getContext]]
	set schemaSteps [getSchemaSteps $schema]

	set lastIdx 0
	set idx 0
	foreach step $schemaSteps {
		lassign $step marker idx

		if {$_interrupted} {
			dict set results rescode 2
			return $results
		}

		if {$idx > 0} {
			$_handler write [string range $schema $lastIdx [expr {$idx - 1}]]
		}
		set lastIdx [expr {$idx + [string length $marker]}]

		switch -- $marker {
			"%TABLE%" {
				# Exporting tables after they're sorted
				set res [exportTable $db $table $structureOnly]
				if {[dict get $res rescode]} {
					dict set results rescode 1
					return $results
				}
			}
			"%TABLE_NAME%" {
				$_handler write $table
			}
		}
	}

	if {$idx > 0} {
		$_handler write [string range $schema $lastIdx end]
	}

	dict set results rescode 0
	set closeWhenOkClicked 1
	update ;# for BusyDialog

	if {$_interrupted} {
		dict set results rescode 2
		return $results
	}
	return $results
}

body ExportDialog::exportTable {db table structureOnly} {
	set results [dict create rescode 0]

	if {$_interrupted} {
		dict set results rescode 2
		return $results
	}

	if {![ModelExtractor::isSupportedSystemTable $table] && ![ModelExtractor::hasDdl $db $table]} {
		dict set results rescode 0
		return $results
	}

	set dialect [$db getDialect]
	set tableInfo [$db getTableInfo $table]

	if {[$_handler provideColumnWidths]} {
		set colsForLength [list]
		foreach row $tableInfo {
			lappend colsForLength "max(length([wrapObjName [dict get $row name] $dialect]))"
		}
		set colWidths [$_queryExecutor directExec "SELECT [join $colsForLength ,] FROM $table" true]
	} else {
		foreach row $tableInfo {
			lappend colWidths 0
		}
	}

	if {[$_handler provideTotalRows]} {
		set totalRows [$_queryExecutor directExec "SELECT count(*) FROM $table" true]
	} else {
		set totalRows 0
	}

	if {$_interrupted} {
		dict set results rescode 2
		return $results
	}

	set cols [list]
	foreach row $tableInfo colWidth $colWidths {
		set dflt [dict get $row dflt_value]

		if {[$db isNull $colWidth]} {
			set colWidth 0
		}

		lappend cols [list \
			[dict get $row name] \
			[dict get $row type] \
			[dict get $row pk] \
			[dict get $row notnull] \
			[expr {[$db isNull $dflt] ? [list "" true] : [list $dflt false]}] \
			$colWidth \
		]
	}
	update ;# for BusyDialog

	$_handler setDb $db
	set ddl [$db getSqliteObjectDdl "table" $table]
	if {[catch {
		$_handler exportTable $table $cols $ddl $totalRows
	} err]} {
		cutOffStdTclErr err
		Error $err
		return $results
	}

	if {!$structureOnly} {
		catch {unset row}
		set i 0
		$db eval "SELECT * FROM [wrapObjName $table [$db getDialect]]" row {
			set data [list]
			foreach colName $row(*) {
				lappend data [list $row($colName) [$db isNull $row($colName)]]
			}

			if {[catch {
				$_handler exportTableRow $data $cols
			} err]} {
				cutOffStdTclErr err
				Error $err
				return $results
			}

			if {$i%100 == 0} {
				update ;# for BusyDialog
				if {$_interrupted} {
					dict set results rescode 2
					return $results
				}
			}
			incr i
		}
	}

	if {[catch {
		$_handler exportTableEnd $table
	} err]} {
		cutOffStdTclErr err
		Error $err
		return $results
	}

	if {$_interrupted} {
		dict set results rescode 2
		return $results
	}
	return $results
}

body ExportDialog::exportIndex {db name sql} {
	set results [dict create rescode 1]
	set cols [list]
	if {$_interrupted} {
		dict set results rescode 2
		return $results
	}

	set re {(?i)CREATE\s+(UNIQUE\s+)*INDEX\s+(IF\s+NOT\s+EXISTS\s+)*}
	append re $::RE(table_or_column)
	append re {\s+ON\s+}
	append re $::RE(table_or_column)
	append re {\s+\((.*)\)}

	set name [stripColName [lindex [regexp -inline -- $re $sql] 3]]
	set table [stripColName [lindex [regexp -inline -- $re $sql] 4]]
	set uniq [regexp -- {(?i).*\s+UNIQUE\s+.*} $sql]
	set colsSql [lindex [regexp -inline -- $re $sql] 5]

	set fullCols [SqlUtils::splitSqlArgs $colsSql]
	set re {(?i)}
	append re $::RE(table_or_column)
	foreach col $fullCols {
		set colOnly [lindex [regexp -inline -- $re $col] 1]
		set colOnly [stripColName $colOnly]

		set re {(?i)\s+COLLATE\s+}
		append re $::RE(table_or_column)
		if {[regexp -- $re $col]} {
			set collation [lindex [regexp -inline -- $re $col] 1]
		} else {
			set collation ""
		}

		set re {(?i)\s+(ASC|DESC)}
		if {[regexp -- $re $col]} {
			set sorting [lindex [regexp -inline -- $re $col] 1]
		} else {
			set sorting ""
		}

		lappend cols [list $colOnly $collation $sorting]
	}

	# Formatting SQL code
	set sql [Formatter::format $sql $db]

	$_handler setDb $db
	if {[catch {
		$_handler exportIndex $name $table $cols $uniq $sql
	} err]} {
		cutOffStdTclErr err
		Error $err
		return $results
	}

	dict set results rescode 0
	set closeWhenOkClicked 1
	update ;# for BusyDialog
	return $results
}

body ExportDialog::exportTrigger {db name sql} {
	set results [dict create rescode 1]
	if {$_interrupted} {
		dict set results rescode 2
		return $results
	}

	set re $::RE(trigger)

	set words [regexp -inline -- $re $sql]
	set trigName [stripColName [lindex $words 2]]
	set when [lindex $words 3]
	set act [lindex $words 4]
	set tableTmp [lindex $words 7]
	set table [stripColName [getObjectFromPath $tableTmp]]

	set condition [string trim [lindex [regexp -inline -- {(?i)\s+WHEN\s+(.*)\s+BEGIN} $sql] 1]]
	set code [string trim [lindex [regexp -inline -- {(?i)\s+BEGIN\s+(.*)\s*END} $sql] 1]]

	# Formatting SQL code
	set code [Formatter::format $code $db]

	$_handler setDb $db
	if {[catch {
		$_handler exportTrigger $trigName $table $when $act $condition $code $sql
	} err]} {
		cutOffStdTclErr err
		Error $err
		return $results
	}

	dict set results rescode 0
	set closeWhenOkClicked 1
	update ;# for BusyDialog
	return $results
}

body ExportDialog::exportView {db name sql} {
	set results [dict create rescode 1]
	if {$_interrupted} {
		dict set results rescode 2
		return $results
	}

	set re {(?i)CREATE\s+VIEW\s+(IF\s+NOT\s+EXISTS\s+)?}
	append re $::RE(table_or_column)
	append re {\s+AS\s+(.*)}
	set res [regexp -inline -- $re $sql]
	set view [stripColName [lindex $res 2]]
	set code [lindex $res 3]

	# Formatting SQL code
	set code [Formatter::format $code $db]

	$_handler setDb $db
	if {[catch {
		$_handler exportView $view $code $sql
	} err]} {
		cutOffStdTclErr err
		Error $err
		return $results
	}

	dict set results rescode 0
	set closeWhenOkClicked 1
	update ;# for BusyDialog
	return $results
}

body ExportDialog::exportResults {db query} {
	set results [dict create rescode 1]

	if {$_interrupted} {
		dict set results rescode 2
		return $results
	}

	set schema [$_handler exportFileSchema [getContext]]
	set schemaSteps [getSchemaSteps $schema]

	set lastIdx 0
	set idx 0
	foreach step $schemaSteps {
		lassign $step marker idx

		if {$_interrupted} {
			dict set results rescode 2
			return $results
		}

		if {$idx > 0} {
			$_handler write [string range $schema $lastIdx [expr {$idx - 1}]]
		}
		set lastIdx [expr {$idx + [string length $marker]}]

		switch -- $marker {
			"%RESULT%" {
				# Exporting tables after they're sorted
				set res [exportResultsData $db $query]
				if {[dict get $res rescode]} {
					dict set results rescode 1
					return $results
				}
			}
			"%QUERY%" {
				$_handler write [Formatter::format $query $db]
			}
		}
	}

	if {$idx > 0} {
		$_handler write [string range $schema $lastIdx end]
	}

	dict set results rescode 0
	set closeWhenOkClicked 1
	update ;# for BusyDialog

	if {$_interrupted} {
		dict set results rescode 2
		return $results
	}
	return $results
}

body ExportDialog::exportResultsData {db query} {
	set results [dict create rescode 1 data ""]

	$_handler setDb $db
	set dialect [$db getDialect]

	if {$_queryExecutor == ""} {
		set _queryExecutor [QueryExecutor ::#auto $db]
	}
	# Since we use single thread this seems to be not required:
	#$_queryExecutor configure -limitedData true ;# truncate huge data volumes in single cells to reasonable length

	set colsForLength [list]
	set colsWithTypes [list]
	set cols [list]
	$_queryExecutor configure -resultsLimit 1
	$_queryExecutor exec $query row {
		foreach cell $row {
			set colDict [dict create database "" table "" column "" displayName "" type "" maxDataWidth 0]
			foreach key [list database table column displayName type] {
				if {[dict exists $cell $key]} {
					dict set colDict $key [dict get $cell $key]
				}
			}
			lappend colsWithTypes $colDict
			lappend colsForLength "max(length([wrapObjName [dict get $cell displayName] $dialect]))"
		}
	}
	$_queryExecutor configure -resultsLimit -1
	
	set subQuery [string trimright [string trim $query] ";"]
	if {[$_handler provideColumnWidths]} {
		set colWidths [$_queryExecutor directExec "SELECT [join $colsForLength ,] FROM ($subQuery)" true]
	} else {
		foreach c $colsForLength {
			lappend colWidths 0
		}
	}
	if {[$_handler provideTotalRows]} {
		set totalRows [$_queryExecutor directExec "SELECT count(*) FROM ($subQuery)" true]
	} else {
		set totalRows 0
	}

	foreach colWithType $colsWithTypes colWidth $colWidths {
		dict set colWithType maxDataWidth [expr {[$db isNull $colWidth] ? 0 : $colWidth}]
		lappend cols $colWithType
	}

	if {[catch {
		$_handler exportResults $cols $totalRows
	} err]} {
		cutOffStdTclErr err
		Error $err
		return $results
	}

	# Free any memory for data query
	unset colsWithTypes
	unset colWidths
	unset subQuery
	unset colsForLength

	set i 0
	$_queryExecutor exec $query row {
		set data [list]
		foreach cell $row {
			set value [dict get $cell value]
			lappend data [list $value [$db isNull $value]]
		}
		if {[catch {
			$_handler exportResultsRow $data $cols
		} err]} {
			cutOffStdTclErr err
			Error $err
			return $results
		}

		if {$i%100 == 0} {
			update ;# for BusyDialog
			if {$_interrupted} {
				dict set results rescode 2
				return $results
			}
		}
		incr i
	}

	if {[catch {
		$_handler exportResultsEnd
	} err]} {
		cutOffStdTclErr err
		Error $err
		return $results
	}

	dict set results rescode 0
	set closeWhenOkClicked 1
	update ;# for BusyDialog
	return $results
}

body ExportDialog::sortTablesByFk {db tablesToExport} {
	set dialect [$db getDialect]
	if {$dialect == "sqlite2"} {
		# sqlite2 doesen't support FK
		return $tablesToExport
	}

	# Extrating ddl for all tables
	array set tableDdl {}
	set lowerTables [list]
	foreach table $tablesToExport {
		set lower [string tolower $table]
		lappend lowerTables $lower
		set tableDdl($lower) [$db onecolumn {SELECT sql FROM sqlite_master WHERE lower(name) = $lower}]
	}

	# Removing virtual tables from list
	set vtables [list]
	foreach lower $lowerTables {
		if {[regexp -- {(?i)^\s*CREATE\s+VIRTUAL.*} $tableDdl($lower)]} {
			lappend vtables $lower
		}
	}

	update ;# for BusyDialog

	# Extracting FK for tables
	array set fk {}
	set parser [UniversalParser ::#auto $db]
	$parser configure -sameThread false -expectedTokenParsing false

	foreach lower $lowerTables {
		set fk($lower) [list]
		if {$lower in $vtables} continue

		$parser parseSql $tableDdl($lower)
		set results [$parser get]

		# Error handling
		if {[dict get $results returnCode]} {
			debug "Table parsing error message: [dict get $results errorMessage]"
			delete object $parser
			error [format "Cannot parse table DDL.\nSQLite version is %s.\nThe DDL is:\n%s\n\nError stack:" [$db onecolumn {SELECT sqlite_version()}] $tableDdl($lower)]
		}

		# Table global FK
		set tableStmt [[dict get $results object] getValue subStatement]
		set tableFks [$tableStmt getFks]
		foreach tableFk $tableFks {
			set fkStmt [$tableFk getValue foreignKey]
			set fkTable [$fkStmt getValue tableName]
			lappend fk($lower) $fkTable
		}

		# Individual column FKs
		foreach colDef [$tableStmt getListValue columnDefs] {
			set colFkConstr [$colDef getFk]
			if {$colFkConstr != ""} {
				set colFk [$colFkConstr getValue foreignKey]
				set fkTable [$colFk getValue tableName]
				lappend fk($lower) $fkTable
			}
		}

		$parser freeObjects
	}

	delete object $parser

	update ;# for BusyDialog

	# Sorting
	set wasSwitch 1
	set iterations 0
	while {$wasSwitch} {
		# The 'while' will repeat sorting until no changes are made in list
		set wasSwitch 0
		foreach lower $lowerTables {
			if {[llength $fk($lower)] == 0} continue
			foreach fkTable $fk($lower) {
				set fkIdx [lsearch -exact -nocase $tablesToExport $fkTable]
				set localIdx [lsearch -exact -nocase $tablesToExport $lower]
				if {$fkIdx == -1 || $localIdx == -1} {
					debug "fkIdx == $fkIdx || localIdx == $localIdx <-- during sorting table for export"
					continue
				}

				if {$fkIdx > $localIdx} {
					set tablesToExport [lreplace $tablesToExport $fkIdx $fkIdx]
					set tablesToExport [linsert $tablesToExport 0 $fkTable]
					set wasSwitch 1
				}
			}
		}
		incr iterations

		if {$iterations > 1000} {
			debug "Sorting tables to export exceeds 1000 iterations. Leaving sorting."
			break
		}
	}

	update ;# for BusyDialog

	return $tablesToExport
}

body ExportDialog::sortViewsByCrossUsage {db viewsToExport} {
	# Extrating ddl for all views
	array set viewDdl {}
	set lowerViews [list]
	foreach view $viewsToExport {
		set lower [string tolower [lindex $view 0]]
		lappend lowerViews $lower
		set viewDdl($lower) [lindex $view 1]
	}

	update ;# for BusyDialog

	# Extracting FK for tables
	array set refs {}
	set parser [UniversalParser ::#auto $db]
	$parser configure -sameThread false -expectedTokenParsing false

	foreach lower $lowerViews {
		set refs($lower) [list]

		$parser parseSql $viewDdl($lower)
		set results [$parser get]

		# Error handling
		if {[dict get $results returnCode]} {
			debug "Table parsing error message: [dict get $results errorMessage]"
			delete object $parser
			error [format "Cannot parse view DDL.\nSQLite version is %s.\nThe DDL is:\n%s\n\nError stack:" [$db onecolumn {SELECT sqlite_version()}] $viewDdl($lower)]
		}

		# Select tables
		set obj [dict get $results object]
		set dataSources [$obj getContextInfo "TABLE_NAMES"]
		foreach dataSourceDict $dataSources {
			set dataSource [dict get $dataSourceDict table]
			set lowerDs [string tolower $dataSource]
			if {$lowerDs in $lowerViews} {
				lappend refs($lower) $dataSource
			}
		}

		$parser freeObjects
	}

	delete object $parser

	update ;# for BusyDialog

	# Sorting
	set wasSwitch 1
	set iterations 0
	while {$wasSwitch} {
		# The 'while' will repeat sorting until no changes are made in list
		set wasSwitch 0
		foreach lower $lowerViews {
			if {[llength $refs($lower)] == 0} continue
			foreach ref $refs($lower) {
				set refIdx [lsearch -index 0 -exact -nocase $viewsToExport $ref]
				set localIdx [lsearch -index 0 -exact -nocase $viewsToExport $lower]
				if {$refIdx == -1 || $localIdx == -1} {
					debug "refIdx == $refIdx || localIdx == $localIdx <-- during sorting view for export"
					continue
				}

				if {$refIdx > $localIdx} {
					set toMove [lindex $viewsToExport $refIdx]
					set viewsToExport [lreplace $viewsToExport $refIdx $refIdx]
					set viewsToExport [linsert $viewsToExport 0 $toMove]
					set wasSwitch 1
				}
			}
		}
		incr iterations

		if {$iterations > 1000} {
			debug "Sorting views to export exceeds 1000 iterations. Leaving sorting."
			break
		}
	}

	update ;# for BusyDialog

	return $viewsToExport
}

body ExportDialog::cancelExecution {} {
	set _interrupted 1
	if {$_queryExecutor != ""} {
		$_queryExecutor interrupt
# 		delete object $_queryExecutor
# 		set _queryExecutor ""
	}
}
