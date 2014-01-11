use src/db/db.tcl
use src/common/common.tcl

#>
# @class Sqlite3
# SQLite v3 database interface implementstion.
#<
class Sqlite3 {
	inherit DB

	#>
	# @method constructor
	# @overloaded DB
	#<
	constructor {name path} {
		DB::constructor $name $path
	} {}

	common nullValue "___NULL_[randcrap 5]___"
	common dictionaryCollation "SQLITESTUDIO_DICTIONARY"

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
		method open {}

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
		# @method getRefreshSchemaData
		# @overloaded DB
		#<
		method getRefreshSchemaData {}

		#>
		# @method getColumns
		# @overloaded DB
		#<
		method getColumns {table {dbName ""}}

		#>
		# @method isNull
		# @param val Value to check.
		# Checks if given value is NULL in database meaning.
		# @return <code>true</code> if given value matches currently configure NULL representation, or <code>false</code> otherwise.
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
		# @method validate
		# @overloaded DB
		#<
		method validate {}

		method getCollations {}
		method isVirtualTable {table}
		method handleCollations {}
		method setFkEnabled {bool}
		method getTableInfo {table {db ""}}
		method isSystemIndex {name}
		method isSystemTable {name}
		method getVirtualTableNames {}

		method getDialect {}
		method vacuum {}
		methodlink interrupt {$_db}

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
		
		proc dictionaryCollation {1 2}
	}
}

body Sqlite3::open {} {
	DB::open
	if {![$this isOpen]} return
	$_db nullvalue $nullValue
	$_db enable_load_extension true
	$_db eval {PRAGMA foreign_keys = 1;}
}

body Sqlite3::getTableInfo {table {db ""}} {
	if {![isOpen]} return
	set res [list]

	# Don't see why this is necessary. Causes bug, that user cannot select
	# from virtual table (in sql editor), because table columns are unknown.
# 	if {[isVirtualTable $table]} {
# 		return $res
# 	}

	set sql "PRAGMA table_info([wrapObjName $table sqlite3])"
	if {$db != ""} {
		set attachName [attach $db]
		set sql "PRAGMA $attachName.table_info([wrapObjName $table sqlite3])"
	}
	
	$_db eval $sql row {
		set el [dict create]
		dict append el name $row(name)
		dict append el type $row(type)
		dict append el notnull $row(notnull)
		dict append el dflt_value $row(dflt_value)
		dict append el pk $row(pk)
		lappend res $el
	}

	if {$db != ""} {
		detach $db
	}

	return $res
}

body Sqlite3::getRefreshSchemaData {} {
	set res [list]
	set sql "SELECT sql, type, name, tbl_name FROM sqlite_master"
	if {!${::DBTree::showSqliteSystemTables}} {
		append sql " WHERE name NOT LIKE 'sqlite_%'"
	}
	set mode [mode]
	short
	$this eval $sql row {
		lappend res [list $row(sql) $row(type) $row(name) $row(tbl_name)]
	}
	$mode

	if {${::DBTree::showSqliteSystemTables}} {
		# sqlite_master table
		set ddl "CREATE TABLE sqlite_master ("
		set columns [list]
		foreach {cid name type notnull dflt_value pk} [$this eval {PRAGMA table_info(sqlite_master)}] {
			lappend columns "$name $type"
		}
		append ddl [join $columns ", "]
		append ddl ")"
		lappend res [list $ddl table sqlite_master]

		# sqlite_temp_master table
		set ddl "CREATE TABLE sqlite_master ("
		set columns [list]
		foreach {cid name type notnull dflt_value pk} [$this eval {PRAGMA table_info(sqlite_temp_master)}] {
			lappend columns "$name $type"
		}
		append ddl [join $columns ", "]
		append ddl ")"
		lappend res [list $ddl table sqlite_temp_master]
	}

	return $res
}

body Sqlite3::long {} {
	$this eval {PRAGMA full_column_names = 1; PRAGMA short_column_names = 0;}
}

body Sqlite3::short {} {
	$this eval {PRAGMA full_column_names = 0; PRAGMA short_column_names = 1;}
}

body Sqlite3::mode {} {
	$this eval {PRAGMA full_column_names} {
		if {$full_column_names} {
			return "long"
		} else {
			return "short"
		}
	}
	return "short"
}

body Sqlite3::createDbObject {name} {
	sqlite3 $name $_path
	return $name
}

body Sqlite3::closeDb {} {
	catch {$_db close}
	set _db ""
}

body Sqlite3::isVirtualTable {table} {
	set ddl ""
	set table [string tolower $table]
	set mode [mode]
	short
	$this eval {SELECT sql FROM sqlite_master WHERE lower(name) = $table} row {
		set ddl $row(sql)
	}
	$mode
	if {$ddl == ""} {
		return false
	}
	if {[regexp -- {(?i)^\s*CREATE\s+VIRTUAL.*} $ddl]} {
		return true
	} else {
		return false
	}
}

body Sqlite3::getVirtualTableNames {} {
	set tables [list]
	set mode [mode]
	short
	$this eval {SELECT sql, lower(name) AS name FROM sqlite_master WHERE type = 'table'} row {
		set ddl $row(sql)
		if {$ddl == ""} {
			continue
		}
		if {[regexp -- {(?i)^\s*CREATE\s+VIRTUAL.*} $ddl]} {
			lappend tables $row(name)
		}
	}
	$mode
	return $tables
}

body Sqlite3::getColumns {table {dbName ""}} {
	if {![isOpen]} return
	set cols [list]
	set dbPrefix ""
	if {$dbName != ""} {
		set dbPrefix "[wrapObjName $dbName [getDialect]]."
	}
	if {[catch {
		$this eval "PRAGMA ${dbPrefix}table_info([wrapObjName $table [getDialect]])" row {
			lappend cols [stripColName $row(name)]
		}
	} err]} {
		debug "Couldn't get table_info for table $table. Error message was:\n$err"
		return [list]
	}
	return $cols
}

body Sqlite3::probe {path} {
	if {![catch {sqlite3 tempDb $path; tempDb eval "SELECT * FROM sqlite_master;"}]} {
		tempDb close
		return 1
	} else {
		return 0
	}
}

body Sqlite3::isNull {val} {
	string equal $val $Sqlite3::nullValue
}

body Sqlite3::getNull {} {
	return $Sqlite3::nullValue
}

body Sqlite3::getHandlerLabel {} {
	return "SQLite 3"
}

body Sqlite3::getHandlerDbVersion {} {
	return 3
}

body Sqlite3::createDbFile {path} {
	set resDict [dict create]
	if {[catch {
		sqlite3 tmp_db $path

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

body Sqlite3::getUnsupportedFeatures {} {
	return [list]
}

body Sqlite3::getPureSqliteObject {path} {
	set i 0
	while {[info commands ::pureSqlite_$i] != ""} {
		incr i
	}
	set obj ::pureSqlite3_$i
	if {![catch {sqlite3 $obj $path}]} {
		return $obj
	} else {
		return ""
	}
}

body Sqlite3::getNativeDatabaseObjects {} {
	set names [list]
	$this eval {PRAGMA database_list} row {
		lappend names $row(name)
	}
	return [lsort -unique [stripColListNames [concat [list "main" "temp"] $names]]]
}

body Sqlite3::validate {} {
	if {![file exists $_path]} {
		return false
	}

	set res true
	if {[catch {
		sqlite3 validating_db $_path
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

body Sqlite3::getCollations {} {
	set resList [list]
	$this eval {PRAGMA collation_list} row {
		lappend resList $row(name)
	}
	return $resList
}

body Sqlite3::getDialect {} {
	return "sqlite3"
}

body Sqlite3::vacuum {} {
	if {[catch {$this eval {VACUUM}} err]} {
		Error [mc "An error occured while call to VACUUM on database:\n%s\n(this is message directly from SQLite3)" $err]
	}
}

body Sqlite3::handleCollations {} {
	$_db collation_needed "collation_needed $_db"
	$_db collate $dictionaryCollation Sqlite3::dictionaryCollation
}

body Sqlite3::dictionaryCollation {1 2} {
	# Check if $a is also at first place after sorting
	expr {[string equal $1 [lindex [lsort -dictionary [list $1 $2]] 0]] ? -1 : 1}
}

body Sqlite3::setFkEnabled {bool} {
	$this eval "PRAGMA foreign_keys = $bool;"
}

body Sqlite3::internalBegin {} {
	$this eval {SAVEPOINT 'SQLiteStudio'}
}

body Sqlite3::internalCommit {} {
	$this eval {RELEASE 'SQLiteStudio'}
}

body Sqlite3::internalRollback {} {
	$this eval {ROLLBACK TO SAVEPOINT 'SQLiteStudio'; COMMIT}
}

body Sqlite3::isSystemIndex {name} {
	string match "sqlite_autoindex_*" $name
}

body Sqlite3::isSystemTable {name} {
	string match "sqlite_*" $name
}
