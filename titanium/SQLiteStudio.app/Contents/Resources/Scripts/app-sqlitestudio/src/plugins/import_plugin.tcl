use src/plugins/plugin.tcl
use src/common/common.tcl

#>
# @class ImportPlugin
# Base class for all importing plugins.
#<
abstract class ImportPlugin {
	inherit Plugin

	constructor {} {}
	destructor {}

	#>
	# @var handlers
	# Keeps list of installed import plugin classes.
	#<
	common handlers [list]

	private {
		variable _interrupted 0
		variable _dbNullValue ""
	
		method failedAsk {msg totRows}
		method validationFailedAsk {msg}
		method buildInsert {wrappedTable vars vals}
	}

	protected {
		#>
		# @method openDataSource
		# The method is called at the begining of importing process, so the plugin can setup its data source.
		#<
		abstract method openDataSource {}
		
		#>
		# @method getColumnList
		# This method should return list of columns that are expected from import source.
		# Each column has to be 2-element list of column name and SQLite data type.
		# In case of importing to existing table only the number of columns is checked
		# to be equal to number of columns in the table.
		# In case of importing conjucted with creating new table column names and data types
		# are used to create the table.
		# @return List of columns with data types.
		#<
		abstract method getColumnList {}
		
		#>
		# @method getNextDataRow
		# This method has to return list of values imported from data source for a single table row,
		# therefore the number of values in list has to be equal to number of columns returned from {@method getColumnList}.
		# Each value is a pair of actual value and boolean indicating whether the value is meant to be NULL.
		# If the NULL indicator is true, then any value placed as the first in the value pair is ignored.
		# Values should already be encoded with utf-8 encoding. It's up to the plugin to take care of it.
		# Returning empty list means, that there is no more data and the import is about to be finished.
		# @return List of pairs (the value and null indicator) or empty list.
		#<
		abstract method getNextDataRow {}

		##
		# @method closeDataSource
		# Closes data source. Needs to be defined in derived class. It will be called just before destructor.
		abstract method closeDataSource {}
	}

	public {
		#>
		# @method init
		# Initializes list of handlers. They should be already loaded by interpreter, this method just find their classes
		# and places them in {@var handlers} variable.
		#<
		proc init {}

		method import {db table tableMode}
		method interrupt {}
		method cancelExecution {}

		#>
		# @method getName
		# @return Name of formatter to display on interface.
		#<
		abstract proc getName {}

		#>
		# @method configurable
		# This method is used to determinate if import engine supports any configuration.
		# @return Boolean value defining if implemented import engine supports and requires configuration. If <code>true</code>, then methods {@method createConfigUI} and {@method applyConfig} should be implemented.
		#<
		abstract proc configurable {}

		#>
		# @method createConfigUI
		# @param path Tk widget path to frame where configuration should be placed.
		# Implementation should create configuration widget in frame pointed by given path.
		# Can do nothing if {@method configurable} returns <code>false</code>.
		#<
		abstract method createConfigUI {path}

		#>
		# @method applyConfig
		# @param path Tk widget path to frame where configuration is placed.
		# Implementation should extract necessary informations from configuration widget and store it in local variables,
		# so they can be used later by other methods.<br>
		# Configuration widget in path will be destroyed just after this method call is completed.
		# Can do nothing if {@method configurable} returns <code>false</code>.
		#<
		abstract method applyConfig {path}

		#>
		# @method validateConfig
		# It's called just before any import action is taken. It allows to validate if all configured parameters (if any) are valid for importing.
		# If there is any invalid parameter, then this method should call <code>error</code> command - it will be caught and displayed in error dialog.
		#<
		abstract method validateConfig {}
	}
}

body ImportPlugin::init {} {
	set handlers [lsort -command Plugin::sortCmd [findClassesBySuperclass "::ImportPlugin"]]
}

body ImportPlugin::import {db table tableMode} {
	set _interrupted 0

	if {$tableMode == "existing"} {
		set tableCols [$db getTableInfo $table]
	}
	
	set dialect [$db getDialect]
	set wrappedTable [wrapObjName $table $dialect]

	# Open datasource
	if {[catch {$this openDataSource} err]} {
		cutOffStdTclErr err
		Error [mc "Error from importing plugin:\n%s" $err]
		return 1
	}

	# Get column list from datasource
	if {[catch {$this getColumnList} colList]} {
		cutOffStdTclErr colList
		Error [mc "Error from importing plugin:\n%s" $colList]
		return 1
	}
	set totalCols [llength $colList]

	# Validate column numbers
	if {$tableMode == "existing"} {
		if {$totalCols < [llength $tableCols]} {
			set code [validationFailedAsk [mc {Number of columns in target table '%s' is less than number of columns in data to import. What would you like to do?} $table]]
			if {$code != ""} {
				eval $code
			}
		} elseif {$totalCols < [llength $tableCols]} {
			set code [validationFailedAsk [mc {Number of columns in target table '%s' is greater than number of columns in data to import. What would you like to do?} $table]]
			if {$code != ""} {
				eval $code
			}
		}
	} else {
		# For "new" mode we need to create column
		set colsToCreate [list]
		
		foreach col $colList {
			lassign $col name type
			lappend colsToCreate "[wrapObjName $name $dialect] $type"
		}
		set cols [join $colsToCreate ", "]

		if {[catch {
			$db eval "CREATE TABLE $wrappedTable ($cols);"
		} err]} {
			cutOffStdTclErr err
			Error [mc "Error creating table '%s':\n%s\n\nImporting aborted." $table $err]
			return 1
		}
	}
	
	# Preparing variables for common INSERT statement
	set valueVars [list]
	for {set i 0} {$i < $totalCols} {incr i} {
		lappend valueVars "\$val_$i"
	}

	# Start transaction
	if {[catch {
		$db begin
	} err]} {
		cutOffStdTclErr err
		Error [mc "Error trying to import data to '%s':\n%s\n\nImporting aborted." $table $err]
		return 1
	}

	# Progress dialog
	set progress [BusyDialog::show [mc {Importing...}] [mc {Importing to table '%s'.} $table] true 50 false]
	BusyDialog::autoProgress 20
	$progress configure -onclose [list $this cancelExecution]
	$progress setCloseButtonLabel [mc {Cancel}]

	# Go through all rows
	set rowNum 1
	while {!$_interrupted} {
		if {[catch {$this getNextDataRow} dataSet]} {
			cutOffStdTclErr dataSet
			set code [failedAsk [mc "Importing plugin raised error when asked for data row number %s. Error details:\n%s.\n\nWhat would you like to do?" $rowNum $dataSet] [expr {$rowNum - 1}]]
			if {$code != ""} {
				eval $code
			}
		}
		if {[llength $dataSet] == 0} {
			# Finished
			break
		}
	
		#
		# Validate number of columns in row
		#
		if {[llength $dataSet] != $totalCols} {
			set code [failedAsk [mc {Number of columns in data row number %s is different than number of columns declared by importing plugin. What would you like to do?} $rowNum] [expr {$rowNum - 1}]]
			if {$code != ""} {
				eval $code
			}
		}

		# Prepare value variables
		set sql [buildInsert $wrappedTable $valueVars $dataSet]
		set i 0
		foreach value $dataSet {
			set val_$i [lindex $value 0]
			incr i
		}

		# Try to insert data
		if {[catch {
			$db eval $sql
		} err]} {
			cutOffStdTclErr err
			set code [failedAsk [mc "Problem occured while importing row number %s:\n%s\n\nWhat would you like to do?" $rowNum $err] [expr {$rowNum - 1}]]
			if {$code != ""} {
				eval $code
			}
		}

		incr rowNum
	}

	# Close datasource
	if {[catch {$this closeDataSource} err]} {
		debug $err
	}

	BusyDialog::hide

	# Process was interrupted?
	if {$_interrupted} {
		if {[catch {
			$db rollback
		} err]} {
			debug $err
			return 1
		}
	}

	# Process finished
	if {[catch {
		$db commit
	} err]} {
		cutOffStdTclErr err
		Error [mc "Error trying to import data to '%s':\n%s\n\nImporting aborted." $table $err]
		catch {$db rollback}
		return 1
	}
	Info [mc {Importing finished.}]

	return 0
}

body ImportPlugin::buildInsert {wrappedTable vars vals} {
	set newVarList [list]
	foreach var $vars val $vals {
		if {[lindex $val 1]} {
			lappend newVarList "null"
		} else {
			lappend newVarList $var
		}
	}
	return "INSERT INTO $wrappedTable VALUES ([join $newVarList {, }]);"
}

body ImportPlugin::failedAsk {msg totRows} {
	YesNoDialog .importProblem -title [mc {Import problem}] -wrapping true -wrapratio 8 \
		-message $msg -first [mc {Skip this data row}] -second [mc {Keep data rows imported so far (%s) and abort} $totRows] \
		-fourth [mc {Rollback data rows imported so far and abort}] -type error -secondicon img_ok -fourthicon img_cancel

	switch -- [.importProblem exec] {
		1 {
			# Skip row
			return {
				continue
			}
		}
		0 {
			# Keep data and abort
			return {
				if {[catch {$this closeDataSource} err]} {
					debug $err
				}
				catch {$db commit}
				BusyDialog::hide
				return 1
			}
		}
		-1 {
			# Rollback data and abort
			return {
				if {[catch {$this closeDataSource} err]} {
					debug $err
				}
				catch {$db rollback}
				BusyDialog::hide
				return 1
			}
		}
	}
	return {}
}

body ImportPlugin::validationFailedAsk {msg} {
	YesNoDialog .importProblem -title [mc {Import problem}] -wrapping true -message $msg \
		-first [mc {Ignore it and proceed}] -second [mc {Abort}] -type warning

	if {![.importProblem exec]} {
		return {
			if {[catch {$this closeDataSource} err]} {
				debug $err
			}
			BusyDialog::hide
			return 1
		}
	}
	return {}
}

body ImportPlugin::interrupt {} {
	set _interrupted 1
}

body ImportPlugin::cancelExecution {} {
	interrupt
}
