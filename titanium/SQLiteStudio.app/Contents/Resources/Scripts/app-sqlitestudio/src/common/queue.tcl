use src/common/leaking_stack.tcl

class Queue {
	inherit LeakingStack

	constructor {{maxSize 10}} {
		LeakingStack::constructor $maxSize
	} {}

	public {
		method front {}
		method back {}
		method pushBack {value}
		method popFront {}
	}
}

body Queue::pushBack {value} {
	LeakingStack::push $value
}

body Queue::popFront {} {
	set v [lindex $_stack 0]
	set _stack [lrange $_stack 1 end]
	return $v
}

body Queue::front {} {
	lindex $_stack 0
}

body Queue::back {} {
	Stack::top
}
