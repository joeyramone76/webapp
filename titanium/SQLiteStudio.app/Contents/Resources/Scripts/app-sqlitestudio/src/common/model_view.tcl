class ModelView {
	private {
		variable sequence 0

		method getNextValue {}
		method getNextVarName {}
	}

	public {
		common bindArray
		common bindLocks

		proc setModelValue {model fieldName varName {modelWriter ""} {widgetReader ""} args}
		proc setViewValue {varName model fieldName {widgetWriter ""} {modelReader ""} args}

		proc bindCheckbutton {model fieldName checkbutton {modelReader ""} {modelWriter ""}}
	}
}

body ModelView::getNextValue {} {
	return [incr sequence]
}

body ModelView::getNextVarName {} {
	return [scope bindArray([getNextValue])]
}

body ModelView::bindCheckbutton {model fieldName checkbutton {modelReader ""} {modelWriter ""}} {
	set varName [$checkbutton cget -variable]
	if {$varName == ""} {
		set varName [getNextVarName]
		$checkbutton configure -variable $varName
		bind $checkbutton <Destroy> +"catch {unset $varName}"
	}

	#
	# Model -> Widget
	#
	if {$modelReader != ""} {
		set value [eval $modelReader readField $fieldName]

		# Bind event
		$model trace add variable $fieldName write [list ModelView::setViewValue $varName $model $fieldName {} $modelReader]

		# On widget destroy
		set unbindScript [list $model trace remove variable $fieldName write [list ModelView::setViewValue $varName $model $fieldName {} $modelReader]]
		bind $checkbutton <Destroy> +$unbindScript
		$model bindOnDelete $unbindScript
	} else {
		set value [$model cget -$fieldName]

		# Bind event
		$model trace add variable $fieldName write [list ModelView::setViewValue $varName $model $fieldName {} {}]

		# On widget destroy
		set unbindScript [list $model trace remove variable $fieldName write [list ModelView::setViewValue $varName $model $fieldName {} {}]]
		bind $checkbutton <Destroy> +$unbindScript
		$model bindOnDelete $unbindScript
	}

	# Update current state
	if {$value == "" || ![string is boolean $value]} {
		error "Bind value (model: $model field: $fieldName) to checkbutton isn't boolean, but: $value"
	}
	set $varName $value

	#
	# Widget -> Model
	#
	#set value [set $varName]
	# No need to update model from checkbutton, since checkbutton was updated by model in reader part.

	if {$modelWriter != ""} {
		# Bind event
		trace add variable $varName write [list ModelView::setModelValue $model $fieldName $varName $modelWriter {}]

		# On widget destroy
		set unbindScript [list trace remove variable $varName write [list ModelView::setModelValue $model $fieldName $varName $modelWriter {}]]
		bind $checkbutton <Destroy> +$unbindScript
		$model bindOnDelete $unbindScript
	} else {
		# Bind event
		trace add variable $varName write [list ModelView::setModelValue $model $fieldName $varName {} {}]

		# On widget destroy
		set unbindScript [list trace remove variable $varName write [list ModelView::setModelValue $model $fieldName $varName {} {}]]
		bind $checkbutton <Destroy> +$unbindScript
		$model bindOnDelete $unbindScript
	}
}

body ModelView::setModelValue {model fieldName varName {modelWriter ""} {widgetReader ""} args} {
	if {[info exists bindLocks($model:$fieldName)]} {
		return
	}
	set bindLocks($varName) 1

	if {[catch { ;# necessary, cause we need to unlock varName below anyway
		if {$widgetReader != ""} {
			set value [eval $widgetReader readWidget]
		} else {
			set value [set $varName]
		}

		if {$modelWriter != ""} {
			eval $modelWriter writeField $fieldName $value
		} else {
			$model configure -$fieldName $value
		}
	} err]} {
		if {$::DEBUG(global)} {
			puts "Error while updating model (setModelValue) with arguments:\n$model\n$fieldName\n$varName\n$modelWriter\n$widgetReader"
		}
	}

	unset bindLocks($varName)
}

body ModelView::setViewValue {varName model fieldName {widgetWriter ""} {modelReader ""} args} {
	if {[info exists bindLocks($varName)]} {
		return
	}
	set bindLocks($model:$fieldName) 1

	if {[catch { ;# necessary, cause we need to unlock varName below anyway
		if {$modelReader != ""} {
			set value [eval $modelReader readField $fieldName]
		} else {
			set value [$model cget -$fieldName]
		}

		if {$widgetWriter != ""} {
			eval $widgetWriter writeWidget $value
		} else {
			set $varName $value
		}
	} err]} {
		if {$::DEBUG(global)} {
			puts "Error while updating widget (setViewValue) with arguments:\n$varName\n$model\n$fieldName\n$widgetWriter\n$modelReader"
		}
	}

	unset bindLocks($model:$fieldName)
}
