class UniversalParser {
	constructor {{db ""}} {}
	destructor {}

	private {
		variable _objects [list]
		variable _db ""
		variable _parser
		variable _parsedDict ""
		variable _expectedDict ""

		method parseOnThread {method args}
		method parse {contents tokens {idx 0}}
	}

	public {
		#
		# Configuration options
		#
		variable stdParsing true
		variable expectedTokenParsing true
		variable tolerateLacksForStdParsing false
		variable sameThread true

		#
		# Public API
		#
		method freeObjects {}
		method parseSql {sql {idx 0}}
		method parseTokens {tokens {idx 0}}
		method setDb {db}
		method get {}
		method getExpected {}

		#>
		# @method parseForErrorChecking {contents db index}
		# This is static method used by SQLEditor for marking errors.
		# It's called from error checking thread to parse sql,
		# then error processing is continued in error checking thread.
		#<
		proc parseForErrorChecking {contents db index}
	}
}

body UniversalParser::constructor {{db ""}} {
	set _db $db
	array set _parser {}
}

body UniversalParser::destructor {} {
	freeObjects
}

body UniversalParser::setDb {db} {
	set _db $db
}

body UniversalParser::freeObjects {} {
	if {[llength $_objects] > 0} {
		delete object {*}$_objects
		set _objects [list]
	}

	foreach dialect [array names _parser] {
		delete object $_parser($dialect)
	}
	array unset _parser
	array set _parser {}

	set _parsedDict ""
	set _expectedDict ""
}

body UniversalParser::get {} {
	return $_parsedDict
}

body UniversalParser::getExpected {} {
	return $_expectedDict
}

body UniversalParser::parseSql {sql {idx 0}} {
	if {$sameThread} {
		set results [parse $sql "" $idx]
	} else {
		set results [parseOnThread parseSqlContents $sql $_db $idx $stdParsing $expectedTokenParsing $tolerateLacksForStdParsing]
	}
	lassign $results _parsedDict _expectedDict
	return $results
}

body UniversalParser::parseTokens {tokens {idx 0}} {
	if {$sameThread} {
		set results [parse "" $tokens $idx]
	} else {
		set results [parseOnThread parseSqlTokens $tokens $_db $idx $stdParsing $expectedTokenParsing $tolerateLacksForStdParsing]
	}
	lassign $results _parsedDict _expectedDict
	return $results
}

body UniversalParser::parseOnThread {method args} {
	# Parse in separate thread
	set id [tpool::post $::PARSER_POOL [list $method {*}$args]]
	tpool::wait $::PARSER_POOL $id
	lassign [tpool::get $::PARSER_POOL $id] parsedDict expectedDict

	# Deserialize parseDict
	set results [list]
	if {$parsedDict != "" && [dict exists $parsedDict object]} {
		set obj [dict get $parsedDict object]
		set deserialized [Serializable::deserialize $obj]
		lappend _objects {*}[dict get $deserialized objects]

		dict set parsedDict object [dict get $deserialized object]
		lappend results $parsedDict
	} else {
		lappend results ""
	}

	# Deserialize expectedDict
	lappend results $expectedDict

	return $results
}

body UniversalParser::parseForErrorChecking {contents db index} {
	set parser [UniversalParser ::#auto $db]
	$parser configure -expectedTokenParsing false
	lassign [$parser parseSql $contents $index] parsedDict expectedDict
	delete object $parser
	return $parsedDict
}

body UniversalParser::parse {contents tokens {idx 0}} {
	# Determinating parser
	set dialect "sqlite3"
	if {$_db != ""} {
		set dialect [$_db getDialect]
	}
	if {![info exists _parser($dialect)]} {
		switch -- $dialect {
			"sqlite2" {
				set _parser(sqlite2) [SqlParser2 ::#auto]
			}
			"sqlite3" {
				set _parser(sqlite3) [SqlParser3 ::#auto]
			}
		}
	}
	set parser $_parser($dialect)

	# Parse SQL with full parsing (but also with lacks tolerantion),
	# then parse for expected tokens
	if {$tokens != ""} {
		if {$stdParsing} {
			$parser setLacksTolerantion $tolerateLacksForStdParsing
			set parsedDict [$parser parseTokens $tokens $idx]
		} else {
			set parsedDict ""
		}
		if {$expectedTokenParsing} {
			$parser setLacksTolerantion true
			set expectedDict [$parser checkForExpectedTokensInTokens $tokens $idx]
		} else {
			set expectedDict ""
		}
	} else {
		if {$stdParsing} {
			$parser setLacksTolerantion $tolerateLacksForStdParsing
			set parsedDict [$parser parse $contents $idx]
		} else {
			set parsedDict ""
		}
		if {$expectedTokenParsing} {
			$parser setLacksTolerantion true
			set expectedDict [$parser checkForExpectedTokens $contents $idx]
		} else {
			set expectedDict ""
		}
	}

	if {$stdParsing} {
		# Extracting toplevel statement object
		set obj [dict get $parsedDict object]

		# Resolving all informations that requires db object
		if {$_db != ""} {
			$obj setBaseDatabase $_db
			$obj callAfterParsing
		}

		# Show statements tree if debug is enabled
		if {$::DEBUG(parser_tree)} {
			$obj debugInTree
		}
	}
	
	if {$::DEBUG(parser)} {
		puts "Parsed dict: $parsedDict"
	}

	return [list $parsedDict $expectedDict]
}
