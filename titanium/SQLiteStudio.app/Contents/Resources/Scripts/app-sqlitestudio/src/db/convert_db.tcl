package require sqlite 2.0
rename sqlite sqlite2
package require sqlite3

proc convertDb {fromFile toFile toVersion unsupported} {
	set results [dict create returnCode 0 errors [list]]
	
	switch -- $toVersion {
		2 {
			sqlite3 fromDb $fromFile
			sqlite2 toDb $toFile
			set fromDialect "sqlite3"
			set toDialect "sqlite2"

			# As long as sqlite3 supports this, we need to make sure we operate on short names.
			fromDb eval {PRAGMA full_column_names = 0; PRAGMA short_column_names = 1;}
		}
		3 {
			sqlite2 fromDb $fromFile
			sqlite3 toDb $toFile
			set fromDialect "sqlite2"
			set toDialect "sqlite3"
		}
		default {
			error "Unsupported version: $toVersion"
		}
	}
	
	toDb eval {BEGIN}

	set err 0
	set tablesToCopy [list]

	# Copying table DDLs
	fromDb eval {SELECT name, sql FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'} R {
		set sql $R(sql)
		if {[string match "*PRIMARY*KEY*AUTOINCREMENT*" $sql] && "AUTOINCREMENT" in $unsupported} {
			regsub -all -- {\s*AUTOINCREMENT\s*} $sql " " newSql
			set sql $newSql
		}
		if {[string match "*COLLATE*" $sql] && "COLLATE" in $unsupported} {
			regsub -all -- {\s*COLLATE\s+\S+\s*} $sql " " newSql
			set sql $newSql
		}
		if {[regexp -- {\s*DEFAULT\s*\([^\)]*\)} $sql] && "EXPR_DEFAULT" in $unsupported} {
			# First do it for numbers
			regsub -all -- "(\\s*DEFAULT\\s*)\\(\\s*($::RE(sql_number))\\s*\\)" $sql {\1 \2} newSql
			set sql $newSql

			# Then do it for sql functions
			regsub -all -- "(?x) (\\s*DEFAULT\\s*)\\(\\s*($::RE(function))\\s*\\)" $sql {\1 '\2'} newSql
			set sql $newSql

			# Then do it for rest of values
			regsub -all -- {(\s*DEFAULT\s*)\(([^\)]*)\)} $sql {\1 '\2'} newSql
			set sql $newSql
		}
		if {[catch {toDb eval $sql} res]} {
			cutOffStdTclErr res
			debug "$res, at:\n$sql"
			dict lappend results errors "(CREATE TABLE $R(name)): $res"
			dict set results returnCode 1
		} else {
			lappend tablesToCopy $R(name)
		}
	}

	# Copying tables data
	foreach table $tablesToCopy {
		catch {array unset R}
		fromDb eval "SELECT * FROM [wrapObjName $table $fromDialect]" R {
			set cols [join [wrapColNames $R(*) $toDialect] ","]
			set vals [list]
			foreach col $R(*) {
				lappend vals "'[escapeSqlString $R($col)]'"
			}
			set vals [join $vals ","]
			set err 0
			if {[catch {toDb eval "INSERT INTO [wrapObjName $table $toDialect] ($cols) VALUES ($vals)"} res]} {
				cutOffStdTclErr res
				debug "$res, at:\nINSERT INTO [wrapObjName $table $toDialect] ($cols) VALUES ($vals)"
				dict lappend results errors "(INSERT INTO $table): $res"
				dict set results returnCode 1
			}
		}
	}

	# Rest objects DDL
	catch {array unset R}
	fromDb eval {SELECT name, type, sql FROM sqlite_master WHERE type <> 'table' AND name NOT LIKE 'sqlite_%'} R {
		set sql $R(sql)
		if {[string trim $sql] == ""} continue
		switch -- $R(type) {
			"index" {
				if {[string match "*COLLATE*" $R(sql)] && "INDEX_COLLATE" in $unsupported} {
					regsub -all -- {\s*COLLATE\s+\S+\s*} $sql " " newSql
					set sql $newSql
				}
			}
		}
		set err 0
		if {[catch {toDb eval $sql} res]} {
			cutOffStdTclErr res
			debug "$res, at:\n$sql"
			dict lappend results errors "(CREATE [string toupper $R(type)] $R(name)): $res"
			dict set results returnCode 1
		}
	}

	# Done
	toDb eval {COMMIT}
	return $results
}
