use src/plugins/plugin.tcl
use src/common/common.tcl

#>
# @class ExportPlugin
# Base class for all exporting plugins.
#<
abstract class ExportPlugin {
	inherit Plugin

	constructor {} {}

	#>
	# @var handlers
	# Keeps list of installed export plugin classes.
	#<
	common handlers [list]

	private {
		variable _iterationCounter 0
	}

	protected {
		variable _db ""
		variable _context ""
		variable _fd ""
	}

	public {
		#>
		# @method init
		# Initializes list of handlers. They should be already loaded by interpreter, this method just find their classes
		# and places them in {@var handlers} variable.
		#<
		proc init {}

		#>
		# @method getName
		# @return Name of formatter to display on interface.
		#<
		abstract proc getName {}

		#>
		# @method isContextSupported {context}
		# @param context <code>DATABASE</code>, <code>TABLE</code>, or <code>QUERY</code>. Last one is for exporting SQL query results.
		# This method is used to determinate if export engine supports given context. If method return false for given context,
		# then the plugin won't appear in list of available plugins for given exporting context.
		# @return Boolean value defining if implemented export engine supports given context.
		#<
		abstract proc isContextSupported {context}

		#>
		# @method configurable
		# @param context <code>DATABASE</code>, <code>TABLE</code>, or <code>QUERY</code>. Last one is for exporting SQL query results.
		# This method is used to determinate if export engine supports any configuration, but this is also good idea to remember exporting context
		# for later use (while exporting) in some class private variable.
		# @return Boolean value defining if implemented export engine supports and requires configuration for given exporting context. If <code>true</code>, then methods {@method createConfigUI} and {@method applyConfig} should be implemented.
		#<
		abstract proc configurable {context}

		#>
		# @method createConfigUI
		# @param path Tk widget path to frame where configuration should be placed.
		# @param context <code>DATABASE</code>, <code>TABLE</code>, or <code>QUERY</code>. Last one is for exporting SQL query results.
		# Implementation should create configuration widget in frame pointed by given path.
		# Can do nothing if {@method configurable} returns <code>false</code>.
		#<
		abstract method createConfigUI {path context}

		#>
		# @method applyConfig
		# @param path Tk widget path to frame where configuration is placed.
		# @param context <code>DATABASE</code>, <code>TABLE</code>, or <code>QUERY</code>. Last one is for exporting SQL query results.
		# Implementation should extract necessary informations from configuration widget and store it in local variables,
		# so they can be used later by other methods.<br>
		# Configuration widget in path will be destroyed just after this method call is completed.
		# Can do nothing if {@method configurable} returns <code>false</code>.
		#<
		abstract method applyConfig {path context}

		#>
		# @method validateConfig
		# @param context <code>DATABASE</code>, <code>TABLE</code>, or <code>QUERY</code>. Last one is for exporting SQL query results.
		# It's called just before any export* is called. It allows to validate if all configured parameters (if any) are valid for exportig in given context.
		# If there is any invalid parameter, then this method should call <code>error</code> command - it will be caught and displayed in error dialog.
		#<
		abstract method validateConfig {context}
		
		#>
		# @method configSize
		# Optional method to implemend. If returns not empty string, it should be list of width and height that the configuration
		# window should resized to. By default it's resized to fit contents.
		#<
		method configSize {}

		#>
		# @method exportResults
		# @param columns List of columns in table. Each element in list is dict of column name, its table, database and datatype (column, table, database, type - keys respectively). Datatype is actually not provided (it's empty) at the moment, since it's not possible to determinate it from results.
		# @param rows Table data as list of rows. Each row is list of values for each column and each value is pair of the value as Tcl sees it and second is boolean indicating if it's <code>null</code> (<code>true</code>) or it's not <code>null</code>.
		# This method gets SQL query results (from SQL editor window) and should convert them to format that is implemented by the plugin, then returned.
		# @return Data in export format, ready to write to file.
		#<
		abstract method exportResults {columns totalRows}
		abstract method exportResultsRow {cellsData columns}
		abstract method exportResultsEnd {}

		#>
		# @method exportTable
		# @param name Name of the table to export.
		# @param columns List of columns in table. Each element in list is sublist of: column name (without 'table_name.' prefix), data type (VARCHAR, DATE, INTEGER, TEXT, etc), primary key boolean (<code>true</code> if column is primary key), not null boolean (<code>true</code> i column is not null), default value of column and length of the longest value in the column. Default value of column is pair of the value and <code>isNull</code> boolean.
		# @param rows Table data as list of rows. Each row is list of values for each column and each value is pair of the value as Tcl sees it and second is boolean indicating if it's <code>null</code> (<code>true</code>) or it's not <code>null</code>.
		# @param ddl Full DDL of table.
		# This method gets table columns and data and should convert them to format that is implemented by the plugin, then returned.
		# @return Data in export format, ready to write to file.
		#<
		abstract method exportTable {name columns ddl totalRows}
		abstract method exportTableRow {cellsData columns}
		abstract method exportTableEnd {name}

		#>
		# @method exportIndex
		# @param name Name of the index to export.
		# @param table Name of the table that index is created for.
		# @param columns Columns of the table that index is created for. Each column is sublist of 3 elements: column name, collation, sorting order. Collation can be <code>NOCASE</code>, <code>BINARY</code>, some custom one, or empty. Sorting order can be <code>ASC</code>, <code>DESC</code> or empty.
		# @param unique Boolean value indicating if index is of UNIQUE type.
		# @param ddl Full DDL of index.
		# This method gets index specification and should convert it to format that is implemented by the plugin, then returned.
		# @return Index specification in export format, ready to write to file.
		#<
		abstract method exportIndex {name table columns unique ddl}

		#>
		# @method exportTrigger
		# @param name Name of the trigger to export.
		# @param table Name of the table or view that trigger is invoked by.
		# @param when <code>BEFORE</code>, <code>AFTER</code>, or <code>INSTEAD OF</code>.
		# @param event <code>DELETE</code>, <code>INSERT</code>, <code>UPDATE</code>, or <code>UPDATE OF <i>columns-list</i></code>.
		# @param condition Condition for <code>WHEN</code> statement.
		# @param code Body of the trigger.
		# @param ddl Full DDL of trigger.
		# This method gets trigger specification and should convert it to format that is implemented by the plugin, then returned.
		# @return Trigger specification in export format, ready to write to file.
		#<
		abstract method exportTrigger {name table when event condition code ddl}

		#>
		# @method exportView
		# @param name Name of the view to export.
		# @param code Body of the view.
		# @param ddl Full DDL of view.
		# This method gets view specification and should convert it to format that is implemented by the plugin, then returned.
		# @return View specification in export format, ready to write to file.
		#<
		abstract method exportView {name code ddl}

		#>
		# @method getEncoding
		# This method should return encoding for writing export file from list of [encoding names], or "binary".
		# It's a good idea to let configure the encoding.
		#<
		abstract method getEncoding {}

		#>
		# @method databaseExportBegin
		# @param dbName Symbolic name as displayed in databases tree.
		# @param dbType Database type string, as displayed in databases tree in right from database name.
		# @param dbFile Full path to database file.
		# Called first when exporting whole database. Useful for adding some header informations.
		# Overloading this method is optional.
		# @return Header informations for database exporting.
		#<
		method databaseExportBegin {dbName dbType dbFile}

		#>
		# @method databaseExportEnd
		# Called last when exporting whole database. Useful for adding some suffix to database export.
		# Overloading this method is optional.
		# @return Additional data as suffix for database exporting.
		#<
		method databaseExportEnd {}

		#>
		# @method exportFileSchema
		# Overloading this method is optional.<br>
		# Schema string (the result of this method) can contain following markers:<br>
		# <u>For databases:</u>
		# <ul>
		# <li><code>%BEGIN%</code> - result of {@method databaseExportBegin}
		# <li><code>%TABLES%</code> - result of all calls to {@method exportTable}
		# <li><code>%INDEXES%</code> - result of all calls to {@method exportIndex}
		# <li><code>%TRIGGERS%</code> - result of all calls to {@method exportTrigger}
		# <li><code>%VIEWS%</code> - result of all calls to {@method exportView}
		# <li><code>%END%</code> - result of {@method databaseExportEnd}
		# <li><code>%DATABASE_NAME%</code> - name of the database
		# </ul>
		# <u>For tables:</u>
		# <ul>
		# <li><code>%TABLE%</code> - result of single call to {@method exportTable}
		# <li><code>%DATABASE_NAME%</code> - name of the database
		# <li><code>%TABLE_NAME%</code> - name of the table
		# </ul>
		# <u>For query results:</u>
		# <ul>
		# <li><code>%RESULT%</code> - result of single call to {@method exportResults}
		# </ul>
		# @return Full schema of exported file depending on context. See default implementation and standard plugins implementations for details.
		#<
		method exportFileSchema {context}

		#>
		# @method beforeStart
		# Called just before actual exporting routine starts - before any calls to export*.
		# Overwriting this method is optional, but can be useful for some initial setup.
		# By default the method should return true.
		# If the method returns false, than the exporting process is interrupted.
		#<
		method beforeStart {}
		
		#>
		# @method finished
		# Called just after the exporting routine is done - there will no more calls to export*.
		# It's still before the output file channel gets closed.
		# Overwriting this method is optional, but can be useful for some final instructions.
		#<
		method finished {}
		
		#>
		# @method afterExport
		# @param exportFile Name (with full path) of the file that export was done into.
		# Called after successful export. Implementation (which is optional) can do some cleanup stuff, or something.
		#<
		method afterExport {exportFile}
		
		#>
		# @method provideColumnWidths {}
		# Plugin should return boolean value:
		# </code>true</code> if the plugin expects column widths to be provided in columns parameter of {@method exportTable}
		# and {@method exportResults}. If <code>false</code> is returned, then all widths will be set to 0.
		# Note, that returning <code>true</code> has slight overhead for the application to collect the information.
		# Therefore default implementation returns <code>false</code> and plugin has to overwrite this method to change it.
		# @return </code>true</code> to provide column widths for the plugin.
		#<
		method provideColumnWidths {}

		#>
		# @method provideTotalRows {}
		# Plugin should return boolean value:
		# </code>true</code> if the plugin expects total number of rows to be provided in parameter of {@method exportTable}
		# and {@method exportResults}. If <code>false</code> is returned, then totalRows will be set to 0.
		# Note, that returning <code>true</code> has slight overhead for the application to collect the information.
		# Therefore default implementation returns <code>false</code> and plugin has to overwrite this method to change it.
		# @return </code>true</code> to provide column widths for the plugin.
		#<
		method provideTotalRows {}
		
		#>
		# @method manageFile
		# Plugin should return true if it wants to create file by itself. By default it returns false
		# and only file descriptor is deilvered to the plugin, so it can write data into the file.
		# Leaving file management to SQLiteStudio itself makes it simpler for developer, because he doesn't need to
		# care about file permissions, etc.
		# If the developer needs to control entire process of file creation, then he can return here true
		# and expect the {@method setFile} call with the path to file selected for exporting.
		# The developer needs to check permissions (and show errors) and overwrite the file.
		# @return Boolean value.
		#<
		method manageFile {}

		#>
		# @method setFile
		# It's called only if {@method manageFile} returns true (default is false).
		# It provides the path for file selected by user to export the data to.
		# If this method returns false, then the exporting process is interrupted.
		#<
		method setFile {path}
		
		#>
		# @method autoFileExtension
		# This method can return the file extension (like ".txt"), so the SQLiteStudio will take care
		# that exported file fill have that extension in case user did not specify any extension for the file.
		# This will make effect only if {@method manageFile} returns false (as in default).
		# Returning empty string means that no auto extesion will be applied.
		# @return File extension or empty string.
		#<
		method autoFileExtension {}
		
		#>
		# @method useFile
		# Return false to disable the file entry for the plugin. Returning false also means that the plugin
		# will take of delivering data to the export media.
		# @return Boolean value.
		#<
		proc useFile {}

		method setDb {db}
		method getDb {}
		method setContext {context}
		method setFileDescriptor {fd}
		method write {data}
	}
}


body ExportPlugin::init {} {
	set handlers [lsort -command Plugin::sortCmd [findClassesBySuperclass "::ExportPlugin"]]
}

body ExportPlugin::exportFileSchema {context} {
	switch -- $context {
		"DATABASE" {
			return "%BEGIN%%TABLES%%INDEXES%%TRIGGERS%%VIEWS%%END%"
		}
		"TABLE" {
			return "%TABLE%"
		}
		"QUERY" {
			return "%RESULT%"
		}
	}
}

body ExportPlugin::autoFileExtension {} {
	return ""
}

body ExportPlugin::databaseExportBegin {dbName dbType dbFile} {
	return ""
}

body ExportPlugin::databaseExportEnd {} {
	return ""
}

body ExportPlugin::afterExport {exportFile} {
}

body ExportPlugin::setContext {context} {
	set _context $context
}

body ExportPlugin::setDb {db} {
	set _db $db
}

body ExportPlugin::getDb {} {
	return $_db
}

body ExportPlugin::setFileDescriptor {fd} {
	set _fd $fd
}

body ExportPlugin::write {data} {
	puts -nonewline $_fd $data
}

body ExportPlugin::beforeStart {} {
	return true
}

body ExportPlugin::finished {} {
}

body ExportPlugin::provideColumnWidths {} {
	return false
}

body ExportPlugin::provideTotalRows {} {
	return false
}

body ExportPlugin::configSize {} {
	return ""
}

body ExportPlugin::manageFile {} {
	return false
}

body ExportPlugin::setFile {path} {
	return true
}

body ExportPlugin::useFile {} {
	return true
}
