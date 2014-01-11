use src/common/common.tcl

#>
# @class UI
# Any class that needs to apply UI changes made in configuration file
# needs to inherit this class and implement {@method updateUISettings}.
#<
class UI {
	#>
	# @method constructor
	# Registers new UI instance by adding it to {@var _instances}.
	#<
	constructor {} {}

	#>
	# @method destructor
	# Deregisters UI instance by removing it from {@var _instances}.
	#<
	destructor {}

	private {
		#>
		# @method _instances
		# List of objects that implements this class.
		#<
		common _instances [list]
	}

	public {
		#>
		# @method updateUISettings
		# This method is called when 'Apply' or 'Ok' button is pressed in
		# the configuration window, but just after all configuration variables has been updated,
		# so this method can read them to use while updating object.
		#<
		abstract method updateUISettings {}

		#>
		# @method updateStaticUISettings {}
		# Not obligatory to be implemented. One update per class.
		#<
		proc updateStaticUISettings {}

		#>
		# @method updateUI
		# It's called by {@class CfgWin} instance to update all objects that implements this - <b>UI</b> class.
		#<
		proc updateUI {}
	}

}

body UI::constructor {} {
	lappend _instances $this
}

body UI::destructor {} {
	lremove _instances $this
}

body UI::updateUI {} {
	foreach cls [findClassesBySuperclass "::UI"] {
		catch {${cls}::updateStaticUISettings}
	}

	foreach inst $_instances {
		if {[string trimleft $inst :] in [info commands]} {
			$inst updateUISettings
		}
	}
}

body UI::updateStaticUISettings {} {
}

