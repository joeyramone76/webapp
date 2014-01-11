#!/usr/bin/env tclsh

set version 2.1.5

package provide sqlitestudio $version

# Fixing working directory
set ::startingDir [pwd]
cd [file dirname [info script]]
set ::applicationDir [pwd]

# Fixing cross platform option handling
set ::argv [linsert $::argv 0 "--"]
incr ::argc

# Defining distribution
if {![catch {package present starkit}]} {
	set ::DISTRIBUTION "binary"
	# Fixing argv0
	set argv0 [file join {*}[lrange [file split $argv0] 0 end-1]]
} else {
	set ::DISTRIBUTION "source"
}

# Debug mode
set ::DEBUG(re) no
set ::DEBUG(global) 0
set ::DEBUG(sql) 0
set ::DEBUG(parser) 0
set ::DEBUG(parser_tree) 0
set ::DEBUG(mc) 0
set ::DEBUG(use_update2) 0
set ::DEBUG(focus) 0

# Input args
set databasesToOpen [list]

proc printArgsHelp {} {
	upvar #0 optPrefix1 p1 optPrefix2 p2
	set msg ""
	append msg ".------------------------------------------------------------------\n"
	append msg "| SQLiteStudio (v$::version) \[http://sqlitestudio.pl]"
	append msg "|\n"
	append msg "| [mc {Command line syntax:}]\n"
	append msg "| $::argv0 \[[mc {options}]] \[[mc {database file to open}]] ...\n"
	append msg "|\n"
	append msg "| [mc {Supported options:}]\n"
	append msg "| --create, -c <file> - [mc {Creates new SQLite3 database and opens it.}]\n"
	append msg "| --debug, -d         - [mc {Enables debug messages on STDOUT.}]\n"
	append msg "| --localbugs <file>  - [mc {Bug reports goes to specified local file.}]\n"
	append msg "| --help, -h          - [mc {Prints this help.}]\n"
	append msg "| --tcllibs <paths>   - [mc {Adds specified directories to Tcl library path.}]\n"
	append msg "|                       [mc {The <paths> is in format: %s} path1:path2:path3:...]\n"
	append msg "| --plugins <dir>     - [mc {Specifies additional directory to look for plugins in it.}]\n"
	append msg "`------------------------------------------------------------------"
	if {$::tcl_platform(platform) == "windows"} {
		package require Tk
		wm title . SQLiteStudio
		ttk::label .l -text $msg -font TkFixedFont -background white
		pack .l -side top -fill both -expand 1
		ttk::button .b -text "Ok" -command "set ::readyToExit 1"
		wm protocol . WM_DELETE_WINDOW "set ::readyToExit 1"
		pack .b -side bottom -pady 5
		vwait ::readyToExit
	} else {
		puts $msg
	}
}

proc checkForOptionArg {arg} {
	if {$arg == ""} {
		return 0
	}
	if {[string match "-*" $arg]} {
		return 0
	}
	return 1
}

array set ::PKG {}
set ::PKG(msgcat) [package require msgcat 1.3]
namespace import msgcat::*

set ::pluginsDir ""
set ::localBugReports ""
set ::dbToCreate ""
set ::QUITTING 0
set ::firstStartAfterUpgrade 0
set ::WIN_GEOM_ZOOMED 0
set ::WIN_GEOM ""

for {set i 0} {$i < $argc} {incr i} {
	set opt [lindex $argv $i]
	if {[string match "-*" $opt]} {
		switch -- $opt {
			"-h" - "--help" {
				printArgsHelp
				exit 0
			}
			"-d" - "--debug" {
				set ::DEBUG(global) yes
			}
			"-c" - "--create" {
				incr i
				set arg [lindex $argv $i]
				if {![checkForOptionArg $arg]} {
					puts [mc {You have to specify database file after '%s' option.} $opt]
					exit 1
				}
				set ::dbToCreate $arg
			}
			"--tcllibs" {
				incr i
				set arg [lindex $argv $i]
				if {![checkForOptionArg $arg]} {
					puts [mc {You have to specify Tcl library path directories after '%s' option.} $opt]
					exit 1
				}
				lappend ::auto_path {*}[split $arg :]
			}
			"--plugins" {
				incr i
				set arg [lindex $argv $i]
				if {![checkForOptionArg $arg]} {
					puts [mc {You have to specify Tcl library path directories after '%s' option.} $opt]
					exit 1
				}
				set ::pluginsDir $arg
			}
			"--localbugs" {
				incr i
				set arg [lindex $argv $i]
				if {![checkForOptionArg $arg]} {
					puts [mc {You have to specify file name after '%s' option.} $opt]
					exit 1
				}
				set ::localBugReports $arg
			}
			"--update-step-2" {
				set ::firstStartAfterUpgrade 1
				incr i
				set arg [lindex $argv $i]
				after 1000 [list catch [list file delete -force $arg]]
				after 5000 [list catch [list file delete -force $arg]] ;# just to be sure
				after 10000 [list catch [list file delete -force $arg]] ;# just to be sure
			}
			"--check-lang" {
				incr i
				set arg [lindex $argv $i]
				if {![checkForOptionArg $arg]} {
					puts  "$argv0 --check-lang <locale>"
					exit 1
				}
				set ::argv [list $arg]
				set ::argc 1
				cd tools
				source -encoding utf-8 check_untranslated_lang.tcl
				exit 0
			}
			"--" {
				# Ignore
			}
			default {
				puts "Unknown option: $opt"
				printArgsHelp
				exit 0
			}
		}
	} elseif {$opt == ""} {
		# MacOSX can pass empty argument when running from boundle. Just skip it.
	} else {
		if {[file pathtype $opt] == "absolute"} {
			set dbFile $opt
		} else {
			set dbFile $::startingDir/$opt
		}
		if {![file readable $dbFile]} {
			puts [mc {File %s is not readable!} $dbFile]
			puts [mc {If you want to create new database, use '%s' option.} "-c"]
			puts [mc {Call '%s' to see help.} "$argv0 --help"]
			exit 1
		}
		lappend databasesToOpen $opt
	}
}

# Reseting argv so Tk won't parse it
set argv [list]
set argc 0

# Fix auto_path for OSX Boundle (binary distribution)
# Not using ::IS_BOUNDLE, becasue we cannot use [tk windowingsystem] yet (it depends on Tk package).
if {[string match "*/SQLiteStudio.app/Contents/MacOS/*" [info nameofexecutable]]} {
	set new_auto_path [list]
	foreach path $auto_path {
		# Exclude /Library, ~/Library and /System
		set idx [string first "/Library" $path]
		if {$idx == 0 || $idx == 1 || [string first "/System" $path] == 0} continue
		lappend new_auto_path $path
	}
	set auto_path $new_auto_path
	unset new_auto_path
	lappend auto_path ../../../lib ;# tclkit in the Boundle
}

# Lib paths
lappend auto_path ./lib
lappend auto_path ./lib/themes

# Basic extensions
set DB_SUPPORT(sqlite2) 1
set ::PKG(Tcl) [package require Tcl 8.5.11]
set ::PKG(Tk) [package require Tk 8.5.11]

# Mac OS X "Open With" and drop on dock icon support
if {[tk windowingsystem] == "aqua"} {
	proc ::tk::mac::OpenDocument {args} {
		set opt [lindex $args 0]
		if {[file pathtype $opt] == "absolute"} {
			set ::dbFile $opt
		} else {
			set ::dbFile $::startingDir/$opt
		}
		lappend ::databasesToOpen $::dbFile
	}
}

# Rest of extensions
set ::PKG(Itcl) [package require Itcl 3.4]
set ::PKG(Itk) [package require Itk 3.4]
if {[catch {
	set ::PKG(sqlite) [package require sqlite 2.0]
	rename sqlite sqlite2
}]} {
	set DB_SUPPORT(sqlite2) 0
	if {$::DEBUG(global)} {
		puts "No sqlite2 package found. Disabling SQLite2 support."
	}
}
set ::PKG(sqlite3) [package require sqlite3 3.7.11]
set ::PKG(treectrl) [package require treectrl 2.3.2]
set ::PKG(autoscroll) [package require autoscroll 1.1]
set ::PKG(csv) [package require csv 0.7.2]
set ::PKG(tdbf) [package require tdbf 0.5]
set ::PKG(md4) [package require md4]
set ::PKG(md5) [package require md5 1]
set ::PKG(sha1) [package require sha1 2]
set ::PKG(sha256) [package require sha256]
set ::PKG(crc16) [package require crc16]
set ::PKG(crc32) [package require crc32]
set ::PKG(uuencode) [package require uuencode]
set ::PKG(yencode) [package require yencode]
set ::PKG(http) [package require http 2.7]
if {[catch {
	set ::PKG(tkpng) [package require tkpng 0.7]
}]} {
	set ::PKG(img::png) [package require img::png 1.4] ;# An alternative
}
set ::PKG(Thread) [package require Thread]
set ::PKG(pdf4tcl) [package require pdf4tcl 0.8]
set ::PKG(tkdnd) [package require tkdnd 2.6]
namespace import itcl::*
namespace import itk::*
namespace import autoscroll::*

set ::httpUserAgent "SQLiteStudio WebBrowser"
::http::config -useragent $::httpUserAgent

tk appname SQLiteStudio

set ::IS_BOUNDLE [expr {
	[tk windowingsystem] == "aqua"
	&&
	[string match "*/SQLiteStudio.app/Contents/MacOS/*" [info nameofexecutable]]
}]

if {[encoding system] == "identity"} {
	encoding system utf-8
}

source src/common/debug.tcl

# [use] procedure
source -encoding utf-8 src/common/use.tcl

# Portable configuration directory
if {$::DISTRIBUTION == "binary"} {
	set portableCfgDir [file dirname [info nameofexecutable]]/sqlitestudio-cfg
} elseif {$::IS_BOUNDLE} {
	set portableCfgDir [file dirname [file dirname [file dirname [file dirname [info nameofexecutable]]]]]/sqlitestudio-cfg
} else {
	set portableCfgDir [file dirname [info script]]/sqlitestudio-cfg
}

# Platform depended code:
use src/platform.tcl
switch -- [os] {
	"linux" {
		ttk::setTheme clam
		set CFG_DIR "$env(HOME)/.sqlitestudio"
	}
	"freebsd" {
		ttk::setTheme clam
		set CFG_DIR "$env(HOME)/.sqlitestudio"
	}
	"solaris" {
		ttk::setTheme clam
		set CFG_DIR "$env(HOME)/.sqlitestudio"
	}
	"macosx" {
		ttk::setTheme aqua
		set CFG_DIR "$env(HOME)/.sqlitestudio"
	}
	"win32" {
		font configure TkFixedFont -size 11
		set dets [osDetails]
		set ver [dict get $dets version]
		switch -- $ver {
			"7" {
				ttk::setTheme vista
			}
			"vista" {
				ttk::setTheme vista
			}
			"2003" {
				ttk::setTheme winnative
			}
			"xp" {
				ttk::setTheme xpnative
			}
			"2000" {
				ttk::setTheme winnative
			}
			"nt" {
				ttk::setTheme winnative
			}
			"9x" {
				ttk::setTheme winnative
			}
		}
		switch -- $ver {
			"7" - "vista" - "2003" - "xp" - "2000" - "nt" {
				if {![info exists env(APPDATA)]} {
					set CFG_DIR [pwd]/sqlitestudio-cfg
					file mkdir $CFG_DIR
				} else {
					set CFG_DIR "$env(APPDATA)/sqlitestudio"
				}
			}
			"9x" {
				set CFG_DIR "$env(HOME)/sqlitestudio"
			}
		}
	}
}

if {[file isdirectory $portableCfgDir] && [file writable $portableCfgDir] && [file readable $portableCfgDir]} {
	set cfgOk 1
	foreach f [glob -directory $portableCfgDir *] {
		if {![file readable $f] || ![file writable $f]} {
			set cfgOk 0
		}
	}

	if {$cfgOk} {
		debug "Using portable configuration directory: $portableCfgDir"
		set CFG_DIR $portableCfgDir
	}
}

lappend auto_path $::CFG_DIR/lib

# Localized decimal point character
set ::DECIMAL_POINT [string index [expr {double(0)}] 1]

# Additional themes
array set ::THEME_VERSION {}
if {![catch {package require ttk::theme::tilegtk} res]} {
	set ::PKG(ttk::theme::tilegtk) $res
}
foreach theme [lsearch -inline -all -glob [package names] ttk::theme::*] {
	regsub -all -- {\:\:} $theme { } sp
	set themeName [lindex $sp end]
	if {![catch {package require $theme} themeVer]} {
		set ::THEME_VERSION($themeName) $themeVer
		set ::PKG($theme) $themeVer
	} else {
		debug "Error loading theme $theme:\n$themeVer"
	}
}

# Configuration directory
if {[catch {file mkdir $::CFG_DIR} res]} {
	Error [mc {Can't create %s directory. The reason is:\n%s. This directory is required.} $::CFG_DIR $res]
	exit 1
}

# Images
array set ::animated {}
foreach f [glob -directory img -nocomplain -tails *] {
	if {$f == "anim"} {
		# Animated images
		foreach f2 [glob -directory img/$f -tails *] {
			set ::animated($f2) [list]
			foreach f3 [lsort -dictionary [glob -directory img/$f/$f2 -tails *]] {
				set img img_${f2}_seq_[string range $f3 0 end-4]
				image create photo $img -file img/$f/$f2/$f3
				lappend ::animated($f2) $img
			}
		}
		continue
	}
	if {[file isdirectory img/$f]} {
		foreach f2 [glob -directory img/$f -tails *] {
			image create photo img_[string range $f2 0 end-4] -file img/$f/$f2
		}
	} else {
		image create photo img_[string range $f 0 end-4] -file img/$f
	}
}

image create photo img_logo -file logo.png

# Remember the main thread
set ::MAIN_THREAD [lindex [thread::names] 0]
if {$::DEBUG(global)} {
	puts "Main thread: $::MAIN_THREAD"
	puts "PID: [pid]"
}

# All threads shared data
tsv::set ::allThreads MAIN_THREAD $::MAIN_THREAD
tsv::set ::allThreads debug_global $::DEBUG(global)
tsv::set ::allThreads debug_parser $::DEBUG(parser)
tsv::set ::allThreads debug_parser_tree $::DEBUG(parser_tree)
tsv::set ::allThreads debug_re $::DEBUG(re)

# Whole application code
foreach f [glob -nocomplain -directory lib *.tcl] {
	use $f
}

set filesToOmmit {
	src/parser/parsing_routines_in_thread.tcl
	src/syntax_checking_thread.tcl
	src/db/convert_db.tcl
}
# 	src/parser/parser.tcl
# 	src/parser/sqlite_2.tcl
# 	src/parser/sqlite_3.tcl

foreach f [glob -nocomplain -directory src *] {
	if {$f in $filesToOmmit} continue
	if {[file isdirectory $f]} {
		foreach f2 [glob -nocomplain -directory $f *] {
			if {$f2 in $filesToOmmit} continue
			if {[string match -nocase "*.tcl" $f2]} {
				use $f2
			}
		}
	} else {
		if {[string match -nocase "*.tcl" $f]} {
			use $f
		}
	}
}

# Disallow to change app version, CFG_DIR and startDir
final version
final CFG_DIR
final startDir

# Loading plugins from application
foreach f [glob -nocomplain -directory src/plugins *] {
	if {[file isdirectory $f]} {
		foreach f2 [glob -nocomplain -directory $f *] {
			if {[string match -nocase "*.tcl" $f2]} {
				use $f2
			}
		}
	}
}

# Loading additional plugins from configuration directory
lappend ::auto_path $::CFG_DIR/plugins
foreach f [glob -nocomplain -directory $::CFG_DIR/plugins *] {
	if {[file isdirectory $f]} {
		foreach f2 [glob -nocomplain -directory $f *] {
			source -encoding utf-8 $f2
		}
	} elseif {[string match "*.tcl" $f]} {
		source -encoding utf-8 $f
	}
}

# Loading additional plugins directory passed in options (optionally)
if {$::pluginsDir != ""} {
	lappend ::auto_path $::pluginsDir
	foreach f [glob -nocomplain -directory $::pluginsDir *] {
		if {[file isdirectory $f]} {
			foreach f2 [glob -nocomplain -directory $f *] {
				source -encoding utf-8 $f2
			}
		} elseif {[string match "*.tcl" $f]} {
			source -encoding utf-8 $f
		}
	}
}

# Translations
foreach langIdx [array names ::langLabelsMap] {
	mclocale $langIdx
	mcload lang
	if {$startingDir != [pwd]} {
		# Support for "lang/" directory for binary distributions.
		mcload $startingDir/lang
	}
}

proc ::msgcat::mcunknown {locale srcstr args} {
	if {$::DEBUG(mc)} {
		puts stderr "Untranslated string for $locale: $srcstr"
	}
	return [eval format \$srcstr $args]
}

if {$::DEBUG(global) && [os] == "win32"} {
	console show
}

# Some initializations
GridHints::initHelpHint
DBTree::initHelpHint
MDIWin::init
TaskBar::Item::initHelpHint
initParserPool
initFonts

foreach class {
	PopulatingPlugin
	SqlFormattingPlugin
	ExportPlugin
	ImportPlugin
	SQLEditor
} {
	${class}::init
}
initDbFileTypes

# Toolbars visibility
set ::VIEW(main_toolbar) 1
set ::VIEW(struct_toolbar) 1
set ::VIEW(wins_toolbar) 1
set ::VIEW(tools_toolbar) 1
set ::VIEW(config_toolbar) 1
set ::MainToolbarOrder [list]

# Loading configuration
CfgWin::load

# Restoring theme
if {${::CfgWin::theme} != ""} {
	catch {ttk::setTheme ${::CfgWin::theme}}
}

# Restoring language
if {${::CfgWin::language} != ""} {
	mclocale ${::CfgWin::language}
} else {
	# No language stored yet
	set lang [getInitialLang]
	mclocale $lang
	set ::CfgWin::language $lang
	CfgWin::save [list ::CfgWin::language $lang]
}

# Now load the fsdialog package, as locale are set
set ::PKG(fsdialog) [package require fsdialog]

# DB handlers list
set ::DB_HANDLERS [list]
foreach cls [find classes] {
	if {[catch {namespace eval $cls {info inherit}} hier]} continue
	if {"::DB" in $hier} {
		lappend ::DB_HANDLERS $cls
	}
}

# First time language pick


# Starting up
setupStdContextMenu
MainWindow MAIN .mainWin
pack .mainWin -fill both -expand 1

# Mac specifig code
if {[tk windowingsystem] == "aqua"} {
	proc tkAboutDialog {} {
		MAIN about
	}

	proc ::tk::mac::ShowPreferences {} {
		MAIN openSettings
	}
}

# Opening databases passed in command line
set existingDbNames [list]
foreach db [DBTREE dblist] {
	lappend existingDbNames [$db getName]
}
foreach dbfile $databasesToOpen {
	set baseName [lindex [file split $dbfile] end]
	set name $baseName
	set i 1
	while {$name in $existingDbNames} {
		set name "$baseName ($i)"
	}
	set db [DBTREE addDB $name $dbfile 1]
	if {$db == ""} continue
	$db open
}
if {$::dbToCreate != ""} {
	set baseName [lindex [file split $::dbToCreate] end]
	set name $baseName
	set i 1
	while {$name in $existingDbNames} {
		set name "$baseName ($i)"
	}
	set createResults [Sqlite3::createDbFile $::dbToCreate]
	if {![dict get $createResults code]} {
		set res [dict get $createResults msg]
		Error [mc {Error while trying to create database: %s} $res]
	} else {
		set db [DBTREE addDB $name $::dbToCreate 1]
		$db open
	}
}

# Restoring order of tasks
Session::applyAllRestoredSession

# Fixing working directory for binary distribution
if {$::DISTRIBUTION == "binary"} {
	cd [file dirname [file dirname $argv0]]
}

# Memory profiling in debug
if {$::DEBUG(global)} {
	proc profile {} {
		set objs [find objects]
		puts [join [lsort -dictionary $objs] \n]
		puts [[lindex $objs end] info heritage]
	}
	bind . <F12> profile
}

# File association on windows
if {$::firstStartAfterUpgrade && [os] == "win32"} {
	reAssocFiles
}

# rename focus focus.orig
# proc focus {args} {
# 	puts "focus $args, at: [join [lrange [buildStackTrace] 0 2] \n]\n---"
# 	focus.orig {*}$args
# }
# 
# rename raise raise.orig
# proc raise {args} {
# 	puts "raise $args, at: [join [lrange [buildStackTrace] 0 2] \n]\n---"
# 	raise.orig {*}$args
# }
# 
# rename lower lower.orig
# proc lower {args} {
# 	puts "lower $args, at: [join [lrange [buildStackTrace] 0 2] \n]\n---"
# 	lower.orig {*}$args
# }

# List of all global objects:
# DBTREE		- DBTree singleton instance.
# MAIN			- MainWindow singleton instance.
# TASKBAR		- TaskBar instance.
# INTERP_POOL	- InterpPool instance.
