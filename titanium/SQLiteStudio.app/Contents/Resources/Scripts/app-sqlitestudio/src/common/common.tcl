#>
# @proc abstract
# @param what This argument value has to be one of '<code>method</code>', '<code>proc</code>', or '<code>class</code>'. Any other will raise an error.
# In other way - this procedure implements abstract methods, classes and procedures (static methods) like in Java for IncrTcl.
#<
proc abstract {what args} {
	switch -- $what {
		"method" {
			lassign $args name arguments
			uplevel "
				method [list $name] [list $arguments] {
					error \"$name method has to be implemented for class \[string trimleft \[\$this info class] :]\"
				}
			"
		}
		"proc" {
			lassign $args name arguments
			uplevel "
				proc [list $name] [list $arguments] {
					error \"$name procedure has to be implemented for class \[string trimleft \[info class] :]\"
				}
			"
		}
		"class" {
			lassign $args name definition
			uplevel [list class $name $definition]
			uplevel [list rename $name _${name}_abstract_class]
			uplevel [list proc $name args [list error "Cannot instantiate abstract class $name"]]
		}
		default {
			error "Only methods/procs can be abstract!"
		}
	}
}

#>
# @proc methodlink
# A shortcut to define method which calls the same method on objec given in second argument.
# Useful for linking methods like 'onecolumn' for sqlite objects.
#<
proc methodlink {name obj} {
	uplevel "method $name {args} {uplevel \"$obj $name \$args\"}"
}

#>
# @proc opt
# A shortcut to define IncrTk widget options.
#<
proc opt {name {init ""} {config ""}} {
	uplevel "itk_option define -$name $name [string totitle $name] [list $init] [list $config]"
}

#>
# @proc final
# @param variable Type of declaration (set/common/variable) or name of variable.
# @param name Name of variable.
# @param value Value for variable.
# Makes sure that given variable has final value and will not be modified.
# This procedure takes 2 syntaxes:
# <ul>
# <li> First uses all arguments and then
# it's used at the variable definition, while setting its value. It supports
# variable defining by <code>set</code>, <code>common</code> or <code>variable</code>.
# Next to arguments are same as arguments for these types of declarations.
# Procedure executes variable definition and attaches trace on it,
# so it won't be modified ever.
# <li> Second uses only first argument and then it's understood as name o variable
# to be final. It doesn't define variable, it expects that variable already exists.
# </ul>
#<
proc final {variable {name ""} {value ""}} {
	if {$name == ""} {
		set name $variable
		uplevel [list trace add variable $name write _final]
	} else {
		switch -- $variable {
			"variable" {
				uplevel [list variable $name $value]
				uplevel [list trace add variable $name write _final]
			}
			"common" {
				uplevel [list common $name $value]
				uplevel [list trace add variable $name write _final]
			}
			"set" {
				uplevel [list set $name $value]
				uplevel [list trace add variable $name write _final]
			}
			default {
				error "final can be used only for \[variable], \[common], or \[set]."
			}
		}
	}
}

#>
# @proc _final
# Internal for {@proc final}.
#<
proc _final {name1 name2 op} {
	error "variable $name1 is final, its cannot be modified."
}

#>
# @proc list_variable
# @param name Name of variable.
# Declares variable in class, initializes it as empty list and creates helper methods:
# <code>addNAME</code>, <code>resetNAME</code>, <code>replaceNAME</code>, <code>remNAME</code>,
# <code>delNAME</code> and <code>countNAME</code>.<br>
# <b>Can be called only from inside of class, which has {@class Clonable} class in its inheritage tree.
#<
proc list_variable {name} {
	set suffix [string toupper [string index $name 0]][string range $name 1 end]
	uplevel "
		variable $name \[list]
		lappend _internal_listVariables $name
		method add$suffix {value} {
			lappend $name \$value
		}
		method reset$suffix {} {
			set $name \[list]
		}
		method count$suffix {} {
			return \[llength $name]
		}
		method replace$suffix {idx newValue} {
			set $name \[lreplace \$name \$idx \$idx \$newValue]
		}
		method rem$suffix {idx} {
			set $name \[lreplace \$name \$idx \$idx]
		}
		method del$suffix {value} {
			set idx \[lsearch -exact \$$name \$value]
			if {\$idx == -1} return
			set $name \[lreplace \$name \$idx \$idx]
		}
	"
}

proc inherit_snit_type {args} {
	foreach type $args {
		set cls ::snit_type_[lindex [wsplit $type "::"] end]
		set code [list class $cls [string map [list \$type $type] {
			protected {
				variable super ""

				set temp [$type create ::%AUTO%]
				foreach method [$temp info methods] {
					set args [$temp info args $method]

					if {$method in [list info cget configure isa]} {
						set method snit_$method
					}
					
					set body ""
					foreach arg $args {
						append body " \$$arg"
					}
					set body "\$super$body"
					method $method $args $body
				}
				unset temp
			}

			constructor {args} {
				set super [$type create ::%AUTO% {*}$args]
			}

			destructor {
				$super destroy
			}
		}]]
		uplevel #0 $code
		uplevel [list inherit $cls]
	}
}

#------------------------

##
# Code from BWidget
proc ComboBoxAutoComplete {path key} {
	#
	# autocomplete a string in the ttk::combobox from the list of values
	#
	# Any key string with more than one character and is not entirely
	# lower-case is considered a function key and is thus ignored.
	#
	# path -> path to the combobox
	#
	if {[string length $key] > 1 && [string tolower $key] != $key} {
		return
	}

	set text [string map [list {[} {\[} {]} {\]}] [$path get]]
	if {[string equal $text ""]} {
		return
	}

	set values [$path cget -values]
	set x [lsearch -glob -nocase $values $text*]
	if {$x < 0} {
		return
	}

	set index [$path index insert]
	$path set [lindex $values $x]
	$path icursor $index
	$path selection range insert end
}

proc acCombo {path} {
	bind $path <KeyRelease> [list ComboBoxAutoComplete $path %K]
	bind $path <FocusOut> [list $path selection clear]
}

#------------------------

proc wcenter {path {req ""}} {
	update idletasks
	set wd [winfo ${req}width $path]
	set ht [winfo ${req}height $path]
	set x [expr {([winfo screenwidth $path]-$wd)/2}]
	set y [expr {([winfo screenheight $path]-$ht)/2}]
	wm geometry $path +$x+$y
}

proc wcenterSmooth {path {req ""}} {
	wm withdraw $path
	update idletasks
	set wd [winfo ${req}width $path]
	set ht [winfo ${req}height $path]
	set x [expr {([winfo screenwidth $path]-$wd)/2}]
	set y [expr {([winfo screenheight $path]-$ht)/2}]
	wm geometry $path +$x+$y
	wm deiconify $path
}

proc wcenterby {path {parent {}} {req ""}} {
	if {$parent == ""} {
		set sp [split $path .]
		if {[llength $sp] > 2} {
			set parent [join [lrange $sp 0 end-1] .]
		} else {
			set parent .
		}
	}
	wm withdraw $path
	update idletasks
	set pWd [winfo width $parent]
	set pHt [winfo height $parent]
	set px [winfo x $parent]
	set py [winfo y $parent]
	set wd [winfo ${req}width $path]
	set ht [winfo ${req}height $path]
	set x [expr {$px+($pWd-$wd)/2}]
	set y [expr {$py+($pHt-$ht)/2}]
	wm geometry $path +$x+$y
	wm deiconify $path
}

proc makeSureIsVisible {path} {
	wm withdraw $path
	update idletasks

	set scrWd [winfo screenwidth $path]
	set scrHg [winfo screenheight $path]

	lassign [split [wm geometry $path] "x+"] w h x y
	set w [winfo reqwidth $path]
	set h [winfo reqheight $path]

	if {$w <= $scrWd} {
		if {$x < 0} {
			set x 0
		} elseif {($x + $w) > $scrWd} {
			set x [expr {$scrWd - $w}]
		}
	}

	if {$h <= $scrHg} {
		if {$y < 0} {
			set y 0
		} elseif {($y + $h) > $scrHg} {
			set y [expr {$scrHg - $h}]
		}
	}

	wm geometry $path +$x+$y
	wm deiconify $path
}

proc isMostlyVisible {path {x ""} {y ""} {w ""} {h ""}} {
	set scrWd [winfo screenwidth $path]
	set scrHg [winfo screenheight $path]

	if {$x == "" || $y == "" || $w == "" || $h == ""} {
		lassign [split [wm geometry $path] "x+"] w h x y
		set w [winfo reqwidth $path]
		set h [winfo reqheight $path]
	}

	if {$x < -($w/2)} {
		return false
	} elseif {($x + ($w/2)) > $scrWd} {
		return false
	}

	if {$y < 0} {
		return false
	} elseif {($y + ($h/2)) > $scrHg} {
		return false
	}

	return true
}

proc lremove {varname item} {
	upvar $varname v
	set pos [lsearch -exact $v $item]
	set v [lreplace $v $pos $pos]
}

proc ldelete {list item} {
	set pos [lsearch -exact $list $item]
	lreplace $list $pos $pos
}

proc lmdelete {list items} {
	foreach item $items {
		set pos [lsearch -exact $list $item]
		set list [lreplace $list $pos $pos]
	}
	return $list
}

proc lmremove {varname items} {
	upvar $varname v
	foreach item $items {
		set pos [lsearch -exact $v $item]
		set v [lreplace $v $pos $pos]
	}
}

proc lremove_all {varname item} {
	upvar $varname v
	while {[set pos [lsearch -exact $v $item]] > -1} {
		set v [lreplace $v $pos $pos]
	}
}

proc lfind {list word} {
	foreach it $list {
		if {[lindex $it 0] == $word} {
			return [lindex $it 1]
		}
	}
	return ""
}

proc lmap {map lst} {
	foreach {key val} $map {
		set pos [lsearch -exact $lst $key]
		if {$pos == -1} continue
		set lst [lreplace $lst $pos $pos $val]
	}
	return $lst
}

proc isttk {arg} {
	if {[string first "ttk::" $arg] > -1} {
		return 1
	} else {
		return 0
	}
}

proc disableFrame {f} {
	foreach child [winfo children $f] {
		catch {$child configure -state disabled}
		disableFrame $child
	}
}

proc enableFrame {f} {
	foreach child [winfo children $f] {
		catch {$child configure -state normal}
		enableFrame $child
	}
}

proc fec {var str body} {
	uplevel "
		foreach $var [list [split $str {}]] {
			$body
		}
	"
}

proc pad {cnt char str} {
	if {$char == " "} {
		return [format %-${cnt}s $str]
	}

	set lgt [string length $str]
	if {$lgt < $cnt} {
		set addlgt [expr {$cnt - $lgt}]
		append str [string repeat $char $addlgt]
		return $str
	} else {
		return $str
	}
}

proc rpad {cnt char str} {
	if {$char == " "} {
		return [format %${cnt}s $str]
	}

	set lgt [string length $str]
	if {$lgt < $cnt} {
		set addlgt [expr {$cnt - $lgt}]
		set str "[string repeat $char $addlgt]$str"
		return $str
	} else {
		return $str
	}
}

proc strip {chars str} {
	set map [list]
	foreach c [split $chars ""] {
		lappend map $c ""
	}
	string map $map $str
}

proc wsplit {str sep} {
	split [string map [list $sep \0] $str] \0
}

proc center {cnt str} {
	set lgt [string length $str]
	if {$lgt >= $cnt} {
		return [string range $str 0 $cnt]
	} else {
		set spcs [expr {$cnt - $lgt}]
		set spcs [expr $spcs.0 / 2]
		if {[string index $spcs 2] == 5} {
			set lsp [string index $spcs 0]
			set rsp [expr {[string index $spcs 0] + 1}]
		} else {
			set lsp [string index $spcs 0]
			set rsp [string index $spcs 0]
		}
		return "[string repeat \  $lsp]$str[string repeat \  $rsp]"
	}
}

proc upperFirstChar {str} {
	return [string toupper [string index $str 0]][string range $str 1 end]
}

proc escapeXML {str} {
	return [string map [list & &amp\; < &lt\; > &gt\; ' &apos\; \" &quot\;] $str]
}

proc escapeHTML {str} {
	return [string map [list \n <BR>] [escapeXML $str]]
}

set ::randchars "abcdefghijklmnopqrstuvwxyz1234567890"
proc randcrap {length {sw {0}}} {
	global randchars
	set crap ""
	if {$sw} {
		while {$length > 0} {
			append crap [binary format c* [rand 255]]
			incr length -1
		}
	} else {
		while {$length > 0} {
			append crap [string index $::randchars [rand 36]]
			incr length -1
		}
	}
	return $crap
}

proc randalpha {length} {
	global randchars
	set crap ""
	while {$length > 0} {
		append crap [string index $::randchars [rand 26]]
		incr length -1
	}
	return $crap
}

proc rand args {
	switch -exact -- [llength $args] {
		0 {
			set lower 0
			set upper 2
		}
		1 {
			set lower 0
			set upper $args
		}
		2 {
			set lower [lindex $args 0]
			set upper [lindex $args 1]
		}
		default {
			error {wrong # args: rand ??minimum? maximum?}
		}
	}
	expr { int((rand() * ($upper - $lower)) + $lower) }
}

proc GetOpenFile {args} {
	switch -- [os] {
		"linux" - "solaris" - "freebsd" {
			return [ttk::getOpenFile {*}$args]
		}
		"macosx" {
			return [tk_getOpenFile {*}$args]
		}
		"win32" {
			return [tk_getOpenFile {*}$args]
		}
		default {
			return [tk_getOpenFile {*}$args]
		}
	}
}

proc GetSaveFile {args} {
	switch -- [os] {
		"linux" - "solaris" - "freebsd" {
			return [ttk::getSaveFile {*}$args]
		}
		"macosx" {
			return [tk_getSaveFile {*}$args]
		}
		"win32" {
			return [tk_getSaveFile {*}$args]
		}
		default {
			return [tk_getSaveFile {*}$args]
		}
	}
}

proc GetAppendFile {args} {
	switch -- [os] {
		"linux" - "solaris" - "freebsd" {
			return [ttk::getAppendFile {*}$args]
		}
		"win32" {
			return [tk_getSaveFile -confirmoverwrite 0 {*}$args]
		}
		default {
			return [ttk::getAppendFile {*}$args]
		}
	}
}

proc GetColor {args} {
	switch -- [os] {
		"linux" - "freebsd" - "solaris" {
			set path [ColorDialog .chooseColor {*}$args]
			return [$path exec]
		}
		"win32" - "macosx" - "macintosh" {
			return [tk_chooseColor {*}$args]
		}
	}
}

proc Error {msg {buttonLabel ""}} {
	if {[winfo exists .errorDialog]} {
		# User has to close previous dialog
		tkwait window .errorDialog
	}
	if {$::DEBUG(global)} {
		puts "Stack for error message:"
		printStackTrace
	}
	MsgDialog .errorDialog -title [mc {Error}] -message $msg -type error -buttonlabel $buttonLabel -wrapping true
	.errorDialog exec
}

proc MultiError {args} {
	if {[winfo exists .errorDialog]} {
		# User has to close previous dialog
		tkwait window .errorDialog
	}
	if {$::DEBUG(global)} {
		puts "Stack for error message:"
		printStackTrace
	}
	MsgDialog .errorDialog -title [mc {Error}] -messageset $args -type error -wrapping true
	.errorDialog exec
}

proc Info {msg {buttonLabel ""}} {
	if {[winfo exists .infoDialog]} {
		# User has to close previous dialog
		tkwait window .infoDialog
	}
	MsgDialog .infoDialog -title [mc {Information}] -message $msg -type info -buttonlabel $buttonLabel -wrapping true
	.infoDialog exec
}

proc MultiInfo {args} {
	if {[winfo exists .infoDialog]} {
		# User has to close previous dialog
		tkwait window .infoDialog
	}
	MsgDialog .infoDialog -title [mc {Information}] -messageset $args -type info -wrapping true
	.infoDialog exec
}

proc Warning {msg {buttonLabel ""}} {
	if {[winfo exists .warnDialog]} {
		# User has to close previous dialog
		tkwait window .warnDialog
	}
	MsgDialog .warnDialog -title [mc {Warning}] -message $msg -type warning -buttonlabel $buttonLabel -wrapping true
	.warnDialog exec
}

proc MultiWarning {args} {
	if {[winfo exists .warnDialog]} {
		# User has to close previous dialog
		tkwait window .warnDialog
	}
	MsgDialog .warnDialog -title [mc {Warning}] -messageset $args -type warning -wrapping true
	.warnDialog exec
}

proc jot {start stop {interval 1}} {
	set l [list]
	for {set i $start} {$i <= $stop} {incr i $interval} {
		lappend l $i
	}
	return $l
}

proc hex_rev {h} {
	return [string index $h 1][string index $h 0]
}

proc max {val args} {
	set max $val
	foreach val $args {
		if {$val > $max} {
			set max $val
		}
	}
	return $max
}

proc min {val args} {
	set min $val
	foreach val $args {
		if {$val < $min} {
			set min $val
		}
	}
	return $min
}

proc buildStackTrace {{mod 0}} {
	set stack [list]
	for {set i [expr {-2 - $mod}]} {true} {incr i -1} {
		if {[catch {set s [info frame $i]}]} break
		lappend stack "[expr {-$i - 2 - $mod}]) [dict get $s cmd] <line [dict get $s line]>"
	}
	return $stack
}

proc printStackTrace {{levels ""}} {
	if {$levels == ""} {
		set levels end
	} else {
		incr levels -1
	}
	uplevel [string map [list %LEV% $levels] {
		puts "Stack trace:"
		puts [join [lrange [buildStackTrace 2] 0 %LEV%] "\n"]
	}]
}

proc versionToInt {ver} {
	set sp [split $ver .]
	lassign $sp major minor patch
	foreach varName {major minor patch} {
		if {[set $varName] == ""} {
			set $varName 0
		}
	}
	set val [expr {$major*10000 + $minor * 100 + $patch}]
}

#>
# @proc findClassesBySuperclass
# @param cls Superclass to look for.
# Finds all classes that has given superclass anywhere in their heritage.
# @return Classes found as list.
#<
proc findClassesBySuperclass {supcls} {
	set lst [list]

	# Superclass cannot start with ::
	set supcls [string trimleft $supcls :]

	# Now, looking for all classes
	foreach cls [::itcl::find classes] {

		# If class has no [info] method - it's useless
		if {[catch {namespace eval $cls "${cls}::info heritage"} hier]} continue

		# We have to trim all classes from hierarchy to avoid starting with ::.
		set newHier [list]
		foreach hCls $hier {
			lappend newHier [string trimleft $hCls :]
		}

		# Finally, check and add to list
		if {$supcls in $newHier && $supcls != $cls} {
			lappend lst $cls
		}
	}
	return $lst
}

proc errorWithFirstArg {args} {
	error [lindex $args 0]
}

proc indentAllLines {txt spaces} {
	set res [list]
	foreach line [split $txt "\n"] {
		lappend res "[string repeat { } $spaces]$line"
	}
	return [join $res "\n"]
}

#>
# @proc cutOffStdTclErr
# @param varName Variable name with standard Tcl error message.
# Cuts off stack tract from standard Tcl error (cuts off 'while executing ...')
# and leaves essential message.<br>
# Given variable name is linked with variable on 1 level up.
#<
proc cutOffStdTclErr {varName} {
	upvar $varName var
	if {[string match "*while executing*" $var]} {
		debug "Tcl error before cut:\n$var"
		# Standard Tcl error. Cut off Tcl stack trace part.
		set idx [string first "while executing" $var]
		set var [string trimright [string range $var 0 [expr {$idx-1}]]]
	} elseif {$::DEBUG(global)} {
		puts "DEBUG Error info (might be unrelated):\n$::errorInfo"
	}
}

proc parseArgs {params} {
	if {[llength $params] % 2 > 0} {
		error "Number of parameters to parseArgs has to be even."
	}

	upvar args inputArgs
	foreach {opt value} $inputArgs {
		foreach {expected operation} $params {
			if {$opt == $expected} {
				uplevel [list set value $value]
				uplevel [list eval $operation]
				break
			}
		}
	}
}

# Returns given path, or [pwd] if given doesn't exist.
if {[info exists ::IS_BOUNDLE] && $::IS_BOUNDLE} {
	# A MacOSX boundle
	proc getPathForFileDialog {path} {
		if {![file exists $path]} {
			set path [pwd]
		}
		set idx [string first "/Contents/MacOS" $path]
		if {$idx > -1} {
			# Goto dir with "Contents" subdir, then one dir up to leave boundle dir.
			set path [file dirname [string range $path 0 $idx]]
		}
		return $path
	}
} else {
	proc getPathForFileDialog {path} {
		if {[file exists $path]} {
			return $path
		} else {
			return [pwd]
		}
	}
}

# -- pdict
# from http://wiki.tcl.tk/23526
#
# Pretty print a dict similar to parray.
#
# USAGE:
#
#   pdict d [i [p [s]]]
#
# WHERE:
#  d - dict value or reference to be printed
#  i - indent level
#  p - prefix string for one level of indent
#  s - separator string between key and value
proc pdict { d {i 0} {p "  "} {s " -> "} } {
	set errorInfo $::errorInfo
	set errorCode $::errorCode
		set fRepExist [expr {0 < [llength\
				[info commands tcl::unsupported::representation]]}]
	while 1 {
		if { [catch {dict keys $d}] } {
			if {! [info exists dName] && [uplevel 1 [list info exists $d]]} {
				set dName $d
				unset d
				upvar 1 $dName d
				continue
			}
			return -code error  "error: pdict - argument is not a dict"
		}
		break
	}
	if {[info exists dName]} {
		puts "dict $dName"
	}
	set prefix [string repeat $p $i]
	set max 0
	foreach key [dict keys $d] {
		if { [string length $key] > $max } {
			set max [string length $key]
		}
	}
	dict for {key val} ${d} {
		puts -nonewline "${prefix}[format "%-${max}s" $key]$s"
		if {
			$fRepExist && ! [string match "value is a dict*" [tcl::unsupported::representation $val]]
			||
			!$fRepExist && [catch {dict keys $val}]
		} {
			puts "'${val}'"
		} else {
			puts ""
			pdict $val [expr {$i+1}] $p $s
		}
	}
	set ::errorInfo $errorInfo
	set ::errorCode $errorCode
	return ""
}

proc copyClassBinds {class newClass} {
	foreach binding [bind $class] {
		bind $newClass $binding [bind $class $binding]
	}
}

proc removeAllBindsBut {class bindList} {
	foreach binding $bindList {
		array set tmprab "<${binding}> 0"
	}

	foreach binding [bind $class] {
		if {[info exists tmprab($binding)]} {
			continue
		}
		bind $class $binding {}
	}

	array unset tmprab
}

proc formatFileSize {byteSize} {
	set units [list B KB MB GB TB PB]
	set ptr 0
	set sizes [list]

	while {$byteSize > 0} {
		lappend sizes [expr {$byteSize % 1024}]
		set byteSize [expr {$byteSize / 1024}]
	}

	set results [list]
	foreach size $sizes unit $units {
		if {$size == 0 || $size == ""} continue
		set results [linsert $results 0 "$size$unit"]
	}
	if {[llength $results] == 0} {
		return "0B"
	}
	return [join $results " "]
}

proc getTimeStamp {} {
	set msecs [clock milliseconds]
	set s [expr {$msecs / 1000}]
	set ms [expr {$msecs % 1000}]
	clock format $s -format "%H:%M:%S.$ms %d.%m.%Y"
}

set ::STD_CONTEXT_MENU ""
proc rememberWidgetForMenu {w} {
	set ::STD_CONTEXT_MENU $w
}

proc attachStdContextMenu {w} {
	bind $w <Button-$::RIGHT_BUTTON> "
		rememberWidgetForMenu $w
		tk_popup .stdTextContextMenu %X %Y
	"
}

proc stdContextMenu_copy {} {
	if {$::STD_CONTEXT_MENU == ""} return
	tk_textCopy $::STD_CONTEXT_MENU
	set ::STD_CONTEXT_MENU ""
}

proc stdContextMenu_cut {} {
	if {$::STD_CONTEXT_MENU == ""} return
	tk_textCut $::STD_CONTEXT_MENU
	set ::STD_CONTEXT_MENU ""
}

proc stdContextMenu_paste {} {
	if {$::STD_CONTEXT_MENU == ""} return
	tk_textPaste $::STD_CONTEXT_MENU
	set ::STD_CONTEXT_MENU ""
}

proc setupStdContextMenu {} {
	# Std Text Context Menu
	set m [menu .stdTextContextMenu -borderwidth 1 -activeborderwidth 1 -tearoff 0]
	$m add command -compound left -command stdContextMenu_copy -image img_copy -label [mc {Copy}]
	$m add command -compound left -command stdContextMenu_cut -image img_cut -label [mc {Cut}]
	$m add command -compound left -command stdContextMenu_paste -image img_paste -label [mc {Paste}]
}

proc reverseArray {arrayName newArrayName} {
	upvar $arrayName arr $newArrayName newArr
	array set newArr {}
	foreach idx [array names arr] {
		set newArr($arr($idx)) $idx
	}
}

#>
# @method unique
# Similar to [lsort -unique], except it doesn't change the order
#<
proc unique {strList} {
	set res [list]
	foreach str $strList {
		if {$res ni $res} {
			lappend res $str
		}
	}
	return $res
}

proc autoWrap {w msg {ratio 5}} {
	set f [$w cget -font]
	if {$f == ""} {
		set f "TkDefaultFont"
	}
	set hg [font metrics $f -ascent]
	set wd [font measure $f $msg]
	# The ratio around 5 is result of formula: i = int(floor(sqrt( x / (y*r) )))
	# where:
	#   'i' is the divisor to be used for width and also multiplier for height,
	#   'x' is width of original message,
	#   'y' is height of original message,
	#   'r' is ratio we're targeting ("width / height" ratio)
	# Result will be calculated for the ratio or a little grater (just to make divisor an integer value).
	set i [expr {int(floor(sqrt( $wd / ($hg * $ratio) )))}]

	if {$i == 0} {
		# We don't want to cause the end of the world, don't we?
		incr i
	}
	$w configure -wraplength [expr {$wd / $i}]
}

proc textIdxCompare {idx1 idx2} {
	lassign [split $idx1 .] l1 c1
	lassign [split $idx2 .] l2 c2

	if {$l1 < $l2} {
		return -1
	} elseif {$l1 > $l2} {
		return 1
	} elseif {$c1 < $c2} {
		return -1
	} elseif {$c1 > $c2} {
		return 1
	} else {
		return 0
	}
}

proc textIdxSort {idx1 idx2} {
	lsort -dictionary [list $idx1 $idx2]
}

proc playAnim {ms lbl img_list} {
	if {![winfo exists $lbl]} return

	set img [lindex [$lbl cget -image] end]
	set idx [lsearch -exact $img_list $img]
	incr idx
	if {$idx > [llength $img_list] - 1} {
		set idx 0
	}
	$lbl configure -image [lindex $img_list $idx]
	after $ms [list playAnim $ms $lbl $img_list]
}

proc genUniqueName {existingNames {prefix ""} {length 6}} {
	set name $prefix[randcrap $length]
	while {$name in $existingNames} {
		set name $prefix[randcrap $length]
	}
	return $name
}

proc genUniqueSeqName {existingNames {prefix ""}} {
	set name ${prefix}0
	for {set i 1} {$name in $existingNames} {incr i} {
		set name ${prefix}$i
	}
	return $name
}

# A test for error raised during [clipboard get -type UTF8_STRING] is to backward compatibility
# with older unixes. Modern unixes should support it.
if {$::tcl_platform(platform) eq "unix" && ![catch {clipboard get -type UTF8_STRING}]} {
	proc getClipboard {} {
		clipboard get -type UTF8_STRING
	}

	proc setClipboard {str} {
		clipboard clear
		clipboard append -type UTF8_STRING $str
	}
} else {
	proc getClipboard {} {
		clipboard get
	}

	proc setClipboard {str} {
		clipboard clear
		clipboard append $str
	}
}

proc isEmail {value} {
	regexp -- {^[a-zA-Z0-9._%+-]+\@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$} $value
}

proc wrapTextByChar {text font width} {
	set textWd [font measure $font $text]
	set allText $text
	set lines [list]
	while {$allText != ""} {
		set afterEndIndex [string length $allText]
		set avgCharWd [expr {double($textWd) / [string length $allText]}]
		set endIdx [expr {int(double($width) / $avgCharWd) - 2}]
		set line [string range $text 0 $endIdx]
		set textWd [font measure $font $line]
		
		# Shrink
		while {$textWd > $width} {
			incr endIdx -1
			set line [string range $allText 0 $endIdx]
			set textWd [font measure $font $line]
		}
		
		# Extend as much as possible
		while {$textWd < $width && $endIdx < $afterEndIndex} {
			incr endIdx
			set line [string range $allText 0 $endIdx]
			set textWd [font measure $font $line]
		}
		
		# If extended too much, go back
		if {$textWd >= $width} {
			incr endIdx -1
		}
		set line [string range $allText 0 $endIdx]
		lappend lines $line
		set allText [string range $allText [expr {$endIdx+1}] end]
	}
	return [join $lines \n]
}
