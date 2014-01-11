use src/platform.tcl

set ::HINT_BG #FFFFDC
set ::HINT_FG #000000
set ::HINT_FONT "HintFont"
set ::HINT_JUST_DESTROYED 0

proc helpHint_onEnter {w msg {cmd "hint_aux"} {delay 700} {fastRespawn true}} {
	queueHint $w $msg $cmd $delay $fastRespawn
}

proc helpHint_onLeave {w msg {hintWidget ".hint_help"} {cmd "hint_aux"} {delay 700} {fastRespawn true}} {
	after cancel [list execHint $cmd $w $msg]
	if {[winfo exists $hintWidget]} {
		catch [list wm withdraw $hintWidget]
	}
	if {$fastRespawn} {
		set ::HINT_JUST_DESTROYED 1
		after 400 [list set ::HINT_JUST_DESTROYED 0]
	}
}

proc queueHint {w msg {cmd "hint_aux"} {delay 700} {fastRespawn true}} {
	if {$fastRespawn && $::HINT_JUST_DESTROYED} {
		set ::HINT_JUST_DESTROYED 0
		{*}$cmd $w $msg
	} else {
		after $delay [list execHint $cmd $w $msg]
	}
}

proc execHint {cmd w msg} {
	if {[catch {
		uplevel #0 "$cmd $w [list $msg]"
	}]} {
		debug "HelpHint error:\n$::errorInfo"
	}
}

#
# Standard hint
#
proc helpHint {w msg} {
	set msg [string map {% %%} $msg]
	bind $w <Enter> "+helpHint_onEnter $w [list $msg]"
	bind $w <Leave> "+helpHint_onLeave $w [list $msg] .hint_help"
	bind $w <ButtonPress-1> "+helpHint_onLeave $w [list $msg] .hint_help"
}

proc cancelHelpHint {w msg} {
	set msg [string map {% %%} $msg]

	helpHint_onLeave $w $msg

	set enter [bind $w <Enter>]
	set leave [bind $w <Leave>]
	set b1 [bind $w <ButtonPress-1>]
	bind $w <Enter> [string map [list "helpHint_onEnter $w [list $msg]" ""] $enter]
	bind $w <Leave> [string map [list "helpHint_onLeave $w [list $msg] .hint_help" ""] $leave]
	bind $w <ButtonPress-1> [string map [list "helpHint_onLeave $w [list $msg] .hint_help" ""] $b1]
}

proc updateHintContents {w msg} {
	if {![winfo exists $w]} return

	set t .hint_help
	if {![winfo exists $t]} return
	$t.l configure -text $msg
}

set t .hint_help
toplevel $t -background black -class Tooltip
if {[tk windowingsystem] eq "aqua"} {
    ::tk::unsupported::MacWindowStyle style $t help none
} else {
    wm overrideredirect $t 1
}
wm withdraw $t
pack [ttk::label $t.l -text "" -borderwidth 0 -background $::HINT_BG -foreground $::HINT_FG -justify left] \
	-fill both -padx 1 -pady 1 -ipadx 3 -ipady 1
catch {wm attributes $t -topmost 1}
wm positionfrom $t program

if {[os] == "win32"} {
	initHintShadow $t
}

proc hint_aux {w msg} {
	if {![winfo exists $w]} return

	set fc [focus]

	set t .hint_help
	if {[info exists ::FORBID_HELP_HINT] && $::FORBID_HELP_HINT == 1} return

	$t.l configure -text $msg -font $::HINT_FONT
	wm deiconify $t
	#wm transient $t $w

	set x [expr {[winfo pointerx $w]+20}]
	set y [expr {[winfo pointery $w]+10}]
	wm geometry $t +$x\+$y
	update idletasks

	set W [winfo reqwidth $t]
	set H [winfo reqheight $t]
	set screenW [winfo screenwidth $t]
	set screenH [winfo screenheight $t]

	set updateGeom 0
	if {$x + $W > $screenW} {
		set x [expr {$x - $W - 30}]
		set updateGeom 1
	}
	if {$y + $H > $screenH} {
		set y [expr {$y - $H - 15}]
		set updateGeom 1
	}
	if {$updateGeom} {
		wm geometry $t +$x\+$y
	}

	# Shadow for win32
	if {[os] == "win32"} {
		raiseHintShadow $t $x $y $W $H
	}

	after idle [focus $fc]
	bind $t <Enter> {after cancel {catch {wm withdraw .hint_help}}}
	bind $t <Leave> "catch {wm withdraw .hint_help}"
	bind $t <ButtonPress-1> "catch {wm withdraw .hint_help}"
	bind $t.l <ButtonPress-1> "catch {wm withdraw .hint_help}"
}

#
# Fancy hints
#

proc initFancyHelpHint {t} {
	toplevel $t -background black -class Tooltip
	if {[tk windowingsystem] eq "aqua"} {
		::tk::unsupported::MacWindowStyle style $t help none
	} else {
		wm overrideredirect $t 1
	}
	wm withdraw $t

	catch {wm attributes $t -topmost 1}
	wm positionfrom $t program

	if {[os] == "win32"} {
		initHintShadow $t
	}
}

proc raiseFancyHelpHint {hintPath cmd w data} {
	if {![winfo exists $w]} return

	set fc [focus]
	set container $hintPath.container
	catch {destroy $container}
	HintTable $container
	pack $container -fill both -expand 1 -padx 1 -pady 1

	eval $cmd

	set x [expr {[winfo pointerx $w]+20}]
	set y [expr {[winfo pointery $w]+10}]

	wm geometry $hintPath +$x\+$y
	wm deiconify $hintPath
	update idletasks

	set W [winfo reqwidth $hintPath]
	set H [winfo reqheight $hintPath]
	set screenW [winfo screenwidth $hintPath]
	set screenH [winfo screenheight $hintPath]

	set updateGeom 0
	if {$x + $W > $screenW} {
		set x [expr {$x - $W - 30}]
		set updateGeom 1
	}
	if {$y + $H > $screenH} {
		set y [expr {$y - $H - 15}]
		set updateGeom 1
	}
	if {$updateGeom} {
		wm geometry $hintPath +$x\+$y
	}

	# Shadow for win32
	if {[os] == "win32"} {
		raiseHintShadow $hintPath $x $y $W $H
	}

	after idle [focus $fc]

	bind $hintPath <Enter> [list after cancel [list catch [list wm withdraw $hintPath]]]
	bind $hintPath <Leave> [list catch [list wm withdraw $hintPath]]
	bind $hintPath <ButtonPress-1> [list catch [list wm withdraw $hintPath]]
}
