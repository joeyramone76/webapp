set errIdx 1000

set ::ERRORCODE(requestedColumnDoesntExist) [incr errIdx]
set ::ERRORCODE(noQuoteCharacterPossible) [incr errIdx]
set ::ERRORCODE(canceled) [incr errIdx]
set ::ERRORCODE(cannotRecreateObject) [incr errIdx]

proc bgerror {msg} {
	# Locker for helpHint
	set ::FORBID_HELP_HINT 1

	# Finding out a thread
	set th [thread::id]
	if {$th == $::MAIN_THREAD} {
		set label "Main thread"
	} else {
		set label "Slave thread"
	}

	# Main part
	puts "------- Error -------"
	puts "Thread: $th ($label)"
	puts "$::errorInfo"
	#puts "Stack trace:"
	#printStackTrace
	puts "---------------------"
	set t .bgError
	if {[winfo exists $t]} {return}
	toplevel $t
	wm withdraw $t
	wm title $t [mc "Background error"]
	ttk::frame $t.d
	ttk::frame $t.u
	pack $t.d -side bottom -fill x
	pack $t.u -side top -fill both -expand 1

	ttk::button $t.d.close -text [mc "Close"] -command "destroy $t"
	pack $t.d.close -side right -pady 5 -padx 80
	ttk::button $t.d.report -text [mc {Report the bug}] -command \
		[list MAIN reportBug [lindex [split $::errorInfo "\n"] 0] "Stack trace:\n$::errorInfo"]
	pack $t.d.report -side left -pady 5 -padx 80

	text $t.u.txt -yscrollcommand "$t.u.s set" -height 30 -width 80 -background white -bd 1
	ttk::scrollbar $t.u.s -command "$t.u.txt yview" -orient vertical
	pack $t.u.txt -side left -fill both -expand 1
	pack $t.u.s -side right -fill y

	attachStdContextMenu $t.u.txt

	$t.u.txt insert end $::errorInfo
	$t.u.txt configure -state disabled
	bind $t.u.txt <1> {focus %W}
	wcenterby $t .
	::tk::SetFocusGrab $t $t.d.close
	wm transient $t .
	bind $t.d.close <Return> "destroy $t"
	bind $t.d.close <Escape> "destroy $t"
	wm deiconify $t

	bind $t <Destroy> "catch {unset ::FORBID_HELP_HINT}"

	# This is critical error and we need to get rid of eventual BusyDialog
	catch {BusyDialog::hide}
	catch {destroy .busyDialog} ;# Just to be sure
}
