rename ::tk_textPaste ::tk_textPaste.orig

# Modified version from original Tk, that does replace
# selected text while pasting under X11.
proc ::tk_textPaste w {
    if {![catch {::tk::GetSelection $w CLIPBOARD} sel]} {
	set oldSeparator [$w cget -autoseparators]
	if {$oldSeparator} {
	    $w configure -autoseparators 0
	    $w edit separator
	}
	catch { $w delete sel.first sel.last }
	$w insert insert $sel
	if {$oldSeparator} {
	    $w edit separator
	    $w configure -autoseparators 1
	}
    }
}

proc ComboListKeyPressed {w key} {
	if {[string length $key] > 1 && [string tolower $key] != $key} {
		return
	}

	set cb [winfo parent [winfo toplevel $w]]
	set text [string map [list {[} {\[} {]} {\]}] $key]
	if {[string equal $text ""]} {
		return
	}

	set values [$cb cget -values]
	set x [lsearch -glob -nocase $values $text*]
	if {$x < 0} {
		return
	}

	set current [$w curselection]
	if {$current == $x && [string match -nocase $text* [lindex $values [expr {$x+1}]]]} {
		incr x
	}

	$w selection clear 0 end
	$w selection set $x
	$w activate $x
	$w see $x
}

bind ComboboxListbox <KeyPress> [list ComboListKeyPressed %W %K]

# For [focus] debugging purpose only:
if {$::DEBUG(focus)} {
	rename ::focus ::focus.orig
	proc focus {args} {
		set stack [buildStackTrace]
		puts "FOCUS: focus $args"
		puts -nonewline "       "
		puts [join $stack "\n       "]
		puts ""
		uplevel [linsert $args 0 focus.orig]
	}
}

# Workaround for losing focus in subtabs when clicking first time on a tab (i.e. data tab)
# This is copied version of ActivateTab from original ttk sources,
# but with commented [update idletasks], which caused unwanted order of focus
proc ttk::notebook::ActivateTab {w tab} {
    set oldtab [$w select]
    $w select $tab
    set newtab [$w select] ;# NOTE: might not be $tab, if $tab is disabled

    if {[focus] eq $w} { return }
    if {$newtab eq $oldtab} { focus $w ; return }

    #update idletasks ;# needed so focus logic sees correct mapped states
    if {[set f [ttk::focusFirst $newtab]] ne ""} {
	ttk::traverseTo $f
    } else {
	focus $w
    }
}

# Workaround for TkTreeCtrl, so it doesn't expand/collapse when pressed "Return",
# while there's no toggle button active for the item.
bind TreeCtrl <KeyPress-Return> {
	set item [%W item id active]
	if {[%W item cget $item -button]} {
		%W item toggle $item
	}
}


# Wrapper for [after] command, so the return code 2 can be detected (bug 897)
# array set ::afterHandlerMapper {}
# proc afterHandler {callStack args} {
# 	unset ::afterHandlerMapper($args)
# 	set code [catch {uplevel #0 [join $args \n]} results]
# 	if {$code == 2} {
# 		set msg "\[after\] received code 2. Stack:\n"
# 		append msg [join $callStack \n]
# 		error $msg
# 	} else {
# 		return -code $code $results
# 	}
# }
# 
# rename after after.orig
# proc after {args} {
# 	set first [lindex $args 0]
# 	if {$first != "" && ([string is integer $first] || [string tolower $first] == "idle") && [llength $args] > 1} {
# 		set rest [lrange $args 1 end]
# 		set id [after.orig $first [list afterHandler [buildStackTrace] {*}$rest]]
# 		set ::afterHandlerMapper($rest) $id
# 		return $id
# 	} elseif {$first == "cancel"} {
# 		set rest [lrange $args 1 end]
# 		if {[info exists ::afterHandlerMapper($rest)]} {
# 			after cancel $::afterHandlerMapper($rest)
# 			unset ::afterHandlerMapper($rest)
# 		} else {
# 			return [after.orig {*}$args]
# 		}
# 	} else {
# 		return [after.orig {*}$args]
# 	}
# }
# 
# proc printAfterHandlerMapper {} {
# 	puts ""
# 	parray ::afterHandlerMapper
# 	after.orig 5000 printAfterHandlerMapper
# }
# if {$::DEBUG(global)} {
# 	printAfterHandlerMapper
# }
