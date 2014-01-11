use src/common/modal.tcl
use src/common/ui_state_handler.tcl

class ColumnDialog {
	inherit Modal UiStateHandler

	constructor {args} {
		Modal::constructor {*}$args -modal 1
	} {}
	destructor {}

	private {
		method createColumn {}
		method createColumnConstraints {}
	}

	protected {
		variable _db ""
		variable _tableDialog ""
		variable _colGrid ""
		variable _sqliteVersion 3
		variable _model ""
		variable _widget
		variable _pkConfig ""
		variable _fkConfig ""
		variable _uniqConfig ""
		variable _chkConfig ""
		variable _notnullConfig ""
		variable _collateConfig ""
		variable _defaultConfig ""
		variable _pk "" ;# model object
		variable _fk "" ;# model object
		variable _uniq "" ;# model object
		variable _chk "" ;# model object
		variable _notnull "" ;# model object
		variable _collate "" ;# model object
		variable _default "" ;# model object

		method createPkConfiguration {}
		method createFkConfiguration {}
		method createUniqConfiguration {}
		method createChkConfiguration {}
		method createNotNullConfiguration {}
		method createCollateConfiguration {}
		method createDefaultConfiguration {}

		method parseInputModel {}
		method storeInModel {}
		method validate {}
	}

	public {
		variable uiVar

		method updatePkUiState {}
		method refreshPk {}
		method showPkConfiguration {}
		method pkToModel {}
		method validatePk {{skipWarnings false}}

		method updateFkUiState {}
		method refreshFk {}
		method showFkConfiguration {}
		method fkToModel {}
		method validateFk {{skipWarnings false}}
		method updateFkColumns {}

		method updateUniqUiState {}
		method refreshUniq {}
		method showUniqConfiguration {}
		method uniqToModel {}
		method validateUniq {{skipWarnings false}}

		method updateChkUiState {}
		method refreshChk {}
		method showChkConfiguration {}
		method chkToModel {}
		method validateChk {{skipWarnings false}}

		method updateNotNullUiState {}
		method refreshNotNull {}
		method showNotNullConfiguration {}
		method notNullToModel {}
		method validateNotNull {{skipWarnings false}}

		method updateCollateUiState {}
		method refreshCollate {}
		method showCollateConfiguration {}
		method collateToModel {}
		method validateCollate {{skipWarnings false}}

		method updateDefaultUiState {}
		method refreshDefault {}
		method showDefaultConfiguration {}
		method defaultToModel {}
		method validateDefault {{skipWarnings false}}

		method okClicked {}
		method grabWidget {}
		method updateUiState {}
		method refreshGrab {{w ""}}
	}
}

#>
# @class TableDialogColumnModel
# Container for columns in {@class TableDialog}
#<
class TableDialogColumnModel {
	public {
		variable fromInput 0
		variable oldName ""

		variable name ""
		variable type ""
		variable size ""
		variable precision ""
		#variable columnCollate 0
		#variable columnCollationName ""
		#variable columnOrder ""


		variable pk 0
		variable pkNamed 0
		variable pkName ""
		variable pkOrder ""
		variable pkConflict ""
		variable pkAutoIncr 0

		variable notnull 0
		variable notnullNamed 0
		variable notnullName ""
		variable notnullConflict ""

		variable uniq 0
		variable uniqNamed 0
		variable uniqName ""
		variable uniqConflict ""

		variable check 0
		variable checkNamed 0
		variable checkName ""
		variable checkExpr ""
		variable checkConflict "" ;# sqlite 2 only

		variable default 0
		variable defaultNamed 0
		variable defaultName ""
		variable defaultValue ""
		variable defaultIsLiteral 0

		variable collate 0
		variable collateNamed 0
		variable collateName ""
		variable collationName ""

		variable fk 0
		variable fkNamed 0
		variable fkName ""
		variable fkTable ""
		variable fkColumn ""
		variable fkOnUpdate ""
		variable fkOnDelete ""
		variable fkMatch ""
		variable fkDeferrable ""
		variable fkInitially ""
	}
}

class ColumnDialogPk {
	public {
		variable named 0
		variable name ""
		variable order ""
		variable conflict ""
		variable autoincr 0 ;# only sqlite 3
	}
}

class ColumnDialogFk {
	public {
		variable named 0
		variable name ""
		variable foreignTable ""
		variable foreignColumn ""
		variable onDelete ""
		variable onUpdate ""
		variable match ""
		variable deferrable ""
		variable initially ""
	}
}

class ColumnDialogUniq {
	public {
		variable named 0
		variable name ""
		variable conflict ""
	}
}

class ColumnDialogChk {
	public {
		variable named 0
		variable name ""
		variable expr ""
		variable conflict "" ;# only sqlite 2
	}
}

class ColumnDialogNotNull {
	public {
		variable named 0
		variable name ""
		variable conflict ""
	}
}

class ColumnDialogCollate {
	public {
		variable named 0
		variable name ""
		variable collation ""
	}
}

class ColumnDialogDefault {
	public {
		variable named 0
		variable name ""
		variable expr ""
		variable isLiteralValue 0
	}
}

body ColumnDialog::constructor {args} {
	parseArgs {
		-db {set _db $value}
		-model {set _model $value}
		-tabledialog {set _tableDialog $value}
	}

	if {[$_db getHandler] == "::Sqlite3"} {
		set _sqliteVersion 3
	} else {
		set _sqliteVersion 2
	}

	#
	# Main part
	#
	set top [ttk::frame $_root.top]
	pack $top -side top -fill both -padx 3 -pady 5 -expand 1

	ttk::labelframe $top.column -text [mc {Column:}]
	ttk::labelframe $top.const -text [mc {Column constraints:}]

	pack $top.column -side top -fill both -pady 3 -ipady 5 -ipadx 5
	pack $top.const -side top -fill both -pady 10

	# Essential contents of dialog
	createColumn
	createColumnConstraints

	#
	# Bottom buttons
	#
	set bottom [ttk::frame $_root.bottom]

	# Ok button
	ttk::button $bottom.ok -text [mc {Add}] -command "$this clicked ok" -compound left -image img_ok
	pack $bottom.ok -side left

	if {$_model != ""} {
		$bottom.ok configure -text [mc {Change}]
	}


	# Cancel button
	ttk::button $bottom.cancel -text [mc {Cancel}] -image img_cancel -compound left -command "$this clicked cancel"
	pack $bottom.cancel -side right

	pack $_root.bottom -side bottom -fill x -padx 3 -pady 3 -expand 1

	# Model
	set _pk [ColumnDialogPk ::#auto]
	set _fk [ColumnDialogFk ::#auto]
	set _uniq [ColumnDialogUniq ::#auto]
	set _chk [ColumnDialogChk ::#auto]
	set _notnull [ColumnDialogNotNull ::#auto]
	set _collate [ColumnDialogCollate ::#auto]
	set _default [ColumnDialogDefault ::#auto]
	if {$_model != ""} {
		parseInputModel
	}

	updateUiState
	after idle [list $_widget(name) icursor end]
}

body ColumnDialog::destructor {} {
	destroy $_pkConfig
	destroy $_fkConfig
	destroy $_uniqConfig
	destroy $_chkConfig
	destroy $_notnullConfig
	destroy $_collateConfig
	destroy $_defaultConfig
}

body ColumnDialog::refreshGrab {{w ""}} {
	if {$w == "" || [string first "." $w 1] == -1} {
		Modal::refreshGrab
	}
}

body ColumnDialog::createColumn {} {
	upvar top top

	set col $top.column

	foreach {p label widget} [list \
		name [mc {Column name}] ttk::entry \
		type [mc {Data type}] ttk::combobox \
		size [mc {Size}] ttk::frame
	] {
		ttk::frame $col.$p
		ttk::label $col.$p.label -text $label -justify left
		set _widget($p) [$widget $col.$p.edit]
		pack $col.$p.label -side top -fill x -expand 1
		pack $col.$p.edit -side bottom -fill x
	}

	pack $col.name -side left -fill x -expand 1 -padx 3
	pack $col.size -side right -padx 3
	pack $col.type -side right -padx 3

	set uiVar(name) ""
	$col.name.edit configure -textvariable [scope uiVar(name)]

	# Size frame
	set uiVar(size:max) ""
	set uiVar(size:precision) ""
	ttk::entry $col.size.edit.max -width 4 -textvariable [scope uiVar(size:max)]
	ttk::entry $col.size.edit.prec -width 4 -textvariable [scope uiVar(size:precision)]
	ttk::label $col.size.edit.sep -text ","
	pack $col.size.edit.max $col.size.edit.sep $col.size.edit.prec -side left
	helpHint $col.size.edit.max [mc {Maximal length of value in column.}]

	set uiVar(type) ""
	$col.type.edit configure -values $::dataTypes -textvariable [scope uiVar(type)]
	acCombo $col.type.edit
}

body ColumnDialog::createColumnConstraints {} {
	upvar top top

	set widgets [list]
	set inFrame [ttk::frame $top.const.inner_frame]
	foreach {w img text cmd forSqlite3} [list \
		pk img_constr_pk [mc {Primary key}] "$this showPkConfiguration" 0 \
		fk img_fk_col [mc {Foreign key}] "$this showFkConfiguration" 1 \
		uniq img_constr_uniq [mc {Unique}] "$this showUniqConfiguration" 0 \
		chk img_constr_check [mc {Check condition}] "$this showChkConfiguration" 0 \
		notnull img_constr_notnull [mc {Not NULL}] "$this showNotNullConfiguration" 0 \
		collate img_constr_collate [mc {Collate}] "$this showCollateConfiguration" 1 \
		default img_constr_default [mc {Default value}] "$this showDefaultConfiguration" 0 \
	] {
		if {$_sqliteVersion == 2 && $forSqlite3} continue

		set f $inFrame.$w
		ttk::frame $f
		label $f.img -image $img
		set uiVar($w) 0
		ttk::checkbutton $f.check -text $text -variable [scope uiVar]($w) -command "$this updateUiState"
		set _widget($w) [ttk::button $f.config -image img_small_more_opts -text [mc {Configure}] -compound right -command $cmd]
		pack $f.img -side left
		pack $f.check -side left -fill x -expand 1
		pack $f.config -side right -padx 3
		lappend widgets $f
	}

	# Pack all of them
	pack $inFrame -fill x -pady 5
	pack {*}$widgets -side top -fill x -padx 2 -pady 2

	createPkConfiguration
	if {$_sqliteVersion == 3} {
		createFkConfiguration
	}
	createUniqConfiguration
	createChkConfiguration
	createNotNullConfiguration
	if {$_sqliteVersion == 3} {
		createCollateConfiguration
	}
	createDefaultConfiguration
}

body ColumnDialog::okClicked {} {
	set closeWhenOkClicked 1
	if {[validate]} {
		set closeWhenOkClicked 0
		return ""
	}
	storeInModel
	return $_model
}

body ColumnDialog::grabWidget {} {
	return $_widget(name)
}

body ColumnDialog::updateUiState {} {
	# Constrain configuration buttons
	foreach type {pk fk uniq chk chk notnull collate default} {
		if {$type in [list fk collate] && $_sqliteVersion == 2} continue
		$_widget($type) configure -state [expr {$uiVar($type) ? "normal" : "disabled"}]
	}
}

##################################################### PK ##################################################

body ColumnDialog::updatePkUiState {} {
	$_widget(pkConstrName) configure -state [expr {$uiVar(pkNamed) ? "normal" : "disabled"}]
}

body ColumnDialog::refreshPk {} {
	set uiVar(pkNamed) [$_pk cget -named]
	set uiVar(pkName) [$_pk cget -name]
	set uiVar(pkAutoIncr) [$_pk cget -autoincr]
	set uiVar(pkOrder) [$_pk cget -order]
	set uiVar(pkConflict) [$_pk cget -conflict]
}

body ColumnDialog::showPkConfiguration {} {
	refreshPk
	updatePkUiState
	wm transient $_widget(pkConfig) $path
	wcenterby $_widget(pkConfig) $path ;# this also does the [wm deiconify]
	focus $path
	grab $_widget(pkConfig)
}

body ColumnDialog::pkToModel {} {
	$_pk configure \
		-named $uiVar(pkNamed) \
		-name $uiVar(pkName) \
		-autoincr $uiVar(pkAutoIncr) \
		-order $uiVar(pkOrder) \
		-conflict $uiVar(pkConflict)
}

body ColumnDialog::validatePk {{skipWarnings false}} {
	if {$uiVar(pkNamed) && $uiVar(pkName) == ""} {
		if {!$skipWarnings} {
			Error [mc {Constraint is marked as being named, but there's no name filled in.}]
		}
		return 1
	}
	return 0
}

body ColumnDialog::createPkConfiguration {} {
	# Create
	set _pkConfig [toplevel .columnPkConfig -background black]
	wm withdraw $_pkConfig
	wm title $_pkConfig [mc {Primary key configuration}]
	set _widget(pkConfig) $_pkConfig
	set main [ttk::frame $_pkConfig.fr]
	pack $main -fill both -expand 1;# -padx 1 -pady 1

	# AutoIncr
	if {$_sqliteVersion == 3} {
		ttk::frame $main.autoincr
		ttk::checkbutton $main.autoincr.lab -text [mc {Autoincrement}] -variable [scope uiVar(pkAutoIncr)]
		set uiVar(pkAutoIncr) 0
		pack $main.autoincr.lab -side left
		pack $main.autoincr -side top -fill x -padx 3 -pady 3
	}

	# Sort order
	ttk::frame $main.order
	ttk::label $main.order.lab -text [mc {Sort order:}]
	set uiVar(pkOrder) ""
	set _widget(pkOrder) [ttk::combobox $main.order.edit -width 12 -values [list "" "ASC" "DESC"] -textvariable [scope uiVar(pkOrder)] -state readonly]
	pack $main.order.lab -side left
	pack $main.order.edit -side right
	pack $main.order -side top -fill x -padx 3 -pady 3

	# Named constraint
	ttk::frame $main.name
	ttk::checkbutton $main.name.lab -text [mc {Named constraint:}] -variable [scope uiVar(pkNamed)] -command "$this updatePkUiState"
	set _widget(pkConstrName) [ttk::entry $main.name.edit -textvariable [scope uiVar(pkName)]]
	set uiVar(pkNamed) 0
	set uiVar(pkName) ""
	pack $main.name.lab -side left
	pack $main.name.edit -side right -fill x -expand 1
	pack $main.name -side top -fill x -padx 3 -pady 3

	# Conflict clause
	ttk::frame $main.conflict
	ttk::label $main.conflict.lab -text [mc {On conflict:}]
	set uiVar(pk:conflict) ""
	ttk::combobox $main.conflict.combo -width 12 -values [list "" "ABORT" "FAIL" "IGNORE" "REPLACE" "ROLLBACK"] -state readonly -textvariable [scope uiVar(pkConflict)]
	pack $main.conflict.combo -side right
	pack $main.conflict.lab -side left
	pack $main.conflict -side top -fill x -padx 3 -pady 3

	# MacOS X appearance fix
	if {[tk windowingsystem] == "aqua"} {
		ttk::frame $main.mac_bottom
		ttk::label $main.mac_bottom.l -text " "
		pack $main.mac_bottom.l -side top
		pack $main.mac_bottom -side bottom -fill x
	}

	# Bottom buttons
	ttk::frame $main.bottom
	ttk::button $main.bottom.ok -text [mc {Ok}] -image img_ok -compound left -command "
			if {!\[$this validatePk]} {
				wm withdraw $_pkConfig
				$this pkToModel
			}
		"
	ttk::button $main.bottom.cancel -text [mc {Cancel}] -image img_cancel -compound left -command "
		wm withdraw $_pkConfig
		$this refreshPk
	"
	pack $main.bottom.ok -side left -pady 3 -padx 2
	pack $main.bottom.cancel -side right -pady 3 -padx 2
	pack $main.bottom -side bottom -fill x

	# Handle closing window
	bind $_pkConfig <Unmap> "$this refreshGrab %W"
	bind $_pkConfig <Map> "grab $_widget(pkConfig)"
	wm protocol $_pkConfig WM_DELETE_WINDOW "wm withdraw $_pkConfig"

	# Other settings
	wm minsize $_pkConfig 300 50
}

##################################################### FK ##################################################

body ColumnDialog::updateFkUiState {} {
	$_widget(fkConstrName) configure -state [expr {$uiVar(fkNamed) ? "normal" : "disabled"}]

	$_widget(fkOnUpdate) configure -state [expr {$uiVar(fkOnUpdateEnabled) ? "readonly" : "disabled"}]
	$_widget(fkOnDelete) configure -state [expr {$uiVar(fkOnDeleteEnabled) ? "readonly" : "disabled"}]
	$_widget(fkMatch) configure -state [expr {$uiVar(fkMatchEnabled) ? "readonly" : "disabled"}]

	if {$uiVar(fkDeferred) == ""} {
		set uiVar(fkDeferredInitially) ""
	}
	$_widget(fkDeferredInitially) configure -state [expr {$uiVar(fkDeferred) != "" ? "readonly" : "disabled"}]
}

body ColumnDialog::refreshFk {} {
	set uiVar(fkNamed) [$_fk cget -named]
	set uiVar(fkName) [$_fk cget -name]
	set uiVar(fkTable) [$_fk cget -foreignTable]
	set uiVar(fkColumn) [$_fk cget -foreignColumn]
	set uiVar(fkOnUpdate) [$_fk cget -onUpdate]
	set uiVar(fkOnUpdateEnabled) [expr {$uiVar(fkOnUpdate) != ""}]
	set uiVar(fkOnDelete) [$_fk cget -onDelete]
	set uiVar(fkOnDeleteEnabled) [expr {$uiVar(fkOnDelete) != ""}]
	set uiVar(fkMatch) [$_fk cget -match]
	set uiVar(fkMatchEnabled) [expr {$uiVar(fkMatch) != ""}]
	set uiVar(fkDeferred) [$_fk cget -deferrable]
	set uiVar(fkDeferredInitially) [$_fk cget -initially]
}

body ColumnDialog::showFkConfiguration {} {
	refreshFk
	updateFkUiState
	wm transient $_widget(fkConfig) $path
	wcenterby $_widget(fkConfig) $path ;# this also does the [wm deiconify]
	focus $path
	grab $_widget(fkConfig)
}

body ColumnDialog::fkToModel {} {
	$_fk configure \
		-named $uiVar(fkNamed) \
		-name $uiVar(fkName) \
		-foreignTable $uiVar(fkTable) \
		-foreignColumn $uiVar(fkColumn) \
		-onUpdate [expr {$uiVar(fkOnUpdateEnabled) ? $uiVar(fkOnUpdate) : ""}] \
		-onDelete [expr {$uiVar(fkOnDeleteEnabled) ? $uiVar(fkOnDelete) : ""}] \
		-match [expr {$uiVar(fkMatchEnabled) ? $uiVar(fkMatch) : ""}] \
		-deferrable $uiVar(fkDeferred) \
		-initially $uiVar(fkDeferredInitially)
}

body ColumnDialog::validateFk {{skipWarnings false}} {
	if {$uiVar(fkTable) == ""} {
		if {!$skipWarnings} {
			Error [mc {No foreign table selected.}]
		}
		return 1
	}
	# It appears that FK is possible with no column selected.
# 	if {$uiVar(fkColumn) == ""} {
# 		if {!$skipWarnings} {
# 			Error [mc {No foreign column selected.}]
# 		}
# 		return 1
# 	}
	if {$uiVar(fkNamed) && $uiVar(fkName) == ""} {
		if {!$skipWarnings} {
			Error [mc {Constraint is marked as being named, but there's no name filled in.}]
		}
		return 1
	}
	if {$uiVar(fkOnUpdateEnabled) && $uiVar(fkOnUpdate) == ""} {
		if {!$skipWarnings} {
			Error [mc {Choose ON UPDATE action, or disable it.}]
		}
		return 1
	}
	if {$uiVar(fkOnDeleteEnabled) && $uiVar(fkOnDelete) == ""} {
		if {!$skipWarnings} {
			Error [mc {Choose ON DELETE action, or disable it.}]
		}
		return 1
	}
	if {$uiVar(fkMatchEnabled) && $uiVar(fkMatch) == ""} {
		if {!$skipWarnings} {
			Error [mc {Choose MATCH action, or disable it.}]
		}
		return 1
	}
	return 0
}

body ColumnDialog::updateFkColumns {} {
	$_widget(fkColumn) configure -values [$_db getColumns $uiVar(fkTable)]
	set uiVar(fkColumn) ""
}

body ColumnDialog::createFkConfiguration {} {
	# Create
	set _fkConfig [toplevel .columnFkConfig -background black]
	wm withdraw $_fkConfig
	wm title $_fkConfig [mc {Foreign key configuration}]
	set _widget(fkConfig) $_fkConfig
	set main [ttk::frame $_fkConfig.fr]
	pack $main -fill both -expand 1;# -padx 1 -pady 1

	# Foreign table
	set tables [$_db getTables]
	foreach table $tables {
		if {[string match "sqlite_*" $table]} {
			lremove tables $table
		}
	}

	ttk::frame $main.table
	ttk::label $main.table.lab -text [mc {Foreign table:}]
	set uiVar(fkTable) ""
	set _widget(fkTable) [ttk::combobox $main.table.edit -values $tables -textvariable [scope uiVar(fkTable)] -state readonly]
	pack $main.table.lab -side left
	pack $main.table.edit -side right -fill x -expand 1
	pack $main.table -side top -fill x -padx 3 -pady 3
	bind $_widget(fkTable) <<ComboboxSelected>> "$this updateFkColumns"

	# Foreign column
	ttk::frame $main.column
	ttk::label $main.column.lab -text [mc {Foreign column:}]
	set uiVar(fkColumn) ""
	set _widget(fkColumn) [ttk::combobox $main.column.edit -values [list] -textvariable [scope uiVar(fkColumn)] -state readonly]
	pack $main.column.lab -side left
	pack $main.column.edit -side right -fill x -expand 1
	pack $main.column -side top -fill x -padx 3 -pady 3

	# Grouped frames
	set globElementsPady 5

	# Actions
	ttk::labelframe $main.acts -text [mc {Reactions}]
	set reactions [list "NO ACTION" "SET NULL" "SET DEFAULT" "CASCADE" "RESTRICT"]

	set w $main.acts.onUpdate
	ttk::frame $w
	set uiVar(fkOnUpdateEnabled) 0
	ttk::checkbutton $w.enabled -text [mc {ON UPDATE}] -variable [scope uiVar(fkOnUpdateEnabled)] -command "$this updateFkUiState"
	set uiVar(fkOnUpdate) "NO ACTION"
	set _widget(fkOnUpdate) [ttk::combobox $w.reaction -values $reactions -textvariable [scope uiVar(fkOnUpdate)] -state readonly -width 12]
	pack $w.enabled -side left
	pack $w.reaction -side right
	pack $w -side top -fill x -padx 3 -pady 2

	set w $main.acts.onDelete
	ttk::frame $w
	set uiVar(fkOnDeleteEnabled) 0
	ttk::checkbutton $w.enabled -text [mc {ON DELETE}] -variable [scope uiVar(fkOnDeleteEnabled)] -command "$this updateFkUiState"
	set uiVar(fkOnDelete) "NO ACTION"
	set _widget(fkOnDelete) [ttk::combobox $w.reaction -values $reactions -textvariable [scope uiVar(fkOnDelete)] -state readonly -width 12]
	pack $w.enabled -side left
	pack $w.reaction -side right
	pack $w -side top -fill x -padx 3 -pady 2

	set w $main.acts.match
	ttk::frame $w
	set uiVar(fkMatchEnabled) 0
	ttk::checkbutton $w.enabled -text [mc {MATCH}] -variable [scope uiVar(fkMatchEnabled)] -command "$this updateFkUiState"
	set uiVar(fkMatch) ""
	set reactions [list "NONE" "PARTIAL" "FULL"]
	set uiVar(fkMatch) "NONE"
	set _widget(fkMatch) [ttk::combobox $w.reaction -values $reactions -textvariable [scope uiVar(fkMatch)] -state readonly -width 12]
	pack $w.enabled -side left
	pack $w.reaction -side right
	pack $w -side top -fill x -padx 3 -pady 2

	pack $main.acts -side top -fill x -pady $globElementsPady

	# Deferred
	ttk::labelframe $main.def -text [mc {Deferred foreign key}]

	set w $main.def.deferred
	set uiVar(fkDeferred) [lindex $::deferredValues 0]
	ttk::frame $w
	set _widget(fkDeferred) [ttk::combobox $w.list -values $::deferredValues -textvariable [scope uiVar(fkDeferred)] -state readonly -width 20]
	bind $_widget(fkDeferred) <<ComboboxSelected>> "$this updateFkUiState"
	pack $w.list -side left
	pack $w -side left -fill x -padx 3 -pady 2

	set w $main.def.initially
	set uiVar(fkDeferredInitially) [lindex $::deferredInitiallyValues 0]
	ttk::frame $w
	set _widget(fkDeferredInitially) [ttk::combobox $w.list -values $::deferredInitiallyValues -textvariable [scope uiVar(fkDeferredInitially)] -state readonly -width 20]
	bind $_widget(fkDeferredInitially) <<ComboboxSelected>> "$this updateFkUiState"
	pack $w.list -side left
	pack $w -side right -fill x -padx 3 -pady 2

	pack $main.def -side top -fill both -padx 2 -pady $globElementsPady

	# Named constraint
	ttk::frame $main.name
	ttk::checkbutton $main.name.lab -text [mc {Named constraint:}] -variable [scope uiVar(fkNamed)] -command "$this updateFkUiState"
	set _widget(fkConstrName) [ttk::entry $main.name.edit -textvariable [scope uiVar(fkName)]]
	set uiVar(fkNamed) 0
	set uiVar(fkName) ""
	pack $main.name.lab -side left
	pack $main.name.edit -side right -fill x -expand 1
	pack $main.name -side top -fill x -padx 3 -pady 3

	# MacOS X appearance fix
	if {[tk windowingsystem] == "aqua"} {
		ttk::frame $main.mac_bottom
		ttk::label $main.mac_bottom.l -text " "
		pack $main.mac_bottom.l -side top
		pack $main.mac_bottom -side bottom -fill x
	}

	# Bottom buttons
	ttk::frame $main.bottom
	ttk::button $main.bottom.ok -text [mc {Ok}] -image img_ok -compound left -command "
			if {!\[$this validateFk]} {
				wm withdraw $_fkConfig
				$this fkToModel
			}
		"
	ttk::button $main.bottom.cancel -text [mc {Cancel}] -image img_cancel -compound left -command "
		wm withdraw $_fkConfig
		$this refreshFk
	"
	pack $main.bottom.ok -side left -pady 3 -padx 2
	pack $main.bottom.cancel -side right -pady 3 -padx 2
	pack $main.bottom -side bottom -fill x

	# Handle closing window
	bind $_fkConfig <Unmap> "$this refreshGrab %W"
	bind $_fkConfig <Map> "grab $_widget(fkConfig)"
	wm protocol $_fkConfig WM_DELETE_WINDOW "wm withdraw $_fkConfig"

	# Other settings
	wm minsize $_fkConfig 300 50
}

#################################################### UNIQ #################################################

body ColumnDialog::updateUniqUiState {} {
	$_widget(uniqConstrName) configure -state [expr {$uiVar(uniqNamed) ? "normal" : "disabled"}]
}

body ColumnDialog::refreshUniq {} {
	set uiVar(uniqNamed) [$_uniq cget -named]
	set uiVar(uniqName) [$_uniq cget -name]
	set uiVar(uniqConflict) [$_uniq cget -conflict]
}

body ColumnDialog::showUniqConfiguration {} {
	refreshUniq
	updateUniqUiState
	wm transient $_widget(uniqConfig) $path
	wcenterby $_widget(uniqConfig) $path ;# this also does the [wm deiconify]
	focus $path
	grab $_widget(uniqConfig)
}

body ColumnDialog::uniqToModel {} {
	$_uniq configure \
		-named $uiVar(uniqNamed) \
		-name $uiVar(uniqName) \
		-conflict $uiVar(uniqConflict)
}

body ColumnDialog::validateUniq {{skipWarnings false}} {
	if {$uiVar(uniqNamed) && $uiVar(uniqName) == ""} {
		if {!$skipWarnings} {
			Error [mc {Constraint is marked as being named, but there's no name filled in.}]
		}
		return 1
	}
	return 0
}

body ColumnDialog::createUniqConfiguration {} {
	# Create
	set _uniqConfig [toplevel .columnUniqConfig -background black]
	wm withdraw $_uniqConfig
	wm title $_uniqConfig [mc {Unique configuration}]
	set _widget(uniqConfig) $_uniqConfig
	set main [ttk::frame $_uniqConfig.fr]
	pack $main -fill both -expand 1;# -padx 1 -pady 1

	# Named constraint
	ttk::frame $main.name
	ttk::checkbutton $main.name.lab -text [mc {Named constraint:}] -variable [scope uiVar(uniqNamed)] -command "$this updateUniqUiState"
	set _widget(uniqConstrName) [ttk::entry $main.name.edit -textvariable [scope uiVar(uniqName)]]
	set uiVar(uniqNamed) 0
	set uiVar(uniqName) ""
	pack $main.name.lab -side left
	pack $main.name.edit -side right -fill x -expand 1
	pack $main.name -side top -fill x -padx 3 -pady 3

	# Conflict clause
	ttk::frame $main.conflict
	ttk::label $main.conflict.lab -text [mc {On conflict:}]
	set uiVar(uniq:conflict) ""
	ttk::combobox $main.conflict.combo -width 12 -values [list "" "ABORT" "FAIL" "IGNORE" "REPLACE" "ROLLBACK"] -state readonly -textvariable [scope uiVar(uniqConflict)]
	pack $main.conflict.combo -side right
	pack $main.conflict.lab -side left
	pack $main.conflict -side top -fill x -padx 3 -pady 3

	# MacOS X appearance fix
	if {[tk windowingsystem] == "aqua"} {
		ttk::frame $main.mac_bottom
		ttk::label $main.mac_bottom.l -text " "
		pack $main.mac_bottom.l -side top
		pack $main.mac_bottom -side bottom -fill x
	}

	# Bottom buttons
	ttk::frame $main.bottom
	ttk::button $main.bottom.ok -text [mc {Ok}] -image img_ok -compound left -command "
			if {!\[$this validateUniq]} {
				wm withdraw $_uniqConfig
				$this uniqToModel
			}
		"
	ttk::button $main.bottom.cancel -text [mc {Cancel}] -image img_cancel -compound left -command "
		wm withdraw $_uniqConfig
		$this refreshUniq
	"
	pack $main.bottom.ok -side left -pady 3 -padx 2
	pack $main.bottom.cancel -side right -pady 3 -padx 2
	pack $main.bottom -side bottom -fill x

	# Handle closing window
	bind $_uniqConfig <Unmap> "$this refreshGrab %W"
	bind $_uniqConfig <Map> "grab $_widget(uniqConfig)"
	wm protocol $_uniqConfig WM_DELETE_WINDOW "wm withdraw $_uniqConfig"

	# Other settings
	wm minsize $_uniqConfig 300 50
}

#################################################### CHK ##################################################

body ColumnDialog::updateChkUiState {} {
	$_widget(chkConstrName) configure -state [expr {$uiVar(chkNamed) ? "normal" : "disabled"}]
}

body ColumnDialog::refreshChk {} {
	set uiVar(chkNamed) [$_chk cget -named]
	set uiVar(chkName) [$_chk cget -name]
	set uiVar(chkExpr) [$_chk cget -expr]
	set uiVar(chkConflict) [$_chk cget -conflict]
}

body ColumnDialog::showChkConfiguration {} {
	refreshChk
	updateChkUiState
	wm transient $_widget(chkConfig) $path
	wcenterby $_widget(chkConfig) $path ;# this also does the [wm deiconify]
	focus $path
	grab $_widget(chkConfig)
}

body ColumnDialog::chkToModel {} {
	$_chk configure \
		-named $uiVar(chkNamed) \
		-name $uiVar(chkName) \
		-expr $uiVar(chkExpr) \
		-conflict $uiVar(chkConflict)
}

body ColumnDialog::validateChk {{skipWarnings false}} {
	if {[string trim $uiVar(chkExpr)] == ""} {
		if {!$skipWarnings} {
			Error [mc {Fill in the condition expression.}]
		}
		return 1
	}
	if {$uiVar(chkNamed) && $uiVar(chkName) == ""} {
		if {!$skipWarnings} {
			Error [mc {Constraint is marked as being named, but there's no name filled in.}]
		}
		return 1
	}
	return 0
}

body ColumnDialog::createChkConfiguration {} {
	# Create
	set _chkConfig [toplevel .columnChkConfig -background black]
	wm withdraw $_chkConfig
	wm title $_chkConfig [mc {Check condition configuration}]
	set _widget(chkConfig) $_chkConfig
	set main [ttk::frame $_chkConfig.fr]
	pack $main -fill both -expand 1;# -padx 1 -pady 1

	# Expression
	ttk::frame $main.expr
	ttk::label $main.expr.lab -text [mc {Condition:}]
	set _widget(chkExpr) [ttk::entry $main.expr.edit -textvariable [scope uiVar(chkExpr)]]
	set uiVar(chkExpr) ""
	pack $main.expr.lab -side left
	pack $main.expr.edit -side right -fill x -expand 1
	pack $main.expr -side top -fill x -padx 3 -pady 3

	# Named constraint
	ttk::frame $main.name
	ttk::checkbutton $main.name.lab -text [mc {Named constraint:}] -variable [scope uiVar(chkNamed)] -command "$this updateChkUiState"
	set _widget(chkConstrName) [ttk::entry $main.name.edit -textvariable [scope uiVar(chkName)]]
	set uiVar(chkNamed) 0
	set uiVar(chkName) ""
	pack $main.name.lab -side left
	pack $main.name.edit -side right -fill x -expand 1
	pack $main.name -side top -fill x -padx 3 -pady 3

	# Conflict clause
	if {$_sqliteVersion == 2} {
		ttk::frame $main.conflict
		ttk::label $main.conflict.lab -text [mc {On conflict:}]
		set uiVar(chk:conflict) ""
		ttk::combobox $main.conflict.combo -width 12 -values [list "" "ABORT" "FAIL" "IGNORE" "REPLACE" "ROLLBACK"] -state readonly -textvariable [scope uiVar(chkConflict)]
		pack $main.conflict.combo -side right
		pack $main.conflict.lab -side left
		pack $main.conflict -side top -fill x -padx 3 -pady 3
	}

	# MacOS X appearance fix
	if {[tk windowingsystem] == "aqua"} {
		ttk::frame $main.mac_bottom
		ttk::label $main.mac_bottom.l -text " "
		pack $main.mac_bottom.l -side top
		pack $main.mac_bottom -side bottom -fill x
	}

	# Bottom buttons
	ttk::frame $main.bottom
	ttk::button $main.bottom.ok -text [mc {Ok}] -image img_ok -compound left -command "
			if {!\[$this validateChk]} {
				wm withdraw $_chkConfig
				$this chkToModel
			}
		"
	ttk::button $main.bottom.cancel -text [mc {Cancel}] -image img_cancel -compound left -command "
		wm withdraw $_chkConfig
		$this refreshChk
	"
	pack $main.bottom.ok -side left -pady 3 -padx 2
	pack $main.bottom.cancel -side right -pady 3 -padx 2
	pack $main.bottom -side bottom -fill x

	# Handle closing window
	bind $_chkConfig <Unmap> "$this refreshGrab %W"
	bind $_chkConfig <Map> "grab $_widget(chkConfig)"
	wm protocol $_chkConfig WM_DELETE_WINDOW "wm withdraw $_chkConfig"

	# Other settings
	wm minsize $_chkConfig 300 50
}

################################################## NOTNULL ################################################

body ColumnDialog::updateNotNullUiState {} {
	$_widget(notnullConstrName) configure -state [expr {$uiVar(notnullNamed) ? "normal" : "disabled"}]
}

body ColumnDialog::refreshNotNull {} {
	set uiVar(notnullNamed) [$_notnull cget -named]
	set uiVar(notnullName) [$_notnull cget -name]
	set uiVar(notnullConflict) [$_notnull cget -conflict]
}

body ColumnDialog::showNotNullConfiguration {} {
	refreshNotNull
	updateNotNullUiState
	wm transient $_widget(notnullConfig) $path
	wcenterby $_widget(notnullConfig) $path ;# this also does the [wm deiconify]
	focus $path
	grab $_widget(notnullConfig)
}

body ColumnDialog::notNullToModel {} {
	$_notnull configure \
		-named $uiVar(notnullNamed) \
		-name $uiVar(notnullName) \
		-conflict $uiVar(notnullConflict)
}

body ColumnDialog::validateNotNull {{skipWarnings false}} {
	if {$uiVar(notnullNamed) && $uiVar(notnullName) == ""} {
		if {!$skipWarnings} {
			Error [mc {Constraint is marked as being named, but there's no name filled in.}]
		}
		return 1
	}
	return 0
}

body ColumnDialog::createNotNullConfiguration {} {
	# Create
	set _notnullConfig [toplevel .columnNotnullConfig -background black]
	wm withdraw $_notnullConfig
	wm title $_notnullConfig [mc {Not null configuration}]
	set _widget(notnullConfig) $_notnullConfig
	set main [ttk::frame $_notnullConfig.fr]
	pack $main -fill both -expand 1;# -padx 1 -pady 1

	# Named constraint
	ttk::frame $main.name
	ttk::checkbutton $main.name.lab -text [mc {Named constraint:}] -variable [scope uiVar(notnullNamed)] -command "$this updateNotNullUiState"
	set _widget(notnullConstrName) [ttk::entry $main.name.edit -textvariable [scope uiVar(notnullName)]]
	set uiVar(notnullNamed) 0
	set uiVar(notnullName) ""
	pack $main.name.lab -side left
	pack $main.name.edit -side right -fill x -expand 1
	pack $main.name -side top -fill x -padx 3 -pady 3

	# Conflict clause
	ttk::frame $main.conflict
	ttk::label $main.conflict.lab -text [mc {On conflict:}]
	set uiVar(notnull:conflict) ""
	ttk::combobox $main.conflict.combo -width 12 -values [list "" "ABORT" "FAIL" "IGNORE" "REPLACE" "ROLLBACK"] -state readonly -textvariable [scope uiVar(notnullConflict)]
	pack $main.conflict.combo -side right
	pack $main.conflict.lab -side left
	pack $main.conflict -side top -fill x -padx 3 -pady 3

	# MacOS X appearance fix
	if {[tk windowingsystem] == "aqua"} {
		ttk::frame $main.mac_bottom
		ttk::label $main.mac_bottom.l -text " "
		pack $main.mac_bottom.l -side top
		pack $main.mac_bottom -side bottom -fill x
	}

	# Bottom buttons
	ttk::frame $main.bottom
	ttk::button $main.bottom.ok -text [mc {Ok}] -image img_ok -compound left -command "
			if {!\[$this validateNotNull]} {
				wm withdraw $_notnullConfig
				$this notNullToModel
			}
		"
	ttk::button $main.bottom.cancel -text [mc {Cancel}] -image img_cancel -compound left -command "
		wm withdraw $_notnullConfig
		$this refreshNotNull
	"
	pack $main.bottom.ok -side left -pady 3 -padx 2
	pack $main.bottom.cancel -side right -pady 3 -padx 2
	pack $main.bottom -side bottom -fill x

	# Handle closing window
	bind $_notnullConfig <Unmap> "$this refreshGrab %W"
	bind $_notnullConfig <Map> "grab $_widget(notnullConfig)"
	wm protocol $_notnullConfig WM_DELETE_WINDOW "wm withdraw $_notnullConfig"

	# Other settings
	wm minsize $_notnullConfig 300 50
}

################################################## COLLATE ################################################

body ColumnDialog::updateCollateUiState {} {
	$_widget(collateConstrName) configure -state [expr {$uiVar(collateNamed) ? "normal" : "disabled"}]
}

body ColumnDialog::refreshCollate {} {
	set uiVar(collateNamed) [$_collate cget -named]
	set uiVar(collateName) [$_collate cget -name]
	set uiVar(collateCollationName) [$_collate cget -collation]
}

body ColumnDialog::showCollateConfiguration {} {
	refreshCollate
	updateCollateUiState
	wm transient $_widget(collateConfig) $path
	wcenterby $_widget(collateConfig) $path ;# this also does the [wm deiconify]
	focus $path
	grab $_widget(collateConfig)
}

body ColumnDialog::collateToModel {} {
	$_collate configure \
		-named $uiVar(collateNamed) \
		-name $uiVar(collateName) \
		-collation $uiVar(collateCollationName)
}

body ColumnDialog::validateCollate {{skipWarnings false}} {
	if {[string trim $uiVar(collateCollationName)] == ""} {
		if {!$skipWarnings} {
			Error [mc {Fill in the collation name.}]
		}
		return 1
	}
	if {$uiVar(collateNamed) && $uiVar(collateName) == ""} {
		if {!$skipWarnings} {
			Error [mc {Constraint is marked as being named, but there's no name filled in.}]
		}
		return 1
	}
	return 0
}

body ColumnDialog::createCollateConfiguration {} {
	# Create
	set _collateConfig [toplevel .columnCollateConfig -background black]
	wm withdraw $_collateConfig
	wm title $_collateConfig [mc {Collating configuration}]
	set _widget(collateConfig) $_collateConfig
	set main [ttk::frame $_collateConfig.fr]
	pack $main -fill both -expand 1;# -padx 1 -pady 1

	# Collation name
	set collations [$_db getCollations]
	ttk::frame $main.collname
	ttk::label $main.collname.lab -text [mc {Collation name:}]
	set _widget(collateCollationName) [ttk::combobox $main.collname.edit -textvariable [scope uiVar(collateCollationName)] -values $collations]
	set uiVar(collateCollationName) ""
	pack $main.collname.lab -side left
	pack $main.collname.edit -side right -fill x -expand 1
	pack $main.collname -side top -fill x -padx 3 -pady 3

	# Named constraint
	ttk::frame $main.name
	ttk::checkbutton $main.name.lab -text [mc {Named constraint:}] -variable [scope uiVar(collateNamed)] -command "$this updateCollateUiState"
	set _widget(collateConstrName) [ttk::entry $main.name.edit -textvariable [scope uiVar(collateName)]]
	set uiVar(collateNamed) 0
	set uiVar(collateName) ""
	pack $main.name.lab -side left
	pack $main.name.edit -side right -fill x -expand 1
	pack $main.name -side top -fill x -padx 3 -pady 3

	# MacOS X appearance fix
	if {[tk windowingsystem] == "aqua"} {
		ttk::frame $main.mac_bottom
		ttk::label $main.mac_bottom.l -text " "
		pack $main.mac_bottom.l -side top
		pack $main.mac_bottom -side bottom -fill x
	}

	# Bottom buttons
	ttk::frame $main.bottom
	ttk::button $main.bottom.ok -text [mc {Ok}] -image img_ok -compound left -command "
			if {!\[$this validateCollate]} {
				wm withdraw $_collateConfig
				$this collateToModel
			}
		"
	ttk::button $main.bottom.cancel -text [mc {Cancel}] -image img_cancel -compound left -command "
		wm withdraw $_collateConfig
		$this refreshCollate
	"
	pack $main.bottom.ok -side left -pady 3 -padx 2
	pack $main.bottom.cancel -side right -pady 3 -padx 2
	pack $main.bottom -side bottom -fill x

	# Handle closing window
	bind $_collateConfig <Unmap> "$this refreshGrab %W"
	bind $_collateConfig <Map> "grab $_widget(collateConfig)"
	wm protocol $_collateConfig WM_DELETE_WINDOW "wm withdraw $_collateConfig"

	# Other settings
	wm minsize $_collateConfig 300 50
}

################################################## DEFAULT ################################################

body ColumnDialog::updateDefaultUiState {} {
	$_widget(defConstrName) configure -state [expr {$uiVar(defNamed) ? "normal" : "disabled"}]
}

body ColumnDialog::refreshDefault {} {
	set uiVar(defNamed) [$_default cget -named]
	set uiVar(defName) [$_default cget -name]
	set uiVar(defMode) [expr {[$_default cget -isLiteralValue] ? "literal" : "expr"}]
	$_widget(defValue) setContents [$_default cget -expr]
}

body ColumnDialog::showDefaultConfiguration {} {
	refreshDefault
	updateDefaultUiState
	wm transient $_widget(defaultConfig) $path
	wcenterby $_widget(defaultConfig) $path ;# this also does the [wm deiconify]
	focus $path
	grab $_widget(defaultConfig)
}

body ColumnDialog::defaultToModel {} {
	$_default configure \
		-named $uiVar(defNamed) \
		-name $uiVar(defName) \
		-expr [$_widget(defValue) getContents] \
		-isLiteralValue [expr {$uiVar(defMode) == "literal"}]
}

body ColumnDialog::validateDefault {{skipWarnings false}} {
# 	if {[string trim [$_widget(defValue) getContents]] == ""} {
# 		if {!$skipWarnings} {
# 			Error [mc {Fill in the default value.}]
# 		}
# 		return 1
# 	}
	if {$uiVar(defNamed) && $uiVar(defName) == ""} {
		if {!$skipWarnings} {
			Error [mc {Constraint is marked as being named, but there's no name filled in.}]
		}
		return 1
	}
	return 0
}

body ColumnDialog::createDefaultConfiguration {} {
	# Create
	set _defaultConfig [toplevel .columnDefaultConfig -background black]
	wm withdraw $_defaultConfig
	wm title $_defaultConfig [mc {Default value configuration}]
	set _widget(defaultConfig) $_defaultConfig
	set main [ttk::frame $_defaultConfig.fr]
	pack $main -fill both -expand 1;# -padx 1 -pady 1

	# Constraint name
	ttk::frame $main.defvalue
	ttk::label $main.defvalue.lab -text [mc {Default value:}]
	set _widget(defValue) [SQLEditor $main.defvalue.edit -selectionascontents false -height 3 -width 30]
	pack $main.defvalue.lab -side left
	pack $main.defvalue.edit -side right -fill x -expand 1
	pack $main.defvalue -side top -fill x -padx 3 -pady 3

	# Literal vs. Expression
	set uiVar(defMode) "literal"
	if {$_sqliteVersion == 3} {
		ttk::labelframe $main.mode -text [mc {Use value as:}]
		ttk::radiobutton $main.mode.literal -text [mc {A literal value}] -variable [scope uiVar(defMode)] -value "literal"
		ttk::radiobutton $main.mode.expr -text [mc {An expression}] -variable [scope uiVar(defMode)] -value "expr"
		pack $main.mode.literal -side top -fill x
		pack $main.mode.expr -side bottom -fill x
		pack $main.mode -side top -pady 3 -fill x -padx 5
	}

	# Named constraint
	ttk::frame $main.name
	ttk::checkbutton $main.name.lab -text [mc {Named constraint:}] -variable [scope uiVar(defNamed)] -command "$this updateDefaultUiState"
	set _widget(defConstrName) [ttk::entry $main.name.edit -textvariable [scope uiVar(defName)]]
	set uiVar(defNamed) 0
	set uiVar(defName) ""
	pack $main.name.lab -side left
	pack $main.name.edit -side right -fill x -expand 1
	pack $main.name -side top -fill x -padx 3 -pady 3

	# MacOS X appearance fix
	if {[tk windowingsystem] == "aqua"} {
		ttk::frame $main.mac_bottom
		ttk::label $main.mac_bottom.l -text " "
		pack $main.mac_bottom.l -side top
		pack $main.mac_bottom -side bottom -fill x
	}

	# Bottom buttons
	ttk::frame $main.bottom
	ttk::button $main.bottom.ok -text [mc {Ok}] -image img_ok -compound left -command "
			if {!\[$this validateDefault]} {
				wm withdraw $_defaultConfig
				$this defaultToModel
			}
		"
	ttk::button $main.bottom.cancel -text [mc {Cancel}] -image img_cancel -compound left -command "
		wm withdraw $_defaultConfig
		$this refreshDefault
	"
	pack $main.bottom.ok -side left -pady 3 -padx 2
	pack $main.bottom.cancel -side right -pady 3 -padx 2
	pack $main.bottom -side bottom -fill x

	# Handle closing window
	bind $_defaultConfig <Unmap> "$this refreshGrab %W"
	bind $_defaultConfig <Map> "grab $_widget(defaultConfig)"
	wm protocol $_defaultConfig WM_DELETE_WINDOW "wm withdraw $_defaultConfig"

	# Other settings
	wm minsize $_defaultConfig 300 50
}

###########################################################################################################

body ColumnDialog::parseInputModel {} {
	set uiVar(name) [$_model cget -name]
	set uiVar(type) [$_model cget -type]
	set uiVar(size:max) [$_model cget -size]
	set uiVar(size:precision) [$_model cget -precision]

	set uiVar(pk) [$_model cget -pk]
	$_pk configure -named [$_model cget -pkNamed]
	$_pk configure -name [$_model cget -pkName]
	$_pk configure -order [$_model cget -pkOrder]
	$_pk configure -conflict [$_model cget -pkConflict]
	if {$_sqliteVersion == 3} {
		$_pk configure -autoincr [$_model cget -pkAutoIncr]
	}

	set uiVar(notnull) [$_model cget -notnull]
	$_notnull configure -named [$_model cget -notnullNamed]
	$_notnull configure -name [$_model cget -notnullName]
	$_notnull configure -conflict [$_model cget -notnullConflict]

	set uiVar(uniq) [$_model cget -uniq]
	$_uniq configure -named [$_model cget -uniqNamed]
	$_uniq configure -name [$_model cget -uniqName]
	$_uniq configure -conflict [$_model cget -uniqConflict]

	set uiVar(chk) [$_model cget -check]
	$_chk configure -named [$_model cget -checkNamed]
	$_chk configure -name [$_model cget -checkName]
	$_chk configure -expr [$_model cget -checkExpr]
	if {$_sqliteVersion == 2} {
		$_chk configure -conflict [$_model cget -checkConflict]
	}

	set uiVar(default) [$_model cget -default]
	$_default configure -named [$_model cget -defaultNamed]
	$_default configure -name [$_model cget -defaultName]
	$_default configure -expr [$_model cget -defaultValue]
	$_default configure -isLiteralValue [$_model cget -defaultIsLiteral]

	if {$_sqliteVersion == 3} {
		set uiVar(collate) [$_model cget -collate]
		$_collate configure -named [$_model cget -collateNamed]
		$_collate configure -name [$_model cget -collateName]
		$_collate configure -collation [$_model cget -collationName]

		set uiVar(fk) [$_model cget -fk]
		$_fk configure -named [$_model cget -fkNamed]
		$_fk configure -name [$_model cget -fkName]
		$_fk configure -foreignTable [$_model cget -fkTable]
		$_fk configure -foreignColumn [$_model cget -fkColumn]
		$_fk configure -onUpdate [$_model cget -fkOnUpdate]
		$_fk configure -onDelete [$_model cget -fkOnDelete]
		$_fk configure -match [$_model cget -fkMatch]
		$_fk configure -deferrable [$_model cget -fkDeferrable]
		$_fk configure -initially [$_model cget -fkInitially]
	}

	refreshPk
	refreshFk
	refreshUniq
	refreshChk
	refreshCollate
	refreshNotNull
	refreshDefault
}

body ColumnDialog::storeInModel {} {
	if {$_model == ""} {
		set _model [TableDialogColumnModel ::#auto]
	}

	$_model configure \
		-name $uiVar(name) \
		-type $uiVar(type) \
		-size $uiVar(size:max) \
		-precision $uiVar(size:precision)

	$_model configure \
		-pk $uiVar(pk) \
		-pkNamed [$_pk cget -named] \
		-pkName [$_pk cget -name] \
		-pkOrder [$_pk cget -order] \
		-pkConflict [$_pk cget -conflict]

	if {$_sqliteVersion == 3} {
		$_model configure -pkAutoIncr [$_pk cget -autoincr]
	}

	$_model configure \
		-notnull $uiVar(notnull) \
		-notnullNamed [$_notnull cget -named] \
		-notnullName [$_notnull cget -name] \
		-notnullConflict [$_notnull cget -conflict]

	$_model configure \
		-uniq $uiVar(uniq) \
		-uniqNamed [$_uniq cget -named] \
		-uniqName [$_uniq cget -name] \
		-uniqConflict [$_uniq cget -conflict]

	$_model configure \
		-check $uiVar(chk) \
		-checkNamed [$_chk cget -named] \
		-checkName [$_chk cget -name] \
		-checkExpr [$_chk cget -expr]

	if {$_sqliteVersion == 2} {
		$_model configure -checkConflict [$_chk cget -conflict]
	}

	$_model configure \
		-default $uiVar(default) \
		-defaultNamed [$_default cget -named] \
		-defaultName [$_default cget -name] \
		-defaultValue [$_default cget -expr]

	if {$_sqliteVersion == 3} {
		$_model configure \
			-collate $uiVar(collate) \
			-collateNamed [$_collate cget -named] \
			-collateName [$_collate cget -name] \
			-collationName [$_collate cget -collation]

		$_model configure \
			-fk $uiVar(fk) \
			-fkNamed [$_fk cget -named] \
			-fkName [$_fk cget -name] \
			-fkTable [$_fk cget -foreignTable] \
			-fkColumn [$_fk cget -foreignColumn] \
			-fkOnUpdate [$_fk cget -onUpdate] \
			-fkOnDelete [$_fk cget -onDelete] \
			-fkMatch [$_fk cget -match] \
			-fkDeferrable [$_fk cget -deferrable] \
			-fkInitially [$_fk cget -initially]
	}
}

body ColumnDialog::validate {} {
	if {$uiVar(pk) && [validatePk true]} {
		Error [mc {Column primary key is not configured correctly.}]
		return 1
	}
	if {$_sqliteVersion == 3 && $uiVar(pk) && $uiVar(pkAutoIncr) && [string toupper $uiVar(type)] != "INTEGER"} {
		Error [mc {AUTOINCREMENT is allowed only with INTEGER type of column.}]
		return 1
	}
	if {$_sqliteVersion == 3 && $uiVar(fk) && [validateFk true]} {
		Error [mc {Column foreign key is not configured correctly.}]
		return 1
	}
	if {$uiVar(uniq) && [validateUniq true]} {
		Error [mc {Column 'unique' constraint is not configured correctly.}]
		return 1
	}
	if {$uiVar(chk) && [validateChk true]} {
		Error [mc {Column 'check' constraint is not configured correctly.}]
		return 1
	}
	if {$uiVar(notnull) && [validateNotNull true]} {
		Error [mc {Column 'notnull' constraint is not configured correctly.}]
		return 1
	}
	if {$uiVar(default) && [validateDefault true]} {
		Error [mc {Column 'default' constraint is not configured correctly.}]
		return 1
	}
	if {$_sqliteVersion == 3 && $uiVar(collate) && [validateCollate true]} {
		Error [mc {Column 'collate' constraint is not configured correctly.}]
		return 1
	}
	if {$uiVar(name) == ""} {
		Error [mc {No column name is specified.}]
		return 1
	}
	if {[$_tableDialog columnExists $uiVar(name)] && ($_model == "" || $_model != "" && ![string equal -nocase $uiVar(name) [$_model cget -name]])} {
		Error [mc {Column with name '%s' already exists in the table.} $uiVar(name)]
		return 1
	}
	if {[string trim $uiVar(type)] == "" && ($uiVar(size:max) != "" || $uiVar(size:precision) != "")} {
		Error [mc {Data type bounds are given, but no data type name is specified.}]
		return 1
	}
	if {$uiVar(size:max) == "" && $uiVar(size:precision) != ""} {
		Error [mc {Data type precision is given, but no data type size is specified.}]
		return 1
	}
	if {$uiVar(size:max) != "" && ![string is integer $uiVar(size:max)]} {
		Error [mc {Data type size has invalid format. Only integer value is allowed.}]
		return 1
	}
	if {$uiVar(size:precision) != "" && ![string is integer $uiVar(size:precision)]} {
		Error [mc {Data type precision has invalid format. Only integer value is allowed.}]
		return 1
	}
	return 0
}
