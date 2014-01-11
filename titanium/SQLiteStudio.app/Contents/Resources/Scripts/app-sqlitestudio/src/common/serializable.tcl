class Serializable {
	protected {
		common objects [list]
		common serializedObjects [dict create]

		method serializeList {value tid {depth 3}}

		method serializeInternal {}
		method deserializeIntrnal {data}
	}

	public {
		method serialize {}
		proc deserialize {serializedData}
	}
}

body Serializable::serializeInternal {} {
	# Objects are serialized to "_<threadId>" suffix-named objects
	# to avoid name conflict while deserialization in other thread.

	set data [dict create]
	set tid [thread::id]
	foreach var [$this info variable] {
		if {
			[string match "::*::this" $var] ||
			[string match "::*::serializedObjects" $var] ||
			[string match "::*::objects" $var]
		} continue

		# Get rid of "::*::"
		set idx [string first "::" $var 1]
		incr idx 2
		set key [string range $var $idx end]

		set isParentStmt [string match "::*::_parentStatement" $var]
		set isChildStmts [string match "::*::_childStatements" $var]

		if {[string first "_" $key] == 0 && !$isParentStmt && !$isChildStmts} {
			# Do not serialize other "_*" variables, unless they're _parentStatement or _childStatements.
			continue
		}

		set value [$this cget -$key]
		if {$isParentStmt} {
			# parentStatement cannot be checked for serialization
			# because it causes infinite recursion.
			set value [$this cget -$key]
			if {$value != ""} {
				set newValue "${value}_$tid"
			} else {
				set newValue ""
			}
			dict set data $key $newValue
		} elseif {$isChildStmts} {
			# Similar case for childStatements
			set value [$this cget -$key]
			set newValue [list]
			foreach obj $value {
				set newName "${obj}_$tid"
				if {![dict exists $serializedObjects $newName]} {
					dict set serializedObjects $newName [dict create class [$obj info class] data [$obj serializeInternal]]
				}
				lappend newValue $newName
			}
			dict set data $key $newValue
		} elseif {$value == ""} {
			dict set data $key $value
		} elseif {[string is list $value]} {
			dict set data $key [serializeList $value $tid]
		} elseif {$value in $objects} {
			set newValue "${value}_$tid"
			if {![dict exists $serializedObjects $newValue]} {
				dict set serializedObjects $newValue [dict create class [$value info class] data [$value serializeInternal]]
			}
			dict set data $key $newValue
		} else {
			dict set data $key $value
		}
	}
	return $data
}

body Serializable::serializeList {value tid {depth 3}} {
	if {[llength $value] == 4 && [regexp -- {\w+\s+.+\s+\d+\s+\d+} $value]} {
		# Just a token
		return $value
	}

	set newValue [list]
	foreach it $value {
		if {$it in $objects} {
			set newIt "${it}_$tid"
			if {![dict exists $serializedObjects $newIt]} {
				dict set serializedObjects $newIt [dict create class [$it info class] data [$it serializeInternal]]
			}
		} elseif {[string is list $it] && $depth > 0} {
			lappend newValue [serializeList $it $tid [expr {$depth - 1}]]
			continue
		} else {
			set newIt $it
		}
		lappend newValue $newIt
	}
	return $newValue
}

body Serializable::deserializeIntrnal {data} {
	dict for {var value} $data {
		$this configure -$var $value
	}
}

body Serializable::serialize {} {
	# Refresh Serializable objects list
	set objects [find objects -isa Serializable]

	# Preparing list of serialized objects
	set serializedObjects [dict create]

	# Serialize self first
	set tid [thread::id]
	set key "${this}_$tid"
	set cls [$this info class]
	dict set serializedObjects $key [dict create class $cls data [serializeInternal]]

	# Now do the actual serialization
	return [dict create object $key objects $serializedObjects]
}

body Serializable::deserialize {serializedData} {
	set serializedObjects [dict get $serializedData objects]
	dict for {objName objDesc} $serializedObjects {
		set cls [dict get $objDesc class]
		set data [dict get $objDesc data]
		set obj [$cls $objName]
		$obj deserializeIntrnal $data
	}
	return [dict create object [dict get $serializedData object] objects [dict keys $serializedObjects]]
}
