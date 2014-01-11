class Privileges {
	public {
		proc doNeedRootForUpdate {}
	}
}

body Privileges::doNeedRootForUpdate {} {
	if {($::DISTRIBUTION != "binary" && !$::IS_BOUNDLE)} {
		return false
	}

	set dir [file dirname [file dirname $::argv0]]
	if {![file writable $dir]} {
		return true
	}

	if {![file writable $::argv0]} {
		return true
	}

	# No need for gaining root, probably already being root
	return false
}
