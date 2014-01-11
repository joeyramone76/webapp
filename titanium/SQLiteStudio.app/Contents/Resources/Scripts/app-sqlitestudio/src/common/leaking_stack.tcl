use src/common/stack.tcl

class LeakingStack {
	inherit Stack

	constructor {maxSize} {}

	private {
		variable _maxSize ""
	}
	
	public {
		method push {value}
	}
}

body LeakingStack::constructor {maxSize} {
	set _maxSize $maxSize
}

body LeakingStack::push {value} {
	Stack::push $value
	if {[llength $_stack] > $_maxSize} {
		set _stack [lrange $_stack 1 end]
	}
}
