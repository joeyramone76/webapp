class UniversalLexer {
	constructor {{db ""}} {}
	destructor {}

	private {
		variable _db ""
		variable _dialect ""
		variable _lexer

		method getLexer {}
		method getDialect {}
	}

	public {
		#
		# Configuration options
		#
		variable sameThread true

		#
		# Public API
		#
		method tokenize {sql}
		method getLastTokenPartialValueFromSql {sql index}
		method setDb {db}
		method setDialect {dialect}

		proc tokenizeStatic {sql {db ""}}
		proc tokenizeStaticOnThread {sql {db ""}}
	}
}

body UniversalLexer::constructor {{db ""}} {
	set _db $db
	array set _lexer {}
}

body UniversalLexer::destructor {} {
	foreach dialect [array names _lexer] {
		delete object $_lexer($dialect)
	}
}

body UniversalLexer::setDb {db} {
	set _db $db
}

body UniversalLexer::setDialect {dialect} {
	set _dialect $dialect
}

body UniversalLexer::getDialect {} {
	set dialect "sqlite3"
	if {$_db != ""} {
		set dialect [$_db getDialect]
	} elseif {$_dialect != ""} {
		set dialect $_dialect
	}
	return $dialect
}

body UniversalLexer::getLexer {} {
	set dialect [getDialect]
	if {![info exists _lexer($dialect)]} {
		switch -- $dialect {
			"sqlite2" {
				set _lexer(sqlite2) [Lexer2 ::#auto]
			}
			"sqlite3" {
				set _lexer(sqlite3) [Lexer3 ::#auto]
			}
		}
	}
	return $_lexer($dialect)
}

body UniversalLexer::getLastTokenPartialValueFromSql {sql index} {
	if {$sameThread} {
		set lexer [getLexer]
		return [$lexer getLastTokenPartialValueFromSql $sql $index]
	} else {
		set dialect [getDialect]
		set id [tpool::post $::PARSER_POOL [list lexer $dialect getLastTokenPartialValueFromSql $sql $index]]
		tpool::wait $::PARSER_POOL $id
		return [tpool::get $::PARSER_POOL $id]
	}
}

body UniversalLexer::tokenize {sql} {
	if {$sameThread} {
		set lexer [getLexer]
		return [$lexer tokenizeSql $sql]
	} else {
		set dialect [getDialect]
		set id [tpool::post $::PARSER_POOL [list lexer $dialect tokenizeSql $sql]]
		tpool::wait $::PARSER_POOL $id
		return [tpool::get $::PARSER_POOL $id]
	}
}

body UniversalLexer::tokenizeStatic {sql {db ""}} {
	set lexer [UniversalLexer ::#auto $db]
	$lexer configure -sameThread true
	set tokens [$lexer tokenize $sql]
	delete object $lexer
	return $tokens
}

body UniversalLexer::tokenizeStaticOnThread {sql {db ""}} {
	set lexer [UniversalLexer ::#auto $db]
	$lexer configure -sameThread false
	set tokens [$lexer tokenize $sql]
	delete object $lexer
	return $tokens
}
