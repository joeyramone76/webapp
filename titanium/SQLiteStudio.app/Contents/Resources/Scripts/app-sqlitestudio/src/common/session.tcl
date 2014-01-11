#>
# @class Session
# Provides support for session storing and restoring.
# <i>'Session'</i> is set of classes that extends <code>Session</code> class
# and needs to be recreated after next application start.
#<
class Session {
	#>
	# @var session
	# This variable is filled while loading configuration file.
	# It contains list of session strings needed to restore session.
	# Each element of the list has first word as identification of object type to be recreated,
	# rest of element words are additional data for object.
	# Unfortunately all object identification types (first words of list elements) needs to be
	# handled by {@method recreate} method. It needs to be modified to support plugins
	# to handle that.
	#<
	common session [list]

	public {
		#>
		# @method applyRestoredSession
		# Some Session implementations need to apply restored session parameters on the existing objects,
		# after application is fully up. An example is TaskBar, where sorting tasks must be delayed until the end.
		# Most classes do not have to implement this.
		#<
		method applyRestoredSession {} {}
	
		#>
		# @method getSessionString
		# Derived class needs to implement this method to return all needed data to restore
		# session for the object. Returned string will be used by {@method recreate} method.
		#<
		abstract method getSessionString {}

		#>
		# @method proc restoreSession {sessionString}
		# @param sessionString Session item data as returned from {@method getSessionString}.
		# Derived class needs to check if this string should be handled by it
		# and if yes, then executes proper code to restore this session item.
		# @return true if the class handled this session string and restored session successfly, or false otherwise.
		#<
		abstract proc restoreSession {sessionString}

		#>
		# @method save
		# Stores session in configuration file. Calls {@method getSessionString} on all objects
		# that inherites this class.
		#<
		proc save {}

		#>
		# @method recreate
		# Restores session from configuration strings. Needs to be modified to handle new object types.
		#<
		proc recreate {}

		proc applyAllRestoredSession {}
	}
}

body Session::save {} {
	set data [list]
	foreach obj [itcl::find objects -isa ::Session] {
		set res [catch {$obj getSessionString} str]
		if {$res || $str == ""} {
			debug "Cannot save session for $obj:\n$str"
			continue
		}
		lappend data $str
	}
	::CfgWin::save [list ::Session::session $data]
}

body Session::recreate {} {
	set handlers [findClassesBySuperclass "::Session"]
	foreach handler $handlers {
		if {[info commands ::${handler}::restoreSession] == ""} {
			lremove handlers $handler
		}
	}

	foreach sessItem $session {
		foreach handler $handlers {
			if {[${handler}::restoreSession $sessItem]} {
				break ;# handled, go to next session item
			}
		}
	}
}

body Session::applyAllRestoredSession {} {
	set handlers [itcl::find objects -isa ::Session]
	foreach hnd $handlers {
		$hnd applyRestoredSession
	}
}
