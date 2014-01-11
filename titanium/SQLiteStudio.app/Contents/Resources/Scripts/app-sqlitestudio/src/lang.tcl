proc autoDetectLanguage {} {
	switch -- [os] {
		"linux" - "solaris" - "freebsd" - "macosx" {
			set list [list LANG LANGUAGE LC_ALL LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES LC_PAPER \
				LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT LC_IDENTIFICATION]
			set locale "en"
			foreach idx [array names ::env] {
				if {$idx in $list && $::env($idx) != ""} {
					foreach langIdx [array names ::unixLangMap] {
						if {[string match $langIdx $::env($idx)]} {
							set locale [string tolower $::unixLangMap($langIdx)]
							break
						}
					}
				}
			}
		}
		"win32" {
			if {[catch {
				set hexLocale [registry get {HKEY_CURRENT_USER\Control Panel\International} Locale]
				set intLocale [scan $hexLocale %x]
			} err]} {
				debug "Problem while reading windows registry for autoDetectLanguage: $err"
				set locale "en"
			} elseif {[info exists ::winLangMap($intLocale)]} {
				set locale $::winLangMap($intLocale)
			} else {
				set locale "en"
			}
		}
	}
	return $locale
}

proc getLangLabels {{multiLang false}} {
	set results [dict create]
	foreach idx [array names ::langLabelsMap] {
		dict set results $idx $::langLabelsMap($idx)
	}
	return $results
}

proc getInitialLang {} {
	set autoDetected [autoDetectLanguage]
	set defIdx [lsearch -exact [array names ::langLabelsMap] $autoDetected]

	wm withdraw .
	set langLabels [getLangLabels true]
	LangDialog .defLang -message "Language:" -title "Language" -values [dict values $langLabels] \
		-index $defIdx -cancelbutton false
	set lang [.defLang exec]
	after idle [list wm deiconify .]

	if {$lang == ""} {
		set locale $autoDetected
	} else {
		set idx [lsearch -exact [dict values $langLabels] $lang]
		if {$idx > -1} {
			set locale [lindex [dict keys $langLabels] $idx]
		} else {
			set locale $autoDetected
		}
	}

	return $locale
}

