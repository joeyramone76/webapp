#>
# @class ThreadClassProxy
# Base class for building proxy classes to use main thread objects from syntax checking thread.
#<
class ThreadClassProxy {
	constructor {thread realObject} {
		set _thread $thread
		set _obj $realObject
	}

	protected {
		variable _thread ""
		variable _obj ""
	}

	protected {
		method call {args}
	}

	public {
		method getOriginalDb {}
		proc makeProxy {methodName}
	}
}

body ThreadClassProxy::call {method args} {
	set result [thread::send $_thread [list $_obj $method {*}$args] output]
	if {$result != 0} {
		error $output
	} else {
		return $output
	}
}

body ThreadClassProxy::makeProxy {methodName} {
	uplevel [string map [list \$methodName $methodName] {
		method $methodName args "return \[call $methodName {*}\$args]"
	}]
}

body ThreadClassProxy::getOriginalDb {} {
	return $_obj
}
