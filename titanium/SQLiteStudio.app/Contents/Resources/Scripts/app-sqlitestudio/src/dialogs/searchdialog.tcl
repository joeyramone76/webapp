use src/common/modal.tcl

class SearchDialog {
	inherit Modal

	constructor {args} {
		eval Modal::constructor $args
	} {}

	destructor {}

	common historyLength 10

	private {
		variable _currIdx 1.0
		variable _edit ""
		variable _doReplace 0
		variable _autoReplace 0
		variable _expMethod ""
		variable _hist [list]
		variable _replHist [list]
	}

	public {
		variable sleep

		method okClicked {}
		method grabWidget {}
# 		method clicked {bt}
	}
}

body SearchDialog::constructor {args} {
	set default ""
	foreach {opt val} $args {
		switch -- $opt {
			"-edit" {
				set _edit $val
			}
			"-replace" {
				set _doReplace $val
			}
		}
	}
	if {$_edit == ""} {
		error "-edit option is required for SearchDialog widget!"
	}

	# Restoring history
	set _hist [CfgWin::getSearchDlgHistory editorWindow FIND]
	set _replHist [CfgWin::getSearchDlgHistory editorWindow REPLACE]

	ttk::frame $_root.u
	ttk::frame $_root.d

	lappend _searchParamWidgets [ttk::frame $_root.u.patt]
	ttk::label $_root.u.patt.l -text "Pattern:"
	ttk::combobox $_root.u.patt.e -values $_hist
	pack $_root.u.patt -side top -fill x -padx 2 -pady 2

	if {$_doReplace} {
		ttk::frame $_root.u.repl
		ttk::label $_root.u.repl.l -text "Replace with:"
		ttk::combobox $_root.u.repl.e -values $_replHist
		ttk::checkbutton $_root.u.askForRepl -text "Ask before replace"
		pack $_root.u.repl.e -side right -fill x -padx 3
		pack $_root.u.repl.l -side right
		pack $_root.u.repl -side top -fill x -padx 2 -pady 2
		pack $_root.u.askForRepl -side top -fill x -padx 2
	}

	ttk::checkbutton $_root.u.case -text "Case sensitive"
# 	ttk::checkbutton $_root.u.globexp -text "Use global expression" -variable [scope _expMethod] -onvalue "global"
	ttk::checkbutton $_root.u.regexp -text "Regular expression" -variable [scope _expMethod] -onvalue "regular"
# 	helpHint $_root.u.globexp [mc {Global expression understeands '*', '?' and \[chars].}]

	ttk::button $_root.d.find -text [mc {Find}] -command "$this clicked ok" -image img_ok -compound left
	ttk::button $_root.d.close -text [mc {Close}] -command "$this clicked cancel" -image img_cancel -compound left
	if {$_doReplace} {
		$_root.d.find configure -text [mc {Replace}]
	}

	pack $_root.u.case $_root.u.regexp -side top -fill x -padx 2

	pack $_root.u.patt.e -side right -fill x -padx 3
	pack $_root.u.patt.l -side right

	pack $_root.u -side top -fill both
	pack $_root.d.find -side left

	pack $_root.d.close -side right
	pack $_root.d -side bottom -fill x -padx 2 -pady 2

	focus $_root.u.patt.e
	$_root.u.patt.e insert end $default
	$_root.u.patt.e selection range 0 end
}

body SearchDialog::destructor {} {
	$_edit tag delete found
}

body SearchDialog::grabWidget {} {
	return $_root.u.patt
}

body SearchDialog::okClicked {} {
	# Handling options
	set opts [list]
	if {[$_root.u.case state] != "selected"} {
		lappend opts "-nocase"
	}

	set patt [$_root.u.patt.e get]
	set _autoReplace 1
	if {$_doReplace} {
		set replValue [$_root.u.repl.e get]

		if {[$_root.u.askForRepl state] == "selected"} {
			set _autoReplace 0
		}
	}

	# Adding to history
	if {$patt ni $_hist} {
		CfgWin::addSearchDlgHistory editorWindow FIND $patt
		set _hist [linsert $_hist 0 $patt]
		$_root.u.patt.e configure -values $_hist

	}
	if {$_doReplace && $replValue ni $_replHist} {
		CfgWin::addSearchDlgHistory editorWindow REPLACE $replValue
		set _replHist [linsert $_replHist 0 $replValue]
		$_root.u.repl.e configure -values $_replHist
	}

	switch -- $_expMethod {
		"global" {
			# Currently not used
			lappend opts "-regexp"
			set patt [string map [list ? . * .*] $patt]

		}
		"regular" {
			lappend opts "-regexp"
		}
	}

	# Processing find or replace
	if {$_doReplace} {
		set _currIdx 1.0
		set finished false
		while {!$finished} {
			set idx [$_edit search -count lgt {*}[join $opts \ ] $patt $_currIdx end]
			if {$idx != ""} {
				$_edit tag delete found
				$_edit see "$idx -1 char"

				set repl 0
				if {$_autoReplace} {
					set repl 1
				} else {
					$_edit tag add found $idx "$idx +$lgt char"
					$_edit tag configure found -borderwidth 1 -background #AAAAFF -foreground black

					set dlg [YesNoDialog $this.#auto -message [mc {Do you want to replace marked text?}] -title [mc {Replace}] -third [mc {Replace all}] -fourth [mc {Abort}] -fourthicon img_abort]
					set res [$dlg exec]
					if {$res > 0} {
						set repl 1
						if {$res == 2} {
							set _autoReplace 1
						}
					} elseif {$res == -1} {
						set finished 1
						set repl 0
					}
				}
				if {$repl} {
					$_edit delete $idx "$idx +$lgt char"
					$_edit insert $idx $replValue
				}
				set _currIdx [$_edit index "$idx + $lgt char"]
			} else {
				Info [mc {Replacing finished.}]
				focus $_root.u.patt.e
				set finished true
			}
		}
	} else {
		set idx [$_edit search -count lgt {*}[join $opts \ ] $patt $_currIdx end]
		if {$idx != ""} {
			$_edit tag delete found
			$_edit tag add found $idx "$idx +$lgt char"
			$_edit tag configure found -borderwidth 1 -background #AAAAFF -foreground black
			$_edit see "$idx -1 char"
			$_edit mark set insert "$idx -1 char"
			set _currIdx [$_edit index "$idx + $lgt char"]
		} else {
			Info [mc {Cannot match the pattern!}]
			focus $_root.u.patt.e
			set _currIdx 1.0
		}
	}
	set closeWhenOkClicked 0
}
