#
# Tcl package index file
#
# Note sqlite*3* init specifically
#
package ifneeded sqlite3 3.7.16.1 \
    [list load [file join $dir libsqlite3.7.16.1.dylib] Sqlite3]
