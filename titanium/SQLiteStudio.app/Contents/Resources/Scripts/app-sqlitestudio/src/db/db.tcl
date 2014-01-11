use src/common/session.tcl
use src/common/signal.tcl
use src/common/leaking_stack.tcl

#>
# @class DB
# Single database representation in {@class DBTree}.
# It's also database abstract interface. It implements
# some of common functionality, but forces derived class
# to implement some database engine depended functions.
#<
class DB {
	inherit Signal

	#>
	# @method constructor
	# @param name Symbolic name of database that is displayed in {@class DBTree}.
	# @param path Path to database file.
	# Creates database object.
	#<
	constructor {name path} {}

	#>
	# @var dbNum
	# Sequence variable used to create database objects. It's incremented for each new object.
	#<
	common dbNum 0

	#>
	# @var stdError
	# List, which has multiplicity of 3 words (3, 6, 9, 12, ...).<br>
	# First word SQLite error code.<br>
	# Second word is message to be displayed instead of database error in error/warning dialogs.<br>
	# Third is error level to be used: <code>error</code>, <code>warning</code>, <code>info</code>.
	#<
	common stdError

	# Standard errors for handler
	array set stdError [list \
		2 [list [mc {An internal logic error in SQLite}] warning] \
		3 [list [mc {Access permission denied}] warning] \
		5 [list [mc "Cannot proceed operation because database is busy.\nPerhaps some other application is accessing it."] warning] \
		6 [list [mc "Cannot proceed operation because database object is locked.\nPerhaps some other application is accessing it."] warning] \
		7 [list [mc {A malloc() failed}] warning] \
		8 [list [mc {Attempt to write a readonly database}] warning] \
		10 [list [mc {Disk I/O error occurred}] warning] \
		11 [list [mc {The database disk image is malformed}] warning] \
		13 [list [mc {Database is full}] warning] \
		14 [list [mc {Unable to open the database file}] error] \
		15 [list [mc {Database lock protocol error}] warning] \
		16 [list [mc {Database is empty}] warning] \
		17 [list [mc {The database schema changed}] warning] \
		18 [list [mc {String or BLOB exceeds size limit}] warning] \
		21 [list [mc {Library used incorrectly}] warning] \
		22 [list [mc {Uses OS features not supported on host}] warning] \
		23 [list [mc {Authorization denied}] warning] \
		24 [list [mc {Auxiliary database format error}] warning] \
		25 [list [mc {2nd parameter to sqlite3_bind out of range}] warning] \
		26 [list [mc {File opened that is not a database file}] warning] \
	]

	protected {
		#>
		# @var _path
		# Stored path to database file. It's the same path as passed to {@method constructor}.
		# @see method getPath
		#<
		variable _path ""

		#>
		# @var _db
		# SQLite database object. Used to all database calls.
		# @see method open
		# @see method close
		# @see method isOpen
		#<
		variable _db ""

		#>
		# @arr _createSql
		# Contains DDL code (SQL used to create) for all objects in database,
		# such as Tables, Indexes, Triggers and Views.
		#<
		variable _createSql

		#>
		# @var _name
		# Symbolic database name that is displayed in {@class DBTree}.
		# @see method getName
		#<
		variable _name ""

		#>
		# @var _tree
		# Reference to tree widget used in {@class DBTree} which contains the DB object.
		#<
		variable _tree ""

		#>
		# @var _temp
		# Temporary flag. Temporary databases are added from command line and they are not stored in configuration.
		#<
		variable _temp 0

		#>
		# @arr _attachedDatabases
		# Keeps map (key-value) of database objects and their names used while attaching to this database.
		# Only currently attached databases are in this array. If some of attached databases is deleted
		# from application, then the signal is emmited and it's detached before it's deleted.
		#<
		variable _attachedDatabases
		
		variable _attachedDatabasesCounter

		#>
		# @var _extensions
		# Keeps list of extensions to load for each query call.
		# Each element of list is just file to load, or pair of file and initialization function.
		#<
		variable _extensions [list]

		variable _interp ""

		#>
		# @method registerFunctions
		# Register all necessary functions for opened database.
		# It's called by {@method open} method.
		#<
		method registerFunctions {}

		#>
		# @method createDbObject
		# @param name Created object has to be named like value given in this parameter.
		# This method should create database direct (clear, not wrapped) interface object, using settings already stored in local object (like {@var \\\$_path}).<br>
		# For example for SQLite3 it would be: <code>sqlite3 #auto \\\$_path</code><br>or somethind like that.
		# @return Object to be stored in {@var _db}, so it can be used later as direct DB interface.
		#<
		abstract method createDbObject {name}

		#>
		# @method closeDb
		# Implementation of this method should close this database.
		#<
		abstract method closeDb {}

		#>
		# @method probe
		# @param path Path to database file.
		# Probes if given file represents database handled by this class.
		# @return <code>true</code> when given database is handled by this class, or <code>false</code> otherwise.
		#<
		abstract proc probe {path}

		#>
		# @method _applyQueryHacks
		# A subset of code used in {@method execQueryUsingHacks}. Used just to split huge code of the {@method execQueryUsingHacks}.
		#<
# 		method _applyQueryHacks {}

		#>
		# @method _executePreparedQuery
		# A subset of code used in {@method execQueryUsingHacks}. Used just to split huge code of the {@method execQueryUsingHacks}.
		#<
# 		method _executePreparedQuery {}

		method getAllObjects {method {attachedDatabaseName ""}}
		method initInterp {}

		abstract method internalBegin {}
		abstract method internalCommit {}
		abstract method internalRollback {}

		variable _transactionTrace [LeakingStack ::#auto 8]
		variable _trace [LeakingStack ::#auto 20]
	}

	public {
		method addTrace {sql}
		#>
		# @method getRefreshSchemaData
		# Derived class implementation of this method has to return informations about current database schema.
		# Schema has to be described by list of elements (one element per one schema object), where each element is sublist
		# of 3 elements (in according order): <code>sql</code>, <code>type</code> and <code>name</code>.<br>
		# <code>sql</code> is DDL of object, <code>type</code> is one of: <code>table</code>, <code>trigger</code>, <code>view</code>,
		# or <code>index</code>. Name is just a name of object.<br>
		# All of these informations are same as executing in SQLite v3 database:<br><code>SELECT * FROM sqlite_master WHERE name NOT LIKE 'sqlite_%'</code>
		# @return Fromatted schema entries.
		#<
		abstract method getRefreshSchemaData {}

		#>
		# @method signal
		# @param receiver Destination class.
		# @param data Signal data.
		# Handles signals destinated for this class.<br><br>
		# <i>Data</i> syntax:
		# <ul>
		# <li><code>OTHER_DB_DELETED</code> <i>databaseObject</i> - notifies that database given by {@class DB} is about to be deleted,
		# </ul>
		#<
		method signal {receiver data}

		#>
		# @method mode
		# @return Current mode - <code>short</code> or <code>long</code>.
		# @see method long
		# @see method short
		#<
		abstract method mode {}

		#>
		# @method long
		# Switches database to use long names for returned columns.
		# Long names has format: <code>table.column</code>. It's for SQLiteStudio internal usage only.
		# This mode should not be changed by user. Default database mode is short.
		# Long mode is used for advanced queries from {@class EditorWin}.
		# @see method short
		# @see method mode
		#<
		abstract method long {}

		#>
		# @method short
		# Switches database to use short names for returned columns.
		# Short names has format: <code>column</code>. It's for SQLiteStudio internal usage only.
		# This mode should not be changed by user. Default database mode is short.
		# Long mode is used for advanced queries from {@class EditorWin}.
		# @see method long
		# @see method mode
		#<
		abstract method short {}

		#>
		# @method getColumns
		# @param table Table name to get columns for.
		# @param dbName Optional attached database name (name as SQLite sees it, not from {@class DBTree}).
		# @return List of columns (their names) for given table.
		#<
		abstract method getColumns {table {dbName ""}}

		abstract method getDialect {}

		#>
		# @method open
		# Opens database pointed by {@var _path}.<br>
		# Creates SQLite database object and stores it in {@var _db} variable.
		# Also emits signal to all {@class EditorWin} windows to refresh database lists in them.
		# @see var _db
		#<
		method open {}
		method quietOpen {}

		#>
		# @method close
		# Closes previously opened database.
		# Also emits signal to all {@class EditorWin} windows to refresh database lists in them.
		# @see var _db
		#<
		method close {}
		method quietClose {}

		#>
		# @method getPath
		# @return Path pointing to database file, the same as passed to {@method constructor}.
		# @see var _path
		#<
		method getPath {}
		method getNewTempPath {}
		method getObjectProperName {name}

		#>
		# @method isOpen
		# @return <code>true</code> is database pointed by {@var _path} is opened and object is ready to use, or <code>false</code> if not.
		# @see var _db
		#<
		method isOpen {}

		#>
		# @method getName
		# @return Symbolic name of database that is displayed in {@class DBTree}, same as passed to {@method constructor}.
		# @see var _name
		#<
		method getName {}

		#>
		# @method getPathFileName
		# @return File name from {@var _path}. It's the part after last file separator.
		#<
		method getPathFileName {}

		#>
		# @method getHandler
		# @return SQLite handler class for this database.
		#<
		method getHandler {}

		#>
		# @method getTables
		# @param attachedDatabaseName Optional name of already attached database (name, as SQLite sees it, not from {@class DBTree}).
		# @return List of tables (their names) in the database.
		#<
		method getTables {{attachedDatabaseName ""}}

		#>
		# @method getIndexes
		# @param attachedDatabaseName Optional name of already attached database (name, as SQLite sees it, not from {@class DBTree}).
		# @return List of indexes (their names) in the database.
		#<
		method getIndexes {{attachedDatabaseName ""}}

		#>
		# @method getTriggers
		# @param attachedDatabaseName Optional name of already attached database (name, as SQLite sees it, not from {@class DBTree}).
		# @return List of triggers (their names) in the database.
		#<
		method getTriggers {{attachedDatabaseName ""}}

		#>
		# @method getViews
		# @param attachedDatabaseName Optional name of already attached database (name, as SQLite sees it, not from {@class DBTree}).
		# @return List of views (their names) in the database.
		#<
		method getViews {{attachedDatabaseName ""}}

		method getAllTables {}
		method getAllIndexes {}
		method getAllTriggers {}
		method getAllViews {}
		method getExistingObjects {}
		method getObjTable {obj}

		#>
		# @method changeTo
		# @param name New symbolic name to change to.
		# @param path New path to file to change to.
		# Changes database object properties to given.
		# If current (before change) database is opened,
		# then this method does nothing, so close the database first.
		# @see method close
		#<
		method changeTo {name path}

		#>
		# @method getSessionString
		# @overloaded Session
		#<
# 		method getSessionString {}

		#>
		# @method restoreSession {sessionString}
		# @overloaded Session
		#<
# 		proc restoreSession {sessionString}

		#>
		# @method stdErrHandle
		# @param err Error code to be handled.
		# Checks whether given message is one of standard database errors and should not be
		# displayed as critical error with stack trace, but just as simple error/warning
		# in error/warning dialog.
		# @return <code>true</code> if it's standard and handled by this method, but it's really critical error (or just unknown) then it returns <code>false</code>.
		#<
		method stdErrHandle {errCode}

		#>
		# @method functionEvalSql
		# @param sql SQL code to evaluate.
		# @param args Arguments passed to function.
		# @param name Name of called SQL function.
		# This method is called as handler for custom SQL functions. It gets customized SQL as a parameter and additionaly some optional parameters,
		# which are assigned to successive integers, starting from 0.
		# @return Value same, as returned from evaluated SQL.
		#<
		method functionEvalSql {name sql args}

		#>
		# @method functionEvalTcl
		# @param tcl Tcl code to evaluate.
		# @param args Arguments passed to function.
		# @param name Name of called SQL function.
		# This method is called as handler for custom SQL functions. It gets customized Tcl as a parameter and additionaly some optional parameters,
		# which are assigned to variabled named with successive integers, starting from 0.
		# @return Value same, as returned from evaluated Tcl.
		#<
		method functionEvalTcl {name tcl args}
		method functionFileContents {path {debug false}}

		#>
		# @method getTableInfo
		# @param table Table name.
		# @param db Optional database object (DB instance) to read table from.
		# Gets information about the table and returns it as a Tcl list,
		# where each element of the list is Tcl dict, where keys are:<br>
		# <ul>
		# <li><code>name</code> - column name,
		# <li><code>type</code> - column type,
		# <li><code>notnull</code> - 1 if column has NOT NULL property,
		# <li><code>dflt_value</code> - default value,
		# <li><code>pk</code> - 1 if column has primary key property.
		# </ul>
		# For SQLite3 it does <code>PRAGMA table_info(table)\\\;</code>.
		# @return Tcl list of Tcl dicts with information for table.
		#<
		method getTableInfo {table {db ""}}

		method getColumnInfo {table column {db ""}}

		#>
		# @method isNull
		# @param val Value to check.
		# Checks if given value is NULL in database meaning.
		# @return <code>true</code> if given value matches currently configure NULL representation, or <code>false</code> otherwise.
		#<
		abstract method isNull {val}
		abstract method getNull {}
		abstract method isVirtualTable {table}
		abstract method getVirtualTableNames {}
		abstract method handleCollations {}
		abstract method setFkEnabled {bool}
		abstract method isSystemIndex {name}
		abstract method isSystemTable {name}

		#>
		# @method getNativeDatabaseObjects
		# @return List of SQLite database names (as for ATTACH and DETACH statements).
		#<
		abstract method getNativeDatabaseObjects {}

		#>
		# @method getHandlerLabel
		# This method is used to represent handler on GUI, for example in case of choosing what database version should be used.
		# @return Symbolic database handler name.
		#<
		abstract proc getHandlerLabel {}
		abstract proc getHandlerDbVersion {}

		#>
		# @method createDbFile
		# @param path PAth to database file to be created.
		# Creates database using given file with database version implemented by derived class.
		# @return Tcl Dictionary with following entries:
		# <table border=1>
		# <tr><td><code>code</code></td><td><code>true</code> if operation has successed, or <code>false</code> otherwise.</td></tr>
		# <tr><td><code>msg</code></td><td>If code is </code>false</code>, then this field contains detailed message for the error.</td></tr>
		# </table>
		#<
		abstract proc createDbFile {path}

		#>
		# @method executeTcl
		# @param cmd Tcl code to execute.
		# Executes given command in separated Tcl interpreter and returns the result. It takes care of creation and deletion of the interpreter.
		# It can throw errors (when given code causes them).
		# It's used by tcl() SQL function.
		# @return Results from execution.
		#<
		method executeTcl {cmd}

		#>
		# @method sqlFromFile
		# @param path Path to SQL file.
		# @param debug If equal to 1, then any errors while execution of SQL from file will be printed to SQL editor status window.
		# Executes all SQL from given file.
		# @return <code>1</code> if execution successed, or <code>0</code> otherwise.
		#<
		method sqlFromFile {{path ""} {debug 0}}

		#>
		# @method getHandlerClassForFile
		# @param path Path to database file.
		# Probes file for all supported databases and matches proper database handler class.
		# @return DB implementation class that handles given database file or empty string if no handler can be matched.
		#<
		proc getHandlerClassForFile {path}

		#>
		# @method getInstanceForFile
		# @param name Database name.
		# @param path Path to database file.
		# Probes file for all supported databases and created matched database handler instance.
		# @return Instance of DB implementation that handles given database file or empty string if no handler can be matched.
		#<
		proc getInstanceForFile {name path}

		proc sortByName {db1 db2}

		#>
		# @method getUnsupportedFeatures
		# @return List of unsupported feature keywords, like <code>AUTOINCREMENT</code>.
		#<
		abstract proc getUnsupportedFeatures {}

		#>
		# @method getPureSqliteObject
		# @param path Path to database file.
		# Probes SQLite handler and returns pure SQLite object (not wrapped by DB class).
		# @return Pure SQLite object.
		#<
		abstract proc getPureSqliteObject {path}

		# SQLite DB object methods

		#>
		# @method authorizer
		# @parameters procName
		# @param procName Callback procedure that should take 5 arguments and return <code>'SQLITE_OK'</code>, <code>'SQLITE_IGNORE'</code>, or <code>'SQLITE_DENY'</code>.
		# See <a href="http://www.sqlite.org/tclsqlite.html#authorizer">SQLite documentation</a> for details.
		#<
		methodlink authorizer {$_db}

		#>
		# @method busy
		# @parameters procName
		# @param procName Callback procedure that should return '1' to break the job, or '0' to continue.
		# See <a href="http://www.sqlite.org/tclsqlite.html#busy">SQLite documentation</a> for details.
		#<
		methodlink busy {$_db}

		#>
		# @method cache
		# @parameters cmd {number {}}
		# @param cmd Has to be <code>'flush'</code>, or <code>'size'</code>.
		# @param number It's used only for <code>'size'</code> command.
		# See <a href="http://www.sqlite.org/tclsqlite.html#cache">SQLite documentation</a> for details.
		#<
		methodlink cache {$_db}

		#>
		# @method changes
		# @parameters
		# @return Number of last changes.
		# See <a href="http://www.sqlite.org/tclsqlite.html#changes">SQLite documentation</a> for details.
		#<
		methodlink changes {$_db}

		#>
		# @method collate
		# @parameters collateName procName
		# @param collateName Callating name.
		# @param procName Collating implementation procedure name. The procedure should take 2 arguments and return '-1', '0', or '1'.
		# See <a href="http://www.sqlite.org/tclsqlite.html#collate">SQLite documentation</a> for details.
		#<
		methodlink collate {$_db}

		#>
		# @method commit_hook
		# @parameters procName
		# @param procName Callback procedure which can throw an error or return non-zero value to rollback instead of commit.
		# See <a href="http://www.sqlite.org/tclsqlite.html#commit_hook">SQLite documentation</a> for details.
		#<
		methodlink commit_hook {$_db}

		#>
		# @method complete
		# @parameters sql
		# @param sql SQL string to check.
		# See <a href="http://www.sqlite.org/tclsqlite.html#complete">SQLite documentation</a> for details.
		# @return <code>'TRUE'</code> is SQL is OK, or <code>'FALSE'</code> if something is missing/wrong.
		#<
		methodlink complete {$_db}

		#>
		# @method copy
		# @parameters conflictAlgorithm tableName fileName {columnSeparator {\t}} {nullIndicator {}}
		# @param conflictAlgorithm Algorithm to use on conflict.
		# @param tableName Name of table to copy data into.
		# @param fileName File name to copy data from.
		# @param columnSeparator Separator for data in given file. It's usualy comma, period, semi-colon, tab, or space.
		# @param nullIndicator String that indicates <code>null</code> value of column.
		# See <a href="http://www.sqlite.org/tclsqlite.html#copy">SQLite documentation</a> for details.
		#<
		methodlink copy {$_db}

		#>
		# @method collation_needed
		# @parameters collateName
		# @param collateName Requested collation name.
		# See <a href="http://www.sqlite.org/tclsqlite.html#collation_needed">SQLite documentation</a> for details.
		#<
		method collation_needed {collateName}

		#>
		# @method errorcode
		# @parameters
		# See <a href="http://www.sqlite.org/tclsqlite.html#errorcode">SQLite documentation</a> for details.
		# @return Most recent numeric error code.
		#<
		methodlink errorcode {$_db}

		#>
		# @method eval
		# @parameters sql {arrayName {}} {script {}}
		# @param sql SQL query to execute.
		# @param arrayName Name of array to store results in. Array will get indexes just like column names. If this parameter is ommited, then local variables with names like columns will be created. Ommit it if query does not return any results.
		# @param script Tcl script to execute for each results row. Ommit it if query does not return any results.
		# See <a href="http://www.sqlite.org/tclsqlite.html#eval">SQLite documentation</a> for details.
		#<
		method eval {args}

		#>
		# @method onecolumn
		# @parameters sql
		# @param sql SQL query where first row of first column will be taken as a result.
		# See <a href="http://www.sqlite.org/tclsqlite.html#onecolumn">SQLite documentation</a> for details.
		#<
		method onecolumn {$_db}

		#>
		# @method exists
		# @parameters sql
		# @param sql SQL query to check if it has any results.
		# See <a href="http://www.sqlite.org/tclsqlite.html#exists">SQLite documentation</a> for details.
		#<
		methodlink exists {$_db}

		#>
		# @method function
		# @parameters sqlFunction procName
		# @param sqlFunction New SQL function that can be used in SQL queries.
		# @param procName Implementation procedure name. Should take as many parameters as will be passed to sqlFunction.
		# See <a href="http://www.sqlite.org/tclsqlite.html#function">SQLite documentation</a> for details.
		#<
		methodlink function {$_db}

		#>
		# @method last_insert_rowid
		# @parameters
		# See <a href="http://www.sqlite.org/tclsqlite.html#last_insert_rowid">SQLite documentation</a> for details.
		# @return Most recently inserted row ID.
		#<
		methodlink last_insert_rowid {$_db}

		#>
		# @method nullvalue
		# @parameters string
		# @param string Null representation string.
		# See <a href="http://www.sqlite.org/tclsqlite.html#nullvalue">SQLite documentation</a> for details.
		#<
		methodlink nullvalue {$_db}

		#>
		# @method progress
		# @parameters opCodes procName
		# @param opCodes Number of SQLite opcodes between invocations.
		# @param procName Procedure name to call for each progress invocation.
		# See <a href="http://www.sqlite.org/tclsqlite.html#progress">SQLite documentation</a> for details.
		#<
		methodlink progress {$_db}

		#>
		# @method timeout
		# @parameters miliseconds
		# @param miliseconds New timeout in miliseconds.
		# See <a href="http://www.sqlite.org/tclsqlite.html#timeout">SQLite documentation</a> for details.
		#<
		methodlink timeout {$_db}

		#>
		# @method total_changes
		# @parameters
		# See <a href="http://www.sqlite.org/tclsqlite.html#total_changes">SQLite documentation</a> for details.
		# @return Total rows changed since database was opened first time.
		#<
		methodlink total_changes {$_db}

		#>
		# @method trace
		# @parameters procName
		# @param procName Callback method that should take one argument - executed SQL query.
		# See <a href="http://www.sqlite.org/tclsqlite.html#trace">SQLite documentation</a> for details.
		#<
		methodlink trace {$_db}

		#>
		# @method transaction
		# @parameters {transactionType {}} script
		# @param transactionType Type of transaction. Can be one of: <code>deferred</code>, <code>exclusive</code> or <code>immediate</code>.
		# @param script Script to execute within the transaction. If script throw error, transaction is rolled back. If everything is OK, then transaction is commited.
		# See <a href="http://www.sqlite.org/tclsqlite.html#transaction">SQLite documentation</a> for details.
		#<
		methodlink transaction {$_db}

		#>
		# @method registerCustomFunction
		# @param name Name of SQL function to register.
		# @param type Type of function implementation - SQL or Tcl.
		# @param code SQL or Tcl code of function to execute.
		# Registers new SQL function that will be available in this database.
		#<
		method registerCustomFunction {name type code}

		#>
		# @method setTemp
		# @param value Temporary flag new value.
		# Sets new value for temporary flag. See {@var _temp}.
		#<
		method setTemp {value}

		#>
		# @method getTemp
		# Gets value of temporary flag. See {@var _temp}.
		# @return Temporary flag value.
		#<
		method isTemp {}

		#>
		# @method convertDb
		# @param toHnd To handler.
		# @param name Name of new database.
		# @param path File of new database.
		# @param register <code>false</code> to avoid registering database in databases tree.
		# Converts database from one type to another (SQLite2<->SQLite3).
		#<
# 		method convertDb {toHnd name path}

# 		method execQueryUsingHacks {query {plainText false} {limitResults true}}
# 		method executePreparedQuery {query {limit ""} {offset ""}}
		method getSqliteObjectDdl {type name}
		method getUniqueObjName {{name ""}}
		method attach {db {name ""}}
		method detach {db}
		method getNativeDb {}
		method getAttachName {db}
		method begin {}
		method commit {}
		method rollback {}
		method getAttachSql {db}
		method getExtensions {}
		method setExtensions {extensions}
		method addExtensions {extensions}
		abstract method validate {}
		abstract method vacuum {}
	}
}

body DB::constructor {name path} {
	set _path $path
	set _name $name
}

body DB::getPathFileName {} {
	return [lindex [file split $_path] end]
}

body DB::open {} {
	if {[catch {
		set _db [createDbObject ::database$dbNum]
		registerFunctions
		DBTREE expandRoot $this
		DBTREE refreshSchemaForDb $this
		MAIN updateEditorsDatabases
		handleCollations
		incr dbNum
	} res]} {
		puts $::errorInfo
		Error [mc "Error while opening %s database:\n%s" $_path $res]
		catch {closeDb}
		DBTREE closeRoot $this
		MAIN updateEditorsDatabases
	}
}

body DB::quietOpen {} {
	if {[catch {
		set _db [createDbObject ::database$dbNum]
		registerFunctions
		incr dbNum
	} res]} {
		Error [mc "Error while opening %s database:\n%s" $_path $res]
	}
}

body DB::collation_needed {collateName} {
	#puts "name: $collateName"
	$_db collate $collateName nocase_compare
}

body DB::registerFunctions {} {
	foreach {name cmd completion} [list \
		tcl [list $this executeTcl] "tcl('Tcl code')" \
		sqlfile [list $this sqlFromFile] "sqlfile('file')" \
		base64_encode ::base64::encode "base64_encode(arg)" \
		base64_decode ::base64::decode "base64_decode(arg)" \
		md5 ::md5::md5 "md5(arg)" \
		sha1 ::sha1::sha1 "sha1(arg)" \
		md4 ::md4::md4 "md4(arg)" \
		sha256 ::sha256::sha256 "sha256(arg)" \
		crc16 ::crc::crc16 "crc16(arg)" \
		crc32 ::crc::crc32 "crc32(arg)" \
		uuencode_encode ::uuencode::encode "uuencode_encode(arg)" \
		uuencode_decode ::uuencode::decode "uuencode_decode(arg)" \
		yencode_encode ::yencode::encode "yencode_encode(arg)" \
		yencode_decode ::yencode::decode "yencode_decode(arg)" \
		file [list $this functionFileContents] "file('file')" \
	] {
		function $name $cmd
		if {$completion ni $::SQL_FUNCTIONS} {
			lappend ::SQL_FUNCTIONS $completion
		}
	}

	# Custom functions
	foreach func [CfgWin::getFunctions] {
		lassign $func name type code
		registerCustomFunction $name $type $code
	}
}

body DB::registerCustomFunction {name type code} {
	switch -- $type {
		"SQL" {
			function $name [list $this functionEvalSql $name $code]
		}
		"Tcl" {
			function $name [list $this functionEvalTcl $name $code]
		}
	}
}

body DB::functionEvalSql {name sql args} {
	for {set i 0} {$i < [llength $args]} {incr i} {
		set $i [lindex $args $i]
	}
	if {[catch {
		$this eval $sql
	} res]} {
		error $res
	} else {
		set outputList [list]
		foreach val $res {
			if {[$this isNull $val]} {
				lappend outputList ""
			} else {
				lappend outputList $val
			}
		}
		return [join $outputList " "]
	}
}

body DB::functionEvalTcl {name tcl args} {
	set cmds [list]
	for {set i 0} {$i < [llength $args]} {incr i} {
		lappend cmds [list set $i [lindex $args $i]]
	}
	lappend cmds $tcl
	set cmd [join $cmds ";\n"]
	set newCmd "namespace eval ::executeTcl {"
	append newCmd $cmd
	append newCmd "}"
	initInterp
	if {[catch {$_interp eval $newCmd} res]} {
		$_interp eval [list namespace delete ::executeTcl]
		set re {can\'t read \"\d+\"\: no such variable}
		if {[regexp -- $re $res]} {
			error [mc {Not enough parameters passed to function '%s'.} $name]
		} else {
			error $res
		}
	}
	$_interp eval [list namespace delete ::executeTcl]
	return $res
}

body DB::executeTcl {cmd} {
	set newCmd "namespace eval ::executeTcl {"
	append newCmd $cmd
	append newCmd "}"
	initInterp
	if {[catch {$_interp eval $newCmd} res]} {
		$_interp eval [list namespace delete ::executeTcl]
		error $res
	}
	$_interp eval [list namespace delete ::executeTcl]
	return $res
}

body DB::sqlFromFile {{path ""} {debug 0}} {
	set debug [expr {[string is boolean $debug] && $debug}]
	if {![file readable $path]} {
		if {$debug} {
			error [mc {Cannot read file: %s} $path]
		}
		return 0
	}
	set fd [::open $path r]
	set data [::read $fd]
	::close $fd

	set queryExecutor [QueryExecutor ::#auto $this]

	# Showing progress bar
	set progress [BusyDialog::show [mc {Query execution...}] [mc {Executing SQL query...}] true 50 false]
	$progress configure -onclose "
		$queryExecutor interrupt
		delete object $queryExecutor
		BusyDialog::hide
	"
	$progress setCloseButtonLabel [mc {Cancel}]
	BusyDialog::autoProgress 20

	if {[catch {
		$queryExecutor directExec $data true
		delete object $queryExecutor
	} res]} {
		BusyDialog::hide
		if {$debug} {
			error $res
		}
		return 0
	} else {
		BusyDialog::hide
		return 1
	}
}

body DB::functionFileContents {path {debug false}} {
	set debug [expr {[string is boolean $debug] && $debug}]
	if {![file readable $path]} {
		if {$debug} {
			error [mc {Cannot read file: %s} $path]
		}
		return ""
	}
	set fd [::open $path r]
	fconfigure $fd -translation binary -encoding binary
	set data [::read $fd]
	::close $fd
	return $data
}

body DB::close {} {
	DBTREE closeRoot $this
	TASKBAR signal TableWin [list CLOSE_BY_DB $this]
	if {$_interp != ""} {
		interp delete $_interp
		set _interp ""
	}
	closeDb
	MAIN updateEditorsDatabases
}

body DB::quietClose {} {
	closeDb
}

body DB::getHandler {} {
	return [$this info class]
}

body DB::getNativeDb {} {
	return $_db
}

body DB::getPath {} {
	return $_path
}

body DB::getNewTempPath {} {
	set path $_path.temp
	set i 0
	while {[file exists ${path}$i]} {
		incr i
	}
	return ${path}$i
}

body DB::getName {} {
	return $_name
}

body DB::isOpen {} {
	if {$_db != ""} {
		return 1
	} else {
		return 0
	}
}

body DB::getTables {{attachedDatabaseName ""}} {
	if {![isOpen]} return
	if {$attachedDatabaseName == "" || $attachedDatabaseName == "main"} {
		set tables [$this eval {SELECT name FROM sqlite_master WHERE type = 'table'}]
	} elseif {$attachedDatabaseName == "temp"} {
		set tables [$this eval {SELECT name FROM sqlite_temp_master WHERE type = 'table'}]
	} else {
		set prefix "[wrapObjName $attachedDatabaseName [getDialect]]"
		if {[catch {
			set tables [$this eval "SELECT name FROM ${prefix}.sqlite_master WHERE type = 'table'"]
		}]} {
			set tables [list]
		}
	}
	lappend tables "sqlite_master" "sqlite_temp_master"
	set tables [lsort -unique $tables]
	return $tables
}

body DB::getIndexes {{attachedDatabaseName ""}} {
	if {![isOpen]} return
	if {$attachedDatabaseName == "" || $attachedDatabaseName == "main"} {
		set indexes [$this eval {SELECT name FROM sqlite_master WHERE type = 'index'}]
	} elseif {$attachedDatabaseName == "temp"} {
		set indexes [$this eval {SELECT name FROM sqlite_temp_master WHERE type = 'index'}]
	} else {
		set prefix "[wrapObjName $attachedDatabaseName [getDialect]]"
		if {[catch {
			set indexes [$this eval "SELECT name FROM ${prefix}.sqlite_master WHERE type = 'index'"]
		}]} {
			set indexes [list]
		}
	}

	# Filtering sqlite system indexes
	set filtered [list]
	foreach idx $indexes {
		if {![string match "sqlite_autoindex_*" $idx]} {
			lappend filtered $idx
		}
	}

	return $filtered
}

body DB::getTriggers {{attachedDatabaseName ""}} {
	if {![isOpen]} return
	if {$attachedDatabaseName == "" || $attachedDatabaseName == "main"} {
		set trigs [$this eval {SELECT name FROM sqlite_master WHERE type = 'trigger'}]
	} elseif {$attachedDatabaseName == "temp"} {
		set trigs [$this eval {SELECT name FROM sqlite_temp_master WHERE type = 'trigger'}]
	} else {
		set prefix "[wrapObjName $attachedDatabaseName [getDialect]]"
		if {[catch {
			set trigs [$this eval "SELECT name FROM ${prefix}.sqlite_master WHERE type = 'trigger'"]
		}]} {
			set trigs [list]
		}
	}
	return $trigs
}

body DB::getViews {{attachedDatabaseName ""}} {
	if {![isOpen]} return
	if {$attachedDatabaseName == "" || $attachedDatabaseName == "main"} {
		set views [$this eval {SELECT name FROM sqlite_master WHERE type = 'view'}]
	} elseif {$attachedDatabaseName == "temp"} {
		set views [$this eval {SELECT name FROM sqlite_temp_master WHERE type = 'view'}]
	} else {
		set prefix "[wrapObjName $attachedDatabaseName [getDialect]]"
		if {[catch {
			set views [$this eval "SELECT name FROM ${prefix}.sqlite_master WHERE type = 'view'"]
		}]} {
			set views [list]
		}
	}
	return $views
}

body DB::changeTo {name path} {
	if {[isOpen]} return
	set _name $name
	set _path $path
	DBTREE saveDBCfg
}

# body DB::getSessionString {} {
# 	return [list DATABASE $_name]
# }
# 
# body DB::restoreSession {sessionString} {
# 	lassign $sessionString type dbName
# 	if {$type != "DATABASE"} {
# 		return 0
# 	}
# 
# 	set db [DBTREE getDBByName $dbName]
# 	if {$db != ""} {
# 		if {![$db isOpen]} {
# 			$db open
# 			DBTREE refreshSchemaForDb $db
# 		}
# 	}
# 	return 1
# }

body DB::getInstanceForFile {name path} {
	# Readable perms test
	set fd [::open $path r]
	read $fd 1
	::close $fd

	set hnd [getHandlerClassForFile $path]
	if {$hnd != ""} {
		return [$hnd ::#auto $name $path]
	} else {
		return ""
	}
}

body DB::getHandlerClassForFile {path} {
	foreach hnd $::DB_HANDLERS {
		if {[${hnd}::probe $path]} {
			return $hnd
		}
	}
	return ""
}

body DB::getPureSqliteObject {path} {
	foreach hnd $::DB_HANDLERS {
		if {[${hnd}::probe $path]} {
			return $hnd
		}
	}
	return ""
}

body DB::eval {args} {
	if {$_db == ""} {
		return ;# Make sure we don't execute posponed evaluations after db is closed.
	}

	if {$::DEBUG(sql)} {
		puts "$_db SQL -> [lindex $args 0]"
	}

	set code [catch {
		uplevel [list $_db eval {*}$args]
	} res]

	if {$code == 1} {
		if {![stdErrHandle [$_db errorcode]]} {
			error $::errorInfo
		}
	} else {
		return $res
	}
}

body DB::onecolumn {args} {
	if {$::DEBUG(sql)} {
		puts "$_db SQL -> [lindex $args 0]"
	}
	if {[catch {
		set retValue [uplevel [list $_db onecolumn {*}$args]]
	} res]} {
		if {![stdErrHandle [$_db errorcode]]} {
			error $::errorInfo
		}
	} else {
		return $retValue
	}
}

body DB::stdErrHandle {errCode} {
	if {[info exists stdError($errCode)]} {
		lassign $stdError($errCode) msg lev
		switch -- $lev {
			"info" {
				Info $msg
			}
			"warning" {
				Warning $msg
			}
			"error" {
				Error $msg
			}
			default {
				error "Unknown error handler level: $lev (error code was: $errCode)"
			}
		}
		return 1
	} else {
		return 0
	}
	return 0
}

body DB::setTemp {value} {
	set _temp $value
}

body DB::isTemp {} {
	return $_temp
}

# body DB::convertDb {toHnd name path} {
# 	set results [dict create returnCode 0 errors [list]]
# 	set createResults [${toHnd}::createDbFile $path]
# 	if {![dict get $createResults code]} {
# 		set res [dict get $createResults msg]
# 		dict lappend results [list [mc {Cannot create database file}] $res]
# 		dict set results returnCode 1
# 		return $results
# 	}
# 	if {[catch {
# 		set newDb [DBTREE addDB $name $path]
# 	}]} {
# 		dict set results returnCode 1
# 		return $results
# 	}
# 
# 	if {![$newDb isOpen]} {
# 		$newDb open
# 	}
# 
# 	set unsupported [${toHnd}::getUnsupportedFeatures]
# 
# 	$newDb begin
# 
# 	set err 0
# 	set tablesToCopy [list]
# 	# Copying table DDLs
# 	set mode [$this mode]
# 	$this short
# 	eval {SELECT name, sql FROM sqlite_master WHERE type = 'table'} R {
# 		set sql $R(sql)
# 		if {[string match "*PRIMARY*KEY*AUTOINCREMENT*" $R(sql)] && "AUTOINCREMENT" in $unsupported} {
# 			regsub -all -- {\s*AUTOINCREMENT\s*} $sql " " newSql
# 			set sql $newSql
# 		}
# 		if {[string match "*COLLATE*" $R(sql)] && "COLLATE" in $unsupported} {
# 			regsub -all -- {\s*COLLATE\s+\S+\s*} $sql " " newSql
# 			set sql $newSql
# 		}
# 		if {[catch {$newDb eval $sql} res]} {
# 			cutOffStdTclErr res
# 			dict lappend results errors $res
# 			dict set results returnCode 1
# 		} else {
# 			lappend tablesToCopy $R(name)
# 		}
# 	}
# 
# 	# Copying tables data
# 	foreach table $tablesToCopy {
# 		catch {array unset R}
# 		eval "SELECT * FROM [wrapObjName $table [getDialect]]" R {
# 			set cols [join [wrapColNames $R(*) [getDialect]] ","]
# 			set vals [list]
# 			foreach col $R(*) {
# 				if {[isNull $R($col)]} {
# 					lappend vals "null"
# 				} elseif {$R($col) != "" && [string is integer $R($col)]} {
# 					lappend vals $R($col)
# 				} else {
# 					lappend vals "'[string map [list ' ''] $R($col)]'"
# 				}
# 			}
# 			set vals [join $vals ","]
# 			set err 0
# 			if {[catch {$newDb eval "INSERT INTO [wrapObjName $table [getDialect]] ($cols) VALUES ($vals)"} res]} {
# 				cutOffStdTclErr res
# 				dict lappend results errors $res
# 				dict set results returnCode 1
# 			}
# 		}
# 	}
# 
# 	# Rest objects DDL
# 	catch {array unset R}
# 	catch {nullvalue ""}
# 	eval {SELECT name, type, sql FROM sqlite_master WHERE type <> 'table'} R {
# 		set sql $R(sql)
# 		if {[string trim $sql] == ""} continue
# 		switch -- $R(type) {
# 			"index" {
# 				if {[string match "*COLLATE*" $R(sql)] && "INDEX_COLLATE" in $unsupported} {
# 					regsub -all -- {\s*COLLATE\s+\S+\s*} $sql " " newSql
# 					set sql $newSql
# 				}
# 			}
# 		}
# 		set err 0
# 		if {[catch {$newDb eval $sql} res]} {
# 			cutOffStdTclErr res
# 			dict lappend results errors $res
# 			dict set results returnCode 1
# 		}
# 	}
# 	$this $mode
# 	catch {nullvalue [set [$this info class]::nullValue]}
# 
# 	# Done
# 	$newDb commit
# 	return $results
# }

body DB::getSqliteObjectDdl {type name} {
	set name [string tolower [string map [list ' ''] $name]]
	set ddl [onecolumn "SELECT sql FROM sqlite_master WHERE type = '$type' AND lower(name) = [wrapString $name]"]
	return $ddl
}

body DB::getObjectProperName {name} {
	if {[ModelExtractor::isSupportedSystemTable $name]} {
		return $name
	}
	set name [string tolower [string map [list ' ''] $name]]
	return [onecolumn "SELECT name FROM sqlite_master WHERE lower(name) = [wrapString $name]"]
}

body DB::attach {db {name ""}} {
	# Check if database is valid for attaching
	if {![$db validate]} {
		Error [mc {Could not attach database %s. It doesn't exists, has incompatible version,or file format is invalid.} [$db getName]]
		return ""
	}

	if {![info exists _attachedDatabases($db)]} {
		if {$name == ""} {
			# Generate name
			set attachName ""
			set existingNames [getNativeDatabaseObjects]
			while {$attachName == "" || $attachName in $existingNames} {
				set attachName "attached_[randcrap 6]"
			}
		} else {
			set attachName $name
		}
	} else {
		incr _attachedDatabasesCounter($db)
		return $_attachedDatabases($db)
	}

	# Attach it
	set remotePath [$db getPath]
	if {[catch {
		$this eval "ATTACH DATABASE '[string map [list ' ''] $remotePath]' AS $attachName"
	} err]} {
		Error [mc "Could not attach database %s. Error message from SQLite:\n%s" [$db getName] $err]
		return ""
	}

	set _attachedDatabases($db) $attachName
	set _attachedDatabasesCounter($db) 1
	return $attachName
}

body DB::getAttachName {db} {
	if {[info exists _attachedDatabases($db)]} {
		return $_attachedDatabases($db)
	} else {
		return ""
	}
}

body DB::getAttachSql {db} {
	# Check if database is valid for attaching
	if {![$db validate]} {
		Error [mc {Could not get attach SQL for database %s. It doesn't exists, has incompatible version, or file format is invalid.} [$db getName]]
		return ""
	}

	# Generate name
	set attachName ""
	set existingNames [getNativeDatabaseObjects]
	while {$attachName == "" || $attachName in $existingNames} {
		set attachName "attached_[randcrap 6]"
	}

	# Attach it
	set remotePath [$db getPath]
	return [dict create sql "ATTACH DATABASE '[string map [list ' ''] $remotePath]' AS $attachName" name $attachName]
}

body DB::detach {db} {
	if {[info exists _attachedDatabases($db)]} {
		# Detaching by symbolic name
		set attachName $_attachedDatabases($db)
		set dbObj $db
	} else {
		# Detaching by actual attach name
		set attachName $db
		set dbObj ""
		foreach idx [array names _attachedDatabases] {
			if {[string equal $_attachedDatabases($idx) $attachName]} {
				set dbObj $idx
			}
			break
		}
	}
	
	if {[info exists _attachedDatabases($dbObj)]} {
		if {$_attachedDatabasesCounter($dbObj) > 1} {
			incr _attachedDatabasesCounter($dbObj) -1
		} else {
			unset _attachedDatabases($dbObj)
			unset _attachedDatabasesCounter($dbObj)
			catch {$this eval "DETACH DATABASE $attachName"}
		}
	}
}

body DB::signal {receiver data} {
	if {[$this isa $receiver]} {
		if {[lindex $data 0] == "OTHER_DB_DELETED"} {
			set db [lindex $data 1]
			if {[info exists _attachedDatabases($db)]} {
				detach $db
			}
		}
	}
}

body DB::getTableInfo {table {db ""}} {
	if {![isOpen]} return
	set res [list]
	set attached false
	set parser [UniversalParser ::#auto $this]
	$parser configure -expectedTokenParsing false

	set name [string tolower $table]

	set sql "SELECT * FROM sqlite_master WHERE lower(name) = [wrapString $name] LIMIT 1"
	if {$db != ""} {
		if {[info exists _attachedDatabases($db)]} {
			set attachName $_attachedDatabases($db)
		} else {
			set attached true
			set attachName [attach $db]
		}
		set sql "SELECT * FROM $attachName.sqlite_master WHERE lower(name) = [wrapString $name] LIMIT 1"
	}

	set mode [$this mode]
	$this short
	$this eval $sql row {
		$parser parseSql $row(sql)
		set results [$parser get]

		# Error handling
		if {[dict get $results returnCode]} {
			$this $mode
			debug "Table '$table' parsing error message: [dict get $results errorMessage]"
			delete object $parser
			error [format "Cannot parse objects DDL.\nSQLite version is %s.\nThe DDL is:\n%s\n\nError stack:" [$_db onecolumn {SELECT sqlite_version()}] $row(sql)]
		}

		# Extracting info
		set createTableStmt [[dict get $results object] getValue subStatement]
		if {![$createTableStmt isa StatementCreateTable] && ![$createTableStmt isa Statement2CreateTable]} {
			# It's a view, not table
			break
		}

		foreach colDef [$createTableStmt getValue columnDefs] {
			# Name
			set name [$colDef getValue columnName]

			# Type
			set typeDef [$colDef getValue typeName]
			set type ""
			if {$typeDef != ""} {
				set type [$typeDef toString]
			}

			# NotNull
			set notnull 0
			if {[$colDef getNotNull] != ""} {
				set notnull 1
			}

			# Default
			set default [set [info class]::nullValue]
			set defStmt [$colDef getDefault]
			if {$defStmt != ""} {
				set expr [$defStmt getValue expr]
				if {$expr != ""} {
					set default [$expr toSql]
				} else {
					set default [$defStmt getValue literalValue]
				}
			}

			# Pk
			set pk 0
			if {[llength [$colDef getPk]] > 0} {
				set pk 1
			}

			set el [dict create]
			dict append el name [stripObjName $name]
			dict append el type $type
			dict append el notnull $notnull
			dict append el dflt_value $default
			dict append el pk $pk
			lappend res $el
		}

		break ;# Just to be sure we parse only one table
	}

	$this $mode
	delete object $parser

	if {$db != "" && $attached} {
		detach $db
	}

	return $res
}

body DB::getColumnInfo {table column {db ""}} {
	if {![isOpen]} return
	set res [dict create table $table column $column type "" pk [list 0 ""] unique [list 0 ""] notnull [list 0 ""] \
		default [list 0 ""] fk [list 0 ""] collate [list 0 ""] check [list 0 ""]]
	set attached false
	set parser [UniversalParser ::#auto $this]
	$parser configure -expectedTokenParsing false

	set name [string tolower $table]

	set sql "SELECT * FROM sqlite_master WHERE lower(name) = [wrapString $name] LIMIT 1"
	if {$db != ""} {
		if {[info exists _attachedDatabases($db)]} {
			set attachName $_attachedDatabases($db)
		} else {
			set attached true
			set attachName [attach $db]
		}
		set sql "SELECT * FROM $attachName.sqlite_master WHERE lower(name) = [wrapString $name] LIMIT 1"
	}

	set sqliteVersion [expr {[$this getDialect] == "sqlite3" ? 3 : 2}]
	
	set mode [$this mode]
	$this short
	$this eval $sql row {
		$parser parseSql $row(sql)
		set results [$parser get]

		# Error handling
		if {[dict get $results returnCode]} {
			$this $mode
			debug "Table '$table' parsing error message: [dict get $results errorMessage]"
			delete object $parser
			error [format "Cannot parse objects DDL.\nSQLite version is %s.\nThe DDL is:\n%s\n\nError stack:" [$_db onecolumn {SELECT sqlite_version()}] $row(sql)]
		}

		# Extracting info
		set createTableStmt [[dict get $results object] getValue subStatement]
		if {![$createTableStmt isa StatementCreateTable] && ![$createTableStmt isa Statement2CreateTable]} {
			# It's a view, not table
			break
		}

		foreach colDef [$createTableStmt getValue columnDefs] {
			# Name
			set name [$colDef getValue columnName]
			if {![string equal -nocase $name $column]} continue

			# Type
			set typeDef [$colDef getValue typeName]
			set type ""
			if {$typeDef != ""} {
				set type [$typeDef toString]
			}
			dict set res type $type

			# Notnull, unqiue, check
			foreach {varName method sqlite_v2} {
				pk getPk 1
				fk getFk 0
				notnull getNotNull 1
				unique getUniq 1
				check getChk 1
				collate getCollate 0
				default getDefault 1
			} {
				if {$sqliteVersion == 2 && !$sqlite_v2} continue
				set $varName [$colDef $method]
				if {[set $varName] != ""} {
					dict set res $varName [list 1 [[set $varName] toSql true]]
				}
			}
		}

		break ;# Just to be sure we parse only one table
	}

	$this $mode
	delete object $parser

	if {$db != "" && $attached} {
		detach $db
	}

	return $res
}

body DB::sortByName {db1 db2} {
	set inList [list [$db1 getName] [$db2 getName]]
	set outList [lsort -dictionary $inList]
	if {$inList == $outList} {
		return -1
	} else {
		return 1
	}
}

body DB::getExtensions {} {
	return $_extensions
}

body DB::setExtensions {extensions} {
	set _extensions $extensions
}

body DB::addExtensions {extensions} {
	lappend _extensions {*}$extensions
	set _extensions [lsort -unique $_extensions]
}

body DB::begin {} {
	$_transactionTrace push "SAVEPOINT 'SQLiteStudio' \[[getTimeStamp]\]\n[buildStackTrace]\n"
	if {[catch {
		$this internalBegin
	} err]} {
		catch {$this errorcode} errCode
		$_transactionTrace push "SAVEPOINT failed \[[getTimeStamp]\]\n[buildStackTrace]\n"
		error "$err\nTransactions trace:\n[join [$_transactionTrace dump] \n]\nDB_ERROR_CODE=$errCode\nSQLite trace:\n[join $_trace \n]\n\nDB object: $this"
	}
	$_transactionTrace push "SAVEPOINT succeed \[[getTimeStamp]\]\n[buildStackTrace]\n"
}

body DB::commit {} {
	$_transactionTrace push "RELEASE 'SQLiteStudio' \[[getTimeStamp]\]\n[buildStackTrace]\n"
	if {[catch {
		$this internalCommit
	} err]} {
		catch {$this errorcode} errCode
		$_transactionTrace push "RELEASE failed \[[getTimeStamp]\]\n[buildStackTrace]\n"
		error "$err\nTransactions trace:\n[join [$_transactionTrace dump] \n]\nDB_ERROR_CODE=$errCode\nSQLite trace:\n[join $_trace \n]\n\nDB object: $this"
	}
	$_transactionTrace push "RELEASE succeed \[[getTimeStamp]\]\n[buildStackTrace]\n"
}

body DB::rollback {} {
	$_transactionTrace push "ROLLBACK TO SAVEPOINT 'SQLiteStudio' \[[getTimeStamp]\]\n[buildStackTrace]\n"
	if {[catch {
		$this internalRollback
	} err]} {
		catch {$this errorcode} errCode
		$_transactionTrace push "ROLLBACK failed \[[getTimeStamp]\]\n[buildStackTrace]\n"
		error "$err\nTransactions trace:\n[join [$_transactionTrace dump] \n]\nDB_ERROR_CODE=$errCode\nSQLite trace:\n[join $_trace \n]\n\nDB object: $this"
	}
	$_transactionTrace push "ROLLBACK succeed \[[getTimeStamp]\]\n[buildStackTrace]\n"
}

body DB::addTrace {sql} {
	if {[string match -nocase "BEGIN*" $sql] || [string match -nocase "COMMIT*" $sql] \
			|| [string match -nocase "ROLLBACK*" $sql]|| [string match -nocase "END*" $sql]} {
		$_trace push $sql
	}
}

body DB::getAllObjects {method {attachedDatabaseName ""}} {
	set results [list]
	foreach obj [$method] {
		lappend results [list "" $obj]
	}
	foreach idx [array names _attachedDatabases] {
		foreach obj [$method $_attachedDatabases($idx)] {
			lappend results [list $_attachedDatabases($idx) $obj]
		}
	}
	return $results
}

body DB::getAllTables {} {
	getAllObjects getTables
}

body DB::getAllIndexes {} {
	getAllObjects getIndexes
}

body DB::getAllTriggers {} {
	getAllObjects getTriggers
}

body DB::getAllViews {} {
	getAllObjects getViews
}

body DB::getExistingObjects {} {
	if {![isOpen]} return
	set objs [$this eval {SELECT name FROM sqlite_master}]
	lappend objs {*}[$this eval {SELECT name FROM sqlite_temp_master}]
	return $objs
}

body DB::getUniqueObjName {{name ""}} {
	set names [getExistingObjects]
	if {$name != ""} {
		if {$name ni $names} {
			return $name
		}
		return [genUniqueSeqName $names "${name}_"]
	} else {
		return [genUniqueSeqName $names [randcrap 4]]
	}
}

body DB::initInterp {} {
	if {$_interp == ""} {
		set _interp [interp create]
		$_interp alias db $this
	}
}

body DB::getObjTable {obj} {
	set sql "SELECT tbl_name FROM sqlite_master WHERE lower(name) = [wrapString [string tolower $obj]] LIMIT 1"
	return [$this onecolumn $sql]
}
