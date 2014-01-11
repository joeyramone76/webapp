class Stack {
	protected {
		variable _stack [list]
	}
	
	public {
		method push {value}
		method pop {}
		method top {}
		method size {}
		method erase {}
		method isEmpty {}
		method dump {}
	}
}

body Stack::push {value} {
	lappend _stack $value
}

body Stack::pop {} {
	set v [lindex $_stack end]
	set _stack [lrange $_stack 0 end-1]
	return $v
}

body Stack::top {} {
	lindex $_stack end
}

body Stack::size {} {
	llength $_stack
}

body Stack::erase {} {
	set _stack [list]
}

body Stack::isEmpty {} {
	expr {$_stack == ""}
}

body Stack::dump {} {
	return $_stack
}
