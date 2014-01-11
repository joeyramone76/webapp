proc validateInt {val} {
	regexp -- {^[0-9]+$} $val
}

proc validateIntInRange {min max val} {
	expr {[regexp -- {^[0-9]+$} $val] && $val >= $min && $val <= $max}
}

proc validatePositiveInt {val} {
	expr { [regexp -- {^[0-9]+$} $val] && $val > 0 }
}

proc validateIntWithEmpty {val} {
	regexp -- {^[0-9]*$} $val
}

proc validateDouble {val} {
	regexp -- {^\d+\.\d+$} $val
}

proc validateDoubleWithEmpty {val} {
	regexp -- {^\d*$} $val
}

proc validateSignedNumeric {val} {
	regexp -- {^[\-\+]?\d+(\.\d+)?$} $val
}

proc validateUnsignedNumeric {val} {
	regexp -- {^\d+(\.\d+)?$} $val
}
