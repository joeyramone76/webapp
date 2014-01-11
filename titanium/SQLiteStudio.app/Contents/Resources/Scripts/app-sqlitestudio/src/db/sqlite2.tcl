if {$::DB_SUPPORT(sqlite2)} {

use src/db/db.tcl

#>
# @class Sqlite2
# SQLite v2 database interface implementstion.
#<
class Sqlite2 {
	inherit DB

	#>
	# @method constructor
	# @overloaded DB
	#<
	constructor {name path} {
		DB::constructor $name $path
	} {}

	common nullValue "null"

	protected {
		#>
		# @method createDbObject
		# @overloaded DB
		#>
		method createDbObject {name}

		#>
		# @method closeDb
		# @overloaded DB
		#<
		method closeDb {}

		method internalBegin {}
		method internalCommit {}
		method internalRollback {}
	}

	public {
		#>
		# @method getRefreshSchemaData
		# @overloaded DB
		#<
		method getRefreshSchemaData {}

		#>
		# @method mode
		# @overloaded DB
		#<
		method mode {}

		#>
		# @method long
		# @overloaded DB
		#<
		method long {}

		#>
		# @method short
		# @overloaded DB
		#<
		method short {}

		#>
		# @method getColumns
		# @overloaded DB
		#<
		method getColumns {table {dbName ""}}

		#>
		# @method isNull
		# @param val Value to check.
		# Checks if given value is NULL in database meaning.
		# @return Always <code>false</code>, since SQLite2 returns empty string for NULLs, unfortunetly.
		# @overloaded DB
		#<
		method isNull {val}
		method getNull {}

		#>
		# @method getNativeDatabaseObjects
		# @overloaded DB
		#<
		method getNativeDatabaseObjects {}

		#>
		# @method onecolumn
		# @param sql SQL statement to call.
		# Calls given SQL and returns first column of first row from results.
		# It overloades default method from {@class DB} to let Sqlite2 handler use variable evaulations
		# in SQL statement.
		# @return Cell value.
		# @overloaded DB
		#<
		method onecolumn {sql}

		#>
		# @method eval
		# @param args Args matches syntax: <code>Sqlite2Object sql <i>?arrayName script?</i></code>
		# Calls given SQL and returns results (if only one argument is given).
		# If next 2 arguments are given, then results are stored in named array and given script is evaluated
		# for each returned row.
		# It overloades default method from {@class DB} to let Sqlite2 handler use variable evaulations
		# in SQL statement.
		# @return All results as a list in case when only one argument was passed to the method. If other arguments were passed then empty stirng is returned.
		# @overloaded DB
		#<
		method eval {args}

		#>
		# @method validate
		# @overloaded DB
		#<
		method validate {}

		method getDialect {}
		method isVirtualTable {table}
		method handleCollations {}
		method setFkEnabled {bool}
		method isSystemIndex {name}
		method isSystemTable {name}
		method getVirtualTableNames {}

		method vacuum {}

		#>
		# @method getHandlerLabel
		# @overloaded DB
		#<
		proc getHandlerLabel {}
		proc getHandlerDbVersion {}

		#>
		# @method createDbFile
		# @overloaded DB
		#<
		proc createDbFile {path}

		#>
		# @method probe
		# @overloaded DB
		#<
		proc probe {path}

		#>
		# @method getUnsupportedFeatures
		# @overloaded DB
		#<
		proc getUnsupportedFeatures {}

		#>
		# @method getPureSqliteObject
		# @overloaded DB
		#<
		proc getPureSqliteObject {path}
	}
}

body Sqlite2::getRefreshSchemaData {} {
	set res [list]
	set sql "SELECT sql, type, name, tbl_name FROM sqlite_master"
	if {!${::DBTree::showSqliteSystemTables}} {
		append sql " WHERE name NOT LIKE 'sqlite_%'"
	}
	set mode [mode]
	short
	$this eval $sql row {
		# Filter sqlite2 *(*autoindex*)* indexes
		if {!${::DBTree::showSqliteSystemTables} && $row(type) == "index" && [isSystemIndex $row(name)]} {
			continue
		}
		lappend res [list $row(sql) $row(type) $row(name) $row(tbl_name)]
	}
	$mode

	if {${::DBTree::showSqliteSystemTables}} {
		# sqlite_master table
		set ddl "CREATE TABLE sqlite_master ("
		set columns [list]
		foreach {cid name type notnull dflt_value pk} [$_db eval {PRAGMA table_info(sqlite_master)}] {
			lappend columns "$name $type"
		}
		append ddl [join $columns ", "]
		append ddl ")"
		lappend res [list $ddl table sqlite_master]

		# sqlite_temp_master table
		set ddl "CREATE TABLE sqlite_master ("
		set columns [list]
		foreach {cid name type notnull dflt_value pk} [$_db eval {PRAGMA table_info(sqlite_temp_master)}] {
			lappend columns "$name $type"
		}
		append ddl [join $columns ", "]
		append ddl ")"
		lappend res [list $ddl table sqlite_temp_master]
	}

	return $res
}

body Sqlite2::long {} {
	$this eval {PRAGMA full_column_names = 1; PRAGMA short_column_names = 0;}
}

body Sqlite2::short {} {
	$this eval {PRAGMA full_column_names = 0; PRAGMA short_column_names = 1;}
}

body Sqlite2::mode {} {
	$this eval {PRAGMA full_column_names} r {
		if {$r(full_column_names)} {
			return "long"
		} else {
			return "short"
		}
	}
	return "short"
}

body Sqlite2::createDbObject {name} {
	sqlite2 $name $_path
	return $name
}

body Sqlite2::closeDb {} {
	catch {$_db close}
	set _db ""
}

body Sqlite2::isVirtualTable {table} {
	return false
}

body Sqlite2::getVirtualTableNames {} {
	return [list]
}

body Sqlite2::getColumns {table {dbName ""}} {
	if {![isOpen]} return
	set cols [list]
	$this eval "PRAGMA table_info([wrapObjName $table [getDialect]])" row {
		lappend cols [stripColName $row(name)]
	}
	return $cols
}

body Sqlite2::probe {path} {
	if {![string is ascii $path]} {
		# SQLite 2 library doesn't deal well with non-ascii file paths/names.
		return 0
	}
	if {![catch {sqlite2 tempDb $path; tempDb eval "SELECT 1;"}]} {
		tempDb close
		return 1
	} else {
		return 0
	}
}

body Sqlite2::isNull {val} {
	return 0
}

body Sqlite2::getNull {} {
	return ""
}

body Sqlite2::onecolumn {sql} {
	set vars [list]
	foreach {tmp1 var tmp2 tmp3 tmp4 tmp5 tmp6} [regexp -inline -all -- {[^\\]((\$\{([^\}]|\\\})+\}|(\$(::|[\w\-\.])+))(\([^\)]*\)){0,1})} $sql] {
		set varName [string range $var 1 end]
		if {[string length $varName] > 0 && [uplevel [list info exists $varName]]} {
			set value [uplevel [list set $varName]]
			set value [string map [list "'" "''"] $value]
			set sql [string map [list $var "'$value'"] $sql]
		}
	}
	if {$::DEBUG(sql)} {
		puts "$_db SQL -> $sql"
	}

	return [$_db onecolumn $sql]
}

body Sqlite2::eval {args} {
	set lgt [llength $args]
	if {$lgt != 1 && $lgt != 3} {
		error "wrong # args: $this eval sql ?arrayName script?"
	}
	set sql [lindex $args 0]

	set vars [list]
	foreach {tmp1 var tmp2 tmp3 tmp4 tmp5 tmp6} [regexp -inline -all -- {[^\\]((\$\{([^\}]|\\\})+\}|(\$(::|[\w\-\.])+))(\([^\)]*\)){0,1})} $sql] {
		set varName [string range $var 1 end]
		if {[string length $varName] > 0 && [uplevel [list info exists $varName]]} {
			set value [uplevel [list set $varName]]
			set value [string map [list "'" "''"] $value]
			set sql [string map [list $var "'$value'"] $sql]
		}
	}

	if {$::DEBUG(sql)} {
		puts "$_db SQL -> [lindex $args 0]"
	}

	if {[catch {
		switch -- $lgt {
			1 {
				return [$_db eval $sql]
			}
			3 {
				set arrName [lindex $args 1]
				set script [lindex $args 2]
				$_db eval $sql R {
					foreach idx $R(*) {
						uplevel [list set $arrName\($idx) $R($idx)]
					}
					uplevel [list set $arrName\(*) $R(*)]
					uplevel $script
				}
			}
		}
	} res] == 1} {
		if {![stdErrHandle $res]} {
			error $::errorInfo
		}
	} else {
		return $res
	}
}

body Sqlite2::getHandlerLabel {} {
	return "SQLite 2"
}

body Sqlite2::getHandlerDbVersion {} {
	return 2
}

body Sqlite2::createDbFile {path} {
	set resDict [dict create]
	if {[catch {
		sqlite2 tmp_db $path

		# Now create templorary some object to mark database format.
		catch {
			tmp_db eval {CREATE TABLE creation_table (tmp INTEGER)}
			tmp_db eval {DROP TABLE creation_table}
		}
	} res]} {
		dict append resDict code false
		dict append resDict msg $res
		return $resDict
	}

	if {[catch {
		tmp_db eval {SELECT * FROM sqlite_master}
	} res]} {
		catch {tmp_db close}
		catch {rename tmp_db {}}
		dict append resDict code false
		dict append resDict msg $res
		return $resDict
	}
	catch {tmp_db close}
	catch {rename tmp_db {}}
	dict append resDict code true
	dict append resDict msg ""
}

body Sqlite2::getUnsupportedFeatures {} {
	return [list \
		AUTOINCREMENT \
		ALTER_TABLE \
		INDEX_COLLATE \
		COLLATE \
		IF_EXISTS \
		EXPR_DEFAULT \
	]
}

body Sqlite2::getPureSqliteObject {path} {
	set i 0
	while {[info commands ::pureSqlite2_$i] != ""} {
		incr i
	}
	set obj ::pureSqlite2_$i
	if {![catch {sqlite2 $obj $path}]} {
		return $obj
	} else {
		return ""
	}
}

body Sqlite2::getNativeDatabaseObjects {} {
	set names [list]
	$this eval {PRAGMA database_list} row {
		lappend names $row(name)
	}
	return [lsort -unique [stripColListNames [concat [list "main" "temp"] $names]]]
}

body Sqlite2::validate {} {
	if {![file exists $_path]} {
		return false
	}

	set res true
	if {[catch {
		sqlite2 validating_db $_path
		validating_db eval {SELECT * FROM sqlite_master}
	} err]} {
		if {$::DEBUG(global)} {
			puts "Database validation failed: $err"
		}
		set res false
	}

	catch {validating_db close}

	return $res
}

body Sqlite2::getDialect {} {
	return "sqlite2"
}

body Sqlite2::vacuum {} {

	if {[catch {
		foreach object [$this eval {SELECT name FROM sqlite_master WHERE type = 'table' OR type = 'index'}] {
			$this eval "VACUUM [wrapObjName $object [getDialect]]"
		}
	} err]} {
		cutOffStdTclErr err
		Error [mc "An error occured while call to VACUUM on database:\n%s\n(this is message directly from SQLite2)" $err]
	}
}

body Sqlite2::handleCollations {} {
	# No collations in sqlite2.
}

body Sqlite2::setFkEnabled {bool} {
}

body Sqlite2::internalBegin {} {
	$this eval {BEGIN}
}

body Sqlite2::internalCommit {} {
	$this eval {COMMIT}
}

body Sqlite2::internalRollback {} {
	$this eval {ROLLBACK}
}

body Sqlite2::isSystemIndex {name} {
	string match "*(*autoindex*)*" $name
}

body Sqlite2::isSystemTable {name} {
	string match "sqlite_*" $name
}

} ;# DB_SUPPORT(sqlite2)
