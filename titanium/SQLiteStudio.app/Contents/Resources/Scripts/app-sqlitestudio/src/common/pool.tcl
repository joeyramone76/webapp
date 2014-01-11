class Pool {
	constructor {class args} {}
	destructor {}

	private {
		variable _timeoutTimer ""
		variable _notifyHolder 0

		method delayTimeout {}
		method timedOut {}
	}

	protected {
		variable _resourceClass ""
		variable _objects [list]
		variable _idle [list]

		method spawn {}
		method kill {obj}
		method release {obj}
		method reserve {}
		method notify {}
	}
	
	public {
		variable min 1
		variable max 1
		variable timeout 60

		method eval {script}
	}
}

body Pool::constructor {class args} {
	set _resourceClass $class
	$this configure {*}$args

	for {set i 0} {$i < $min} {incr i} {
		set obj [$this spawn]
		lappend _objects $obj
		lappend _idle $obj
	}
}

body Pool::destructor {} {
	foreach obj $_objects {
		kill $obj
	}
}

body Pool::spawn {} {
	set obj [$_resourceClass ::#auto]
	lappend _objects $obj
	lappend _idle $obj
}

body Pool::kill {obj} {
	lremove _objects $obj
	if {$obj ni $_idle} {
		release $obj
	}
	lremove _idle $obj
	delete object $obj
}

body Pool::reserve {} {
	set obj [lindex $_idle 0]
	while {$obj == ""} {
		if {[llength $_idle] == 0 && $max > [llength $_objects]} {
			$this spawn
		} else {
			vwait [scope _notifyHolder]
		}

		set obj [lindex $_idle 0]
	}
	return $obj
}

body Pool::release {obj} {
	lappend _idle $obj
	notify
}

body Pool::notify {} {
	incr _notifyHolder
}

body Pool::eval {script} {
	delayTimeout

	set obj [reserve]
	set result [$obj eval $script]
	release $obj
	return $result
}

body Pool::delayTimeout {} {
	after cancel [code $this timedOut]
	after [expr {60*$timeout}] [code $this timedOut]
}

body Pool::timedOut {} {
	while {[llength $_objects] > $min && [llength $_idle] > 0} {
		set time [clock seconds]
		set oldest [lindex $_idle 0]
		foreach obj [lrange $_idle 1 end] {
			set objTime [$obj getLastEvalTime]
			if {$objTime < $oldest} {
				set oldest $obj
				set time $objTime
			}
		}
		kill $oldest
	}
	delayTimeout
}
