use src/platform.tcl

if {[os] == "win32"} {

	# Re-associate file extensions to SQLiteStudio
	proc reAssocFiles {} {
		if {$::DISTRIBUTION != "binary"} return

		if {[catch {exec cmd /c assoc} cmdAssoc]} {
			debug "Error executing ASSOC: $cmdAssoc"
			return
		}
		if {[catch {exec cmd /c ftype} cmdFType]} {
			debug "Error executing FTYPE: $cmdFType"
			return
		}

		# Collecting current association list
		set associations [dict create]

		set assocTable [dict create]
		foreach assocLine [split $cmdAssoc \n] {
			set sp [split $assocLine =]
			dict set assocTable [lindex $sp 1] [lindex $sp 0]
		}

		set ftypeTable [dict create]
		foreach ftypeLine [split $cmdFType \n] {
			if {![string match -nocase "*sqlitestudio*.exe*" $ftypeLine]} {
				# Not associated
				continue
			}

			set idx [string first "=" $ftypeLine]
			set type [string range $ftypeLine 0 [expr {$idx - 1}]]
			set app [string range $ftypeLine [expr {$idx + 1}] end]

			dict set ftypeTable $type $app
			if {![dict exists $assocTable $type]} {
				continue
			}
			set ext [dict get $assocTable $type]
			dict lappend associations $ext [dict create ext $ext app $app delkey "" delvalue "" ftype $type]
		}

		package require registry 1.1
		set s "\\"
		set rootKey [join {HKEY_CURRENT_USER Software Microsoft Windows CurrentVersion Explorer FileExts} $s]
		foreach key [registry keys $rootKey ".*"] {
			if {"Application" in [registry values [join [list $rootKey $key] $s]]} {
				# WinXP
				set valueKey [join [list $rootKey $key] $s]
				set valueName "Application"
				set delkey $valueKey
				set delvalue $valueName
			} elseif {"Progid" in [registry values [join [list $rootKey $key] $s]]} {
				# WinXP - case 2
				set valueKey [join [list $rootKey $key] $s]
				set valueName "Progid"
				set delkey $valueKey
				set delvalue $valueName
			} elseif {"UserChoice" in [registry keys [join [list $rootKey $key] $s]] && "Progid" in [registry values [join [list $rootKey $key UserChoice] $s]]} {
				# Win 7 & Vista
				set valueKey [join [list $rootKey $key UserChoice] $s]
				set valueName "Progid"
				set delkey $valueKey
				set delvalue ""
			} else {
				continue
			}
			
			if {[catch {registry get $valueKey $valueName} app]} {
				continue
			}

			if {[string match -nocase "*sqlitestudio*.exe" $app]} {
				dict lappend associations $key [dict create ext $key app $app delkey $delkey delvalue $delvalue ftype ""]
			} elseif {[dict exists $ftypeTable $app]} {
				dict lappend associations $key [dict create ext $key app [dict get $ftypeTable $app] delkey $delkey delvalue $delvalue ftype ""]
			}
		}

		if {[llength $associations] == 0} {
			return
		}

		set d [AssocDialog .assoc -list $associations -title [mc {File associations}]]
		set newAssocList [$d exec]
		
		if {[llength $newAssocList] == 0} {
			return
		}
		
		set extensionsToAssoc [list]
		set problematicExtensions [list]
		set newApp "[file nativename $::argv0] %1 %*"
		set execApp [string map [list \\ \\\\] $newApp]
		dict for {ext assocList} $newAssocList {
			foreach assoc $assocList {
				set ftype [dict get $assoc ftype]
				set delkey [dict get $assoc delkey]

				if {$ftype != ""} {
					if {[catch {exec {*}[subst -nobackslashes -nocommands {cmd /c ftype ${ftype}=$execApp}]} err]} {
						debug "ftype error: $err"
						lappend problematicExtensions $ext
					}
				} elseif {$delkey != ""} {
					set name [dict get $assoc delvalue]
					if {[catch {registry delete $delkey $name} err]} {
						debug "registry delete error: $err"
						lappend problematicExtensions $ext
					} else {
						if {[catch {
							exec cmd /c assoc $ext=sqlitestudio
							exec {*}[subst -nobackslashes -nocommands {cmd /c ftype sqlitestudio=$execApp}]
						} err]} {
							debug "assoc/ftype error: $err"
							lappend problematicExtensions $ext
						} else {
							puts "file $ext to $execApp associated"
						}
					}
				} else {
					debug "Neither ftype or delkey is filled. This is unpexpected. Dict is: $assoc"
					continue
				}
			}
		}

		if {[llength $problematicExtensions] > 0} {
			MultiInfo \
				[list [mc "Following file extensions could not be associated to the current SQLiteStudio version:\n%s" [join $problematicExtensions ", "]] txt] \
				[list [mc {Click the link below to find out what is possible reason and solutions.}] txt] \
				[list $::AssocDialog::winAssocManualUrl link]
		}
	}

} ;# if win32
