set ::THEME_SETTINGS {
	default {
		toolbar {
			use_themed_background false
			button_padx 2
			separator_padx 0
		}
	}
	tilegtk {
		toolbar {
			use_themed_background false
		}
	}
	tileqt {
		toolbar {
			use_themed_background false
		}
	}
	keramik {
		toolbar {
			use_themed_background true
		}
	}
	keramik_alt {
		toolbar {
			use_themed_background true
		}
	}
	pseudovista {
		toolbar {
			use_themed_background true
		}
	}
	aqua {
		toolbar {
			button_padx 0
			separator_padx 2
		}
	}
}

# text widget doesn't have this option, we need to emulate it and we need this value for it
entry .tempEntry
set ::DISABLED_FONT_COLOR [.tempEntry cget -disabledforeground]
destroy .tempEntry

#>
# @method getThemeSetting
# @param theme Theme to get property for.
# @param component Component to get property for. See components defined in <code>default</code> theme (in ::THEME_SETTINGS).
# @param property Property of the component. Each component supports different properties. See properties defined in <code>default</code> theme (in ::THEME_SETTINGS).
# ::THEME_SETTINGS contains theme-specific look&feel settings to make themes looking more consistently.
# To add custom settings for new theme you need to add new dict key named as the theme and fill its dict
# values (see comments of ::THEME_SETTINGS variable in theme_settings.tcl file).
# If no specific settings are found for the theme (or for specific property of theme) then defaults are used.
# @return Value of the requested property or - if it's not defined - corresponding value from <code>default</code> theme defined in ::THEME_SETTINGS, or empty string if given component or property is invalid.
#<
proc getThemeSetting {theme component property} {
	if {[dict exists $::THEME_SETTINGS $theme $component $property]} {
		return [dict get $::THEME_SETTINGS $theme $component $property]
	} else {
		return [dict get $::THEME_SETTINGS default $component $property]
	}
}
