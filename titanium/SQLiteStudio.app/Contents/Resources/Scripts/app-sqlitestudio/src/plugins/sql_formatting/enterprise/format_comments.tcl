use src/plugins/sql_formatting/enterprise/format_s.tcl

class FormatComments {
	inherit FormatStatement

	protected {
		method handleMultilineComment {contents}
	}

	public {
		method formatComments {}
	}
}

body FormatComments::formatComments {} {
	set expandOneline [cfg com_expand_one_line]
	set indentMultiline [cfg com_indent_multiline]
	set starIndent [cfg com_star_indent_multiline]

	set allTokens [$_statement cget -allTokens]
	set comments [list]
	foreach token $allTokens {
		if {[lindex $token 0] == "COMMENT"} {
			set contents [lindex $token 1]
			
			switch -glob -- $contents {
				"--*" {
					# -- ... case
					# No change here for now.
				}
				default {
					# /* ... */ case
					set contents [handleMultilineComment $contents]
				}
			}

			lappend comments $contents
		}
	}
	return [join $comments "\n"]
}

body FormatComments::handleMultilineComment {contents} {
	upvar expandOneline expandOneline indentMultiline indentMultiline starIndent starIndent

	set contents [lindex [regexp -inline -- {^\/\*(.*)\*\/$} $contents] 1]
	set lines [split [string trim $contents] "\n"]

	if {[llength $lines] > 1} {
		set processed [list]
		lappend processed "/*"
		foreach line $lines {
			if {[regexp -- {^\s\*\s*.*} $line]} {
				set line [lindex [regexp -- {^\s\*\s*(.*)} $line] 1]
			}
			if {$indentMultiline} {
				if {$starIndent} {
					set line " * $line"
				} else {
					incrIndent
					set line "[indent]$line"
					decrIndent
				}
			} elseif {$starIndent} {
				set line "* $line"
			}
			lappend processed $line
		}
		if {$indentMultiline && $starIndent} {
			lappend processed " */"
		} else {
			lappend processed "*/"
		}
		set contents [join $processed "\n"]
	} else {
		set line [lindex $lines 0]
		if {$expandOneline} {
			if {$indentMultiline} {
				if {$starIndent} {
					set contents "/*\n * $line\n */"
				} else {
					incrIndent
					set contents "/*\n[indent]$line\n*/"
					decrIndent
				}
			} elseif {$starIndent} {
				set contents "/*\n* $line\n*/"
			} else {
				set contents "/*\n$line\n*/"
			}
		} else {
			set contents "/* [string trim $line] */"
		}
	}

	return $contents
}
