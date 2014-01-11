#>
# @class Clonable
# Provides possibility of cloning objects that inherites this class.
#<
class Clonable {
	private {
		method deepCloneHandleValue {cloned value}
	}

	protected {
		variable _internal_listVariables [list]
	}

	public {
		#>
		# @method clone
		# Makes a copy of the object and returns that copy.
		# Does not copy objects recurently, so if you need to do so, then you have 2 choices:<br>
		# 1. Use {@method deepClone} method which works recurently on Clonable instances, but it's slower.
		# 2. Overload this method, call Clonable::clone to clone rest of fields not-recurently,
		# and finally make a deep cloning manually on whichever field you want,
		# replacing values in new object returned by Clonable::clone, then return this object.
		# @return Brand new copy of object with same data as in current object.
		#<
		method clone {}

		#>
		# @method deepClone
		# Makes a deep copy of the objecta and returns it.
		# If any field has Clonable object as value, then it will be cloned as well.
		# It you need some field to be a list of Clonable objects, or mix of Clonable objects and other values,
		# then declare the field using {@proc list_variable}, so deepClone will treat it correctly.
		#<
		method deepClone {}
	}
}

body Clonable::clone {} {
	set cloned [[$this info class] ::#auto]
	foreach var [$this info variable] {
		$cloned configure -$var [set $var]
	}
	return $cloned
}

body Clonable::deepClone {} {
	set cloned [[$this info class] ::#auto]
	foreach var [$this info variable] {
		if {$var in $_internal_listVariables} {
			foreach val [set $var] {
				$cloned add$var [deepCloneHandleValue $clone $val]
			}
		} else {
			$cloned configure -$var [deepCloneHandleValue $clone [set $var]]
		}
	}
	return $cloned
}

body Clonable::deepCloneHandleValue {cloned value} {
	set isClonable 0
	if {![catch {$value isa ::Clonable} res]} {
		set isClonable $res
	}

	if {$isClonable} {
		return [[set $value] deepClone]
	} else {
		return [set $value]
	}
}
