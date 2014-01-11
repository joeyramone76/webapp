use src/common/modal.tcl

class ImportDbDialog {
	inherit Modal

	constructor {args} {
		Modal::constructor {*}$args
	} {}

	opt db

	private {
		variable _db ""
		variable _mode ""
		variable _listCombo ""
		variable _fileEntry ""
		variable _fileButton ""
	}

	public {
		method okClicked {}
		method grabWidget {}
		method chooseDBFile {}
		method updateState {}
	}
}

body ImportDbDialog::constructor {args} {
	set _mode "list"

	# List of databases
	set lst $_root.list
	ttk::frame $lst
	pack $lst -side top -fill x -padx 3 -pady 5

	ttk::frame $lst.rbt
	pack $lst.rbt -side top -fill x
	ttk::radiobutton $lst.rbt.bt -text [mc {Import from one of databases:}] -variable [scope _mode] -value "list" -command "$this updateState"
	pack $lst.rbt.bt -side left -fill x

	set dbNames [list]
	foreach db [DBTREE dblist] {
		lappend dbNames [$db getName]
	}

	set _listCombo [ttk::combobox $lst.combo -values $dbNames -state readonly]
	pack $lst.combo -side top -fill x

	# Database from file
	set fl $_root.file
	ttk::frame $fl
	pack $fl -side top -fill x -padx 3 -pady 5

	ttk::frame $fl.rbt
	pack $fl.rbt -side top -fill x
	ttk::radiobutton $fl.rbt.bt -text [mc {Choose database file to import:}] -variable [scope _mode] -value "file" -command "$this updateState"
	pack $fl.rbt.bt -side left -fill x

	ttk::frame $fl.file
	pack $fl.file -side top -fill x
	set _fileEntry [ttk::entry $fl.file.e]
	pack $fl.file.e -side left -fill x
	set _fileButton [ttk::button $fl.file.b -text [mc {Browse}] -command "$this chooseDBFile"]
	pack $fl.file.b -side right -padx 2

	ttk::frame $_root.d
	pack $_root.d -side bottom -fill x
	ttk::frame $_root.d.f
	pack $_root.d.f -side bottom -fill x

	ttk::button $_root.d.f.ok -text [mc "Ok"] -command "$this clicked ok" -compound left -image img_ok
	pack $_root.d.f.ok -side left -pady 3 -padx 5
	ttk::button $_root.d.f.cancel -text [mc "Cancel"] -command "$this clicked cancel" -compound left -image img_cancel
	pack $_root.d.f.cancel -side right -pady 3 -padx 5

	updateState

	eval itk_initialize $args
	set _db $itk_option(-db)
}

body ImportDbDialog::okClicked {} {
	set closeWhenOkClicked 0

	switch -- $_mode {
		"list" {
			set dbName [$_listCombo get]
			if {$dbName == ""} {
				Warning [mc {No database chosen.}]
				return
			}
			set remoteDb [DBTREE getDBByName $dbName]
			if {![$remoteDb isOpen]} {
				$remoteDb open
			}
		}
		"file" {
			set remoteDb [DB::getPureSqliteObject [$_fileEntry get]]
			if {$remoteDb == ""} {
				Warning [mc {Cannot open specified database.}]
				return
			}
		}
	}

	if {[catch {
		set mode [$remoteDb mode]
		$remoteDb short
		set sqls [list]
		$remoteDb eval {SELECT name, sql FROM sqlite_master} r {
			if {[string match "sqlite_*" $r(name)]} continue
			lappend sqls $r(sql)
		}
		$remoteDb $mode
		$_db eval [join $sqls ";"]
	} res]} {
		cutOffStdTclErr res
		Error [mc "Error while importing database:\n%s" $res]
		return
	}

	set closeWhenOkClicked 1
	DBTREE refreshSchema
}

body ImportDbDialog::grabWidget {} {
	return $_root.list.rbt.bt
}

body ImportDbDialog::chooseDBFile {} {
	set dir $::startingDir
	set dir [getPathForFileDialog $dir]
	set file ""

	if {[os] == "macosx"} {
		set f [GetOpenFile -title [mc {Select file}] -initialdir $dir -initialfile $file]
	} else {
		set f [GetOpenFile -title [mc {Select file}] -initialdir $dir -initialfile $file -filetypes $::DB_FILE_TYPES -parent [winfo toplevel $_root]]
	}

	if {[os] == "win32" && [string match "*.lnk" $f]} {
		set f [readlnk $f]
	}
	if {$f == ""} return
	$_fileEntry delete 0 end
	$_fileEntry insert end $f
}

body ImportDbDialog::updateState {} {
	switch -- $_mode {
		"list" {
			$_listCombo configure -state readonly
			$_fileEntry configure -state disabled
			$_fileButton configure -state disabled
		}
		"file" {
			$_listCombo configure -state disabled
			$_fileEntry configure -state normal
			$_fileButton configure -state normal
		}
	}
}
