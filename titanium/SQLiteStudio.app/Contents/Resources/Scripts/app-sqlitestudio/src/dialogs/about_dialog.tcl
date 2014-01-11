use src/common/modal.tcl

#>
# @class AboutDialog
# Regular 'About' dialog with SQLiteStudio logo and some application description.
#<
class AboutDialog {
	inherit Modal

	#>
	# @var aboutFile
	# Absolute path to About file. It's different for source and binary distributions.
	#<
	common aboutFile "[pwd]/About.txt"
	common licenceFile "[pwd]/Licence.txt"
	common boldFont "TkTextFontBold"

	#>
	# @method constructor
	# @param args Options passed to {@class Modal}.
	# Default constructor. Initializes all contents.
	#<
	constructor {args} {
		eval Modal::constructor $args -modal 1 -resizable 1 -expandcontainer 1
	} {}

	private {
		variable _text ""
		variable _licence ""
		variable _pkgs ""
	}

	public {
		#>
		# @method okClicked
		# @overloaded Modal
		#<
		method okClicked {}

		#>
		# @method grabWidget
		# @overloaded Modal
		#<
		method grabWidget {}
	}
}

body AboutDialog::constructor {args} {
	ttk::frame $_root.u
	pack $_root.u -side top -fill both -expand 1

	# Logo on left side
	ttk::frame $_root.u.l
	pack $_root.u.l -side left -fill y

	ttk::label $_root.u.l.ico -image img_logo
	pack $_root.u.l.ico -side top -pady 20 -padx 10

	# Tabs
	set tabs [ttk::notebook $_root.u.tabs]
	$tabs add [ttk::frame $tabs.about] -text [mc {About}] -compound left -image img_about
	$tabs add [ttk::frame $tabs.pkgs] -text [mc {Packages and plugins}] -compound left -image img_plugin
	$tabs add [ttk::frame $tabs.licence] -text [mc {Licence}] -compound left -image img_licence

	# About tab
	set _text [text $tabs.about.txt -highlightthickness 0 -borderwidth 1 -relief solid -yscrollcommand "$tabs.about.s set" \
			-background ${::SQLEditor::background_color} -foreground ${::SQLEditor::foreground_color} \
			-selectbackground ${::SQLEditor::selected_background} -selectforeground ${::SQLEditor::selected_foreground} \
			-insertontime 500 -insertofftime 500 -selectborderwidth 0 -wrap word -width 90 -height 30 \
		]
	ttk::scrollbar $tabs.about.s -command "$tabs.about.txt yview"
	pack $_text -side left -fill both -expand 1
	pack $tabs.about.s -side right -fill y

	# Licence tab
	set _licence [text $tabs.licence.txt -highlightthickness 0 -borderwidth 1 -relief solid -yscrollcommand "$tabs.licence.s set" \
			-background ${::SQLEditor::background_color} -foreground ${::SQLEditor::foreground_color} \
			-selectbackground ${::SQLEditor::selected_background} -selectforeground ${::SQLEditor::selected_foreground} \
			-insertontime 500 -insertofftime 500 -selectborderwidth 0 -wrap word -width 90 -height 30 \
		]
	ttk::scrollbar $tabs.licence.s -command "$tabs.licence.txt yview"
	pack $_licence -side left -fill both -expand 1
	pack $tabs.licence.s -side right -fill y

	# Packages tab
	set _pkgs [text $tabs.pkgs.txt -highlightthickness 0 -borderwidth 1 -relief solid -yscrollcommand "$tabs.pkgs.s set" \
			-background ${::SQLEditor::background_color} -foreground ${::SQLEditor::foreground_color} \
			-selectbackground ${::SQLEditor::selected_background} -selectforeground ${::SQLEditor::selected_foreground} \
			-insertontime 500 -insertofftime 500 -selectborderwidth 0 -wrap word -width 90 -height 30 \
		]
	ttk::scrollbar $tabs.pkgs.s -command "$tabs.pkgs.txt yview"
	pack $_pkgs -side left -fill both -expand 1
	pack $tabs.pkgs.s -side right -fill y

	$_pkgs tag configure bold -font AboutBoldFont

	# Placing tabs
	pack $tabs -side right -fill both -expand 1

	# Bottom
	ttk::frame $_root.d
	pack $_root.d -side bottom -fill x

	ttk::button $_root.d.ok -text [mc "Close"] -command "$this clicked ok" -compound left -image img_ok
	pack $_root.d.ok -side top -pady 3

	eval itk_initialize $args

	# Feeding about
	set fd [open $aboutFile r]
	set data [read $fd]
	close $fd

	# Feeding pkgs
	set pkgsDict [MAIN getInstalledPackages]
	set pluginsList [MAIN getInstalledPlugins]

	$_pkgs insert end [mc {Installed plugins:}] bold
	$_pkgs insert end "\n"
	foreach plugin $pluginsList {
		$_pkgs insert end "$plugin\n"
	}
	$_pkgs insert end "\n"
	$_pkgs insert end [mc {Used Tcl packages:}] bold
	$_pkgs insert end "\n"
	foreach key [lsort -dictionary [dict keys $pkgsDict]] {
		set value [dict get $pkgsDict $key]
		$_pkgs insert end "[pad 40 {.} $key] $value\n"
	}

	# Feeding licence
	set fd [open $licenceFile r]
	set licenceData [read $fd]
	close $fd

	if {![catch {package present sqlite3} res]} {
		set sqlite3ver $res
	}

	$_text insert end $data
	if {[info exists sqlite3ver]} {
		$_text insert end "____________________\n\n"
		$_text insert end [mc {SQLite3 engine version: %s} $sqlite3ver]
		$_text insert end "\n"
	}
	$_text configure -state disabled

	$_licence insert end $licenceData
	$_licence configure -state disabled

	$_pkgs configure -state disabled
}

body AboutDialog::okClicked {} {
}

body AboutDialog::grabWidget {} {
	return $_root.d.ok
}
