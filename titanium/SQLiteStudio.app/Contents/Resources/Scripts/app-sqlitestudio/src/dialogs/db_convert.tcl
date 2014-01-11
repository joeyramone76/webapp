use src/common/modal.tcl

class DbConvertDialog {
	inherit Modal

	constructor {args} {
		Modal::constructor {*}$args
	} {}

	private {
		variable _db ""

		method convertDb {srcDb dstDbHnd dstName dstDbFile}
	}

	public {
		variable uiVar

		method okClicked {}
		method grabWidget {}
		method chooseDBFile {}
		method updateFile {}
		method notifyNameChange {varName arrIdx op}
	}
}

body DbConvertDialog::constructor {args} {
	parseArgs {
		-db {set _db $value}
	}

	set dblist [list]
	foreach db [DBTREE dblist] {
		lappend dblist [$db getName]
	}

	# Source database
	set f [ttk::frame $_root.db]
	pack $f -side top -fill both
	ttk::label $f.l -text [mc {Database to convert:}] -justify left
	pack $f.l -side top -fill x -pady 2 -padx 0.2c
	ttk::combobox $f.e -values $dblist -state readonly
	pack $f.e -side top -fill x -pady 0.1c -padx 0.2c

	# New database name
	set f [ttk::frame $_root.newname]
	pack $f -side top -fill both
	ttk::label $f.l -text [mc {Converted database name:}] -justify left
	pack $f.l -side top -fill x -pady 2 -padx 0.2c
	ttk::entry $f.e -textvariable [scope uiVar](name)
	pack $f.e -side top -fill x -pady 0.1c -padx 0.2c

	# New database file
	set f [ttk::frame $_root.file]
	pack $f -side top -fill both
	ttk::label $f.l -text [mc {File to use for converted database:}] -justify left
	pack $f.l -side top -fill x -pady 2 -padx 0.2c
	ttk::frame $f.f
	pack $f.f -side top -fill x -pady 0.1c -padx 0.2c

	ttk::entry $f.f.e -width 40 -textvariable [scope uiVar](file)
	pack $f.f.e -side left -fill x
	ttk::button $f.f.bn -image img_new_db -command "$this chooseDBFile"
	pack $f.f.bn -side right -fill none -padx 2
	helpHint $f.f.bn [mc {Choose new file for database}]

	# New database version
	set f [ttk::frame $_root.ver]
	pack $f -side top -fill both
	ttk::label $f.l -text [mc {Database version:}] -justify left
	pack $f.l -side left -fill x -pady 0.2c -padx 0.2c
	ttk::frame $f.f
	pack $f.f -side right -fill x -pady 0.2c -padx 0.2c

	set dbHndLabels [list]
	foreach supDb $::DB_HANDLERS {
		lappend dbHndLabels [${supDb}::getHandlerLabel]
	}

	ttk::combobox $_root.ver.f.e -width 16 -values [lsort -dictionary $dbHndLabels] -state readonly
	pack $_root.ver.f.e -side left -fill x

	trace add variable [scope uiVar] write [list $this notifyNameChange]

	# Bottom
	ttk::frame $_root.d
	pack $_root.d -side bottom -fill x
	ttk::frame $_root.d.f
	pack $_root.d.f -side bottom -fill x

	ttk::button $_root.d.f.ok -text [mc {Convert}] -command "$this clicked ok" -compound left -image img_ok
	pack $_root.d.f.ok -side left -pady 3 -padx 5
	ttk::button $_root.d.f.cancel -text [mc {Cancel}] -command "$this clicked cancel" -compound left -image img_cancel
	pack $_root.d.f.cancel -side right -pady 3 -padx 5

	if {$_db != ""} {
		$_root.db.e set [$_db getName]
		set uiVar(name) "[$_db getName]-new"
		$_root.newname.e icursor end
		$_root.db.e configure -state disabled

		lremove dbHndLabels [[$_db info class]::getHandlerLabel]
		set sorted [lsort -dictionary $dbHndLabels]
		$_root.ver.f.e configure -values $sorted
		$_root.ver.f.e set [lindex $sorted 0]
	}
	setTitle [mc {Convert database}]
}

body DbConvertDialog::updateFile {} {
	set dir [file dirname [$_db getPath]]
	if {[string match "*.*" $uiVar(name)]} {
		set file $uiVar(name)
	} else {
		set file $uiVar(name).db
	}
	set uiVar(file) [file join $dir $file]
}

body DbConvertDialog::notifyNameChange {varName arrIdx op} {
	if {$arrIdx == "name"} {
		updateFile
	}
}

body DbConvertDialog::okClicked {} {
	set closeWhenOkClicked 0
	set name [$_root.newname.e get]
	set dbfile [$_root.file.f.e get]
	set srcDbName [$_root.db.e get]
	set srcDb [DBTREE getDBByName $srcDbName]
	if {$srcDbName == ""} {
		Error [mc {You chave to choose database to convert.}]
		return
	}
	if {$srcDb == ""} {
		Error [mc {Error resolving database with name %s!} $srcDbName]
		return
	}
	if {$dbfile == ""} {
		Error [mc {You have to specify new database file.}]
		return
	}
	if {[file exists $dbfile]} {
		Error [mc {Cannot use existing file for converted database.}]
		return
	}
	if {[DBTREE getDBByName $name] != ""} {
		Error [mc {Cannot use existing name for converted database.}]
		return
	}

	set dbLabel [$_root.ver.f.e get]
	set dbHnd ""
	foreach supDb $::DB_HANDLERS {
		if {[${supDb}::getHandlerLabel] == $dbLabel} {
			set dbHnd $supDb
			break
		}
	}
	if {$dbHnd == ""} {
		set res [mc {Cannot find handler for database labeled with: %s} $dbLabel]
		Error [mc {Error while trying to create database: %s} $res]
		return
	}

	if {![$_db isOpen]} {
		$_db open
	}
	set results [convertDb $srcDb $dbHnd $name $dbfile]
	set returnCode [dict get $results returnCode]
	if {$returnCode != 2} {
		set closeWhenOkClicked 1
		DBTREE refreshSchema
	}
	if {$returnCode != 0} {
		set errs [dict get $results errors]
		if {[llength $errs] > 0} {
			set errors "- "
			append errors [join [lsort -unique $errs] "\n- "]
			if {[llength $errs] > 5} {
				set msg [mc "Some problems occured while converting database, but it was converted omitting objects causing problems. Details:\n%s" $errors]
				if {$returnCode != 2} {
					append msg \n\n
					append msg [mc {Nevertheless, the converted database may still be usable.}]
				}
				TextBrowseDialog .convertingErrors -title [mc {Database converting error}]
				.convertingErrors setText $msg
				after idle [list .convertingErrors exec]
			} else {
				set type warning
				set msgs [list]
				lappend msgs [list [mc "Some problems occured while converting database, but it was converted omitting objects causing problems. Details:\n%s" $errors] txt]
				if {$returnCode != 2} {
					set type info
					lappend msgs [list [mc {Nevertheless, the converted database may still be usable.}] txt]
				}
				after idle [list MsgDialog::showMulti [mc {Database converting problems}] $msgs]
			}
		}
	}
}

body DbConvertDialog::convertDb {srcDb dstDbHnd dstName dstDbFile} {
	set progress [BusyDialog::show [mc {Converting database}] [mc {Converting database %s to %s (%s format).} [$srcDb getName] $dstName [${dstDbHnd}::getHandlerLabel]] false 50 false]
	BusyDialog::autoProgress 20

	set thread [thread::create]
	thread::send $thread [list set ::DEBUG(global) $::DEBUG(global)]
	thread::send $thread [list set ::DEBUG(re) $::DEBUG(re)]
	thread::send $thread [list source $::applicationDir/src/common/debug.tcl]
	thread::send $thread [list source $::applicationDir/src/common/common.tcl]
	thread::send $thread [list source $::applicationDir/src/common/common_sql.tcl]
	thread::send $thread [list source $::applicationDir/src/db/convert_db.tcl]
	thread::send $thread [list set srcDbFile [$srcDb getPath]]
	thread::send $thread [list set dstDbFile $dstDbFile]
	thread::send $thread [list set toVersion [${dstDbHnd}::getHandlerDbVersion]]
	thread::send $thread [list set unsupported [${dstDbHnd}::getUnsupportedFeatures]]

	thread::send -async $thread {convertDb $srcDbFile $dstDbFile $toVersion $unsupported} ::threadExecutionResults($thread)
	vwait ::threadExecutionResults($thread)
	catch {thread::release $thread}

	BusyDialog::hide
	set results $::threadExecutionResults($thread)
	if {[catch {
		set newDb [DBTREE addDB $dstName $dstDbFile]
	}]} {
		debug $::errorInfo
		dict lappend results errors [mc {Could not register converted database in SQLiteStudio.}]
		dict set results returnCode 2
	}
	return $results
}

body DbConvertDialog::grabWidget {} {
	return $_root.newname.e
}

body DbConvertDialog::chooseDBFile {} {
	set dir $::startingDir
	set dir [getPathForFileDialog $dir]
	if {[os] == "macosx"} {
		set f [GetSaveFile -title [mc {Choose file}] -initialdir $dir]
	} else {
		set f [GetSaveFile -title [mc {Choose file}] -initialdir $dir -filetypes $::DB_FILE_TYPES -parent [winfo toplevel $_root]]
	}

	if {[os] == "win32" && [string match "*.lnk" $f]} {
		set f [readlnk $f]
	}
	if {$f == ""} return
	$_root.file.f.e delete 0 end
	$_root.file.f.e insert end $f
}
