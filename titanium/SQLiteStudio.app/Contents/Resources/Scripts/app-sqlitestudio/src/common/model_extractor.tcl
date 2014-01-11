class ModelExtractor {
	constructor {} {}
	destructor {}

	private {
		variable _parser ""
	}

	protected {
		method getModel {db name typeForMsg}
	}

	public {
		proc getObjectDdl {db name}
		proc getDdlForSystemTable {name}
		proc isSupportedSystemTable {name}
		proc hasDdl {db objectName}
		proc getDdl {db objectName}

		##
		# @method getModelForEditDialog
		# If object has no DDL, then standard error is thrown,
		# if the DDL cannot be parsed, then error with code=5 is thrown.
		proc getModelForEditDialog {db name typeForMsg parser}
	}
}

body ModelExtractor::constructor {} {
}

body ModelExtractor::destructor {} {
	if {$_parser != ""} {
		delete object $_parser
	}
}

body ModelExtractor::hasDdl {db objectName} {
	set objectName [string tolower $objectName]
	set ddl [$db onecolumn {SELECT sql FROM sqlite_master WHERE lower(name) = $objectName}]
	expr {$ddl != "" && ![$db isNull $ddl]}
}

body ModelExtractor::getObjectDdl {db name} {
	set name [string tolower $name]
	set ddl [$db onecolumn "SELECT sql FROM sqlite_master WHERE lower(name) = '$name'"]
	if {$ddl == "" || [$db isNull $ddl]} {
		# Bugfix for detecting DDL of objects with unicode characters,
		# reported at http://forum.sqlitestudio.pl/viewtopic.php?f=19&t=99&p=424
		$db eval {SELECT lower(name) AS name, sql FROM sqlite_master} row {
			puts "$row(name) eq $name -> [string equal $row(name) $name]"
			if {[string equal $row(name) $name]} {
				set ddl $row(sql)
				break
			}
		}
		if {$ddl == "" || [$db isNull $ddl]} {
			error "No DDL for object $name while trying to edit it. Please report this!"
		}
	}
	return $ddl
}

body ModelExtractor::getDdl {db objectName} {
	if {[isSupportedSystemTable $objectName]} {
		set ddl [getDdlForSystemTable $objectName]
	} else {
		set ddl [getObjectDdl $db $objectName]
	}
	return $ddl
}

body ModelExtractor::getModelForEditDialog {db name typeForMsg parser} {
	if {[isSupportedSystemTable $name]} {
		set ddl [getDdlForSystemTable $name]
	} else {
		set ddl [getObjectDdl $db $name]
	}

	# Parse DDL
	$parser configure -expectedTokenParsing false
	$parser parseSql $ddl
	set results [$parser get]

	# Error handling
	if {[dict get $results returnCode]} {
		debug "[string totitle $typeForMsg] parsing error message: [dict get $results errorMessage]"
		error [format "Cannot parse objects DDL.\nSQLite version is %s.\nThe DDL is:\n%s\n\nError stack:" [$db onecolumn {SELECT sqlite_version()}] $ddl] "" 5 ;# 5 is some custom errorcode, different than 1
	}

	# Open dialog
	return [[dict get $results object] getValue subStatement]
}

body ModelExtractor::getModel {db name typeForMsg} {
	if {$_parser == ""} {
		set _parser [UniversalParser ::#auto $db]
		$_parser configure -sameThread true
	}
	set model [getModelForEditDialog $db $name $typeForMsg $_parser]
	return $model
}

body ModelExtractor::isSupportedSystemTable {name} {
	expr {$name in [list "sqlite_master" "sqlite_temp_master"]}
}

body ModelExtractor::getDdlForSystemTable {name} {
	switch -- $name {
		"sqlite_master" {
			return {CREATE TABLE sqlite_master (type, name, tbl_name, rootpage, sql)}
		}
		"sqlite_temp_master" {
			return {CREATE TABLE sqlite_master (type, name, tbl_name, rootpage, sql)}
		}
		default {
			error "Unsupported system table for getting DDL: $name"
		}
	}
}
