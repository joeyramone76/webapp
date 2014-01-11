use src/common/modal.tcl

class BindParamDialog {
	inherit Modal

	constructor {args} {
		Modal::constructor {*}$args -resizable 1 -expandcontainer 1 -allowreturn 1
	} {}

	protected {
		variable _tokenizedStatements ""
		variable _edits [list]
		variable _paramToIndex

		method getKey {tokens}
	}

	public {
		variable checkState

		method okClicked {}
		method grabWidget {}
		method getSize {}
		method updateNullState {queryIdx fieldIdx}
		method switchNull {queryIdx fieldIdx}
		method updateSameValue {paramName queryIdx fieldIdx}
		method checkModified {paramName}
	}
}

body BindParamDialog::constructor {args} {
	parseArgs {
		-tokens {set _tokenizedStatements $value}
	}

	array set _paramToEdit {}
	array set _paramToCheckbox {}
	array set _paramToNullVar {}

	ScrolledFrame $_root.top
	pack $_root.top -side top -fill both -padx 3 -pady 5 -expand 1
	set fr [$_root.top getFrame]

	set historyKey [getKey $_tokenizedStatements]
	set historyValues [CfgWin::getBindHistory $historyKey]

	# Creating frames
	set firstEntry ""
	set i 1
	foreach tokens $_tokenizedStatements partialHistoryValues $historyValues {
		set j 1
		set bindTokens [list]
		foreach token $tokens {
			if {[lindex $token 0] != "BIND_PARAM"} continue
			lappend bindTokens $token
		}
		if {[llength $bindTokens] > 0} {
			ttk::labelframe $fr.$i -text [mc {Query number %s} $i]
			pack $fr.$i -side top -fill x -padx 2 -pady 3
			foreach token $bindTokens histValuePair $partialHistoryValues {
				lassign $histValuePair histValue histValueNull
			
				set paramName [lindex $token 1]
				ttk::labelframe $fr.$i.$j -text [mc {Parameter number %s (named: %s):} $j $paramName]
				pack $fr.$i.$j -side top -fill x -padx 2 -pady 3

				# NULL
				set checkState($i:$j:null) [expr {$histValueNull != "" ? $histValueNull : 0}]
				pack [ttk::frame $fr.$i.$j.options] -side top -fill x
				ttk::checkbutton $fr.$i.$j.options.null -text [mc {NULL value}] \
					-variable [scope checkState]($i:$j:null) -takefocus 0 -command [list $this updateNullState $i $j]
				pack $fr.$i.$j.options.null -side left
				helpHint $fr.$i.$j.options.null [mc {You can use '%s' keyboard shortcut to switch NULL value.} ${::Shortcuts::setNullInForm}]

				# Edit panel
				set editWidget [BlobEditPanel $fr.$i.$j.e -textheight 4 -value $histValue]
				lappend _edits $editWidget
				pack $fr.$i.$j.e -side top -fill both

				# Same value option
				ttk::button $fr.$i.$j.options.sameVal -text [mc {Copy value to other '%s' parameters (%s)} $paramName 1] -takefocus 0 \
					-command [list $this updateSameValue $paramName $i $j]
				helpHint $fr.$i.$j.options.sameVal [mc "By enabling this all parameters with same name\nwill also have same value as this one."]

				lappend _paramToIndex($paramName) [list $i $j]

				$fr.$i.$j.e bindEdits <${::Shortcuts::setNullInForm}> "$this switchNull $i $j; break"
				updateNullState $i $j

				if {$firstEntry == ""} {
					set firstEntry $fr.$i.$j.e
				}

				incr j
			}
		}
		incr i
	}
	
	foreach paramName [array names _paramToIndex] {
		if {[llength $_paramToIndex($paramName)] > 1} {
			foreach idxPair $_paramToIndex($paramName) {
				set cb $fr.[join $idxPair .].options.sameVal
				$cb configure -text [mc {Copy value to other '%s' parameters (%s)} $paramName [llength $_paramToIndex($paramName)]]
				pack $cb -side right -padx 3 -pady 2
			}
		}
	}

	set lgt [llength $_edits]
	for {set i 0} {$i < $lgt} {incr i} {
		set widget [lindex $_edits $i]
		set nextWidget [lindex $_edits [expr {$i+1}]]
		set prevWidget [lindex $_edits [expr {$i-1}]]
		if {$nextWidget != ""} {
			set parent [winfo parent $nextWidget]
			$widget bindEdits <Tab> "focus $nextWidget; $_root.top see $parent; break"
		} else {
			$widget bindEdits <Tab> "break"
		}
		if {$prevWidget != ""} {
			set parent [winfo parent $prevWidget]
			$widget bindEdits <<PrevWindow>> "focus $prevWidget; $_root.top see $parent; break"
		} else {
			$widget bindEdits <<PrevWindow>> "break"
		}
	}

	$_root.top makeChildsScrollable

	# Bottom part of dialog
	ttk::frame $_root.d
	pack $_root.d -side bottom -fill x
	ttk::frame $_root.d.f
	pack $_root.d.f -side bottom

	ttk::button $_root.d.f.ok -text [mc {Execute query}] -command "$this clicked ok" -compound left -image img_ok
	pack $_root.d.f.ok -side left -pady 3 -padx 2
	ttk::button $_root.d.f.cancel -text [mc {Cancel}] -command "$this clicked cancel" -compound left -image img_cancel
	pack $_root.d.f.cancel -side left -pady 3 -padx 2

	if {$firstEntry != ""} {
		$firstEntry setTextFocus
	}
}

body BindParamDialog::switchNull {queryIdx fieldIdx} {
	set checkState($queryIdx:$fieldIdx:null) [expr {!$checkState($queryIdx:$fieldIdx:null)}]
	updateNullState $queryIdx $fieldIdx
}

body BindParamDialog::updateNullState {queryIdx fieldIdx} {
	set fr [$_root.top getFrame]
	set null $checkState($queryIdx:$fieldIdx:null)
	$fr.$queryIdx.$fieldIdx.e setDisabled $null
}

body BindParamDialog::grabWidget {} {
	return [$_root.top getFrame]
}

body BindParamDialog::okClicked {} {
	set cnt [llength $_tokenizedStatements]
	set editPtr 0
	set historyKey [getKey $_tokenizedStatements]
	set historyValues [list]
	set queryIdx 1
	for {set i 0} {$i < $cnt} {incr i} {
		set paramIdx 1
		set tokens [lindex $_tokenizedStatements $i]
		set partialHistoryValues [list]
		set tokensCnt [llength $tokens]
		for {set j 0} {$j < $tokensCnt} {incr j} {
			set token [lindex $tokens $j]

			if {[lindex $token 0] == "BIND_PARAM"} {
				set edit [lindex $_edits $editPtr]
				
				if {$checkState($queryIdx:$paramIdx:null)} {
					set token [lreplace $token 0 1 KEYWORD NULL]
					lappend partialHistoryValues [list "" 1]
					
					# Replace preceding operator if can
					set prevIdx [expr {$j-1}]
					switch -- [lindex $tokens $prevIdx 1] {
						"=" {
							set tokens [lreplace $tokens $prevIdx $prevIdx [list KEYWORD IS 0 0]]
						}
						"<>" {
							set tokens [lreplace $tokens $prevIdx $prevIdx [list KEYWORD NOT 0 0]]
						}
					}
				} else {
					set value [$edit get]
					set token [lreplace $token 0 1 "OTHER" $value]
					lappend partialHistoryValues [list $value 0]
				}
				
				incr editPtr
				incr paramIdx
			}

			set tokens [lreplace $tokens $j $j $token]
		}
		lappend historyValues $partialHistoryValues
		set _tokenizedStatements [lreplace $_tokenizedStatements $i $i $tokens]
		incr queryIdx
	}
	CfgWin::putBindHistory $historyKey $historyValues
	return $_tokenizedStatements
}

body BindParamDialog::getKey {tokenizedStatements} {
	set keyTokenList [list]
	foreach tokens $tokenizedStatements {
		set keyTokens [list]
		foreach token $tokens {
			if {[lindex $token 0] != "BIND_PARAM"} continue
			lappend keyTokens [lindex $token 1]
		}
		lappend keyTokenList $keyTokens
	}
	return [md5::md5 $keyTokenList]
}

body BindParamDialog::getSize {} {
	return [list 660 500]
}

body BindParamDialog::updateSameValue {paramName queryIdx fieldIdx} {
	set fr [$_root.top getFrame]

	set clickedEdit "$fr.$queryIdx.$fieldIdx.e"
	set clickedEditNullCb "$fr.$queryIdx.$fieldIdx.options.null"
	set clickedEditNullValue $checkState($queryIdx:$fieldIdx:null)

	set edits [list]
	set nullCbs [list]
	set nullValueVars [list]
	foreach idxPair $_paramToIndex($paramName) {
		lassign $idxPair qIdx fIdx
		if {"$qIdx:$fIdx" == "$queryIdx:$fieldIdx"} continue

		lappend edits "$fr.$qIdx.$fIdx.e"
		lappend nullCbs "$fr.$qIdx.$fIdx.options.null"
		lappend nullValueVars checkState($qIdx:$fIdx:null)
	}

	set value [$clickedEdit get]
	foreach edit $edits {
		if {$edit == $clickedEdit} continue
		$edit setValue $value
	}
	foreach nullVar $nullValueVars {
		set $nullVar $clickedEditNullValue
	}
	foreach idxPair $_paramToIndex($paramName) {
		updateNullState {*}$idxPair
	}
}
