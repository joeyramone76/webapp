use src/common/panel.tcl

class ImgCheckButton {
	inherit Panel

	constructor {args} {}
	destructor {}

	protected {
		variable _btn ""
		variable _onImg ""
		variable _offImg ""
		variable _variable ""
		variable _onValue 1
		variable _offValue 0
		variable _cmd ""
		variable _tracingEnabled 1
		variable _value ""

		method bindVariable {varName}
		method updateState {}
	}

	public {
		method variableChanged {var arrIdx op}
		method changeVariable {}
		method invoke {}
		method configure {args}
	}
}

body ImgCheckButton::constructor {args} {
	ttk::button $path.button -style Toolbutton -command "$this invoke"
	set _btn $path.button
	pack $_btn

	eval configure $args
	updateState
}

body ImgCheckButton::destructor {} {
	if {$_variable != ""} {
		uplevel #0 [list trace remove variable $_variable write [list $this variableChanged]]
	}
}

body ImgCheckButton::invoke {} {
	if {$_value == $_onValue} {
		set _value $_offValue
	} else {
		set _value $_onValue
	}
	updateState
	set _tracingEnabled 0
	uplevel #0 [list set $_variable $_value]
	set _tracingEnabled 1
	if {$_cmd != ""} {
		uplevel #0 $_cmd
	}
}

body ImgCheckButton::bindVariable {varName} {
	if {$_variable != ""} {
		uplevel #0 [list trace remove variable $_variable write [list $this variableChanged]]
	}
	uplevel #0 [list trace add variable $varName write [list $this variableChanged]]
	set _variable $varName
	variableChanged {} {} {}
}

body ImgCheckButton::variableChanged {var arrIdx op} {
	if {!$_tracingEnabled} return
	set value [uplevel #0 [list set $_variable]]
	if {$value == $_onValue} {
		set _value $_onValue
	} else {
		set _value $_offValue
	}
	updateState
}

body ImgCheckButton::updateState {} {
	$_btn configure -image [expr {$_value == $_onValue ? $_onImg : $_offImg}]
}

body ImgCheckButton::configure {args} {
	foreach {opt val} $args {
		switch -- $opt {
			"-onimage" {
				set _onImg $val
			}
			"-offimage" {
				set _offImg $val
			}
			"-variable" {
				bindVariable $val
			}
			"-onvalue" {
				set _onValue $val
			}
			"-offvalue" {
				set _offValue $val
			}
			"-command" {
				set _cmd $val
			}
			default {
				$_btn configure $opt $val
			}
		}
	}
}
