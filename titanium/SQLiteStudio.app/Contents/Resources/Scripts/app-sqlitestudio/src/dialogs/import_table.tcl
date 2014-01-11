use src/common/modal.tcl

class ImportTableDialog {
	inherit Modal

	constructor {args} {
		eval Modal::constructor $args
	} {}

	common _sepLabels [list [mc "\\t (tab)"] [mc {  (white-space)}] [mc {, (comma)}] [mc {; (semicolon)}]]
	common _separators [list "\t" " " "," ";"]

	opt db
	opt table

	private {
		variable _db ""
		variable _table ""
	}

	public {
		method okClicked {}
		method grabWidget {}
		method chooseFile {}
	}
}

body ImportTableDialog::constructor {args} {
	ttk::frame $_root.file
	pack $_root.file -side top -fill both
	ttk::label $_root.file.l -text "" -justify left
	pack $_root.file.l -side top -fill x -pady 2 -padx 0.2c
	ttk::frame $_root.file.f
	pack $_root.file.f -side top -fill x -pady 0.1c -padx 0.2c

	ttk::entry $_root.file.f.e -width 40
	pack $_root.file.f.e -side left -fill x
	ttk::button $_root.file.f.b -image img_open -command "$this chooseFile"
	pack $_root.file.f.b -side right -fill none -padx 3

	ttk::frame $_root.sep
	pack $_root.sep -side top -pady 3
	ttk::label $_root.sep.l -text [mc {Separator:}]
	ttk::combobox $_root.sep.c -values $_sepLabels -state readonly -width 16
	helpHint $_root.sep.c [mc "Common separator is \\t (tab), but sometimes others can be met."]
	pack $_root.sep.c $_root.sep.l -side right -padx 2
	$_root.sep.c set [lindex $_sepLabels 0]

	ttk::frame $_root.d
	pack $_root.d -side bottom -fill x
	ttk::frame $_root.d.f
	pack $_root.d.f -side bottom

	ttk::button $_root.d.f.ok -text [mc "Ok"] -command "$this clicked ok" -compound left -image img_ok
	pack $_root.d.f.ok -side left -pady 3
	ttk::button $_root.d.f.cancel -text [mc "Cancel"] -command "$this clicked cancel" -compound left -image img_cancel
	pack $_root.d.f.cancel -side left -pady 3

	eval itk_initialize $args
	set _db $itk_option(-db)
	set _table $itk_option(-table)
	$_root.file.l configure -text [mc {Import data file for '%s' table:} $_table]
}


body ImportTableDialog::okClicked {} {
	set f [$_root.file.f.e get]
	set delim [lindex $_separators [$_root.sep.c current]]
	if {![file readable $f]} {
		Error [mc {File '%s' isn't readable!} $f]
	}
	if {[catch {
		$_db eval "COPY $_table FROM '$f' USING DELIMITERS '$delim'"
	} res]} {
		cutOffStdTclErr res
		Error [mc "Error while trying to copy data:\n%s" $res]
	}
}

body ImportTableDialog::grabWidget {} {
	return $_root.file.f.e
}

body ImportTableDialog::chooseFile {} {
	if {[file exists [file dirname [$_db getPath]]]} {
		set dir [file dirname [$_db getPath]]
	} else {
		set dir [pwd]
	}
	set file [lindex [file split [$_db getPath]] end]
	if {![file exists $file]} {
		set file ""
	}
	set f [GetOpenFile -title [mc {Select file}] -initialdir $dir -initialfile $file -parent [winfo toplevel $_root]]
	if {$f == ""} return
	$_root.file.f.e delete 0 end
	$_root.file.f.e insert end $f
}
