
if {[string first "-psn" [lindex $argv 0]] == 0} { set argv [lrange $argv 1 end]}

if [catch {source [file join [file dirname [info script]] app-sqlitestudio/main.tcl]}] {
set err [string map [list \" '] $errorInfo]
set err "Could not start SQLiteStudio because:\n$err"
set script "tell app \"System Events\" to display dialog \"$err\""
exec osascript -e $script &
puts $err
exit
}

