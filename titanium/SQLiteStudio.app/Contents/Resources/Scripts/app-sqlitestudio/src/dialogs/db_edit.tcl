use src/common/modal.tcl

# NOTE:
# There is very ugly hack in this class.
# There is no way to use getAppendFile procedure for Windows
# and Macintosh, so there are 2 separate buttons for
# getOpenFile and getSaveFile.
class DBEditDialog {
	inherit Modal

	opt db
	opt mode "edit"

	constructor {args} {
		eval Modal::constructor $args
	} {}

	private {
		variable _db ""
		variable _mode ""
		variable _preselectFile ""
	}

	public {
		variable uiVar

		method okClicked {}
		method grabWidget {}
		method chooseDBFile {{openOrSave ""}}
		method updateUiState {}
		method updateName {}
		method updateHandler {}
		method notifyFileChange {varName arrIdx op}
	}
}

body DBEditDialog::constructor {args} {
	set uiVar(reg) 1

	parseArgs {
		-db {set _db $value}
		-mode {set _mode $value}
		-file {set _preselectFile $value}
	}

	set uiVar(file) ""
	ttk::frame $_root.file
	pack $_root.file -side top -fill both
	set lf [ttk::labelframe $_root.file.lf -text [mc {Database file:}]]
	pack $lf -side top -fill x -pady 6 -padx 4
# 	ttk::frame $_root.file.f
# 	pack $_root.file.f -side top -fill x -pady 2 -padx 4

	ttk::entry $lf.e -width 40 -textvariable [scope uiVar](file)
	pack $lf.e -side left -fill x
	ttk::button $lf.b -image img_open -command "$this chooseDBFile"
	pack $lf.b -side right -fill none -padx 3

	ttk::frame $_root.name
	pack $_root.name -side top -fill both
	set lf [ttk::labelframe $_root.name.lf -text [mc {Database name:}]]
	pack $lf -side top -fill x -pady 6 -padx 4

	set uiVar(nameType) "auto"
	ttk::radiobutton $lf.auto -text [mc {Generate automatically}] -variable [scope uiVar](nameType) \
		-value "auto" -command [list $this updateUiState]
	pack $lf.auto -side top -fill x -pady 2 -padx 4
	ttk::radiobutton $lf.manual -text [mc {Type name in field below:}] -variable [scope uiVar](nameType) \
		-value "manual" -command [list $this updateUiState]
	pack $lf.manual -side top -fill x -pady 2 -padx 4

	set uiVar(name) ""
	ttk::entry $lf.manual_value -textvariable [scope uiVar](name)
	pack $lf.manual_value -side top -fill x -pady 2 -padx 4

	ttk::frame $_root.ver
	pack $_root.ver -side top -fill both
	ttk::label $_root.ver.l -text [mc {Database version:}] -justify left
	pack $_root.ver.l -side left -fill x -pady 4 -padx 4
	ttk::frame $_root.ver.f
	pack $_root.ver.f -side right -fill x -pady 4 -padx 4

	set dbLabels [list]
	foreach supDb $::DB_HANDLERS {
		lappend dbLabels [${supDb}::getHandlerLabel]
	}

	ttk::combobox $_root.ver.f.e -width 16 -values [lsort -dictionary $dbLabels] -state readonly
	pack $_root.ver.f.e -side left -fill x
	$_root.ver.f.e set [Sqlite3::getHandlerLabel]

	if {$_mode == "new"} {
		ttk::frame $_root.reg
		pack $_root.reg -side top -fill both
		ttk::checkbutton $_root.reg.c -text [mc {Remember it permanently}] -variable [scope uiVar(reg)]
		pack $_root.reg.c -side left -padx 4 -pady 5
		helpHint $_root.reg.c [mc "If disabled, then the database will be registered only\nfor this single SQLiteStudio session."]
	}

	ttk::frame $_root.d
	pack $_root.d -side bottom -fill x
	ttk::frame $_root.d.f
	pack $_root.d.f -side bottom -fill x

	ttk::button $_root.d.f.ok -text [mc "Ok"] -command "$this clicked ok" -compound left -image img_ok
	pack $_root.d.f.ok -side left -pady 3 -padx 5
	ttk::button $_root.d.f.cancel -text [mc "Cancel"] -command "$this clicked cancel" -compound left -image img_cancel
	pack $_root.d.f.cancel -side right -pady 3 -padx 5

	if {$_mode == "edit"} {
		#$_root.name.e insert end [$_db getName]
		#$_root.file.f.e insert end [$_db getPath]
		set uiVar(name) [$_db getName]
		set uiVar(file) [$_db getPath]
		set dbLabel [[$_db info class]::getHandlerLabel]
		$_root.ver.f.e set $dbLabel
		$_root.ver.f.e configure -values [list $dbLabel] -state disabled
		set uiVar(nameType) "manual"
		setTitle [mc {Edit database}]
	} else {
		setTitle [mc {Add database}]
		if {$_preselectFile != ""} {
			if {[file exists $_preselectFile]} {
				set uiVar(file) $_preselectFile
				updateName
				updateHandler
			} else {
				Warning [mc {File '%s' doesn't exist!} $_preselectFile]
			}
		}
	}

	trace add variable [scope uiVar] write [list $this notifyFileChange]

	updateUiState
}

body DBEditDialog::okClicked {} {
	set closeWhenOkClicked 0
	set name $uiVar(name)
	set dbfile $uiVar(file)
	if {$dbfile == ""} {
		Info [mc {You have to specify database file.}]
		return
	}

	if {[file pathtype $dbfile] == "relative"} {
		set dbfile [file join $::startingDir $dbfile]
	}

	set dbByName [DBTREE getDBByName $name]
	if {$dbByName != "" && !($_mode == "edit" && $dbByName == $_db)} {
		Info [mc {Database named '%s' already exists on databases list. Please pick other name.} $name]
		return
	}

	set dbByPath [DBTREE getDBByPath $dbfile]
	if {$dbByPath != "" && !($_mode == "edit" && $dbByPath == $_db)} {
		Info [mc {Database '%s' already exists on databases list with name '%s'. Please pick other database file or abort.} $dbfile [$dbByPath getName]]
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
	

	if {$dbHnd == "Sqlite2" && ![string is ascii $dbfile]} {
		Error [mc {SQLite 2 driver doesn't deal with non-ASCII file names well. Please do not use national characters, use ASCII-compliant file name.}]
		return
	}

	if {$_mode == "edit"} {
		# Changing name if needed
		set pathEqual [string equal $dbfile [$_db getPath]]
		set nameEqual [string equal $name [$_db getName]]
		if {!$pathEqual || !$nameEqual} {
			if {[$_db isOpen]} {
				$_db close
			}
			$_db changeTo $name $dbfile
		}
		set closeWhenOkClicked 1
	} else {
		set createResults [${dbHnd}::createDbFile $dbfile]
		if {![dict get $createResults code]} {
			set res [dict get $createResults msg]
			Error [mc {Error while trying to create database: %s} $res]
			return
		}

		set temp [expr {$_mode == "new" && !$uiVar(reg)}]
		if {![catch {
			DBTREE addDB $name $dbfile $temp
		}]} {
			set closeWhenOkClicked 1
		}
	}

	DBTREE refreshSchema
}

body DBEditDialog::grabWidget {} {
	return $_root.file.lf.e
}

body DBEditDialog::chooseDBFile {{openOrSave ""}} {
	if {$_mode == "edit"} {
		if {[file exists [file dirname [$_db getPath]]]} {
			set dir [file dirname [$_db getPath]]
		} else {
			set dir $::startingDir
		}
		set file [lindex [file split [$_db getPath]] end]
		if {![file exists $file]} {
			set file ""
		}
	} else {
		set dir $::startingDir
		set file ""
	}

	set dir [getPathForFileDialog $dir]

	set dialog "GetAppendFile"
	set label [mc {Select file}]
	if {$openOrSave == "save"} {
		set dialog "GetSaveFile"
		set label [mc {Type not existing file for new database}]
	} elseif {$openOrSave == "open"} {
		set dialog "GetOpenFile"
		set label [mc {Select existing database file}]
	}
	if {[os] == "macosx"} {
		set f [$dialog -title $label -initialdir $dir -initialfile $file]
	} else {
		set f [$dialog -title $label -initialdir $dir -initialfile $file -filetypes $::DB_FILE_TYPES -parent [winfo toplevel $_root]]
	}

	if {[os] == "win32" && [string match "*.lnk" $f]} {
		set f [readlnk $f]
	}
	if {$f == ""} return
	if {![winfo exists $_root]} return
	set uiVar(file) $f

	if {[file exists $f]} {
		updateHandler
	}
}

body DBEditDialog::updateHandler {} {
	set cls [DB::getHandlerClassForFile $uiVar(file)]
	if {$cls != ""} {
		$_root.ver.f.e set [${cls}::getHandlerLabel]
	} else {
		Warning [mc {%s is not supported database!} $uiVar(file)]
	}
}

body DBEditDialog::notifyFileChange {varName arrIdx op} {
	if {$arrIdx == "file"} {
		updateName
	}
}

body DBEditDialog::updateName {} {
	if {$uiVar(nameType) != "auto"} {
		return
	}
	if {[string trim $uiVar(file)] != ""} {
		set fileOnly [lindex [file split $uiVar(file)] end]
		set name $fileOnly

		set i 1
		while {[DBTREE getDBByName $name] != ""} {
			set name "${fileOnly}_$i"
			incr i
		}

		set uiVar(name) $name
	} else {
		set uiVar(name) ""
	}
}

body DBEditDialog::updateUiState {} {
	if {$uiVar(nameType) == "auto"} {
		$_root.name.lf.manual_value configure -state disabled
	} else {
		$_root.name.lf.manual_value configure -state normal
	}
	updateName
}
