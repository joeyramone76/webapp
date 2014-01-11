proc try {args} {
	switch -- [llength $args] {
		3 {
			if {[lindex $args 1] == "catch"} {
				_trycatch [lindex $args 0] [lindex $args 2]
			} elseif {[lindex $args 1] == "finally"} {
				_tryfinally [lindex $args 0] [lindex $args 2]
			} else {
				error "wrong args # should be: try body catch body finally body\nor: try body finally body\nor try body catch body"
			}
		}
		5 {
			if {[lindex $args 1] == "catch" && [lindex $args 3] == "finally"} {
				_trycatchfinally [lindex $args 0] [lindex $args 2] [lindex $args 4]
			} else {
				error "wrong args # should be: try body catch body finally body\nor: try body finally body\nor try body catch body"
			}
		}
		default {
			error "wrong args # should be: try body catch body finally body\nor: try body finally body\nor try body catch body"
		}
	}
}

# var error
# var ::errorInfo
# var ::errorCode
proc _trycatch {body1 body2} {
	uplevel 2 "
		if {\[catch {
			$body1
		} error]} {
			$body2
		}
	"
}

# var error
# var ::errorInfo
# var ::errorCode
proc _tryfinally {body1 body2} {
	uplevel 2 "
		set catchCode 0
		if {\[catch {
			$body1
		} error]} {
			set catchCode [catch {$body2}]
		}
		$body2
		if {\$catchCode} {
			error \$::errorInfo
		}
	"
}

# var error
# var ::errorInfo
# var ::errorCode
proc _trycatchfinally {body1 body2 body3} {
	uplevel 2 "
		set catchCode 0
		if {\[catch {
			$body1
		} error]} {
			set catchCode [catch {$body2}]
		}
		$body3
		if {\$catchCode} {
			error \$::errorInfo
		}
	"
}
