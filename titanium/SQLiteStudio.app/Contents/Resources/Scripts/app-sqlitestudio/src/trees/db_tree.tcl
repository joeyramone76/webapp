use src/trees/browser_tree.tcl
use src/common/singleton.tcl
use src/common/signal.tcl
use src/shortcuts.tcl
use src/common/tktree_tracer.tcl
use src/common/dnd.tcl

#>
# @class DBTree
# This is tree for databases management, which is placed on the
# left side of the main window.
#<
use src/common/signal.tcl

#>
# @class DBTree
# Database tree. Implements database objects manipulation.
#<
class DBTree {
	inherit BrowserTree Singleton Signal Shortcuts TkTreeTracer Dnd Session

	#>
	# @method constructor
	# @param args Option-value pairs. There is no specific options for DBTree class.
	# Restores databases from configuration file, creates shortcut bindings
	# and initializes context menu.
	#<
	constructor {args} {
		Tree::constructor {*}$args
		Dnd::constructor true
	} {}

	#>
	# @var showSqliteSystemTables
	# Boolean value determinating if <code>sqlite_*</code> tables are displayed in database tables tree.
	# It's configurable via {@class CfgWin} dialog.
	#<
	common showSqliteSystemTables false
	common singleClick false

	common helpHintWin ".dbTreeHelpHint"

	#>
	# @var viewOpenMode
	# What to do when double-clicked on a view in objects tree: "dialog" for opening view edition dialog, "data" for showing view data.
	#<
	common viewOpenMode "data"
	
	common displayMode "objectsUnderTable"

	common showColumnsUnderTable false

	private {
		#>
		# @var _dblist
		# List of {@class DB} objects.
		#<
		variable _dblist [list]

		#>
		# @var _menu
		# Contains database tree context menu widget.
		#<
		variable _menu ""

		#>
		# @arr _treeNode
		#<
		variable _treeNode

		variable _dragItem ""
		variable _dragItemData ""

		#>
		# @method getSelectedTable
		# @return Currently selected table node or empty string if table is not selected.
		#<
		method getSelectedTable {}

		#>
		# @method getSelectedView
		# @return Currently selected view node or empty string if view is not selected.
		#<
		method getSelectedView {}

		#>
		# @method getSelectedIndex
		# @return Currently selected index node or empty string if index is not selected.
		#<
		method getSelectedIndex {}

		#>
		# @method getSelectedTrigger
		# @return Currently selected trigger node or empty string if trigger is not selected.
		#<
		method getSelectedTrigger {}

		method describeActiveItem {}
		method openClickedItem {it}
		method moveDbInList {db atDb}
		method aboutToMoveObjToTable {sourceDb sourceType sourceObj targetDb targetTable}
		method moveObjToTable {sourceDb sourceType sourceObj targetDb targetTable copyOrMove}
		method aboutToMoveTable {sourceDb sourceTable targetDb}
		method moveTable {sourceDb sourceTable targetDb mode}
		method moveView {sourceDb sourceView targetDb copyOrMove}
		method isTableUsedByAnyView {db table viewsVar}
	}

	public {
		method getSelectionProfile {}
	
		#>
		# @method getSelectedDb
		# @return Currently selected database node or empty string if database is not selected.
		#<
		method getSelectedDb {}

		#>
		# @method dblist
		# @return Exact value of {@var _dblist} variable.
		#<
		method dblist {}

		#>
		# @method refreshSchema
		# Refreshes schema of all opened databases. It's done by calling {@method DB::refreshSchema} with parameter value '1'.
		#<
		method refreshSchema {}

		method refreshSchemaForDb {db {force 0} {updateMenu 1}}

		#>
		# @method deleteSelectedItem
		# Deletes currently selected item from tree (if possible).
		# Calls one of: {@method delTable}, {@method delIndex}, {@method delTrigger}, or {@method delView}.
		#<
		method deleteSelectedItem {}

		#>
		# @method addDB
		# @param name Symbolic name of new database.
		# @param path Path to new database file.
		# @param temp Temporary flag.
		# Creates {@class DB} object and appends it to {@var _dblist} variable using given parameters.
		# New database is displayed in databases tree.
		#<
		method addDB {name path {temp 0}}

		#>
		# @method delDB
		# @param db {@class DB} object - database to delete from list.
		# Deletes database from list (also from tree), but doesn't delete it from file system.
		#<
		method delDB {db}

		#>
		# @method delSelectedDB
		# Deletes database object which is related with currently selected database node in tree.
		#<
		method delSelectedDB {}

		#>
		# @method saveDBCfg
		# Saves database list, their states (opened or closed) in configuration file.
		#<
		method saveDBCfg {}

		#>
		# @method clicked
		# Refreshes toolbar and database menu.
		# @overloaded BrowserTree
		#<
		method clicked {x y}

		#>
		# @method doubleClicked
		# @overloaded BrowserTree
		#<
		method doubleClicked {x y}

		#>
		# @method connectToSelected
		# Opens database that is currently selected in tree. If no database is selected or selected database
		# is opened, then the method does nothing.
		#<
		method connectToSelected {}

		#>
		# @method disconnectFromSelected
		# Closes database that is currently selected in tree. If no database is selected or selected database
		# is closed, then the method does nothing.
		#<
		method disconnectFromSelected {}

		#>
		# @method getActiveDatabases
		# @return List of opened databases.
		#<
		method getActiveDatabases {}

		#>
		# @method getDBByName
		# @param name Name of database to get.
		# @return {@class DB} object with same name value as given in parameter, or empty string if no such object found.
		#<
		method getDBByName {name}

		#>
		# @method getDBByPath
		# @param path Path to db file.
		# @return {@class DB} object with same name value as given in parameter, or empty string if no such object found.
		#<
		method getDBByPath {path}

		#>
		# @method getMenu
		# @return Menu widget command (to access that menu).
		#<
		method getMenu {}

		#>
		# @method newTable
		# Opens {@class NewTableDialog} to create new table in currently selected database.
		#<
		method newTable {}

		#>
		# @method editTable
		# Opens {@class EditTableDialog} for currently selected table.
		#<
		method editTable {}
		method createSimilarTable {}

		#>
		# @method delTable
		# Asks user for deleting selected table and deletes it when user agrees to do it.
		#<
		method delTable {}

		#>
		# @method newIndex
		# Opens {@class NewIndexDialog} to create new table in currently selected database.
		#<
		method newIndex {}

		#>
		# @method editIndex
		# Opens {@class EditIndexDialog} for currently selected table.
		#<
		method editIndex {}

		#>
		# @method delIndex
		# Asks user for deleting selected index and deletes it when user agrees to do it.
		#<
		method delIndex {}

		#>
		# @method newTrigger
		# Opens {@class NewTriggerDialog} to create new table in currently selected database.
		#<
		method newTrigger {}

		#>
		# @method editTrigger
		# Opens {@class EditTriggerDialog} for currently selected table.
		#<
		method editTrigger {}

		#>
		# @method delTrigger
		# Asks user for deleting selected trigger and deletes it when user agrees to do it.
		#<
		method delTrigger {}

		#>
		# @method newView
		# Opens {@class NewViewDialog} to create new table in currently selected database.
		#<
		method newView {}

		#>
		# @method editView
		# Opens {@class EditViewDialog} for currently selected table.
		#<
		method editView {}

		#>
		# @method delView
		# Asks user for deleting selected view and deletes it when user agrees to do it.
		#<
		method delView {}

		#>
		# @method showViewData
		# Opens {@class EditorWin}, inserts SQL query into it and executes it, so EditorWin shows data returned by selected view.
		# If selected tree node doesn't represent View, then nothing happens.
		#<
		method showViewData {}
		method integrityCheck {}

		#>
		# @method createNewDB
		# Opens {@class DBEditDialog} to create new {@class DB} object and add it to tree and {@var _dblist}.
		#<
		method createNewDB {}

		#>
		# @method editDB
		# Opens {@class DBEditDialog} to change settings of selected database.
		#<
		method editDB {}

		#>
		# @method menuPost
		# @param x X-coordinate to post menu.
		# @param y Y-coordinate to post menu.
		# Posts context menu at given coordinates. It's called by <i>Button-3</i> event.
		#<
		method menuPost {x y}

		#>
		# @method createFK
		# Opens {@class NewFKTriggerDialog} to create triggers for emulation of Foreign Key.
		#<
# 		method createFK {}

		#>
		# @method exportDB
		# Opens {@class ExportDialog} to export selected database.
		#<
		method exportDB {}

		#>
		# @method vacuumDB
		# Asks user if he wants to VACUUM selected database and does it if user agrees.
		#<
		method vacuumDB {}

		#>
		# @method exportTable
		# Opens {@class ExportDialog} to export selected table.
		#<
		method exportTable {}

		#>
		# @method importTable
		# Opens {@class ImportDialog} to import data to selected table.
		#<
		method importTable {}

		method editColumn {db table column}
		
		#>
		# @method signal
		# @param receiver Destination class.
		# @param data Signal data.
		# Handles signals destinated for this class.<br><br>
		# <i>Data</i> syntax:
		# <ul>
		# <li><code>REFRESH DB_OBJ</code> <i>databaseObject</i> - refreshes schema for database given by {@class DB},
		# <li><code>REFRESH DB_NAME</code> <i>databaseName</i> - refreshes schema for database with given name.
		# </ul>
		#<
		method signal {receiver data}

		#>
		# @method openTableWindow
		# @param db Database containing given table.
		# @param table Table to open window for.
		# Opens {@class TableWin} for given table.
		#<
		method openTableWindow {db table}

		#>
		# @method updateShortcuts
		# @overloaded Shortcuts
		#<
		method updateShortcuts {}

		#>
		# @method clearShortcuts
		# @overloaded Shortcuts
		#<
		method clearShortcuts {}

		#>
		# @method executeSqlFromFile
		# Opens file dialog to choose SQL file. Then executes SQL from that file and shows dialog message
		# with results of the execution.
		#<
		method executeSqlFromFile {{db ""}}

		#>
		# @method importSchemaFromOtherDb
		# Opens dialog window or importing database schema.
		#<
		method importSchemaFromOtherDb {}

		#>
		# @method populateTable
		# Opens dialog for populating table.
		#<
		method populateTable {}

		#>
		# @method getRegisteredDatabaseList
		# @return List of database objects ({@class DB}) registered in application (visible in tree on the left).
		#<
		method getRegisteredDatabaseList {}

		#>
		# @method getSessionString
		# @overloaded Session
		#<
		method getSessionString {}

		#>
		# @method restoreSession {sessionString}
		# @overloaded Session
		#<
		proc restoreSession {sessionString}

		method convertDb {}
		method getDatabaseNames {}
		method expandRoot {db}
		method closeRoot {db}
		method loadDatabases {}
		method sortDatabases {}
		method enterPresed {}
		method applyFilter {filter}
		method resetAutoIncrement {}
		method itemEnter {it col}
		method itemLeave {it col}
		method tracerButtonPressed {button it col}
		method helpHint {w it}
		method fillHint {data hintTable}
		method refreshDbSchemaObjUnderTable {db force}
		method refreshDbSchemaFlat {db force}
		method cleanTreeNodeArray {db}
		method eraseTableData {}
		method onDrag {x y}
		method onDrop {x y}
		method onDragLeave {}
		method onDragReturn {}
		method canDropAt {x y}
		method isDndPossible {x y}
		method getDragImage {}
		method getDragLabel {}
		method getTreeNode {key}
		proc initHelpHint {}
	}
}

body DBTree::constructor {args} {
	bind $_tree <Delete> "$this deleteSelectedItem"

	set _menu [menu $_tree.menu -borderwidth 1 -activeborderwidth 1 -tearoff 0]
	bind $_tree <Button-$::RIGHT_BUTTON> "+if {\[$this menuPost %x %y]} {tk_popup $_menu %X %Y}"
	bind $_tree <Return> "$this enterPresed; break"
	$_tree notify bind $_tree <ActiveItem> [list MAIN updateMenuAndToolbar]

	initTracer $_tree
	createDnd $_tree $_tree
}

body DBTree::loadDatabases {} {
	set databases [CfgWin::getDBList]
	set cnt [llength $databases]
	incr cnt
	
	BusyDialog::show [mc {Loading}] [mc {Loading database list}] 0 $cnt 0 "determinate"
	foreach w $databases {
		set name [lindex $w 0]
		set path [lindex $w 1]
		BusyDialog::invoke
		if {[catch {
			set db [DB::getInstanceForFile $name $path]
		} err]} {
			Error [mc {Given database file (%s) doesn't exist or is unreadable.} $path]
			continue
		}
		if {$db == ""} {
			Error [mc {Given database file (%s) doesn't exist or is unreadable.} $path]
			continue
		}
		lappend _dblist $db
		$db setTemp 0
		refreshSchemaForDb $db
	}
	BusyDialog::hide
	update idletasks
	saveDBCfg
}

body DBTree::getMenu {} {
	return $_menu
}

body DBTree::menuPost {x y} {
	set item [$_tree identify $x $y]
	if {$item == ""} {
		set it ""
		set data ""
		set db ""
		set type ""
		set CMENU(type) "ALL"
	} else {
		if {[lindex $item 0] != "item"} {return false}
		set it [lindex $item 1]
		if {$it == "" || $it == 0} {return false}
		set data [getData $it]
		set db [lindex $data 1]
		set type [lindex $data 0]
		set CMENU(type) [lindex $data 0]
	}
	set CMENU(db) $db

	set displayResetAutoIncr 0
	if {$type == "TABLE"} {
		set table [lindex $data 2]
		if {"sqlite_sequence" in [$db getTables]} {
			$db eval {SELECT name FROM sqlite_sequence WHERE name = $table} row {
				set displayResetAutoIncr 1
			}
		}
	}

	$_menu delete 0 end

	set correctEntries [list "ALL" "TABLE" "TABLES" "INDEX" "INDEXES" "TRIGGER" "TRIGGERS" "VIEW" "VIEWS" "DATABASE"]
	if {$CMENU(type) ni $correctEntries} {
		return false
	}

	cmenu "DATABASE" -1 $_menu add command -compound left -image img_DB_open -label [mc "Connect"] -command "DBTREE connectToSelected"
	cmenu "DATABASE" 1 $_menu add command -compound left -image img_DB_close -label [mc "Disconnect"] -command "DBTREE disconnectFromSelected"
	cmenu "DATABASE" 0 $_menu add separator
	cmenu "ALL" 0 $_menu add command -compound left -image img_DB_new -label [mc "Add database"] -command "DBTREE createNewDB"
	cmenu "DATABASE" 0 $_menu add command -compound left -image img_DB_edit -label [mc "Edit database"] -command "DBTREE editDB"
	cmenu "DATABASE" 0 $_menu add command -compound left -image img_DB_remove -label [mc "Remove from list"] -command "DBTREE delSelectedDB"
	cmenu "DATABASE" 0 $_menu add separator
	cmenu "DATABASE" 1 $_menu add command -compound left -image img_export_db -label [mc "Export database"] -command "DBTREE exportDB"
	cmenu "DATABASE" 1 $_menu add command -compound left -image img_import_db -label [mc "Import schema from other database"] -command "DBTREE importSchemaFromOtherDb"
	cmenu "DATABASE" 1 $_menu add command -compound left -image img_convert -label [mc "Convert database"] -command "DBTREE convertDb"
	cmenu "DATABASE" 1 $_menu add command -compound left -image img_vacuum -label [mc "Vacuum"] -command "DBTREE vacuumDB"
	cmenu "DATABASE" 1 $_menu add command -compound left -image img_integrity_check -label [mc "Integrity check"] -command "DBTREE integrityCheck"
	cmenu "DATABASE" 1 $_menu add command -compound left -image img_execute_from_file -label [mc "Execute SQL from file"] -command "DBTREE executeSqlFromFile"
	cmenu "ALL" 2 $_menu add separator
	cmenu "" 2 $_menu add command -compound left -image img_new_table -label [mc {New table}] -command "$this newTable"
	cmenu "TABLE" 2 $_menu add command -compound left -image img_table_edit -label [mc {Edit table}] -command "$this editTable"
	cmenu "TABLE" 2 $_menu add command -compound left -image img_del_table -label [mc {Drop table}] -command "$this delTable"
	cmenu "TABLE" 2 $_menu add command -compound left -image img_table_similar -label [mc {Create similar table}] -command "$this createSimilarTable"
	if {$displayResetAutoIncr} {
		cmenu "TABLE" 2 $_menu add command -compound left -image img_reset_incr -label [mc {Reset autoincrement for '%s'} $table] -command "$this resetAutoIncrement"
	}
	cmenu "TABLE" 2 $_menu add command -compound left -image img_whisk -label [mc {Erase table data}] -command "$this eraseTableData"
	cmenu "TABLE" 2 $_menu add separator
	cmenu "INDEX" 2 $_menu add separator
	cmenu "" 2 $_menu add command -compound left -image img_new_index -label [mc {New index}] -command "$this newIndex"
	cmenu "INDEX" 2 $_menu add command -compound left -image img_index_edit -label [mc {Edit index}] -command "$this editIndex"
	cmenu "INDEX" 2 $_menu add command -compound left -image img_del_index -label [mc {Drop index}] -command "$this delIndex"
	cmenu "INDEX" 2 $_menu add separator
	cmenu "TRIGGER" 2 $_menu add separator
	cmenu "" 2 $_menu add command -compound left -image img_new_trigger -label [mc {New trigger}] -command "$this newTrigger"
	cmenu "TRIGGER" 2 $_menu add command -compound left -image img_trigger_edit -label [mc {Edit trigger}] -command "$this editTrigger"
	cmenu "TRIGGER" 2 $_menu add command -compound left -image img_del_trigger -label [mc {Drop trigger}] -command "$this delTrigger"
	cmenu "TRIGGER" 2 $_menu add separator
	#cmenu "" 2 $_menu add command -compound left -image img_fk -label [mc {Create foreign key}] -command "$this createFK"
	cmenu "VIEW" 2 $_menu add separator
	cmenu "" 2 $_menu add command -compound left -image img_new_view -label [mc {New view}] -command "$this newView"
	cmenu "VIEW" 2 $_menu add command -compound left -image img_view_edit -label [mc {Edit view}] -command "$this editView"
	cmenu "VIEW" 2 $_menu add command -compound left -image img_del_view -label [mc {Drop view}] -command "$this delView"
	cmenu "VIEW" 2 $_menu add separator
	cmenu "VIEW" 2 $_menu add command -compound left -image img_show_view_data -label [mc {Show view data}] -command "$this showViewData"
	cmenu "TABLE" 2 $_menu add separator
	cmenu "TABLE" 2 $_menu add command -compound left -image img_table_export -label [mc {Export table}] -command "$this exportTable"
	cmenu "VIEW" 2 $_menu add command -compound left -image img_table_export -label [mc {Export view}] -command "$this exportTable"
	cmenu "TABLE" 2 $_menu add command -compound left -image img_table_import -label [mc {Import data to table}] -command "$this importTable"
	cmenu "DATABASE" 2 $_menu add command -compound left -image img_table_import -label [mc {Import data to table}] -command "$this importTable"
	cmenu "TABLE" 2 $_menu add command -compound left -image img_populate_table -label [mc {Populate table}] -command "$this populateTable"
	cmenu "ALL" 2 $_menu add separator
	cmenu "ALL" 0 $_menu add command -compound left -image img_tree_refresh -label [mc "Refresh databases tree"] -command "DBTREE refreshSchema"
	cmenu "ALL" 0 $_menu add command -compound left -image img_sort_alphabet -label [mc "Sort databases alphabetically"] -command "DBTREE sortDatabases"
	return true
}

body DBTree::addDB {name path {temp 0}} {
	foreach db $_dblist {
		if {[$db getPath] == $path} {
			Error [mc {Given database is already on the list.}]
			return
		}
		if {[$db getName] == $name} {
			Error [mc {Given database name is already on the list.}]
			return
		}
	}

	if {[catch {
		set db [DB::getInstanceForFile $name $path]
	} err]} {
		if {![file readable $path]} {
			Error [mc {Given database file doesn't exist or is unreadable.}]
			return
		} else {
			error $err
		}
	}
	if {$db == ""} return
	lappend _dblist $db
	$db setTemp $temp
	saveDBCfg
	refreshSchemaForDb $db
	return $db
}

body DBTree::delDB {db} {
	if {[$db isOpen]} {
		$db close
	}
	lremove _dblist $db

	$_tree item delete $_treeNode($db:ROOT)
	array unset _treeNode $db:*

	delete object $db
	saveDBCfg
}

body DBTree::createNewDB {} {
	if {[winfo exists .dbdialog]} {
		raise .dbdialog
		return
	}
	DBEditDialog .dbdialog -mode new
	.dbdialog exec
}

body DBTree::editDB {} {
	set db [getSelectedDb]
	if {$db == ""} return
	set dialog [DBEditDialog .editDB -db $db -mode edit]
	$dialog exec
}

body DBTree::dblist {} {
	return $_dblist
}

body DBTree::getDatabaseNames {} {
	set resultList [list]
	foreach db $_dblist {
		lappend resultList [$db getName]
	}
	return $resultList
}

body DBTree::refreshSchema {} {
	set selectedItem [DBTREE getSelectedItem]
	set selectedData ""
	if {$selectedItem != ""} {
		set selectedData [DBTREE getData $selectedItem]
	}

	foreach db $_dblist {
		refreshSchemaForDb $db 1 0
	}

	update idletasks
	MAIN updateMenuAndToolbar
}

body DBTree::refreshSchemaForDb {db {force 0} {updateMenu 1}} {

	switch -- $displayMode {
		"objectsUnderTable" {
			refreshDbSchemaObjUnderTable $db $force
		}
		"flat" {
			refreshDbSchemaFlat $db $force
		}
		default {
			set displayMode "objectsUnderTable"
			CfgWin::save ::DBTree::displayMode $displayMode $force
		}
	}

	setSelected $_treeNode($db:ROOT)
	if {$updateMenu} {
		MAIN updateMenuAndToolbar
	}

	TASKBAR signal EditorWin [list UPDATE_DB_TABLES $this]
}

body DBTree::cleanTreeNodeArray {db} {
	foreach mask [list \
		$db:TABLES \
		$db:INDEXES \
		$db:TRIGGERS \
		$db:VIEWS \
		COLUMNS:$db:* \
		INDEXES:$db:* \
		TRIGGERS:$db:* \
		TABLE:$db:* \
		INDEX:$db:* \
		TRIGGER:$db:* \
		VIEW:$db:* \
	] {
		catch {array unset _treeNode $mask}
	}
}

body DBTree::refreshDbSchemaObjUnderTable {db force} {
	# Keep track of open nodes
	array set nodeOpen {}
	if {[info exists _treeNode($db:ROOT)] && $_treeNode($db:ROOT) != ""} {
		set nodeOpen($db:ROOT) [$_tree item isopen $_treeNode($db:ROOT)]
		set childs [$_tree item children $_treeNode($db:ROOT)]
		if {$childs != ""} {
			foreach idx {TABLES VIEWS} {
				if {[info exists _treeNode($db:$idx)]} {
					set nodeOpen($db:$idx) [$_tree item isopen $_treeNode($db:$idx)]
				}
			}
			foreach idx [concat \
				[array names _treeNode COLUMNS:$db:*] \
				[array names _treeNode INDEXES:$db:*] \
				[array names _treeNode TRIGGERS:$db:*] \
				[array names _treeNode TABLE:$db:*] \
			] {
				set nodeOpen($idx) [$_tree item isopen $_treeNode($idx)]
			}
			
			$_tree item delete [lindex $childs 0] [lindex $childs end]
		}
	}

	if {$force || ![info exists _treeNode($db:ROOT)] || $_treeNode($db:ROOT) == ""} {
		if {[info exists _treeNode($db:ROOT)] && $_treeNode($db:ROOT) != ""} {
			$_tree item delete $_treeNode($db:ROOT)
		}
		set _treeNode($db:ROOT) [$this addItem root img_database [$db getName] no]
		$this setData $_treeNode($db:ROOT) [list DATABASE $db]
	}

	$this setElementLabel $_treeNode($db:ROOT) "[[$db info class]::getHandlerLabel]"

	cleanTreeNodeArray $db

	if {![$db isOpen]} return

	set _treeNode($db:TABLES) [$this addItem $_treeNode($db:ROOT) img_table [mc {Tables}] no]
	set _treeNode($db:VIEWS) [$this addItem $_treeNode($db:ROOT) img_view [mc {Views}] no]

	foreach idx {TABLES VIEWS} {
		$this setData $_treeNode($db:$idx) [list $idx $db]
	}

	set indexes [list]
	set triggers [list]
	set tables [list]

	set virtualTables [$db getVirtualTableNames]

	foreach row [$db getRefreshSchemaData] {
		lassign $row sql type name tblname
		set lowerName [string tolower $name]
		set lowerTblName [string tolower $tblname]
		set _createSql($name) [decode $sql]
		switch -- $type {
			"table" {
				lappend tables $name
				set isVirtual [expr {$lowerName in $virtualTables}]
				if {$isVirtual} {
					set tableImg img_virtual_table
				} else {
					set tableImg img_table
				}

				set node [$this addItem $_treeNode($db:TABLES) $tableImg $name no]
				$this setData $node [list TABLE $db $name]
				set _treeNode(TABLE:$db:$lowerName) $node
				if {[string match "sqlite_*" $lowerName]} {
					$this setElementLabel $node [mc {SQLite system table}]
				}
				$this incrElementLabelNumber $_treeNode($db:TABLES)

				if {!$isVirtual} {
					# Columns
					if {$showColumnsUnderTable} {
						set idxNode [$this addItem $node img_column [mc {Columns}] no]
						$this setData $idxNode [list COLUMNS $db $name]
						set _treeNode(COLUMNS:$db:$lowerName) $idxNode
					}

					# Indexes
					set idxNode [$this addItem $node img_index [mc {Indexes}] no]
					$this setData $idxNode [list INDEXES $db $name]
					set _treeNode(INDEXES:$db:$lowerName) $idxNode

					# Triggers
					set trigNode [$this addItem $node img_trigger [mc {Triggers}] no]
					$this setData $trigNode [list TRIGGERS $db $name]
					set _treeNode(TRIGGERS:$db:$lowerName) $trigNode
				}

				$this setButton $node false
			}
			"index" {
				lappend indexes [list $name $sql $tblname]
			}
			"trigger" {
				lappend triggers [list $name $sql $tblname]
			}
			"view" {
				set node [$this addItem $_treeNode($db:VIEWS) img_view $name no]
				$this setData $node [list VIEW $db $name]
				set _treeNode(VIEW:$db:$lowerName) $node
				$this incrElementLabelNumber $_treeNode($db:VIEWS)

				# Triggers
				set trigNode [$this addItem $node img_trigger [mc {Triggers}] no]
				$this setData $trigNode [list TRIGGERS $db $name]
				set _treeNode(TRIGGERS:$db:$lowerName) $trigNode
			}
		}
	}

	# Columns
	if {$showColumnsUnderTable} {
		foreach table $tables {
			set lowerName [string tolower $table]
			if {$lowerName in $virtualTables} continue

			foreach colDict [$db getTableInfo $table] {
				set colName [dict get $colDict name]
				set node [$this addItem $_treeNode(COLUMNS:$db:$lowerName) img_column $colName no]
				$this setData $node [list COLUMN $db $table $colName]
				set _treeNode(COLUMN:$db:$lowerName) $node
				$this incrElementLabelNumber $_treeNode(COLUMNS:$db:$lowerName)
			}
			$this setButton $_treeNode(TABLE:$db:$lowerName) true
		}
	}

	# Indexes
	foreach index $indexes {
		lassign $index name sql idxTable
		set lowerName [string tolower $name]
		set lowerTblName [string tolower $idxTable]

		if {[catch {
		set node [$this addItem $_treeNode(INDEXES:$db:$lowerTblName) img_index $name no]
		} err]} {
			puts $err
			parray _treeNode INDEXES:*
		}
		$this setData $node [list INDEX $db $name]
		set _treeNode(INDEX:$db:$lowerName) $node
		$this incrElementLabelNumber $_treeNode(INDEXES:$db:$lowerTblName)
		$this setButton $_treeNode(TABLE:$db:$lowerTblName) true
		$this incrElementLabelNumber $_treeNode(TABLE:$db:$lowerTblName)

		if {[string match "sqlite_autoindex_*" $name] || [string match "(* autoindex *)" $name]} {
			$this setElementLabel $node [mc {SQLite system index}]
			continue
		}
	}

	# Triggers
	foreach trig $triggers {
		lassign $trig name sql trigTable
		set lowerName [string tolower $name]
		set lowerTblName [string tolower $trigTable]

		set node [$this addItem $_treeNode(TRIGGERS:$db:$lowerTblName) img_trigger $name no]
		$this setData $node [list TRIGGER $db $name]
		set _treeNode(TRIGGER:$db:$lowerName) $node
		$this incrElementLabelNumber $_treeNode(TRIGGERS:$db:$lowerTblName)
		if {[info exists _treeNode(TABLE:$db:$lowerTblName)]} {
			$this setButton $_treeNode(TABLE:$db:$lowerTblName) true
			$this incrElementLabelNumber $_treeNode(TABLE:$db:$lowerTblName)
		} elseif {[info exists _treeNode(VIEW:$db:$lowerTblName)]} {
			$this setButton $_treeNode(VIEW:$db:$lowerTblName) true
			$this incrElementLabelNumber $_treeNode(VIEW:$db:$lowerTblName)
		}
	}

	foreach idx {TABLES VIEWS} {
		$this sort $_treeNode($db:$idx)
	}

	foreach table $tables {
		set lowerName [string tolower $table]
		if {$lowerName in $virtualTables} continue

		set childs [list]
		if {$showColumnsUnderTable} {
			lappend childs {*}[getChilds $_treeNode(COLUMNS:$db:$lowerName)]
		}
		lappend childs {*}[getChilds $_treeNode(INDEXES:$db:$lowerName)]
		lappend childs {*}[getChilds $_treeNode(TRIGGERS:$db:$lowerName)]
		if {[llength $childs] == 0} {
			set nodeOpen(TABLE:$db:$lowerName) 0
		} else {
			$this sort $_treeNode(INDEXES:$db:$lowerName)
			$this sort $_treeNode(TRIGGERS:$db:$lowerName)
		}
	}

	foreach nodeIdx [array names nodeOpen] {
		if {$nodeOpen($nodeIdx) && [info exists _treeNode($nodeIdx)]} {
			$_tree item expand $_treeNode($nodeIdx)
		}
	}
}

body DBTree::refreshDbSchemaFlat {db force} {
	# Keep track of open nodes
	array set nodeOpen {}
	if {[info exists _treeNode($db:ROOT)] && $_treeNode($db:ROOT) != ""} {
		set nodeOpen(ROOT) [$_tree item isopen $_treeNode($db:ROOT)]
		set childs [$_tree item children $_treeNode($db:ROOT)]
		if {$childs != ""} {
			foreach idx {TABLES INDEXES TRIGGERS VIEWS} {
				if {[info exists _treeNode($db:$idx)]} {
					set nodeOpen($idx) [$_tree item isopen $_treeNode($db:$idx)]
				}
			}
			foreach idx [array names _treeNode TABLE:$db:*] {
				set nodeOpen($idx) [$_tree item isopen $_treeNode($idx)]
			}
			$_tree item delete [lindex $childs 0] [lindex $childs end]
		}
	}

	if {$force || ![info exists _treeNode($db:ROOT)] || $_treeNode($db:ROOT) == ""} {
		if {[info exists _treeNode($db:ROOT)] && $_treeNode($db:ROOT) != ""} {
			$_tree item delete $_treeNode($db:ROOT)
		}
		set _treeNode($db:ROOT) [$this addItem root img_database [$db getName] no]
		$this setData $_treeNode($db:ROOT) [list DATABASE $db]
	}

	$this setElementLabel $_treeNode($db:ROOT) "[[$db info class]::getHandlerLabel]"

	cleanTreeNodeArray $db

	if {![$db isOpen]} return

	set _treeNode($db:TABLES) [$this addItem $_treeNode($db:ROOT) img_table [mc {Tables}] no]
	set _treeNode($db:INDEXES) [$this addItem $_treeNode($db:ROOT) img_index [mc {Indexes}] no]
	set _treeNode($db:TRIGGERS) [$this addItem $_treeNode($db:ROOT) img_trigger [mc {Triggers}] no]
	set _treeNode($db:VIEWS) [$this addItem $_treeNode($db:ROOT) img_view [mc {Views}] no]

	foreach idx {TABLES INDEXES TRIGGERS VIEWS} {
		$this setData $_treeNode($db:$idx) [list $idx $db]
	}

	set virtualTables [$db getVirtualTableNames]

	foreach row [$db getRefreshSchemaData] {
		lassign $row sql type name
		set lowerName [string tolower $name]
		set _createSql($name) [decode $sql]
		switch -- $type {
			"table" {
				lappend tables $name
				set isVirtual [expr {$lowerName in $virtualTables}]
				if {$isVirtual} {
					set tableImg img_virtual_table
				} else {
					set tableImg img_table
				}

				set node [$this addItem $_treeNode($db:TABLES) $tableImg $name no]
				$this setData $node [list TABLE $db $name]
				set _treeNode(TABLE:$db:$lowerName) $node
				if {[string match "sqlite_*" $name]} {
					$this setElementLabel $node [mc {SQLite system table}]
				}
				$this incrElementLabelNumber $_treeNode($db:TABLES)
				
				if {$showColumnsUnderTable && !$isVirtual} {
					foreach colDict [$db getTableInfo $name] {
						set colName [dict get $colDict name]
						set colNode [$this addItem $node img_column $colName no]
						$this setData $colNode [list COLUMN $db $name $colName]
						set _treeNode(COLUMN:$db:$colName) $colNode
					}
					$this setButton $_treeNode(TABLE:$db:$lowerName) true
				}
			}
			"index" {
				set node [$this addItem $_treeNode($db:INDEXES) img_index $name no]
				$this setData $node [list INDEX $db $name]
				set _treeNode(INDEX:$db:$lowerName) $node
				if {[string match "sqlite_autoindex_*" $lowerName] || [string match "(* autoindex *)" $lowerName]} {
					$this setElementLabel $node [mc {SQLite system index}]
				}
				$this incrElementLabelNumber $_treeNode($db:INDEXES)
			}
			"trigger" {
				set node [$this addItem $_treeNode($db:TRIGGERS) img_trigger $name no]
				$this setData $node [list TRIGGER $db $name]
				set _treeNode(TRIGGER:$db:$lowerName) $node
				$this incrElementLabelNumber $_treeNode($db:TRIGGERS)
			}
			"view" {
				set node [$this addItem $_treeNode($db:VIEWS) img_view $name no]
				$this setData $node [list VIEW $db $name]
				set _treeNode(VIEW:$db:$lowerName) $node
				$this incrElementLabelNumber $_treeNode($db:VIEWS)
			}
		}
	}

	foreach idx {TABLES INDEXES TRIGGERS VIEWS} {
		$this sort $_treeNode($db:$idx)
	}

	foreach nodeIdx [array names nodeOpen] {
		if {$nodeOpen($nodeIdx) && [info exists _treeNode($db:$nodeIdx)]} {
			$_tree item expand $_treeNode($db:$nodeIdx)
		}
	}
}

body DBTree::getSelectionProfile {} {
	set itemDesc [describeActiveItem]
	set item [dict get $itemDesc item]
	set profile [list default]
	if {$item != ""} {
		set db [dict get $itemDesc db]
		set dbOpen [dict get $itemDesc dbOpen]
		set data [dict get $itemDesc data]
		lappend profile any [expr {$dbOpen ? "open" : "closed"}]
		if {$dbOpen} {
			switch -- [lindex $data 0] {
				"DATABASE" {
					lappend profile db
				}
				"TABLES" {
					lappend profile tables
				}
				"TABLE" {
					set table [lindex $data 2]
					catch {
						# Check if enabling "reset autoincrement"
						$db eval {SELECT name FROM sqlite_sequence WHERE name = $table LIMIT 1} row {
							lappend profile autoincr
						}
					}
					lappend profile table
				}
				"COLUMNS" {
					if {$::DBTree::displayMode == "objectsUnderTable"} {
						lappend profile table
					}
					lappend profile columns
				}
				"COLUMN" {
					if {$::DBTree::displayMode == "objectsUnderTable"} {
						lappend profile table
					}
					lappend profile columns
				}
				"INDEXES" {
					if {$::DBTree::displayMode == "objectsUnderTable"} {
						lappend profile table
					}
					lappend profile indexes
				}
				"INDEX" {
					if {$::DBTree::displayMode == "objectsUnderTable"} {
						lappend profile table
					}
					lappend profile index
				}
				"TRIGGERS" {
					if {$::DBTree::displayMode == "objectsUnderTable"} {
						lappend profile table
					}
					lappend profile triggers
				}
				"TRIGGER" {
					if {$::DBTree::displayMode == "objectsUnderTable"} {
						lappend profile table
					}
					lappend profile trigger
				}
				"VIEWS" {
					lappend profile views
				}
				"VIEW" {
					lappend profile view
				}
				default {
					error "Invalid db item type: [lindex $data 0]"
				}
			}
		}
	} else {
		lappend profile none
	}
	return $profile
}

body DBTree::applyFilter {filter} {
	if {$filter == ""} {
		set filter "*"
	} else {
		set filter "*$filter*"
	}

	foreach db $_dblist {
		set hideDb 0
		if {![string match -nocase $filter [$db getName]]} {
			set hideDb 1
		} else {
			set hideDb 0
		}

		if {[$db isOpen]} {
			switch -- $displayMode {
				"objectsUnderTable" {
					# Tables
					set mainNode $_treeNode($db:TABLES)
					set visible 0
					foreach node [getChilds $mainNode] {
						set child1visible 0
						foreach childLevel1Node [getChilds $node] {
							set child2visible 0
							foreach childLevel2Node [getChilds $childLevel1Node] {
								if {[string match -nocase $filter [getText $childLevel2Node]]} {
									show $childLevel2Node
									set hideDb 0
									incr child1visible
									incr child2visible
								} else {
									hide $childLevel2Node
								}
							}
							if {$child2visible > 0} {
								show $childLevel1Node
							} else {
								hide $childLevel1Node
							}
							setElementLabel $childLevel1Node $child2visible
						}
						setElementLabel $node [expr {$child1visible > 0 ? $child1visible : ""}]
					
						if {[string match -nocase $filter [getText $node]] || $child1visible} {
							show $node
							set hideDb 0
							incr visible
						} else {
							hide $node
						}
					}
					setElementLabel $mainNode $visible

					# Views
					set mainNode $_treeNode($db:VIEWS)
					set visible 0
					foreach node [getChilds $mainNode] {
						if {[string match -nocase $filter [getText $node]]} {
							show $node
							set hideDb 0
							incr visible
						} else {
							hide $node
						}
					}
					setElementLabel $mainNode $visible
				}
				"flat" {
					foreach mainNode [list $_treeNode($db:TABLES) $_treeNode($db:INDEXES) $_treeNode($db:TRIGGERS) $_treeNode($db:VIEWS)] {
						set visible 0
						foreach node [getChilds $mainNode] {
							if {[string match -nocase $filter [getText $node]]} {
								show $node
								set hideDb 0
								incr visible
							} else {
								hide $node
							}
						}
						setElementLabel $mainNode $visible
					}
				}
				default {
					error "Invalid DBTree::displayMode: $displayMode"
				}
			}
		}
		if {$hideDb} {
			hide $_treeNode($db:ROOT)
		} else {
			show $_treeNode($db:ROOT)
		}
	}
}

body DBTree::expandRoot {db} {
	if {![info exists _treeNode($db:ROOT)]} return
	$this expand $_treeNode($db:ROOT)
}

body DBTree::closeRoot {db} {
	if {![info exists _treeNode($db:ROOT)]} return
	$this delChilds $_treeNode($db:ROOT)
}

body DBTree::saveDBCfg {} {
	CfgWin::saveDBList $_dblist
}

body DBTree::clicked {x y} {
	BrowserTree::clicked $x $y
# 	update idletasks
# 	MAIN updateMenuAndToolbar
	if {$singleClick} {
		set item [$_tree identify $x $y]
		if {[lindex $item 0] != "item"} return
		set it [lindex $item 1]
		openClickedItem $it
	}
}

body DBTree::delSelectedDB {} {
	set it [$_tree item id active]
	if {$it == "" || $it == 0} return
	set data [getData $it]
	set db [lindex $data 1]

	catch {destroy .delDb}
	set dialog [YesNoDialog .delDb -title [mc {Remove database}] -message [mc {Are you sure you want to remove '%s' database from the list?} [$db getName]]]
	if {[$dialog exec]} {
		delDB $db
		refreshSchema
	}
}

body DBTree::describeActiveItem {} {
	set it [$_tree item id active]
	if {$it != "" && $it != 0} {
		set data [getData $it]
		set db [lindex $data 1]
		set open [$db isOpen]
		
		return [dict create item $it db $db dbOpen $open data $data]
	} else {
		return [dict create item ""]
	}
}

# body DBTree::refreshToolbar {} {
# 	set it [$_tree item id active]
# 	if {$it != "" && $it != 0} {
# 		set data [getData $it]
# 		set db [lindex $data 1]
# 
# 		set open [$db isOpen]
# 		set openNeg [expr {!$open}]
# 		if {$open} {
# 			MAIN setTBActive open_db false
# 			MAIN setTBActive close_db true
# 		} else {
# 			MAIN setTBActive open_db true
# 			MAIN setTBActive close_db false
# 		}
# 
# 		foreach id {
# 			databases:remove
# 			databases:edit
# 		} {
# 			MAIN setMenuActive $id true
# 		}
# 
# # 		foreach id {
# # 			databases:connect
# # 		} {
# # 			MAIN setMenuActive $id $openNeg
# # 		}
# 
# # 		foreach id {
# # 			databases:disconnect
# # 			databases:refresh
# # 			databases:export
# # 		} {
# # 			MAIN setMenuActive $id $open
# # 		}
# 
# 		foreach bt {
# 			del_table
# 			edit_table
# 			del_index
# 			edit_index
# 			del_trigger
# 			edit_trigger
# 			del_view
# 			edit_view
# 		} {
# 			MAIN setTBActive $bt false
# 		}
# 		foreach bt {
# 			rem_db
# 			edit_db
# 		} {
# 			MAIN setTBActive $bt true
# 		}
# 		foreach bt {
# 			close_db
# 			new_table
# 			new_index
# 			new_trigger
# 			new_view
# 		} {
# 			MAIN setTBActive $bt $open
# 		}
# 		if {$open} {
# 			switch -- [lindex $data 0] {
# 				"TABLE" {
# 					MAIN setTBActive del_table true
# 					MAIN setTBActive edit_table true
# 				}
# 				"INDEX" {
# 					MAIN setTBActive del_index true
# 					MAIN setTBActive edit_index true
# 				}
# 				"TRIGGER" {
# 					MAIN setTBActive del_trigger true
# 					MAIN setTBActive edit_trigger true
# 				}
# 				"VIEW" {
# 					MAIN setTBActive del_view true
# 					MAIN setTBActive edit_view true
# 				}
# 			}
# 		}
# 	} else {
# 		foreach bt {
# 			edit_db
# 			rem_db
# 			open_db
# 			close_db
# 		} {
# 			MAIN setTBActive $bt false
# 		}
# 		foreach bt {
# 			new_table
# 			edit_table
# 			del_table
# 			new_index
# 			edit_index
# 			del_index
# 			new_trigger
# 			edit_trigger
# 			del_trigger
# 			new_view
# 			edit_view
# 			del_view
# 		} {
# 			MAIN setTBActive $bt false
# 		}
# 
# 		foreach id {
# 			databases:remove
# 			databases:edit
# 			databases:disconnect
# 			databases:refresh
# 			databases:export
# 		} {
# 			MAIN setMenuActive $id false
# 		}
# 	}
# }

body DBTree::deleteSelectedItem {} {
	set it [$_tree item id active]
	if {$it == "" || $it == "0"} return
	set data [getData $it]
	set db [lindex $data 1]
	if {$db != "" && [$db isOpen]} {
		switch -- [lindex $data 0] {
			"DATABASE" {
				delSelectedDB
			}
			"TABLE" {
				delTable
			}
			"INDEX" {
				delIndex
			}
			"TRIGGER" {
				delTrigger
			}
			"VIEW" {
				delView
			}
		}
	}
}

body DBTree::connectToSelected {} {
	set it [$_tree item id active]
	if {$it == "" || $it == 0} return
	set data [getData $it]
	set db [lindex $data 1]

	if {[lindex $data 0] != "DATABASE"} return
	if {[$db isOpen]} return
	$db open
	MAIN updateMenuAndToolbar
}

body DBTree::disconnectFromSelected {} {
	set it [$_tree item id active]
	if {$it == "" || $it == 0} return
	set data [getData $it]
	set db [lindex $data 1]

	if {![$db isOpen]} return
	$db close
	MAIN updateMenuAndToolbar
}

body DBTree::openClickedItem {it} {
	if {$it == "" || $it == 0} return
	set data [getData $it]
	set db [lindex $data 1]

	switch -- [lindex $data 0] {
		"DATABASE" {
			if {[$db isOpen]} {
				if {[$_tree item isopen $it]} {
					$_tree item collapse $it
				} else {
					$_tree item expand $it
				}
			} else {
				$db open
			}
		}
		"TABLE" {
			openTableWindow $db [lindex $data 2]
		}
		"INDEX" {
			editIndex
		}
		"TRIGGER" {
			editTrigger
		}
		"VIEW" {
			switch -- $viewOpenMode {
				"dialog" {
					editView
				}
				"data" {
					showViewData
				}
			}
		}
		"COLUMN" {
			set table [lindex $data 2]
			set column [lindex $data 3]
			editColumn $db $table $column
		}
		default {
			if {!$singleClick} {
				if {[$_tree item isopen $it]} {
					$_tree item collapse $it
				} else {
					$_tree item expand $it
				}
			}
		}
	}
}

body DBTree::doubleClicked {x y} {
	BrowserTree::doubleClicked $x $y
	if {!$singleClick} {
		set item [$_tree identify $x $y]
		if {[lindex $item 0] != "item"} return
		set it [lindex $item 1]
		openClickedItem $it
	}
}

body DBTree::enterPresed {} {
	set it [getSelectedItem]
	if {$it == ""} return
	openClickedItem $it
}

body DBTree::editColumn {db table column} {
	if {![ModelExtractor::hasDdl $db $table]} {
		Info [mc {Table '%s' has no DDL. Probably it doesn't exist anymore, or it's system table.} $table]
		return
	}

	catch {destroy .editTable}
	set dialog [TableDialog .editTable -title [mc {Edit table}] -db $db -table $table -editcolumn $column]
	$dialog exec
}

body DBTree::openTableWindow {db table} {
	set origName $table
	set table [$db getObjectProperName $table]
	if {[string trim $table] == "" && [string trim $origName] != ""} {
		if {![ModelExtractor::isSupportedSystemTable $table] && ![ModelExtractor::hasDdl $db $table]} {
			Info [mc {Table '%s' has no DDL. Probably it's system table and cannot be accessed with table window.} $origName]
		} else {
			# No such object in database
			debug "Couldn't find object with name '$origName' in database while trying to open table window."
		}
		return ""
	}
	set title [TableWin::formatTitle $table [$db getName]]
	if {[TASKBAR taskExists $title]} {
		TASKBAR select $title
		return [[TASKBAR getTaskByTitle $title] getWinObj]
	} else {
		set tables [$db getTables]
		if {$table in $tables} {
			# Check if it's a virtual table
			if {[$db isVirtualTable $table]} {
				Info [mc {'%s' is a virtual table, therefore cannot be browsed in table window.} $table]
				return ""
			}
			return [TASKBAR createTask TableWin $title $db $table]
		} else {
			return ""
		}
	}
}

body DBTree::getActiveDatabases {} {
	set dblist [list]
	foreach db $_dblist {
		if {[$db isOpen]} {
			lappend dblist $db
		}
	}
	return $dblist
}

body DBTree::getDBByName {name} {
	foreach db $_dblist {
		if {[string equal -nocase [$db getName] $name]} {
			return $db
		}
	}
	return ""
}

body DBTree::getDBByPath {path} {
	if {[tk windowingsystem] == "x11"} {
		# Only UNIXes use case-sensitive FS
		foreach db $_dblist {
			if {[string equal [$db getPath] $path]} {
				return $db
			}
		}
	} else {
		foreach db $_dblist {
			if {[string equal -nocase [$db getPath] $path]} {
				return $db
			}
		}
	}
	return ""
}

body DBTree::newTable {} {
	set it [$_tree item id active]
	if {$it == "" || $it == "0"} return
	set data [getData $it]
	set db [lindex $data 1]
	catch {destroy .newTable}
	if {$db != "" && [$db isOpen]} {
		set dialog [TableDialog .newTable -title [mc {New table}] -db $db]
	} else {
		set dialog [TableDialog .newTable -title [mc {New table}]]
	}
	$dialog exec
}

body DBTree::editTable {} {
	# Get tree node and its data
	set it [$_tree item id active]
	if {$it == "" || $it == 0} return
	set data [getData $it]
	set db [lindex $data 1]
	if {[lindex $data 0] != "TABLE"} return
	set table [lindex $data 2]

	set parser [UniversalParser ::#auto $db]
	if {[catch {set model [ModelExtractor::getModelForEditDialog $db $table table $parser]} err]} {
		if {$::errorCode == 5} {
			delete object $parser
			error $err
		} else {
			debug $err
		}
	}
	if {(![info exists model] || $model == "") && ![ModelExtractor::isSupportedSystemTable $table]} {
		Info [mc {Table '%s' has no DDL. Probably it's system table and should not be edited.} $table]
		delete object $parser
		return
	}

	# Check if it's a virtual table
	if {[$db isVirtualTable $table]} {
		Info [mc {'%s' is a virtual table, therefore cannot be edited in table dialog.} $table]
		delete object $parser
		return
	}

	# Open dialog
	catch {destroy .editTable}
	set dialog [TableDialog .editTable -title [mc {Edit table}] -db $db -table $table -model $model]
	$dialog exec
	delete object $parser
}

body DBTree::createSimilarTable {} {
	# Get tree node and its data
	set it [$_tree item id active]
	if {$it == "" || $it == 0} return
	set data [getData $it]
	set db [lindex $data 1]
	if {[lindex $data 0] != "TABLE"} return
	set table [lindex $data 2]

	set parser [UniversalParser ::#auto $db]
	if {[catch {set model [ModelExtractor::getModelForEditDialog $db $table table $parser]} err]} {
		if {$::errorCode == 5} {
			delete object $parser
			error $err
		} else {
			debug $err
		}
	}
	if {![info exists model] || $model == ""} {
		Info [mc {Table '%s' has no DDL. Probably it doesn't exist anymore, or it's system table.} $table]
		delete object $parser
		return
	}

	# Check if it's a virtual table
	if {[$db isVirtualTable $table]} {
		Info [mc {'%s' is a virtual table. Creating similar tables is possible only for regular SQLite tables.} $table]
		delete object $parser
		return
	}

	# Open dialog
	catch {destroy .similarTable}
	set dialog [TableDialog .similarTable -title [mc {Create similar table}] -db $db -table $table -similar true]
	$dialog exec
	delete object $parser
}

body DBTree::resetAutoIncrement {} {
	# Get tree node and its data
	set it [$_tree item id active]
	if {$it == "" || $it == 0} return
	set data [getData $it]
	set db [lindex $data 1]
	if {[lindex $data 0] != "TABLE"} return
	set table [lindex $data 2]

	$db eval {DELETE FROM sqlite_sequence WHERE name = $table}
}

body DBTree::integrityCheck {} {
	# Get tree node and its data
	set it [$_tree item id active]
	if {$it == "" || $it == 0} return
	set data [getData $it]
	if {[lindex $data 0] != "DATABASE"} return
	set db [lindex $data 1]

	set title [mc {Integrity check (%s)} [$db getName]]
	if {[TASKBAR taskExists $title]} {
		set task [TASKBAR getTaskByTitle $title]
		set edit [$task getWinObj]
	} else {
		set edit [MainWindow::openSqlEditor $title]
		set task [TASKBAR getTaskByTitle $title]
	}
	$edit setDatabase $db
	$edit setSQL "PRAGMA integrity_check;\n"
	$edit execQuery
	update idletasks
	$task setActive
}

body DBTree::delTable {} {
	set it [$_tree item id active]
	if {$it == "" || $it == "0"} return
	set data [getData $it]
	set db [lindex $data 1]
	if {$db != "" && [$db isOpen]} {
		if {[lindex $data 0] == "TABLE"} {
			set table [lindex $data 2]

			if {![ModelExtractor::hasDdl $db $table]} {
				return
			}

			catch {destroy .delTable}
			set dialog [YesNoDialog .delTable -title [mc {Drop table}] -message [mc {Are you sure you want to DROP '%s' table?} $table]]

			if {"IF_EXISTS" in [[$db info class]::getUnsupportedFeatures]} {
				set sql "DROP TABLE [wrapObjName $table [$db getDialect]]"
			} else {
				set sql "DROP TABLE IF EXISTS [wrapObjName $table [$db getDialect]]"
			}

			if {[$dialog exec]} {
				set progressArgs [list [mc {Dropping table}] [mc {Dropping table '%s'} $table] false 50 false]
				set progress [BusyDialog::show {*}$progressArgs]
				BusyDialog::autoProgress 20

				# Check for VIEW dependencies and ask user what to do
				set views [list]
				if {[isTableUsedByAnyView $db $table views]} {
					set dialog [YesNoDialog .delTable -title [mc {Drop table}] -message [mc "Table '%s' is used by views:\n%s.\nThose views will become unusable.\nDo you want to drop the table anyway?" $table [join $views {, }]]]
					BusyDialog::hide
					if {![$dialog exec]} {
						return
					}
					set progress [BusyDialog::show {*}$progressArgs]
					BusyDialog::autoProgress 20
				}

				# Do the DROP
				if {[catch {
					set queryExecutor [QueryExecutor ::#auto $db]
					$queryExecutor configure -execInThread true
					set execResult [$queryExecutor exec $sql]
					delete object $queryExecutor
				} err]} {
					BusyDialog::hide
					cutOffStdTclErr err
					Error $err
				} else {
					refreshSchemaForDb $db
					if {[dict get $execResult returnCode] != 0} {
						Error [join [dict get $execResult errors] \n]
					} else {
						TASKBAR signal TableWin [list CLOSE $table]
						MAIN updateMenuAndToolbar
					}
					BusyDialog::hide
				}
			}
		}
	}
}

body DBTree::newIndex {} {
	set it [$_tree item id active]
	if {$it == "" || $it == "0"} return
	set data [getData $it]
	set type [lindex $data 0]
	set db [lindex $data 1]

	set table ""
	if {$type == "TABLE"} {
		set table [lindex $data 2]
	} elseif {$displayMode == "objectsUnderTable"} {
		if {$type == "INDEXES" || $type == "TRIGGERS"} {
			set tableIt [$_tree item id "$it parent"]
			set data [getData $tableIt]
			set table [lindex $data 2]
		} elseif {$type == "INDEX" || $type == "TRIGGER"} {
			set parentIt [$_tree item id "$it parent"]
			set tableIt [$_tree item id "$parentIt parent"]
			set data [getData $tableIt]
			set table [lindex $data 2]
		}
	}

	catch {destroy .newIndex}
	if {$db != "" && [$db isOpen]} {
		set dialog [IndexDialog .newIndex -title [mc {New index}] -preselecttable $table -db $db]
	} else {
		set dialog [IndexDialog .newIndex -title [mc {New index}] -preselecttable $table]
	}
	$dialog exec
}

body DBTree::editIndex {} {
	set it [$_tree item id active]
	if {$it == "" || $it == "0"} return
	set data [getData $it]
	set db [lindex $data 1]
	if {!($db != "" && [$db isOpen] && [lindex $data 0] == "INDEX")} return
	set idx [lindex $data 2]

	set parser [UniversalParser ::#auto $db]
	if {[catch {set model [ModelExtractor::getModelForEditDialog $db $idx index $parser]} err]} {
		if {$::errorCode == 5} {
			delete object $parser
			error $err
		} else {
			debug $err
		}
	}
	if {![info exists model] || $model == ""} {
		Info [mc {Index '%s' has no DDL. Probably it's system index and should not be edited.} $idx]
		delete object $parser
		return
	}

	# Open dialog
	catch {destroy .editIndex}
	set dialog [IndexDialog .editIndex -title [mc {Edit index}] -db $db -index $idx -model $model]
	$dialog exec
	delete object $parser
}

body DBTree::delIndex {} {
	set it [$_tree item id active]
	if {$it == "" || $it == "0"} return
	set data [getData $it]
	set db [lindex $data 1]
	if {$db != "" && [$db isOpen]} {
		if {[lindex $data 0] == "INDEX"} {
			set idx [lindex $data 2]
			set dialog [YesNoDialog .yesno -title [mc {Delete index}] -message [mc {Are you sure you want to delete '%s' index?} $idx]]

			if {"IF_EXISTS" in [[$db info class]::getUnsupportedFeatures]} {
				set sql "DROP INDEX [wrapObjName $idx [$db getDialect]]"
			} else {
				set sql "DROP INDEX IF EXISTS [wrapObjName $idx [$db getDialect]]"
			}

			if {[$dialog exec]} {
				set progress [BusyDialog::show [mc {Dropping index}] [mc {Dropping index '%s'} $idx] false 50 false]
				BusyDialog::autoProgress 20

				if {[catch {
					set queryExecutor [QueryExecutor ::#auto $db]
					$queryExecutor configure -execInThread true
					set execResult [$queryExecutor exec $sql]
					delete object $queryExecutor
				} err]} {
					BusyDialog::hide
					cutOffStdTclErr err
					Error $err
				} else {
					refreshSchemaForDb $db
					if {[dict get $execResult returnCode] != 0} {
						Error [join [dict get $execResult errors] \n]
					} else {
						TASKBAR signal TableWin [list REFRESH_IDX $idx]
						MAIN updateMenuAndToolbar
					}
					BusyDialog::hide
				}
			}
		}
	}
}

body DBTree::newTrigger {} {
	set it [$_tree item id active]
	if {$it == "" || $it == "0"} return
	set data [getData $it]
	set type [lindex $data 0]
	set db [lindex $data 1]

	set table ""
	set useTable 0
	if {$type == "TABLE"} {
		set table [lindex $data 2]
		set useTable 1
	} elseif {$displayMode == "objectsUnderTable"} {
		if {$type == "INDEXES" || $type == "TRIGGERS"} {
			set tableIt [$_tree item id "$it parent"]
			set data [getData $tableIt]
			set table [lindex $data 2]
			set useTable 1
		} elseif {$type == "INDEX" || $type == "TRIGGER"} {
			set parentIt [$_tree item id "$it parent"]
			set tableIt [$_tree item id "$parentIt parent"]
			set data [getData $tableIt]
			set table [lindex $data 2]
			set useTable 1
		}
	}


	catch {destroy .newTrig}
	if {$db != "" && [$db isOpen]} {
		if {$useTable} {
			set dialog [TriggerDialog .newTrig -title [mc {New trigger}] -db $db -preselecttable $table]
		} else {
			set dialog [TriggerDialog .newTrig -title [mc {New trigger}] -db $db]
		}
	} else {
		set dialog [NewTriggerDialog .newTrig -title [mc {New trigger}]]
	}
	$dialog exec
}

body DBTree::editTrigger {} {
	set it [$_tree item id active]
	if {$it == "" || $it == "0"} return
	set data [getData $it]
	set db [lindex $data 1]
	if {!($db != "" && [$db isOpen] && [lindex $data 0] == "TRIGGER")} return

	set trig [lindex $data 2]

	set parser [UniversalParser ::#auto $db]
	if {[catch {set model [ModelExtractor::getModelForEditDialog $db $trig trigger $parser]} err]} {
		if {$::errorCode == 5} {
			delete object $parser
			set msg [mc "The Trigger '%s' has invalid DDL statement. You cannot edit it in dialog window. You need to drop it and recreate with valid syntax.\n\nSQLiteStudio can put DDL of this trigger into new SQL editor window so you can see what's wrong and fix it. Would you like SQLiteStudio to do so?" $trig]
			if {[YesNoDialog::warning $msg]} {
				set dialect [$db getDialect]
				set editor [MAIN openSqlEditor [mc {Fix trigger}]]
				$editor setDatabase $db
				set contents "-- DROP old, invalid trigger\n"
				append contents "DROP TRIGGER [wrapObjIfNeeded $trig $dialect];\n\n"
				append contents "-- Create fixed trigger. Fix syntax errors marked in red:\n"
				append contents [ModelExtractor::getObjectDdl $db $trig]
				$editor setSQL $contents
			}
			return
		} else {
			debug $err
		}
	}
	if {![info exists model] || $model == ""} {
		Info [mc "Trigger '%s' has no DDL.\nProbably it's system trigger and should not be edited." $trig]
		delete object $parser
		return
	}

	catch {destroy .editTrig}
	set dialog [TriggerDialog .editTrig -title [mc {Edit trigger}] -db $db -trigger $trig]
	$dialog exec
	delete object $parser
}

body DBTree::delTrigger {} {
	set it [$_tree item id active]
	if {$it == "" || $it == "0"} return
	set data [getData $it]
	set db [lindex $data 1]
	if {$db != "" && [$db isOpen]} {
		if {[lindex $data 0] == "TRIGGER"} {
			set trig [lindex $data 2]
			set dialog [YesNoDialog .yesno -title [mc {Delete trigger}] -message [mc {Are you sure you want to delete '%s' trigger?} $trig]]

			if {"IF_EXISTS" in [[$db info class]::getUnsupportedFeatures]} {
				set sql "DROP TRIGGER [wrapObjName $trig [$db getDialect]]"
			} else {
				set sql "DROP TRIGGER IF EXISTS [wrapObjName $trig [$db getDialect]]"
			}

			if {[$dialog exec]} {
				# TODO: 'IF EXISTS' isn't handled by sqlite, throws exception
				#$db eval "DROP TRIGGER IF EXISTS \[$trig]"
				if {[catch {
					$db eval $sql
				} err]} {
					cutOffStdTclErr err
					Error $err
				} else {
					refreshSchemaForDb $db
					TASKBAR signal TableWin [list REFRESH_TRIG $trig]
					MAIN updateMenuAndToolbar
				}
			}
		}
	}
}

body DBTree::newView {} {
	set it [$_tree item id active]
	if {$it == "" || $it == "0"} return
	set data [getData $it]
	set db [lindex $data 1]
	catch {destroy .newView}
	if {$db != "" && [$db isOpen]} {
		set dialog [ViewDialog .newView -title [mc {New view}] -db $db]
	} else {
		set dialog [ViewDialog .newView -title [mc {New view}]]
	}
	$dialog exec
}

body DBTree::editView {} {
	set it [$_tree item id active]
	if {$it == "" || $it == "0"} return
	set data [getData $it]
	set db [lindex $data 1]
	if {!($db != "" && [$db isOpen] && [lindex $data 0] == "VIEW")} return

	set view [lindex $data 2]

	set parser [UniversalParser ::#auto $db]
	if {[catch {set model [ModelExtractor::getModelForEditDialog $db $view view $parser]} err]} {
		if {$::errorCode == 5} {
			delete object $parser
			set msg [mc "The View '%s' has invalid DDL statement. You cannot edit it in dialog window. You need to drop it and recreate with valid syntax.\n\nSQLiteStudio can put DDL of this view into new SQL editor window so you can see what's wrong and fix it. Would you like SQLiteStudio to do so?" $view]
			if {[YesNoDialog::warning $msg]} {
				set dialect [$db getDialect]
				set editor [MAIN openSqlEditor [mc {Fix view}]]
				$editor setDatabase $db
				set contents "-- DROP old, invalid view\n"
				append contents "DROP VIEW [wrapObjIfNeeded $view $dialect];\n\n"
				append contents "-- Create fixed view. Fix syntax errors marked in red:\n"
				append contents [ModelExtractor::getObjectDdl $db $view]
				$editor setSQL $contents
			}
			return
		} else {
			debug $err
		}
	}
	if {![info exists model] || $model == ""} {
		Info [mc {View '%s' has no DDL. Probably it's system view and should not be edited.} $view]
		delete object $parser
		return
	}

	catch {destroy .editView}
	set dialog [ViewDialog .editView -title [mc {Edit view}] -db $db -view $view]
	$dialog exec
	delete object $parser
}

body DBTree::delView {} {
	set it [$_tree item id active]
	if {$it == "" || $it == "0"} return
	set data [getData $it]
	set db [lindex $data 1]
	if {$db != "" && [$db isOpen]} {
		if {[lindex $data 0] == "VIEW"} {
			set view [lindex $data 2]
			set dialog [YesNoDialog .yesno -title [mc {Delete view}] -message [mc {Are you sure you want to delete '%s' view?} $view]]

			if {"IF_EXISTS" in [[$db info class]::getUnsupportedFeatures]} {
				set sql "DROP VIEW [wrapObjName $view [$db getDialect]]"
			} else {
				set sql "DROP VIEW IF EXISTS [wrapObjName $view [$db getDialect]]"
			}

			if {[$dialog exec]} {
				if {[catch {
					$db eval $sql
				} err]} {
					cutOffStdTclErr err
					Error $err
				} else {
					refreshSchemaForDb $db
				}
			}
		}
	}
}

body DBTree::isTableUsedByAnyView {db table viewsVar} {
	upvar $viewsVar views

	set parser [UniversalParser ::#auto $db]
	$parser configure -expectedTokenParsing false -sameThread false

	set viewDdls [list]
	$db eval {SELECT name, sql FROM sqlite_master WHERE type = 'view'} row {
		lappend viewDdls [list $row(name) $row(sql)]
	}

	foreach view $viewDdls {
		lassign $view name ddl
		$parser parseSql $ddl
		set parsedDict [$parser get]
		if {[dict get $parsedDict returnCode] != 0} {
			debug "Could not parse:\n$ddl"
			continue
		}
		set obj [dict get $parsedDict object]
		set tables [$obj getContextInfo "ALL_TABLE_NAMES"]
		foreach t $tables {
			if {[string equal -nocase [dict get $t table] $table]} {
				lappend views $name
				break
			}
		}
		$parser freeObjects
	}

	delete object $parser

	return [expr {[llength $views] > 0}]
}

body DBTree::eraseTableData {} {
	set it [$_tree item id active]
	if {$it == "" || $it == "0"} return
	set data [getData $it]
	set db [lindex $data 1]
	if {$db != "" && [$db isOpen]} {
		if {[lindex $data 0] == "TABLE"} {
			set table [lindex $data 2]

			catch {destroy .eraseTableData}
			set dialog [YesNoDialog .eraseTableData -title [mc {Erase data}] -message [mc {Are you sure you want to delete all data from table '%s'?} $table]]

			set sql "DELETE FROM [wrapObjIfNeeded $table [$db getDialect]]"
			if {[$dialog exec]} {
				set progress [BusyDialog::show [mc {Deleting data}] [mc {Deleting data from table '%s'} $table] false 50 false]
				BusyDialog::autoProgress 20

				if {[catch {
					set queryExecutor [QueryExecutor ::#auto $db]
					$queryExecutor configure -execInThread true
					set execResult [$queryExecutor exec $sql]
					delete object $queryExecutor
				} err]} {
					BusyDialog::hide
					cutOffStdTclErr err
					Error $err
				} else {
					BusyDialog::hide
					TASKBAR signal TableWin [list REFRESH_DATA $table]
				}
			}
		}
	}
}

body DBTree::signal {receiver data} {
	if {[$this isa $receiver]} {
		if {[lindex $data 0] == "REFRESH"} {
			if {[lindex $data 1] == "DB_OBJ"} {
				set db [lindex $data 2]
				if {[catch {
					refreshSchemaForDb $db
				} err]} {
					refreshSchema
				}
			} elseif {[lindex $data 1] == "DB_NAME"} {
				set db [getDBByName [lindex $data 2]]
				if {$db != ""} {
					refreshSchemaForDb $db
				} else {
					refreshSchema
				}
			} elseif {[lindex $data 1] == "toolbar"} {
				MAIN updateMenuAndToolbar
			} else {
				refreshSchema
			}
		}
	}
	foreach db $_dblist {
		$db signal $receiver $data
	}
}

body DBTree::showViewData {} {
	lassign [getSelectedView] db view
	if {$view == "" || $db == ""} return

	set title [mc {'%s' view data} $view]
	if {[TASKBAR taskExists $title]} {
		set task [TASKBAR getTaskByTitle $title]
		set edit [$task getWinObj]
	} else {
		set edit [MainWindow::openSqlEditor $title]
		set task [TASKBAR getTaskByTitle $title]
	}
	$edit setDatabase $db
	$edit setSQL "SELECT * FROM [wrapObjName $view [$db getDialect]];\n"
	$edit execQuery
	update idletasks
	$task setActive
}

body DBTree::exportDB {} {
	set db [getSelectedDb]
	if {$db == "" || ![$db isOpen]} return

	catch {destroy .exportTable}
	ExportDialog .exportTable -showdb true -title [mc {Export database}] -db $db -readonly true -type database
	.exportTable exec
}

body DBTree::vacuumDB {} {
	set db [getSelectedDb]
	if {$db == "" || ![$db isOpen]} return

	catch {destroy .yesno}
	YesNoDialog .yesno -message [mc {Are you sure you want to make a vacuum?}]
	if {[.yesno exec]} {
		set progress [BusyDialog::show [mc {Vacuuming}] [mc {Vacuuming '%s'} [$db getName]] false 50 false]
		BusyDialog::autoProgress 20

		if {[catch {
			set queryExecutor [QueryExecutor ::#auto $db]
			$queryExecutor configure -execInThread true -noTransaction true
			set execResult [$queryExecutor exec "VACUUM"]
			delete object $queryExecutor
		} err]} {
			BusyDialog::hide
			cutOffStdTclErr err
			Error $err
		} else {
			BusyDialog::hide
		}
	}
}

body DBTree::exportTable {} {
	lassign [getSelectedTable] db table
	if {$table == ""} {
		lassign [getSelectedView] db table
		if {$table == ""} {
			return
		}
	}
	catch {destroy .exportTable}

	set dialog [ExportDialog .exportTable -showdb true -showtable true -title [mc {Export}] -type table -db $db -table $table]
	$dialog exec
}

body DBTree::importTable {} {
	lassign [getSelectedTable] db table
	if {![info exists db] || $db == ""} {
		set db [getSelectedDb]
		if {$db == "" || ![$db isOpen]} return
		set tab [list -newtable ""]
	} else {
		if {![$db isOpen]} return
		if {$table == ""} {
			set tab [list -newtable ""]
		} else {
			set tab [list -existingtable $table]
		}
	}

	catch {destroy .importTable}

	set dialog [ImportDialog .importTable -title [mc {Import data}] -db $db {*}$tab]
	$dialog exec
}

body DBTree::updateShortcuts {} {
	bind $_tree <${::Shortcuts::refresh}> "$this refreshSchema"
}

body DBTree::clearShortcuts {} {
	bind $_tree <${::Shortcuts::refresh}> ""
}

body DBTree::executeSqlFromFile {{db ""}} {
	if {$db == ""} {
		set db [getSelectedDb]
	}
	if {$db == "" || ![$db isOpen]} return

	set types [list \
		[list [mc {SQL files}]				{.sql}] \
		[list [mc {All files}]				{*}] \
	]
	set f [GetOpenFile -title [mc {Select SQL file to be executed}] -filetypes $types -parent .]
	if {$f == ""} return

	if {[catch {$db sqlFromFile $f true} res]} {
		Warning [mc "Error while executing SQL:\n%s" $res]
	} else {
		Info [mc {SQL executed sucessfly.}]
	}
}

body DBTree::importSchemaFromOtherDb {} {
	set db [getSelectedDb]
	if {$db == "" || ![$db isOpen]} return
	catch {destroy .importDB}
	set dialog [ImportDbDialog .importDB -db $db -title [mc {Import database schema}]]
	$dialog exec
}

body DBTree::populateTable {} {
	lassign [getSelectedTable] db table
	if {$table == ""} return

	if {[winfo exists .populateTable]} {
		destroy .populateTable
	}

	set dialog [PopulateTableDialog .populateTable -db $db -table $table -title [mc {Populate table}]]
	$dialog exec
}

body DBTree::getSelectedDb {} {
	set it [$_tree item id active]
	if {$it == "" || $it == "0"} return
	set data [getData $it]
	set db [lindex $data 1]
	if {$db == ""} return
	return $db
}

body DBTree::getSelectedTable {} {
	set it [$_tree item id active]
	if {$it == "" || $it == "0"} return
	set data [getData $it]
	set db [lindex $data 1]
	if {!($db != "" && [$db isOpen])} return
	if {[lindex $data 0] != "TABLE"} return
	set table [lindex $data 2]

	return [list $db $table]
}

body DBTree::getSelectedView {} {
	set it [$_tree item id active]
	if {$it == "" || $it == "0"} return
	set data [getData $it]
	set db [lindex $data 1]
	if {!($db != "" && [$db isOpen])} return
	if {[lindex $data 0] != "VIEW"} return
	set view [lindex $data 2]

	return [list $db $view]
}

body DBTree::getSelectedIndex {} {
	set it [$_tree item id active]
	if {$it == "" || $it == "0"} return
	set data [getData $it]
	set db [lindex $data 1]
	if {!($db != "" && [$db isOpen])} return
	if {[lindex $data 0] != "INDEX"} return
	set index [lindex $data 2]

	return [list $db $index]
}

body DBTree::getSelectedTrigger {} {
	set it [$_tree item id active]
	if {$it == "" || $it == "0"} return
	set data [getData $it]
	set db [lindex $data 1]
	if {!($db != "" && [$db isOpen])} return
	if {[lindex $data 0] != "TRIGGER"} return
	set trig [lindex $data 2]

	return [list $db $trig]
}

body DBTree::convertDb {} {
	set it [$_tree item id active]
	if {$it == "" || $it == "0"} return
	set data [getData $it]
	set db [lindex $data 1]
	if {!($db != "" && [$db isOpen])} return

	if {[winfo exists .convertDb]} {
		destroy .convertDb
	}

	set dialog [DbConvertDialog .convertDb -db $db]
	$dialog exec
}

body DBTree::getRegisteredDatabaseList {} {
	set dbList [list]
	foreach db $_dblist {
		lappend dbList $db
	}
	return $dbList
}

body DBTree::sortDatabases {} {
	set _dblist [lsort -command DB::sortByName $_dblist]
	$_tree item sort root -dictionary
	saveDBCfg
}

body DBTree::itemEnter {it col} {
	helpHint_onEnter $_tree $it [list $this helpHint] 1000 false
}

body DBTree::itemLeave {it col} {
	helpHint_onLeave $_tree $it $helpHintWin [list $this helpHint] 1000 false
}

body DBTree::tracerButtonPressed {button it col} {
	helpHint_onLeave $_tree $it $helpHintWin [list $this helpHint] 1000 false
}

body DBTree::initHelpHint {} {
	initFancyHelpHint $helpHintWin
}

body DBTree::helpHint {w it} {
	set data [getData $it]
	set type [lindex $data 0]
	if {$type ni [list "DATABASE" "TABLE" "INDEX" "TRIGGER" "VIEW" "COLUMN"]} {
		return
	}

	if {$type == "TABLE" && $displayMode != "objectsUnderTable"} {
		return
	}

	if {$type in [list "INDEX" "TRIGGER"] && $displayMode != "flat"} {
		return
	}

	set cmd "$this fillHint [list $data] \$container"
	raiseFancyHelpHint $helpHintWin $cmd $w $data
}

body DBTree::fillHint {data hintTable} {
	set db [lindex $data 1]
	switch -- [lindex $data 0] {
		"DATABASE" {
			$hintTable setTitle [mc {Database: %s} [$db getName]]

			set dialect [$db getDialect]
			set path [$db getPath]
			set version [[$db getHandler]::getHandlerLabel]
			set fileSize [formatFileSize [file size $path]]
			
			set quietOpen 0
			if {![$db isOpen]} {
				$db quietOpen
				set quietOpen 1
			}
			
			if {[$db isOpen]} {
				if {$dialect == "sqlite3"} {
					set schemaVersion [$db onecolumn "PRAGMA schema_version;"]
					set encoding [$db onecolumn "PRAGMA encoding;"]
				}

				if {$quietOpen} {
					$db quietClose
				}
			}
			
			foreach var {
				path
				version
				fileSize
				schemaVersion
				encoding
			} label [list \
				[mc {URI:}] \
				[mc {Version:}] \
				[mc {File size:}] \
				[mc {Schema version:}] \
				[mc {Encoding:}] \
			] {
				if {![info exists $var]} continue
				$hintTable addRow $label [set $var]
			}
		}
		"TABLE" {
			# This is executed only for "objectsUnderTable"
			set table [lindex $data 2]
			set lowerTable [string tolower $table]
			if {[$db isVirtualTable $table]} {
				$hintTable setMode "img-label"
				$hintTable addRow img_virtual_table [mc {Virtual table}]
			} else {
				set indexes [list]
				set triggers [list]
				set columns [$db getColumns $table]

				foreach child [getChilds $_treeNode(INDEXES:$db:$lowerTable)] {
					lappend indexes [$this getText $child]
				}

				foreach child [getChilds $_treeNode(TRIGGERS:$db:$lowerTable)] {
					lappend triggers [$this getText $child]
				}

				$hintTable setTitle [mc {Table: %s} $table]
				$hintTable setMode "img-label-label"
				$hintTable setValueWrapLength 300
				$hintTable addRow [list img_column [mc {Columns:}]] [join $columns ", "]
				$hintTable addRow [list img_index [mc {Indexes:}]] [join $indexes ", "]
				$hintTable addRow [list img_trigger [mc {Triggers:}]] [join $triggers ", "]
			}
		}
		"COLUMN" {
			set table [lindex $data 2]
			set column [lindex $data 3]
			$hintTable setTitle [mc {Column: %s} $column]
			$hintTable setMode "img-label-label"
			$hintTable setValueWrapLength 300

			set columnInfo [$db getColumnInfo $table $column]
			$hintTable addRow [list img_column [mc {Data type}]] [dict get $columnInfo type]
			foreach {key img label1 label2} [list \
				pk			img_constr_pk		[mc {Primary key}] "" \
				fk			img_fk_col			[mc {Foreign key}] [lindex [dict get $columnInfo fk] 1] \
				notnull		img_constr_notnull	[mc {Not null}] "" \
				unique		img_constr_uniq		[mc {Unique}] "" \
				check		img_constr_check	[mc {Check condition}] [lindex [dict get $columnInfo check] 1] \
				collate		img_constr_collate	[mc {Collate}] [lindex [dict get $columnInfo collate] 1] \
				default		img_constr_default	[mc {Default value}] [lindex [dict get $columnInfo default] 1] \
			] {
				if {[lindex [dict get $columnInfo $key] 0]} {
					$hintTable addRow [list $img $label1] $label2
				}
			}
		}
		"INDEX" {
			# This is executed only for "flat"
			set dialect [$db getDialect]
			set index [lindex $data 2]
			set sql [$db getSqliteObjectDdl index $index]

			# Parse index and get referenced table
			set parser [UniversalParser ::#auto]
			$parser parseSql $sql
			set parsedDict [$parser get]
			if {[dict get $parsedDict returnCode] != 0} {
				debug "Could not parse index while filling helpHint for DBTree:\n[dict get $parsedDict errorMessage]"
				continue
			}
			set obj [dict get $parsedDict object]
			set idxStmt [$obj getValue subStatement]
			set idxTable [$idxStmt getValue onTable]
			$parser freeObjects
			delete object $parser

			$hintTable setTitle [mc {Index: %s} $index]
			$hintTable addRow [mc {Indexed table:}] $idxTable
		}
		"TRIGGER" {
			# This is executed only for "flat"
			set dialect [$db getDialect]
			set trigger [lindex $data 2]
			set sql [$db getSqliteObjectDdl trigger $trigger]

			# Parse index and get referenced table
			set parser [UniversalParser ::#auto]
			$parser parseSql $sql
			set parsedDict [$parser get]
			if {[dict get $parsedDict returnCode] != 0} {
				debug "Could not parse trigger while filling helpHint for DBTree:\n[dict get $parsedDict errorMessage]"
				continue
			}
			set obj [dict get $parsedDict object]
			set trigStmt [$obj getValue subStatement]
			set trigTable [$trigStmt getValue tableName]
			$parser freeObjects
			delete object $parser

			$hintTable setTitle [mc {Trigger: %s} $trigger]
			$hintTable addRow [mc {On table:}] $trigTable
		}
		"VIEW" {
			set view [lindex $data 2]
			set columns [$db getColumns $view]
			$hintTable setTitle [mc {View: %s} $view]
			$hintTable setMode "img-label-label"
			$hintTable setValueWrapLength 300
			$hintTable addRow [list img_column [mc {Columns:}]] [join $columns ", "]
		}
	}
}

body DBTree::onDrag {x y} {
	set item [$_tree identify $x $y]
	if {[lindex $item 0] != "item"} {
		return false
	}
	set it [lindex $item 1]
	if {$it == "" || $it == "0"} return
	set _dragItem $it
	set _dragItemData [getData $it]
	$_tree element configure e_sel_rect -showfocus false
}

body DBTree::onDrop {x y} {
	$_tree element configure e_sel_rect -showfocus true
	
	set sourceDb [lindex $_dragItemData 1]
	set sourceType [lindex $_dragItemData 0]

	set item [$_tree identify $x $y]
	if {[lindex $item 0] != "item"} {
		if {$sourceType == "DATABASE"} {
			# Only databases can be dropped on empty spaces
			if {$y < 5} {
				set targetDb [lindex $_dblist 0]
			} else {
				set targetDb ""
			}
			moveDbInList $sourceDb $targetDb
		}
		return
	}

	set it [lindex $item 1]
	if {$it == "" || $it == "0"} {
		return
	}
	set dropItem $it
	set dropItemData [getData $it]

	set data [getData $it]
	set targetType [lindex $data 0]
	set targetDb [lindex $data 1]

	switch -- $targetType {
		"TABLE" {
			if {$sourceType in [list "INDEX" "TRIGGER"]} {
				aboutToMoveObjToTable $sourceDb $sourceType [lindex $_dragItemData 2] $targetDb [lindex $data 2]
			} elseif {$sourceType == "TABLE" && $sourceDb != $targetDb} {
				aboutToMoveTable $sourceDb [lindex $_dragItemData 2] $targetDb
			}
		}
		"TABLES" {
			if {$sourceType == "TABLE" && $sourceDb != $targetDb} {
				aboutToMoveTable $sourceDb [lindex $_dragItemData 2] $targetDb
			}
		}
		"INDEX" - "INDEXES" {
			if {$sourceType == "INDEX"} {
				set targetTable [$targetDb getObjTable [lindex $data 2]]
				aboutToMoveObjToTable $sourceDb $sourceType [lindex $_dragItemData 2] $targetDb $targetTable
			}
		}
		"TRIGGER" - "TRIGGERS" {
			if {$sourceType == "TRIGGER"} {
				set targetTable [$targetDb getObjTable [lindex $data 2]]
				aboutToMoveObjToTable $sourceDb $sourceType [lindex $_dragItemData 2] $targetDb $targetTable
			}
		}
		"VIEW" - "VIEWS" {
			if {$sourceType == "VIEW" && $sourceDb != $targetDb} {
				aboutToMoveObjToTable $sourceDb $sourceType [lindex $_dragItemData 2] $targetDb ""
			}
		}
		"DATABASE" {
			if {$sourceType == "TABLE"} {
				aboutToMoveTable $sourceDb [lindex $_dragItemData 2] $targetDb
			} elseif {$sourceType == "VIEW"} {
				aboutToMoveObjToTable $sourceDb $sourceType [lindex $_dragItemData 2] $targetDb ""
			} elseif {$sourceType == "DATABASE"} {
				moveDbInList $sourceDb $targetDb
			}
		}
	}

	set _dragItem ""
	set _dragItemData ""
}

body DBTree::onDragLeave {} {
	$_tree element configure e_sel_rect -showfocus true
}

body DBTree::onDragReturn {} {
	$_tree element configure e_sel_rect -showfocus false
}

body DBTree::canDropAt {x y} {
	set item [$_tree identify $x $y]
	set sourceType [lindex $_dragItemData 0]
	if {[lindex $item 0] != "item"} {
		if {$sourceType == "DATABASE"} {
			return true
		} else {
			return false
		}
	}
	set it [lindex $item 1]
	if {$it == "" || $it == "0"} {
		return false
	}

	set sourceDb [lindex $_dragItemData 1]
	set data [getData $it]
	set targetType [lindex $data 0]
	set targetDb [lindex $data 1]

	switch -- $targetType {
		"TABLE" {
			if {$sourceType in [list "INDEX" "TRIGGER"]} {
				return true
			} elseif {$sourceType == "TABLE"} {
				return true
			}
		}
		"TABLES" {
			if {$sourceType == "TABLE"} {
				return true
			}
		}
		"INDEX" - "INDEXES" {
			if {$sourceType == "INDEX"} {
				return true
			}
		}
		"TRIGGER" - "TRIGGERS" {
			if {$sourceType == "TRIGGER"} {
				return true
			}
		}
		"VIEW" - "VIEWS" {
			if {$sourceType == "VIEW"} {
				return true
			}
		}
		"DATABASE" {
			if {$sourceType in [list "DATABASE" "TABLE" "VIEW"]} {
				return true
			}
		}
	}

	return false
}

body DBTree::isDndPossible {x y} {
	set item [$_tree identify $x $y]
	if {[lindex $item 0] != "item"} {
		return false
	}
	set it [lindex $item 1]
	if {$it == "" || $it == "0"} {
		return false
	}
	set data [getData $it]
	if {[lindex $data 0] in [list "TABLE" "INDEX" "TRIGGER" "VIEW" "DATABASE"]} {
		return true
	}
	return false
}

body DBTree::getDragImage {} {
	switch -- [lindex $_dragItemData 0] {
		"TABLE" {
			return img_table
		}
		"INDEX" {
			return img_index
		}
		"TRIGGER" {
			return img_trigger
		}
		"VIEW" {
			return img_view
		}
		"DATABASE" {
			return img_database
		}
	}
	return ""
}

body DBTree::getDragLabel {} {
	switch -- [lindex $_dragItemData 0] {
		"TABLE" - "INDEX" - "TRIGGER" - "VIEW" {
			return [lindex $_dragItemData 2]
		}
		"DATABASE" {
			return [[lindex $_dragItemData 1] getName]
		}
	}
	return ""
}

body DBTree::moveDbInList {db atDb} {
	if {$db == $atDb} return

	set sourceIdx [lsearch -exact $_dblist $db]
	
	# Determinating direction of movement
	if {$atDb == ""} {
		set direction down
	} else {
		set direction [expr {$sourceIdx < [lsearch -exact $_dblist $atDb] ? "down" : "up"}]
	}

	set _dblist [lreplace $_dblist $sourceIdx $sourceIdx]

	if {$atDb == ""} {
		set targetIdx end
	} else {
		set targetIdx [lsearch -exact $_dblist $atDb]
		if {$direction == "down"} {
			incr targetIdx
		}
	}
	set _dblist [linsert $_dblist $targetIdx $db]

	saveDBCfg
	refreshSchema

	setSelected $_treeNode($db:ROOT)
}

body DBTree::aboutToMoveObjToTable {sourceDb sourceType sourceObj targetDb targetTable} {
	set m $_root.dndMenu
	catch {destroy $m}

	switch -- $sourceType {
		"INDEX" {
			set labelCp [mc {Copy index '%s' for table '%s'} $sourceObj $targetTable]
			set labelMv [mc {Move index '%s' to table '%s'} $sourceObj $targetTable]
			set imgCp img_new_index
			set imgMv img_move_index
		}
		"TRIGGER" {
			set labelCp [mc {Copy trigger '%s' for table '%s'} $sourceObj $targetTable]
			set labelMv [mc {Move trigger '%s' to table '%s'} $sourceObj $targetTable]
			set imgCp img_new_trigger
			set imgMv img_move_trigger
		}
		"VIEW" {
			set labelCp [mc {Copy view '%s' for database '%s'} $sourceObj [$targetDb getName]]
			set labelMv [mc {Move view '%s' to database '%s'} $sourceObj [$targetDb getName]]
			set imgCp img_new_view
			set imgMv img_move_view
		}
	}

	lassign [winfo pointerxy .] x y

	menu $m -tearoff 0
	if {$sourceType == "VIEW"} {
		$m add command -compound left -image $imgCp -label $labelCp -command [itcl::code $this moveView $sourceDb $sourceObj $targetDb "copy"]
		$m add command -compound left -image $imgMv -label $labelMv -command [itcl::code $this moveView $sourceDb $sourceObj $targetDb "move"]
	} else {
		$m add command -compound left -image $imgCp -label $labelCp -command [itcl::code $this moveObjToTable $sourceDb $sourceType $sourceObj $targetDb $targetTable "copy"]
		$m add command -compound left -image $imgMv -label $labelMv -command [itcl::code $this moveObjToTable $sourceDb $sourceType $sourceObj $targetDb $targetTable "move"]
	}
	tk_popup $m $x $y
}

body DBTree::moveView {sourceDb sourceView targetDb copyOrMove} {
	set targetDialect [$targetDb getDialect]
	set sourceDialect [$sourceDb getDialect]
	set newName [$targetDb getUniqueObjName $sourceView]
	set copiedObjects [list]

	set method "toSqlite3"
	if {$targetDialect == "sqlite2"} {
		set method "toSqlite2"
	}

	set middleJobScript [list SqlConverter::replaceNameField "viewName" $newName]
	set ddl [$sourceDb getSqliteObjectDdl "view" $sourceView]
	set copySql [SqlConverter::$method $sourceDb $ddl $middleJobScript]
	if {[catch {$targetDb eval $copySql} res]} {
		# Automatic, quiet way failed. Now use the dialog.
		debug $res
		set parser [UniversalParser ::#auto $sourceDb]
		if {[catch {set model [ModelExtractor::getModelForEditDialog $sourceDb $sourceView "view" $parser]} err]} {
			if {$::errorCode == 5} {
				delete object $parser
				error $err
			} else {
				debug $err
			}
		}

		if {![info exists model] || $model == ""} {
			Info [mc {View '%s' has no DDL, therefore cannot be edited.} $sourceView]
			delete object $parser
			return
		}
		set code [Lexer::detokenize [[$model cget -subSelect] cget -allTokens]]
		delete object $parser

		set newName [$targetDb getUniqueObjName $sourceView]
		switch -- $copyOrMove {
			"copy" {
				set title [mc {Copy view}]
				set okLabel [mc {Copy}]
			}
			"move" {
				set title [mc {Move view}]
				set okLabel [mc {Move}]
			}
		}

		catch {destroy .copyDialog}
		set dialog [ViewDialog .copyDialog -title $title -db $targetDb -code $code -name $newName -oklabel $okLabel]
		if {[$dialog exec] == 0} {
			return
		}
	}

	if {$copyOrMove == "move"} {
		set sql "DROP VIEW [wrapObjName $sourceView [$sourceDb getDialect]]"
		if {[catch {
			$sourceDb eval $sql
		} err]} {
			cutOffStdTclErr err
			Error $err
		} else {
			refreshSchemaForDb $sourceDb
		}
	}

	refreshSchemaForDb $targetDb
}

body DBTree::moveObjToTable {sourceDb sourceType sourceObj targetDb targetTable copyOrMove} {
	set targetDialect [$targetDb getDialect]
	set sourceDialect [$sourceDb getDialect]
	set newName [$targetDb getUniqueObjName $sourceObj]
	set copiedObjects [list]

	set method "toSqlite3"
	if {$targetDialect == "sqlite2"} {
		set method "toSqlite2"
	}

	switch -- $sourceType {
		"INDEX" {
			set middleJobScript [list SqlConverter::replaceNameField "indexName" $newName]
		}
		"TRIGGER" {
			set middleJobScript [list SqlConverter::replaceNameField "trigName" $newName]
		}
	}

	set ddl [$sourceDb getSqliteObjectDdl [string tolower $sourceType] $sourceObj]
	set copySql [SqlConverter::$method $sourceDb $ddl $middleJobScript]
	if {[catch {$targetDb eval $copySql} res]} {
		# Automatic, quiet way failed. Now use the dialog.
		debug $res
		set parser [UniversalParser ::#auto $sourceDb]
		if {[catch {set model [ModelExtractor::getModelForEditDialog $sourceDb $sourceObj [expr {$sourceType == "INDEX" ? "index" : "trigger"}] $parser]} err]} {
			if {$::errorCode == 5} {
				delete object $parser
				error $err
			} else {
				debug $err
			}
		}

		if {![info exists model] || $model == ""} {
			if {$sourceType == "INDEX"} {
				Info [mc {Index '%s' has no DDL. Probably it's system index and should not be edited.} $sourceObj]
			} else {
				Info [mc {Trigger '%s' has no DDL. Probably it's system trigger and should not be edited.} $sourceObj]
			}
			delete object $parser
			return
		}

		set newName [$targetDb getUniqueObjName $sourceObj]

		switch -- $sourceType {
			"INDEX" {
				set dialogType "IndexDialog"
				$model configure -indexName $newName
			}
			"TRIGGER" {
				set dialogType "TriggerDialog"
				$model configure -trigName $newName
			}
		}

		switch -- "$copyOrMove $sourceType" {
			"copy INDEX" {
				set title [mc {Copy index}]
			}
			"move INDEX" {
				set title [mc {Move index}]
			}
			"copy TRIGGER" {
				set title [mc {Copy trigger}]
			}
			"move TRIGGER" {
				set title [mc {Move trigger}]
			}
		}

		catch {destroy .copyDialog}
		switch -- $copyOrMove {
			"copy" {
				set dialog [$dialogType .copyDialog -title $title -preselecttable $targetTable -db $targetDb -similarmodel $model -oklabel [mc {Copy}]]
			}
			"move" {
				set dialog [$dialogType .copyDialog -title $title -preselecttable $targetTable -db $targetDb -similarmodel $model -oklabel [mc {Move}]]
			}
		}
		set res [$dialog exec]
		delete object $parser
		if {$res == 0} {
			return
		}
	}

	if {$copyOrMove == "move"} {
		set sql "DROP $sourceType [wrapObjName $sourceObj [$sourceDb getDialect]]"
		if {[catch {
			$sourceDb eval $sql
		} err]} {
			cutOffStdTclErr err
			Error $err
		} else {
			refreshSchemaForDb $sourceDb
			TASKBAR signal TableWin [list REFRESH_IDX $sourceObj]
			TASKBAR signal TableWin [list REFRESH_TRIG $sourceObj]
		}
	}

	refreshSchemaForDb $targetDb
}

body DBTree::aboutToMoveTable {sourceDb sourceTable targetDb} {
	set m $_root.dndMenu
	catch {destroy $m}

	if {$sourceDb eq $targetDb} return

	set labelCpAll [mc {Copy table '%s' to database '%s' (include data, indexes and triggers)} $sourceTable [$targetDb getName]]
	set labelCpData [mc {Copy table '%s' to database '%s' (include data)} $sourceTable [$targetDb getName]]
	set labelCpIdxTrig [mc {Copy table '%s' to database '%s' (include indexes and triggers)} $sourceTable [$targetDb getName]]
	set labelCpSkip [mc {Copy table '%s' to database '%s' (skip data, indexes and triggers)} $sourceTable [$targetDb getName]]
	set labelMvAll [mc {Move table '%s' to database '%s' (include data, indexes and triggers)} $sourceTable [$targetDb getName]]
	set labelMvData [mc {Move table '%s' to database '%s' (include data)} $sourceTable [$targetDb getName]]
	set labelMvIdxTrig [mc {Move table '%s' to database '%s' (include indexes and triggers)} $sourceTable [$targetDb getName]]
	set labelMvSkip [mc {Move table '%s' to database '%s' (skip data, indexes and triggers)} $sourceTable [$targetDb getName]]

	set imgCpAll img_copy_table_with_all
	set imgCpData img_copy_table_with_data
	set imgCpIdxTrig img_copy_table_with_idx_trig
	set imgCpSkip img_copy_table_only
	set imgMvAll img_move_table_with_all
	set imgMvData img_move_table_with_data
	set imgMvIdxTrig img_move_table_with_idx_trig
	set imgMvSkip img_move_table_only

	lassign [winfo pointerxy .] x y

	menu $m -tearoff 0
	$m add command -compound left -image $imgCpAll -label $labelCpAll -command [itcl::code $this moveTable $sourceDb $sourceTable $targetDb "copy all"]
	$m add command -compound left -image $imgCpData -label $labelCpData -command [itcl::code $this moveTable $sourceDb $sourceTable $targetDb "copy data"]
	$m add command -compound left -image $imgCpIdxTrig -label $labelCpIdxTrig -command [itcl::code $this moveTable $sourceDb $sourceTable $targetDb "copy idxtrig"]
	$m add command -compound left -image $imgCpSkip -label $labelCpSkip -command [itcl::code $this moveTable $sourceDb $sourceTable $targetDb "copy skip"]
	$m add separator
	$m add command -compound left -image $imgMvAll -label $labelMvAll -command [itcl::code $this moveTable $sourceDb $sourceTable $targetDb "move all"]
	$m add command -compound left -image $imgMvData -label $labelMvData -command [itcl::code $this moveTable $sourceDb $sourceTable $targetDb "move data"]
	$m add command -compound left -image $imgMvIdxTrig -label $labelMvIdxTrig -command [itcl::code $this moveTable $sourceDb $sourceTable $targetDb "move idxtrig"]
	$m add command -compound left -image $imgMvSkip -label $labelMvSkip -command [itcl::code $this moveTable $sourceDb $sourceTable $targetDb "move skip"]
	tk_popup $m $x $y
}

body DBTree::moveTable {sourceDb sourceTable targetDb mode} {
	if {"copy" in $mode} {
		set title [mc {Copying table...}]
		set msg [mc {Copying table '%s' from '%s' to '%s'.} $sourceTable [$sourceDb getName] [$targetDb getName]]
	} else {
		set title [mc {Moving table...}]
		set msg [mc {Moving table '%s' from '%s' to '%s'.} $sourceTable [$sourceDb getName] [$targetDb getName]]
	}

	BusyDialog::show $title $msg false 50 false
	BusyDialog::autoProgress 20

	set targetDialect [$targetDb getDialect]
	set sourceDialect [$sourceDb getDialect]
	set newName [$targetDb getUniqueObjName $sourceTable]
	set copiedObjects [list]

	set method "toSqlite3"
	if {$targetDialect == "sqlite2"} {
		set method "toSqlite2"
	}

	# Direct data copying only between same SQLite versions.
	set directCopyData 0
	if {$sourceDialect == $targetDialect} {
		set directCopyData 1
	}

	# Attach sourceDb to targetDb to copy data.
	if {("all" in $mode || "data" in $mode) && $directCopyData} {
		set attachedDb [$targetDb attach $sourceDb]
		if {$attachedDb == ""} {
			# Could not attach
			BusyDialog::hide
			return
		}
	}

	# Copying/moving rest of objects
	set copySqls [list]
	lappend copySqls "BEGIN"

	# Table
	set middleJobScript [list SqlConverter::replaceNameField "tableName" $newName]
	set ddl [$sourceDb getSqliteObjectDdl "table" $sourceTable]
	lappend copySqls [SqlConverter::$method $sourceDb $ddl $middleJobScript]
	lappend copiedObjects "TABLE" $sourceTable

	# Prepare for loop over index and trigger objects
	array set fields {
		"index" "onTable"
		"trigger" "tableName"
	}

	# Do the loop
	if {"all" in $mode || "idxtrig" in $mode} {
		set mode [$sourceDb mode]
		$sourceDb short
		set sql "SELECT sql, type, name FROM sqlite_master WHERE type IN ('index', 'trigger') AND lower(tbl_name) = [wrapString [string tolower $sourceTable]]"
		$sourceDb eval $sql row {
			if {[$sourceDb isSystemIndex $row(name)]} continue
			set middleJobScript [list SqlConverter::replaceNameField $fields($row(type)) $newName]
			lappend copySqls [SqlConverter::$method $sourceDb $row(sql) $middleJobScript]
			# No need to add these objects to copiedObjects, because they will get deleted automatically with table.
		}
		$sourceDb $mode
	}

	# Execute copy sql
	update
	set sql [join $copySqls ";\n"]
	append sql ";"
	if {[catch {$targetDb eval $sql} res]} {
		catch {$targetDb eval {ROLLBACK}}
		BusyDialog::hide
		debug $res
		cutOffStdTclErr res
		Error [mc "Could not create object in target database:\n%s" $res]
		return
	}
	update

	if {"all" in $mode || "data" in $mode} {
		#
		# Do copy data
		#
		if {$directCopyData} {
			set sql "INSERT INTO [wrapObjIfNeeded $newName $targetDialect] SELECT * FROM [wrapObjIfNeeded $attachedDb $sourceDialect].[wrapObjIfNeeded $sourceTable $targetDialect]"
			if {[catch {$targetDb eval $sql} res]} {
				catch {$targetDb eval {ROLLBACK}}
				BusyDialog::hide
				debug $res
				cutOffStdTclErr res
				Error [mc "Could not copy data:\n%s" $res]
				return
			}
			$targetDb eval {COMMIT}
			$targetDb detach $sourceDb
		} else {
			if {[catch {
				# Copying data indirectly for different SQLite versions
				set wrappedTargetTable [wrapObjIfNeeded $newName $targetDialect]
				set vals ""
				set code ""

				# Determinate columns
				$sourceDb eval "SELECT * FROM [wrapObjIfNeeded $sourceTable $sourceDialect] LIMIT 1" row {
					set i 0
					set valList [list]
					set codeList [list]
					foreach col $row(*) {
						set varName val_[pad 3 "0" $i]
						lappend valList \$$varName
						lappend codeList "set $varName \$row($col)"
						incr i
					}
					set vals [join $valList ", "]
					set code [join $codeList \n]
				}

				# Do the actual copying
				set i 0
				$sourceDb eval "SELECT * FROM [wrapObjIfNeeded $sourceTable $sourceDialect]" row {
					eval $code
					$targetDb eval "INSERT INTO $wrappedTargetTable VALUES ($vals)"
					if {$i % 50 == 0} {
						update ;# idletasks seems not to work correctly here, because of same thread used.
					}
					incr i
				}
				$targetDb eval {COMMIT}
			} res]} {
				catch {$targetDb eval {ROLLBACK}}
				BusyDialog::hide
				debug $res
				cutOffStdTclErr res
				Error [mc "Could not copy table data from source database to target database. Details: %s" $res]
				return
			}
		}
	} else {
		#
		# Skip data copying
		#
		$targetDb eval {COMMIT}
	}

	# If moving (not copying) - delete original objects
	if {"move" in $mode} {
		$sourceDb eval {BEGIN}
		if {[catch {
			foreach {type obj} $copiedObjects {
				$sourceDb eval "DROP $type [wrapObjIfNeeded $obj $sourceDialect]"
			}
		} res]} {
			$sourceDb eval {ROLLBACK}
			debug $res
			cutOffStdTclErr res
			Error [mc "Could not delete object(s) from source database. Details: %s" $res]
		}
		$sourceDb eval {COMMIT}

		# Close table windows
		foreach {type obj} $copiedObjects {
			TASKBAR signal TableWin [list CLOSE $obj]
		}
	}

	update

	BusyDialog::hide
	refreshSchema
}

body DBTree::getTreeNode {key} {
	if {![info exists _treeNode($key)]} {
		return ""
	}
	return $_treeNode($key)
}

body DBTree::getSessionString {} {
	set sessionString [list]

	foreach db $_dblist {
		set dbString [dict create dbname [$db getName] open false]
		if {![$db isOpen]} {
			lappend sessionString $dbString
			continue
		}
		dict set dbString open true
		dict set dbString treeStatus [reportNodeStatus $_treeNode($db:ROOT)]
		lappend sessionString $dbString
	}

	return [list DATABASES $sessionString]
}

body DBTree::restoreSession {sessionString} {
	lassign $sessionString type sessionString
	if {$type != "DATABASES"} {
		return 0
	}

	foreach str $sessionString {
		if {![dict get $str open]} continue
		
		set dbName [dict get $str dbname]
		set status [dict get $str treeStatus]
		set db [DBTREE getDBByName $dbName]
		if {$db != ""} {
			if {![$db isOpen]} {
				$db open
			}
			DBTREE applyNodeStatus [DBTREE getTreeNode $db:ROOT] $status
		}
	}
	
	return 1
}

