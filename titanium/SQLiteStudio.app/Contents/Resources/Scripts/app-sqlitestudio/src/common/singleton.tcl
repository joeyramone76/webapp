#>
# @class Singleton
# Singleton design pattern implementation.
# Any classes that inherites Singleton can have only one instance for whole application.
#<
class Singleton {
	#>
	# @method constructor
	# Remembers created class so it can't be created ever again.
	# Atteption to create it (second instance of class) will throw an error.
	#<
	constructor {} {}

	#>
	# @method destructor
	# Clears any info about the singleton instance.
	#<
	destructor {}

	#>
	# @arr instance
	# Kind of instances registry. Each class that inherites Singleton fills it's
	# entry in this array while creating first instance.
	#<
	protected {
		common instance
	}

	public {
		#>
		# @method exists
		# @param cls Class to check.
		# Checks if given class already has an instance.
		# @return <code>true</code> if class has the instance or <code>false</code> otherwise.
		#<
		proc exists {cls}

		#>
		# @method getSingletonIndex
		# @param cls Class to get index for.
		# This method allows to get index of {@var instance} array for given class.
		# It does NOT check if the instance already exists, it only formats the index.
		# @return Index to use with {@var instance} array.
		#<
		proc getSingletonIndex {cls}

		#>
		# @method get
		# @param cls Class to get existing singleton for.
		# Points to already existing singleton. It doesn't create new instance.
		# Singletons has to be created manualy, since there might be additional arguments for constructor required.
		# @return Singleton instance of given class.
		#<
		proc get {cls}
	}
}

body Singleton::constructor {} {
	if {[exists [$this info class]]} {
		error "Can't create second instance of Singleton!"
	}
	set instance([getSingletonIndex [$this info class]]) $this
}

body Singleton::destructor {} {
	catch {unset instance([getSingletonIndex [$this info class]])}
}

body Singleton::exists {cls} {
	return [info exists instance([getSingletonIndex $cls])]
}

body Singleton::get {cls} {
	if {![exists $cls]} {
		return ""
	}
	return $instance([getSingletonIndex $cls])
}

body Singleton::getSingletonIndex {cls} {
	return [string trimleft $cls :]
}
