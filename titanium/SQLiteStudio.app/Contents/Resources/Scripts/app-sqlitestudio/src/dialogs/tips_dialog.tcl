use src/common/modal.tcl

#>
# @class TipsDialog
# This is implementation of 'Did you know that...' dialog.
#<
class TipsDialog {
	inherit Modal

	#>
	# @method constructor
	# @param args Options passed to {@class Modal}.
	# Default constructor. Initializes all contents.
	#<
	constructor {args} {
		eval Modal::constructor $args -modal 0
	} {}

	#>
	# @method destructor
	# Saves 'Do not show this dialog' value in configuration.
	#<
	destructor {}

	private {
		#>
		# @var hide
		# If <code>true</code> then this dialog will not be shown at application sturtup,
		# <code>false</code> if dialog will be shown.
		#<
		common hide 0

		#>
		# @arr tip
		# Array of tips displayed in this dialog. It's filled by {@method createTipsList} method.
		#<
		common tip

		#>
		# @var _text
		# Contents text widget.
		#<
		variable _text ""

		#>
		# @var currTip
		# Number of current tip, casted from whole list at object creation.
		#<
		variable currTip
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

		#>
		# @method next
		# Switches dialog contents to next tip.
		#<
		method next {}

		#>
		# @method prev
		# Switches dialog contents to previous tip.
		#<
		method prev {}

		#>
		# @method createTipsList
		# Creates list of tips. Body of this message contains all tips.
		# It's called by some parent object, like {@class MainWindow}.
		#<
		proc createTipsList {}
	}
}

body TipsDialog::constructor {args} {
	ttk::frame $_root.u
	pack $_root.u -side top -fill both

	ttk::frame $_root.u.u
	pack $_root.u.u -side top -fill x

	frame $_root.u.u.imgbg -background white -border 0
	pack $_root.u.u.imgbg -fill x -expand 1 -side left

	label $_root.u.u.imgbg.img -image img_didyouknow -border 0 -highlightthickness 0
	pack $_root.u.u.imgbg.img -side left

	ttk::frame $_root.u.t
	set _text [text $_root.u.t.txt -highlightthickness 0 -borderwidth 1 -relief solid -yscrollcommand "$_root.u.t.s set" \
			-background ${::SQLEditor::background_color} -foreground ${::SQLEditor::foreground_color} \
			-selectbackground ${::SQLEditor::selected_background} -selectforeground ${::SQLEditor::selected_foreground} \
			-insertontime 500 -insertofftime 500 -selectborderwidth 0 -wrap word -width 60 -height 15 \
		]
	ttk::scrollbar $_root.u.t.s -command "$_root.u.t.txt yview"
	autoscroll $_root.u.t.s
	pack $_text -side left -fill both -expand 1
	pack $_root.u.t.s -side right -fill y
	pack $_root.u.t -side top -fill both

	# Next / Prev
	ttk::frame $_root.sw
	pack $_root.sw -side top -fill x

	ttk::button $_root.sw.prev -text "  [mc {Previous}]" -command "$this prev" -compound left -image img_left_arrow_btn
	pack $_root.sw.prev -side left -pady 10 -padx 10

	ttk::button $_root.sw.next -text "[mc {Next}]  " -command "$this next" -compound right -image img_right_arrow_btn
	pack $_root.sw.next -side right -pady 10 -padx 10

	# Close button
	ttk::frame $_root.d
	pack $_root.d -side bottom -fill x

	ttk::button $_root.d.ok -text [mc "Close"] -command "$this clicked ok" -compound left -image img_ok
	pack $_root.d.ok -side right -pady 3 -padx 10

	ttk::checkbutton $_root.d.hide -text [mc {Do not show this dialog at startup}] -variable TipsDialog::hide
	pack $_root.d.hide -side right -pady 3 -padx 10

	eval itk_initialize $args

	# Contents
	set currTip [rand [llength [array names tip]]]
	set data $tip([lindex [array names tip] $currTip])

	$_text insert end $data
	$_text configure -state disabled
}

body TipsDialog::destructor {} {
	CfgWin::save [list ::TipsDialog::hide $hide]
}

body TipsDialog::okClicked {} {
}

body TipsDialog::grabWidget {} {
	return $_root.d.ok
}

body TipsDialog::next {} {
	$_text configure -state normal
	$_text delete 1.0 end
	incr currTip
	if {[lindex [array names tip] $currTip] == ""} {
		set currTip 0
	}
	$_text insert end $tip([lindex [array names tip] $currTip])
	$_text configure -state disabled
}

body TipsDialog::prev {} {
	$_text configure -state normal
	$_text delete 1.0 end
	incr currTip -1
	if {$currTip == -1} {
		set currTip [expr {[llength [array names tip]]-1}]
	}
	$_text insert end $tip([lindex [array names tip] $currTip])
	$_text configure -state disabled
}

body TipsDialog::createTipsList {} {
	set i 0
	foreach txt [list \
		[mc {
			If you dislike to open multiple SQL editors, you can use single editor,
			write a lot of SQL in it and finally select (mark) only this part of code you want to execute,
			then press Execute SQL.
		}] \
		[mc {
			You can configure all SQL editor syntax colors in settings.
		}] \
		[mc {
			Valid table names in SQL editor are highlighted with blue color (configurable).
			If a table name you expect to be highlighted - is not, it means that you've made a mistake when typing the name,
			or you've got selected other context database in SQL editor (at the top of editor window),
			where that table doesn't exist.<br><br>
			You can also press and hold Control key to underline valid table names - they become links so you can
			open adequate table windows quickly.
		}] \
		[mc {
			You can use Control+Space shortcut (configurable) to complete word you've started typing in SQL editor.
			Completion engine can also guess next word by a SQL context and show you filtered list of words matching that context.
		}] \
		[mc {
			There are various shortcuts (all of them are configurable) that can make using SQLiteStudio much easier
			and faster.
		}] \
		[mc {
			You do not have to confirm each edition in data grid by pressing Enter or "Commit" button at toolbar.
			You can just click on any other cell (or anywhere else) to make edited data commit by itself.
			To rollback changes done while editing cell - press Escape.<br><br>
		}] \
		[mc {
			If you close SQLiteStudio with any MDI windows opened, they all will be restored (including SQL code typed in editors),
			while next application startup, unless you disable "session restoring" in settings.
		}] \
		[mc {
			SQLiteStudio provides some extra SQLite functions that you can use in SQL editor. These are:
			tcl() - runs custom Tcl code in new, separated Tcl interpreter,<br>
			sqlfile() - executes SQL from given file in current database,<br>
			md5() - calculates MD5 checksum of given argument,<br>
			base64_encode() - encodes given argument with BASE64 algorithm,<br>
			base64_decode() - decodes given argument with BASE64 algorithm,<br>
			for more functions see User Manual.<br>
			Examples:<br><br>
			<tab>SELECT tcl('return [expr {pow(5,5)} ]') AS '5 to power 5';<br><br>
			<tab>SELECT sqlfile('C:/schema.sql');<br><br>
		}] \
		[mc {
			You can define your own SQL functions that will be available in database while editing it with SQLiteStudio.
			It helps to emulate functions implemented in target application which uses the database.<br>
			To implement new function go to Custom SQL functions dialog and push add button (one with plus icon on it),
			then enter it's name and choose language you want to use to implement function (Tcl or SQL).<br>
			Implementation code can contain $0, $1, $2 and so on - they are positional parameters passed to function when it's invoked.<br><br>
			Here's example function implementation code using SQL:<br>
			<tab>SELECT 2 * id FROM table_name WHERE id = $1;
			<br><br>
			And here's one implemented with Tcl:<br>
			<tab>set fd [open filename r]<br>
			<tab>set data [read $fd]<br>
			<tab>close $fd<br>
			<tab>return $data
		}] \
		[mc {
			If you're looking for some word in table data, but you don't want to write SQL for it, or just don't remember
			which column contains this word, go to table data view, type the word in filter entry and push "Apply filter".
			It will find all occurances of the word (even with prefixes or suffixes) in any
			column and table data will be filtered to these matched entries only.
		}] \
		[mc {
			You can edit values in results grid, but be aware that columns that doesn't come from a table directly (for example they are result of math operations on column) - cannot be edited.
			Such uneditable cells are also ommited when some data has been pasted into the grid.
		}] \
		[mc {
			If you want to see ROWID of some specific row, you can just leave your mouse pointer over the row you're insterested in for a moment.
			The tip will pop up with ROWID (and other informations) for that row.<br><br>
			In data grid view of table window you can switch displaying ROWID instead of order number in first column. This option is available from grid view context menu.
		}] \
		[mc {
			To put NULL value to a cell (not just empty value) you need to use either Backspace key while cell is selected, or select "Set NULL value" from grid view context menu.<br>
			You can do above while having multiple cells selected.<br><br>
			Form View lets you to set NULL value for each cell separately using checkbox or Alt-n shortcut (which is configurable).<br><br>
			Remember that you can always set NULL value manually using SQL query.
		}] \
		[mc {
			You can place results of executed query below actual query, instead of switching to next tab. Just switch SQL Editor window layout in Configuration window.
		}] \
		[mc {
			You can always get back to queries you've executed before by switching to history tab in SQL Editor window.<br><br>
			Number of entries kept in history is configurable, but be aware, that if that value is too high, then each time you will open new SQL Editor
			the whole history will be read and it might slowdown the opening process a little.
		}] \
		[mc {
			SQL Editor window can help you with writting queries - press Control+Space (or whatever shortcut you've configured) in the window to raise query completion dialog.
		}] \
		[mc {
			You can use multiple database names in single SQL query without taking care of attaching them into current database.
			SQLiteStudio will handle it for you.<br><br>
			Use database names as displayed in databases tree on the left side. An example:<br>
			<tab>SELECT t1.*, t2.* FROM table1 t1 JOIN other_database.table2 t2 ON (t1.id = t2.id);
		}] \
		[mc {
			You can hold "Control" key and click on the data grid to select entire row, instead of a single cell.
		}] \
		[mc {
			In SQL Editor window you can select just a part of the SQL query and click "Execute" (or press %s)
			to execute only selected part of the code.
		} $::Shortcuts::executeSql] \
	] {
		set txt [string map [list \t "" \n " " "<br>" \n] [string trim $txt]]
		regsub -all -- {\n[ \t]+} $txt "\n" tip($i)
		set tip($i) [string map [list <tab> "  "] $tip($i)]
		incr i
	}
}
