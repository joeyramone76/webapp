use src/common/modal.tcl

class FunctionsDialog {
	inherit Modal

	#>
	# @var sortByName
	# Configurable variable (in config dialog) that decides if functions in list
	# are sorted by name or by creation order.
	#<
	common sortByName 0

	constructor {args} {
		eval Modal::constructor $args -resizable 1 -expandcontainer 1
	} {}

	private {
		variable _tree ""
		variable _type ""
		variable _sqlEditor ""
		variable _tclEditor ""
		variable _nameEdit ""
		variable _delBtn ""
		variable _currEditItem ""

		method getCurrentEdit {}
		method readExistingFunctions {}
		method storeCurrEdit {}
	}

	public {
		method okClicked {}
		method grabWidget {}
		method implTypeChoosen {}
		method updateState {item}
		method addFunction {}
		method delFunction {}
		method nameModified {}
		method setModified {value}
		method apply {}
	}
}

body FunctionsDialog::constructor {args} {
	pack [ttk::panedwindow $_root.u -orient horizontal] -side top -fill both -expand 1
	pack [ttk::frame $_root.d] -side bottom -fill x

	#pack [ttk::frame $_root.u.l] -side left -fill y
	#pack [ttk::frame $_root.u.r] -side right -fill both -expand 1
	ttk::frame $_root.u.l
	ttk::frame $_root.u.r
	$_root.u add $_root.u.l -weight 1
	$_root.u add $_root.u.r -weight 5

	set _tree [BrowserTree $_root.u.l.tree -clicked "$this updateState \$item"]
	[$_tree getTree] configure -width 100 -showrootlines 0 -showrootbutton 0 -showbuttons 0
	pack $_tree -side top -fill both -expand 1

	set man [ttk::frame $_root.u.l.manage_tree]
	pack $man -side top -fill x -pady 4 -padx 3
	ttk::button $man.add -image img_db_insert -command "$this addFunction"
	set _delBtn [ttk::button $man.del -image img_db_delete -command "$this delFunction" -state disabled]
	pack $man.add -side left -padx 5
	pack $_delBtn -side right -padx 5

	pack [ttk::frame $_root.u.r.top] -side top -fill x -pady 1 -padx 2
	pack [ttk::frame $_root.u.r.body] -side bottom -fill both -expand 1

	ttk::label $_root.u.r.top.type_lab -text [mc {Implementation:}]
	ttk::label $_root.u.r.top.name_lab -text [mc {Name:}]
	ttk::frame $_root.u.r.top.sep
	set _nameEdit [ttk::entry $_root.u.r.top.name_e -width 15 -state disabled]
	set _type [ttk::combobox $_root.u.r.top.type_cb -values [list SQL Tcl] -state disabled -width 5]
	$_type set ""
	pack $_root.u.r.top.name_lab -side left
	pack $_nameEdit -side left -fill x -expand 1
	pack $_root.u.r.top.sep -side left -padx 10
	pack $_type -side right
	pack $_root.u.r.top.type_lab -side right

	bind $_nameEdit <Any-KeyRelease> "$this nameModified"

	set editorHint [mc "Use \$0, \$1, \$2, \$3, ... - as positional parameters\nthat will be passed to the function.\nFor example call to my_function('x',5) will call\nmy_function with 'x' as \$0 and 5 as \$1."]
	
	set _sqlEditor [SQLEditor $_root.u.r.body.sql -state disabled -validatesql true]
	set _tclEditor [TclEditor $_root.u.r.body.tcl -state disabled]
	pack $_sqlEditor -fill both -expand 1
	$_sqlEditor configure -width 10 -height 3
	$_tclEditor configure -width 10 -height 3
	$_sqlEditor updateUISettings
	$_tclEditor updateUISettings
	helpHint $_sqlEditor $editorHint
	helpHint $_tclEditor $editorHint

	bind [$_sqlEditor getWidget] <Any-KeyRelease> "$this setModified true"
	bind [$_tclEditor getWidget] <Any-KeyRelease> "$this setModified true"

	bind $_type <<ComboboxSelected>> "$this implTypeChoosen; $this setModified true"

	ttk::button $_root.d.ok -text [mc {Ok}] -command [list $this clicked ok] -compound left -image img_ok
	ttk::button $_root.d.apply -text [mc {Apply}] -command [list $this apply] -compound left -image img_apply
	ttk::button $_root.d.cancel -text [mc {Cancel}] -command [list $this clicked cancel] -compound left -image img_cancel
	pack $_root.d.ok -side left -padx 1
	pack $_root.d.apply -side left -padx 1
	pack $_root.d.cancel -side right -padx 1
	pack $_root.d -side bottom -pady 2

	readExistingFunctions
	setModified false
}

body FunctionsDialog::readExistingFunctions {} {
	foreach func [CfgWin::getFunctions] {
		lassign $func name type code
		switch -- $type {
			"SQL" {
				set img img_database
			}
			"Tcl" {
				set img img_tcl
			}
		}

		set it [$_tree addItem root $img $name false]
		set data [dict create type $type code $code]
		[$_tree getTree] item element configure $it 1 e_datatxt -data $data
	}
}

body FunctionsDialog::okClicked {} {
	apply
}

body FunctionsDialog::apply {} {
	set closeWhenOkClicked 0
	storeCurrEdit

	set t [$_tree getTree]

	# Validating
	set was [list]
	foreach it [$t item children root] {
		set name [$_tree getText $it]
		if {$name in $was} {
			Warning [mc {Cannot use two functions with same name! Change name for '%s'.} $name]
			return
		}
		if {$name in [list "tcl" "sqlfile"]} {
			Warning [mc {Cannot use 'tcl' or 'sqlfile' for function name, these names are reserved! }]
			return
		}
		lappend was $name
	}

	# Old functions list
	set oldFunctions [list]
	foreach func [CfgWin::getFunctions] {
		lappend oldFunctions [lindex $func 0]
	}

	set dblist [list]
	foreach db [DBTREE dblist] {
		if {![$db isOpen]} continue
		lappend dblist $db
	}

	foreach db $dblist {
		foreach func $oldFunctions {
			set msg [mc {Function '%s' is not implemented!} $func]
			$db function $func [list errorWithFirstArg $msg]
		}
	}

	# Saving
	CfgWin::clearFunctions

	foreach it [$t item children root] {
		set data [$t item element cget $it 1 e_datatxt -data]
		set type [dict get $data type]
		set code [dict get $data code]
		set name [$_tree getText $it]
		CfgWin::saveFunction $name $type $code
		foreach db $dblist {
			$db registerCustomFunction $name $type $code
		}
	}

	setModified false
	set cedit [getCurrentEdit]
	if {$cedit != ""} {
		focus [$cedit getWidget]
	}
	set closeWhenOkClicked 1
}

body FunctionsDialog::implTypeChoosen {} {
	set type [$_type get]
	set item [[$_tree getTree] item id active]
	switch -- $type {
		"SQL" {
			pack forget $_tclEditor
			pack $_sqlEditor -fill both -expand 1
			$_sqlEditor setContents [$_tclEditor getContents 1]
			if {$item != "" && $item != "0"} {
				[$_tree getTree] item element configure $item 0 e_img -image img_database
			}
		}
		"Tcl" {
			pack forget $_sqlEditor
			pack $_tclEditor -fill both -expand 1
			$_tclEditor setContents [$_sqlEditor getContents 1]
			if {$item != "" && $item != "0"} {
				[$_tree getTree] item element configure $item 0 e_img -image img_tcl
			}
		}
	}
}

body FunctionsDialog::grabWidget {} {
	return $_root.u.l.tree
}

body FunctionsDialog::storeCurrEdit {} {
	if {$_currEditItem == ""} return

	set type [$_type get]
	switch -- $type {
		"SQL" {
			set code [$_sqlEditor getContents]
		}
		"Tcl" {
			set code [$_tclEditor getContents]
		}
	}

	set data [dict create type $type code $code]
	[$_tree getTree] item element configure $_currEditItem 1 e_datatxt -data $data
}

body FunctionsDialog::updateState {item} {
	set item [[$_tree getTree] item id active]
	storeCurrEdit
	if {$item == "" || $item == "0"} {
		$_type set ""
		$_nameEdit delete 0 end
		$_sqlEditor setContents ""
		$_tclEditor setContents ""
		$_delBtn configure -state disabled
		$_nameEdit configure -text "" -state disabled
		$_sqlEditor configure -state disabled
		$_tclEditor configure -state disabled
		$_type configure -state disabled
		set _currEditItem ""
	} else {
		set name [[$_tree getTree] item element cget $item 0 e_txt -text]
		set data [[$_tree getTree] item element cget $item 1 e_datatxt -data]
		$_delBtn configure -state normal
		$_nameEdit configure -state normal
		$_nameEdit delete 0 end
		$_nameEdit insert end $name
		$_sqlEditor configure -state normal
		$_tclEditor configure -state normal
		$_type configure -state readonly

		set type [dict get $data type]
		$_type set $type
		implTypeChoosen

		switch -- $type {
			"SQL" {
				$_sqlEditor setContents [dict get $data code]
			}
			"Tcl" {
				$_tclEditor setContents [dict get $data code]
			}
		}

		set _currEditItem $item
	}
}

body FunctionsDialog::addFunction {} {
	set newFnName "func"
	set it [$_tree addItem root img_database $newFnName false]
	set data [dict create type "SQL" code ""]
	[$_tree getTree] item element configure $it 1 e_datatxt -data $data
}

body FunctionsDialog::delFunction {} {
	set name [$_tree getText $_currEditItem]
	set dialog [YesNoDialog .delFunc -title [mc {Delete function}] -message [mc {Are you sure you want to delete function '%s'?} $name]]
	if {![$dialog exec]} return

	set _currEditItem ""
	set it [$_tree getSelectedItem]
	$_tree delItem $it
	updateState $it
}

body FunctionsDialog::nameModified {} {
	set item [[$_tree getTree] item id active]
	if {$item != "" && $item != "0"} {
		[$_tree getTree] item element configure $item 0 e_txt -text [$_nameEdit get]
		setModified true
	}
}

body FunctionsDialog::setModified {value} {
	if {$value} {
		$_root.d.apply configure -state normal
	} else {
		$_root.d.apply configure -state disabled
	}
}

body FunctionsDialog::getCurrentEdit {} {
	set type [$_type get]
	switch -- $type {
		"SQL" {
			return $_sqlEditor
		}
		"Tcl" {
			return $_tclEditor
		}
	}
}
