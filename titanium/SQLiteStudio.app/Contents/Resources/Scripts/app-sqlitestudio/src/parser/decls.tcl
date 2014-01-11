use src/keywords.tcl

namespace eval sqlite3 {
	variable statementSyntax
	variable KEYWORDS
	variable RESERVED_KEYWORDS
	variable NOT_RESERVED_KEYWORDS

	set KEYWORDS [list]
	set RESERVED_KEYWORDS [list]
	set NOT_RESERVED_KEYWORDS [list]
	foreach {kw type} $::PARSABLE_KEYWORDS_SQLite3 {
		lappend KEYWORDS $kw
		if {$type} {
			lappend RESERVED_KEYWORDS $kw
		} else {
			lappend NOT_RESERVED_KEYWORDS $kw
		}
	}
}

namespace eval sqlite2 {
	variable statementSyntax
	variable KEYWORDS
	variable RESERVED_KEYWORDS
	variable NOT_RESERVED_KEYWORDS

	set KEYWORDS [list]
	set RESERVED_KEYWORDS [list]
	set NOT_RESERVED_KEYWORDS [list]
	foreach {kw type} $::PARSABLE_KEYWORDS_SQLite2 {
		lappend KEYWORDS $kw
		if {$type} {
			lappend RESERVED_KEYWORDS $kw
		} else {
			lappend NOT_RESERVED_KEYWORDS $kw
		}
	}
}
