class Formatter {
	common formatter ""

	public {
		proc format {txt {db ""}}
	}
}

body Formatter::format {txt {db ""}} {
	if {$formatter == ""} {
		catch {array unset hndClass}
		array set hndClass {}
		foreach hnd $SqlFormattingPlugin::handlers {
			set name [${hnd}::getName]
			set hndClass($name) $hnd
		}
		set defHnd ${SqlFormattingPlugin::defaultHandler}
		if {![info exists hndClass($defHnd)] && $SqlFormattingPlugin::handlers != ""} {
			set defHnd [[lindex $SqlFormattingPlugin::handlers 0]::getName]
			set SqlFormattingPlugin::defaultHandler $defHnd
		}
		set formatter [$hndClass($defHnd) ::#auto]
	}

	# Removing comments. Formating would break by comments.
	#set txt [SqlUtils::removeComments $txt]

	# Tokenize and format
	set tokenizedQuery [SqlUtils::stringTokenize $txt]
	set txt [$formatter formatSql $tokenizedQuery $txt $db]
	return $txt
}
