use src/common/common.tcl

#>
# @class DataEditor
# Base class for TableWin and EditorWin, as they do contain Grid and Form editors.
#<
class DataEditor {
	common useTabToJump 1

	protected {
		variable _formViewModified 0
		variable _disableModifyFlagDetection 0
		variable _dataEditorWidget
		variable _formFieldMinHeight
		variable _formFieldMaxHeight

		#>
		# @var _noUpdates
		# This variable is set by derived class when it detects that there's no way to update database data container (table).
		#<
		variable _noUpdates false

		#>
		# @var _commitInProgress
		# Variable used to keep commit/rollback operations invoked from toolbars to be atomic.
		#<
		variable _commitInProgress 0

		#>
		# @var _commitFormInProgress
		# Variable used to keep commit/rollback operations in form view invoked from toolbars to be atomic.
		#<
		variable _commitFormInProgress 0

		#>
		# @var _needToRecreateForm
		# It's a boolean switch to indicate whether <i>form view</i> needs to be refreshed after user
		# switches to it.
		#<
		variable _needToRecreateForm 1

		#>
		# @method getGridObject
		# @return Grid instance (or it's derived class) placed in Grid edit tab.
		#<
		abstract method getGridObject {}

		#>
		# @method getFormFrame
		# @return ScolledFrame that's placed in Form edit tab.
		#<
		abstract method getFormFrame {}

		#>
		# @method getDataTabs
		# @return Notebook widget containing Grid and Form frame.
		#<
		abstract method getDataTabs {}

		abstract method updateFormViewToolbar {}
		abstract method prevDataTab {}
		abstract method nextDataTab {}
		abstract method formFirstRow {}
		abstract method formPrevRow {}
		abstract method formNextRow {}
		abstract method formLastRow {}
		abstract method getSelectedRowDataWithNull {{limited true}}
		abstract method updateEditorToolbar {}
	}

	public {
		variable dataEditorCheckState

		method commitFormEdit {}
		method rollbackFormEdit {}
		method transferFormToGrid {}
		method formEditModifiedFlagProxy {}
		method fillForm {{fromScratch true}}
		method markToFillForm {}
		method focusDataTab {}
		method commitGrid {{itColList ""}}
		method rollbackGrid {{itColList ""}}
		method focusFirstFormWidget {}
		method seeFormWidget {widget}
		method handleTabKey {cls widget nextWidget}
		method canDestroy {}
		method switchNull {colName}
		method updateNullState {colName}
		method handleEmptySpin {w}
		method formFieldResize {w sepW y typeToSwitch}
	}
}

body DataEditor::transferFormToGrid {} {
	set dataForm [getFormFrame]
	set dataGrid [getGridObject]

	set data [list]
	foreach child [winfo children [$dataForm getFrame]] {
		if {[winfo exists $child.edit.e]} {
			set cls [winfo class $child.edit.e]
			set colName [string range [$child cget -text] 1 end-1]
			set numericType 0
			switch -- $cls {
				"Spinbox" - "TSpinbox" {
					set val [$child.edit.e get]
					set numericType 1
				}
				"Text" {
					set val [$child.edit.e get 1.0 "end -1 chars"]
				}
				"BlobEditPanel" {
					set val [$child.edit.e get]
				}
				"TLabel" {
					set val [$child.edit.e cget -text]
				}
				default {
					error "Unknown class in form view: $cls"
				}
			}
			if {[info exists val]} {
				lappend data [list $val $dataEditorCheckState($colName:null)] $colName $numericType
				unset val
			}
		}
	}

	set gridData [$this getSelectedRowDataWithNull false]

	set dataLength [llength $data]
	set gridDataLength [llength $gridData]
	if {$dataLength != ($gridDataLength * 3)} {
		# This happens when dataeditor is asked if it can be closed multiple times (for example by eventloop),
		# but the grid already deleted its columns.
		debug "$this: dataLength != (gridDataLength * 3) -> $dataLength != ($gridDataLength * 3)"
		return
	}

	set changedColumns [list]
	foreach {formVal colName numType} $data gridCellVal $gridData {
		lassign $gridCellVal v2 v2null
		lassign $formVal v1 v1null
		if {$v1null || $v2null} {
			if {!($v1null && $v2null)} {
				# One of values is null, but not both
				lappend changedColumns $colName
			}
		} elseif {![string equal $v1 $v2]} {
			lappend changedColumns $colName
		}
	}
	if {[llength $changedColumns] == 0} return

	set cols [$dataGrid getColumns true]
	set it [$dataGrid getSelectedRow]
	if {$it != ""} {
		foreach {val colName numType} $data gridVal $gridData gridCol $cols {
			lassign $gridCol col colName2 colType
			if {$colName in $changedColumns} {
				$dataGrid setCellDataWithNull $it $col $val
				$dataGrid markForCommit $it $col "edit" $val $gridVal
			}
		}
	} else {
		set rowData [list]
		foreach {val colName numType} $data {
			lappend rowData $val
		}
		$dataGrid setSelectedRowData $rowData
		$dataGrid markForCommit $it "" "new" $rowData ""
	}
}

body DataEditor::formEditModifiedFlagProxy {} {
	if {$_disableModifyFlagDetection} {
		return 1
	}
	set _formViewModified 1
	updateFormViewToolbar
	return 1
}

body DataEditor::fillForm {{fromScratch true}} {
	set dataForm [getFormFrame]
	set dataGrid [getGridObject]

	if {!$_needToRecreateForm} {
		return
	}
	set _needToRecreateForm 0

	if {[$dataGrid isSelectedRowNew]} {
		set rowData [$dataGrid getSelectedRowDataWithNull]
	} else {
		set rowData [$this getSelectedRowDataWithNull false]
	}
	if {$rowData == ""} {
		$dataForm reset
		return
	}
	lassign [$dataGrid getSelectedCell] it col

	if {$fromScratch} {
		$dataForm reset
		array set _dataEditorWidget {}
	}
	array set dataEditorCheckState {}

	set _disableModifyFlagDetection 1

	set f [$dataForm getFrame]
	set i 0
	set widgetsList [list] ;# List of form widgets for Tab focus order.
	foreach c [$dataGrid getColumnsAsDisplayed true] el $rowData column [$dataGrid getColumns true] {
		set v [lindex $el 0]
		set isnull [lindex $el 1]
		if {$isnull} {
			set v ""
		}
		lassign $column col colText colType
		set editable [$dataGrid isEditPossible $it $col]
		set colName [lindex $c 1]

		set dataEditorCheckState($colName:null) $isnull

		# Field name
		set typeToSwitch [string tolower [lindex $c 2]]
		if {$fromScratch} {
			set w [ttk::labelframe $f.$i -text " $colName "]

			# If this is rownum field, we don't want "NULL value" here
			if {$typeToSwitch != "rownum"} {
				set cmd [list [list $this formEditModifiedFlagProxy]]
				lappend cmd [list $this updateNullState $colName]
				pack [ttk::frame $w.nullframe] -side top -fill x
				set _dataEditorWidget($colName:null) [ttk::checkbutton $w.nullframe.cb -text [mc {NULL value}] \
					-variable [scope dataEditorCheckState]($colName:null) -takefocus 0 -command [join $cmd ";"]]
				pack $_dataEditorWidget($colName:null) -side left

				helpHint $_dataEditorWidget($colName:null) [mc {You can use '%s' keyboard shortcut to switch NULL value.} ${::Shortcuts::setNullInForm}]
			}

			pack [ttk::frame $w.edit] -side top -fill both -expand 1
			lappend widgetsList $w.edit.e
		} else {
			set w $f.$i
			$w configure -text " $colName "
			if {!$dataEditorCheckState($colName:null)} {
				updateNullState $colName
			}
		}

		# Separator for resizing
		if {$fromScratch} {
			set sepW [ttk::frame $f.${i}_sepFrame -cursor sb_v_double_arrow]
			pack [ttk::separator $sepW.sep -orient horizontal] -side top -fill x -pady 3
			bind $sepW <B1-Motion> [list $this formFieldResize $w $sepW %y $typeToSwitch]
			bind $sepW.sep <B1-Motion> [list $this formFieldResize $w $sepW %y $typeToSwitch]
		} else {
			set sepW $f.${i}_sepFrame
		}

		if {$typeToSwitch != "rownum"} {
			# Field state
			$_dataEditorWidget($colName:null) configure -state [expr {$editable ? "normal" : "disabled"}]
		}

		# Data fields
		switch -- $typeToSwitch {
			"rownum" {
				if {$fromScratch} {
					set _dataEditorWidget($colName) [ttk::label $w.edit.e -text $v]
					pack $w.edit.e -side left -padx 5 -pady 2
				} else {
					$w.edit.e configure -text $v
				}
			}
			"numeric" - "real" - "integer" - "int" {
				if {$fromScratch} {
					set _dataEditorWidget($colName) [ttk::spinbox $w.edit.e -increment 1 -from -999999999999999 \
						-to 999999999999999 -validate key -validatecommand "$this formEditModifiedFlagProxy" \
						-command "$this handleEmptySpin $w.edit.e; $this formEditModifiedFlagProxy"]
					if {$::ttk::currentTheme == "vista"} { ;# fix for vista theme to left-align spinbox in formview
						$w.edit.e configure -style TSpinboxLeftAligned
					}
					pack $w.edit.e -side left -fill x -padx 2 -pady 2 -expand 1

					bind $w.edit.e <${::Shortcuts::commitFormView}> "$this commitFormEdit; break"
					bind $w.edit.e <${::Shortcuts::rollbackFormView}> "$this rollbackFormEdit; break"
					bind $w.edit.e <${::Shortcuts::insertRow}> "$this addRowInFormView; break"
					bind $w.edit.e <Escape> "$this rollbackFormEdit; break"
					bind $w.edit.e <${::Shortcuts::setNullInForm}> "$this switchNull $colName; break"
					bind $w.edit.e <${::Shortcuts::formViewFirstRow}> "$this formFirstRow; break"
					bind $w.edit.e <${::Shortcuts::formViewPrevRow}> "$this formPrevRow; break"
					bind $w.edit.e <${::Shortcuts::formViewNextRow}> "$this formNextRow; break"
					bind $w.edit.e <${::Shortcuts::formViewLastRow}> "$this formLastRow; break"
				}
				$w.edit.e set $v
				$w.edit.e configure -state [expr {$editable ? "normal" : "disabled"}]
			}
			"blob" {
				if {$fromScratch} {
					set _dataEditorWidget($colName) [BlobEditPanel $w.edit.e -value $v -modifycmd "$this formEditModifiedFlagProxy" -textheight 3]
					pack $w.edit.e -side left -fill both -padx 2 -pady 2 -expand 1

					$w.edit.e bindEdits <${::Shortcuts::commitFormView}> "$this commitFormEdit; break"
					$w.edit.e bindEdits <${::Shortcuts::rollbackFormView}> "$this rollbackFormEdit; break"
					$w.edit.e bindEdits <${::Shortcuts::insertRow}> "$this addRowInFormView; break"
					$w.edit.e bindEdits <Escape> "$this rollbackFormEdit; break"
					$w.edit.e bindEdits <${::Shortcuts::setNullInForm}> "$this switchNull $colName; break"
					$w.edit.e bindEdits <${::Shortcuts::formViewFirstRow}> "$this formFirstRow; break"
					$w.edit.e bindEdits <${::Shortcuts::formViewPrevRow}> "$this formPrevRow; break"
					$w.edit.e bindEdits <${::Shortcuts::formViewNextRow}> "$this formNextRow; break"
					$w.edit.e bindEdits <${::Shortcuts::formViewLastRow}> "$this formLastRow; break"
				} else {
					$w.edit.e setValue $v
				}
				$w.edit.e setModified false
				$w.edit.e setReadOnly [expr {!$editable}]
			}
			default {
				if {$fromScratch} {
					set _dataEditorWidget($colName) [text $w.edit.e -background ${::SQLEditor::background_color} \
						-foreground ${::SQLEditor::foreground_color} \
						-insertborderwidth 1 -selectbackground ${::SQLEditor::selected_background} -borderwidth 1 \
						-selectforeground ${::SQLEditor::selected_foreground} -insertontime 500 -insertofftime 500 \
						-font ${::SQLEditor::font} -selectborderwidth 0 -wrap char -undo true -width 60 -height 3 \
						-yscrollcommand "$w.edit.s set"]
					bind $w.edit.e <<Modified>> "$this formEditModifiedFlagProxy"
					pack $w.edit.e -side left -fill both -padx 2 -pady 2 -expand 1
					ttk::scrollbar $w.edit.s -orient v -command "$w.edit.e yview"
					pack $w.edit.s -side right -fill y
					::autoscroll::autoscroll $w.edit.s
					$w.edit.e insert end $v

					bind $w.edit.e <${::Shortcuts::commitFormView}> "$this commitFormEdit; break"
					bind $w.edit.e <${::Shortcuts::rollbackFormView}> "$this rollbackFormEdit; break"
					bind $w.edit.e <${::Shortcuts::insertRow}> "$this addRowInFormView; break"
					bind $w.edit.e <Escape> "$this rollbackFormEdit; break"
					bind $w.edit.e <${::Shortcuts::setNullInForm}> "$this switchNull $colName; break"
					bind $w.edit.e <${::Shortcuts::formViewFirstRow}> "$this formFirstRow; break"
					bind $w.edit.e <${::Shortcuts::formViewPrevRow}> "$this formPrevRow; break"
					bind $w.edit.e <${::Shortcuts::formViewNextRow}> "$this formNextRow; break"
					bind $w.edit.e <${::Shortcuts::formViewLastRow}> "$this formLastRow; break"
					attachStdContextMenu $w.edit.e
				} else {
					$w.edit.e delete 1.0 end
					$w.edit.e insert end $v
				}
				$w.edit.e edit modified false
				$w.edit.e configure -state [expr {$editable ? "normal" : "disabled"}]
			}
		}
		if {$fromScratch} {
			pack $w -side top -fill both -pady 10 -expand 1
			pack $sepW -side top -fill x;# -ipady 3
		}
		if {$editable} {
			updateNullState $colName
		}
		incr i
	}

	if {$fromScratch} {
		pack [ttk::frame $f.$i] -side top -fill x -ipady 6
		$dataForm makeChildsScrollable
	}

	set widgetsList [lreplace $widgetsList 0 0]
	set lgt [llength $widgetsList]
	for {set i 0} {$i < $lgt} {incr i} {
		set widget [lindex $widgetsList $i]
		set nextWidget [lindex $widgetsList [expr {$i+1}]]
		set prevWidget [lindex $widgetsList [expr {$i-1}]]
		set cls [winfo class $widget]
		switch -- $cls {
			"Text" {
				bind $widget <Tab> "[list $this handleTabKey $cls $widget $nextWidget]; break"
				if {$prevWidget != ""} {
					set parent [winfo parent [winfo parent $prevWidget]]
					bind $widget <<PrevWindow>> "focus $prevWidget; $this seeFormWidget $parent; break"
				} else {
					bind $widget <<PrevWindow>> "break"
				}
				bind $widget <${::Shortcuts::prevSubTab}> "$this prevDataTab; break"
				bind $widget <${::Shortcuts::nextSubTab}> "$this nextDataTab; break"
			}
			"BlobEditPanel" {
				$widget bindEdits <Tab> "[list $this handleTabKey $cls $widget $nextWidget]; break"
				if {$prevWidget != ""} {
					set parent [winfo parent [winfo parent $prevWidget]]
					$widget bindEdits <<PrevWindow>> "focus $prevWidget; $this seeFormWidget $parent; break"
				} else {
					$widget bindEdits <<PrevWindow>> "break"
				}
				$widget bindEdits <${::Shortcuts::prevSubTab}> "$this prevDataTab; break"
				$widget bindEdits <${::Shortcuts::nextSubTab}> "$this nextDataTab; break"
			}
			"TSpinbox" {
				bind $widget <${::Shortcuts::prevSubTab}> "$this prevDataTab; break"
				bind $widget <${::Shortcuts::nextSubTab}> "$this nextDataTab; break"
			}
		}
	}

	if {[llength $widgetsList] >= 1} {
		focus [lindex $widgetsList 0]
	}

	set _formViewModified 0
	set _disableModifyFlagDetection 0
	updateFormViewToolbar
}

body DataEditor::switchNull {colName} {
	set dataEditorCheckState($colName:null) [expr {!$dataEditorCheckState($colName:null)}]
	formEditModifiedFlagProxy
	updateNullState $colName
}

body DataEditor::updateNullState {colName} {
	set w $_dataEditorWidget($colName)
	set null $dataEditorCheckState($colName:null)

	set cls [winfo class $w]
	switch -- $cls {
		"BlobEditPanel" {
			$w setDisabled $null
		}
		"Text" {
			if {$null} {
				$w configure -foreground $::DISABLED_FONT_COLOR -state disabled
			} else {
				$w configure -foreground ${::SQLEditor::foreground_color} -state normal
			}
		}
		default {
			$w configure -state [expr {$null ? "disabled" : "normal"}]
		}
	}
}

body DataEditor::handleTabKey {cls widget nextWidget} {
	if {$useTabToJump} {
		if {$nextWidget != ""} {
			set parent [winfo parent [winfo parent $nextWidget]]
		}
		switch -- $cls {
			"Text" {
				if {$nextWidget != ""} {
					focus $nextWidget
					$this seeFormWidget $parent
				}
			}
			"BlobEditPanel" {
				if {$nextWidget != ""} {
					focus $nextWidget
					$this seeFormWidget $parent
				}
			}
		}
	} else {
		[focus] insert insert "\t"
	}
}

body DataEditor::focusFirstFormWidget {} {
	set dataForm [getFormFrame]
	set f [$dataForm getFrame]
	set w "${f}.1.edit.e"
	if {[winfo exists $w]} {
		focus $w
	}
}

body DataEditor::markToFillForm {} {
	set _needToRecreateForm 1
	updateFormViewToolbar
}


body DataEditor::commitFormEdit {} {
	if {$_commitFormInProgress} return
	set _commitFormInProgress 1

	if {[catch {
		set dataGrid [getGridObject]
		transferFormToGrid
		markToFillForm
		commitGrid [list [list [$dataGrid getSelectedRow] ""]]
		fillForm false
	} err]} {
		set _commitFormInProgress 0
		error $err
	}
	set _commitFormInProgress 0
}

body DataEditor::rollbackFormEdit {} {
	if {$_commitFormInProgress} return
	set _commitFormInProgress 1

	if {[catch {
		set dataGrid [getGridObject]
		if {[$dataGrid count] == 0} {
			$dataForm reset
		}
		markToFillForm
		rollbackGrid [list [list [$dataGrid getSelectedRow] ""]]
		fillForm false
	} err]} {
		set _commitFormInProgress 0
		error $err
	}
	set _commitFormInProgress 0
}

body DataEditor::focusDataTab {} {
	set dataTabs [getDataTabs]
	set dataGrid [getGridObject]
	set dataForm [getFormFrame]
	switch -glob -- [$dataTabs select] {
		"*form*" - "*t2*" {
			if {[$dataGrid count] == 0} {
				$dataForm reset
				markToFillForm
			} else {
				set f [$dataForm getFrame]
				focus $f
				fillForm
				if {[winfo exists [$dataForm getFrame].1]} {
					focus [$dataForm getFrame].1.edit.e
				}
			}
		}
		"*grid*" - "*t1*" {
			set grid [$dataGrid getWidget]
			focus $grid
			$dataGrid setSelection
		}
		"*text*" - "*t3*" {
			focus [$dataTabs.t3.text getEdit]
		}
	}
}

body DataEditor::commitGrid {{itColList ""}} {
	if {$_commitInProgress} return
	set _commitInProgress 1

	set dataGrid [getGridObject]
	if {[$dataGrid isEditing]} {
		$dataGrid commitEdit
		set _commitInProgress 0
		$this updateEditorToolbar
		return
	}

	if {[catch {
		$dataGrid commitAll $itColList
		markToFillForm
	} err]} {
		append err "\nStack 1:\n$::errorInfo"
		set _commitInProgress 0
		error $err
	}
	set _commitInProgress 0
}

body DataEditor::rollbackGrid {{itColList ""}} {
	if {$_commitInProgress} return
	set _commitInProgress 1

	set dataGrid [getGridObject]
	if {[$dataGrid isEditing]} {
		$dataGrid rollbackEdit
		set _commitInProgress 0
		$this updateEditorToolbar
		return
	}

	if {[catch {
		$dataGrid rollbackAll $itColList
		markToFillForm
	} err]} {
		append err "\nStack 1:\n$::errorInfo"
		set _commitInProgress 0
		error $err
	}
	set _commitInProgress 0
}

body DataEditor::seeFormWidget {widget} {
	set dataForm [getFormFrame]
	$dataForm see $widget
}

body DataEditor::canDestroy {} {
	if {$_noUpdates} {
		return true
	}

	set dataTabs [getDataTabs]
	set tab [$dataTabs select]
	if {[string match "*form*" $tab] || [string match "*t2*" $tab]} {
		transferFormToGrid
	}
	set dataGrid [getGridObject]
	if {[$dataGrid areTherePendingCommits]} {
		set dialog [YesNoDialog .yesno -title [mc {Pending commits}] -message [mc "There are uncommited rows.\nAre you sure you want to close '%s' window anywy?" [$this getTitle]]]
		if {[$dialog exec]} {
			return true
		} else {
			return false
		}
	} else {
		return true
	}
}

body DataEditor::handleEmptySpin {w} {
	if {[$w get] == -999999999999999} {
		$w set 0
	}
}

body DataEditor::formFieldResize {w sepW y typeToSwitch} {
	if {![winfo exists _formFieldMinHeight]} {
		pack propagate $w false
		set wH [winfo height $w]
		switch -- $typeToSwitch {
			"rownum" - "numeric" - "real" - "integer" - "int" {
				set _formFieldMinHeight $wH
				set _formFieldMaxHeight $wH
			}
			"blob" {
				set _formFieldMinHeight 130
				set _formFieldMaxHeight 99999
			}
			default {
				set _formFieldMinHeight 100
				set _formFieldMaxHeight 99999
			}
		}
	}
	
	if {[winfo class $w] == "TSeparator"} {
		incr y 3
	}
	
	set wY [winfo y $w]
	set sepY [winfo y $sepW]
	set newH [expr {$sepY + $y - $wY - 14}]
	if {$newH < $_formFieldMinHeight || $newH > $_formFieldMaxHeight} return

	$w configure -height $newH
	#update idletasks ;# doesn't seem to be necessary
}
