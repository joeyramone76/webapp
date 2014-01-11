use src/parser/debug_tree.tcl

set ::PARSER_POOL ""

proc initParserPool {} {
	set ::PARSER_POOL [tpool::create -minworkers 2 -maxworkers 2 -idletime 60 \
		-initcmd [string map [list \
			%APP_DIR% [list $::applicationDir] \
			%DEBUG_TREE% $::PARSER_DEBUG_TREE \
			%DEBUG_OPTS% [array get ::PARSER_DEBUG_TREE_OPTS] \
		] {
			cd [file nativename %APP_DIR%]
			set ::PARSER_DEBUG_TREE [list %DEBUG_TREE%]
			array set ::PARSER_DEBUG_TREE_OPTS [list %DEBUG_OPTS%]
			if {[catch {
				source src/parser/parsing_routines_in_thread.tcl
			} err]} {
				error "Error while starting error checking thread: $err\n"
			}
		}]]
}
