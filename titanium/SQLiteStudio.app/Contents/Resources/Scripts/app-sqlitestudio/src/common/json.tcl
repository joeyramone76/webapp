#>
# @class Json
# JSON writer (and parser in some future).
# Written from scratch, because the one in tcllib doesn't work with streamed data.
#<
class Json {
	constructor {} {}
	destructor {}

	private {
		common _quotes [list "\"" "\\\"" / \\/ \\ \\\\ \b \\b \f \\f \n \\n \r \\r \t \\t]

		variable _indent 0
		variable _contextStack "" ;# ARRAY/OBJECT
		variable _context ""
		variable _itemCounter ""
		variable _counterStack ""
		variable _objectKeyMaxLength ""
		variable _objectKeyLengthStack ""

		method indent {}
		method indentObjectValue {value}
		method incrIndent {}
		method decrIndent {}
		method wrapValue {value}
		method wrapString {value}
		method beginBlock {char context objectKey}
		method endBlock {char}
		method nextValue {}
		method alignKey {key}
		method objectKeysForAlignment {keys}
	}

	public {
		variable indent 0
		variable align 0

		method addValue {value {objValue ""}}
		method beginArray {}
		method beginArrayForKey {key}
		method endArray {}
		method beginObject {{keys ""}}
		method beginObjectForKey {key {keys ""}}
		method endObject {}
	}
}

body Json::constructor {} {
	set _contextStack [Stack ::#auto]
	set _counterStack [Stack ::#auto]
	set _objectKeyLengthStack [Stack ::#auto]
}

body Json::destructor {} {
	delete object $_contextStack
	delete object $_counterStack
	delete object $_objectKeyLengthStack
}

body Json::indent {} {
	if {$indent} {
		string repeat { } $_indent
	} else {
		return ""
	}
}

body Json::incrIndent {} {
	incr _indent 4
}

body Json::decrIndent {} {
	incr _indent -4
}

body Json::indentObjectValue {value} {
	if {[string first "\n" $value] == -1} {
		return $value
	}
	set lines [split $value \n]
	set outLines [list [lindex $sp 0]]
	set indent "[indent][pad $_objectKeyMaxLength { } {}]   "
	foreach line $lines {
		lappend outLines "$indent$line"
	}
	join $outLines \n
}

body Json::wrapString {value} {
	return "\"[string map $_quotes $value]\""
}

body Json::wrapValue {value} {
	if {[string trim $value] != "" && [string is double $value]} {
		string map $_quotes $value
	} else {
		wrapString $value
	}
}

body Json::nextValue {} {
	set result ""
	if {$_itemCounter > 0} {
		append result ","
	}
	if {$indent && $_indent > 0} {
		append result "\n[indent]"
	}
	return $result
}

body Json::addValue {value {objValue ""}} {
	if {$_context == ""} {
		error "Cannot add objects to JSON when not in any context. (tried to add '$value')"
	}
	if {$_context == "FINISHED"} {
		error "Cannot add another root element."
	}

	set result [nextValue]
	switch -- $_context {
		"ARRAY" {
			append result [wrapValue $value]
		}
		"OBJECT" {
			set value [wrapString $value]
			set objValue [wrapValue $objValue]
			if {$indent} {
				append result "[alignKey $value] : [indentObjectValue $objValue]"
			} else {
				append result "$value:$objValue"
			}
		}
	}
	incr _itemCounter

	return $result
}

body Json::beginArray {} {
	beginBlock "\[" "ARRAY" ""
}

body Json::beginArrayForKey {key} {
	beginBlock "\[" "ARRAY" $key
}

body Json::endArray {} {
	endBlock "\]"
}

body Json::beginObject {{keys ""}} {
	set result [beginBlock "\{" "OBJECT" ""]
	if {$indent} {
		objectKeysForAlignment $keys
	}
	return $result
}

body Json::beginObjectForKey {key {keys ""}} {
	set result [beginBlock "\{" "OBJECT" $key]
	if {$indent} {
		objectKeysForAlignment $keys
	}
	return $result
}

body Json::endObject {} {
	set result [endBlock "\}"]
	if {$indent} {
		set _objectKeyMaxLength [$_objectKeyLengthStack pop]
	}
	return $result
}

body Json::beginBlock {char context objectKey} {
	if {$_context == "FINISHED"} {
		error "Cannot add another root element."
	}
	set result [nextValue]
	if {$_context == "OBJECT"} {
		set key [wrapString $objectKey]
		if {$indent} {
			append result "[alignKey $key] : "
		} else {
			append result "${key}:"
		}
	}
	append result "$char"

	$_counterStack push $_itemCounter
	$_contextStack push $_context
	set _itemCounter 0
	set _context $context
	incrIndent
	
	return $result
}

body Json::endBlock {char} {
	decrIndent
	set result ""
	if {$indent} {
		append result "\n[indent]"
	}
	append result "$char"

	set _context [$_contextStack pop]
	set _itemCounter [$_counterStack pop]
	if {$_itemCounter != ""} {
		incr _itemCounter
	} else {
		set _context "FINISHED"
	}

	return $result
}

body Json::objectKeysForAlignment {keys} {
	$_objectKeyLengthStack push $_objectKeyMaxLength
	if {[llength $keys] == 0} {
		set _objectKeyMaxLength 0
		return
	}

	set lengths [list]
	foreach key $keys {
		lappend lengths [string length [wrapString $key]]
	}
	set _objectKeyMaxLength [tcl::mathfunc::max {*}$lengths]
}

body Json::alignKey {key} {
	if {$align} {
		pad $_objectKeyMaxLength { } $key
	} else {
		return $key
	}
}
