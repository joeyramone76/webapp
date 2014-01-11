class EnterpriseSqlFormattingPlugin {
	inherit SqlFormattingPlugin

	private {
		common _edit
		common _editWidget
		common _notebook ""
		common _previewSql
		common _widget

		proc createIndent {path}
		proc createNewlines {path}
		proc createSpaces {path}
		proc createNames {path}
		proc createComments {path}
		proc createFrameContents {path data previewSqlIndex}
		proc formatSqlInternal {originalQuery db}
		proc saveConfig {}
	}

	public {
		common wrappers [list "\[[mc {name}]\]" "\"[mc {name}]\"" "'[mc {name}]'" "`[mc {name}]` ([mc {SQLite3 only}])"]
		common config
		common uiVar

		method formatSql {tokenizedQuery originalQuery {db ""}}
		proc getName {}
		proc createConfigUI {path}
		proc applyConfig {path}
		proc configurable {}
		proc updateConfigState {}
		proc updatePreview {index}
		proc init {}
		proc tabChanged {}
	}
}

body EnterpriseSqlFormattingPlugin::init {} {
	uplevel #0 {
		# Loading rest of plugins files
		foreach pluginFile [glob -nocomplain -directory src/plugins/sql_formatting/enterprise *.tcl] {
			use $pluginFile
		}
	}

	array set _previewSql {
		indent {
			SELECT 5 BETWEEN (2 + 4) and (5 + 7) FROM a;
			SELECT t1.id, t1.value AS val, t2.*, (2 * t2.value) AS dbl FROM table1 t1 JOIN table2 AS t2 ON (t1.id = t2.id) WHERE t2.value > 50 ORDER BY t1.id DESC LIMIT 10, 5;
			CREATE UNIQUE INDEX IF NOT EXISTS dbName.ind1 ON [messages col] (id COLLATE x ASC, language DESC, description);
		}
		newlines {
			SELECT 2 IS NOT ( SELECT t1.u + t2.y FROM dfgdfg t1 JOIN dfgdfg t2 ON ( t1.dfgd = t2.dfgd ) ), (SELECT col1 FROM table1) AS col1 FROM table2;
			INSERT INTO table1 (id, value1, value2) VALUES (1, (2+5), (SELECT id FROM table2));
			SELECT t1.id, t1.value AS val, max(t2.col1, t2.col2), (2 * t2.value) AS dbl FROM table1 t1 JOIN table2 AS t2 ON (t1.id = t2.id) WHERE t2.value > 50 ORDER BY t1.id DESC LIMIT 10, 5;
			SELECT ( 2 + ( SELECT t1.u + t2.y FROM dfgdfg t1 JOIN dfgdfg t2 ON ( t1.dfgd = t2.dfgd ) ) ) FROM a;
			CREATE UNIQUE INDEX IF NOT EXISTS dbName.ind1 ON [messages col] (id COLLATE x ASC, language DESC, description);
		}
		spaces {
			SELECT ( 2 + ( SELECT t1.u + t2.y FROM dfgdfg t1 JOIN dfgdfg t2 ON ( t1.dfgd = t2.dfgd ) ) ) FROM a;
			SELECT t1.id, t1.value AS val, t2.*, (2 * t2.value) AS dbl FROM table1 t1 JOIN table2 AS t2 ON (t1.id = t2.id) WHERE t2.value > 50 ORDER BY t1.id DESC LIMIT 10, 5;
			CREATE UNIQUE INDEX IF NOT EXISTS dbName.ind1 ON [messages col] (id COLLATE x ASC, language DESC, description);
		}
		names {
			SELECT ( 2 + ( SELECT t1.u + t2.y FROM dfgdfg t1 JOIN dfgdfg t2 ON ( t1.dfgd = t2.dfgd ) ) ) FROM a;
			SELECT t1.[some id], t1.[strange "columne" name] AS val, t2.*, (2 * t2.value) AS dbl FROM "table with [square bracket] in name" t1 JOIN table2 AS t2 ON (t1.id = t2.id) WHERE t2.value > 50 ORDER BY t1.id DESC LIMIT 10, 5;
			CREATE TABLE tab (id integer primary key, value1 varchar(6), value2 number(8, 2));
		}
		comments "
			-- Comment 1
			SELECT column1 FROM table1; /* Comment 2 */
			/* Multiline comment\nexample */
		"
	}

	# TODO: rename ind_inside_of_parenthesis to ind_lists, because in fact it indents all lists
	foreach {varName val} [list \
		useUiVar							0 \
		ind_tabsize							4 \
		ind_lineup							1 \
		ind_inside_of_parenthesis			1 \
		ind_parenthesis						0 \
		nl_before_open_parenthesis_def		0 \
		nl_after_open_parenthesis_def		1 \
		nl_before_close_parenthesis_def		1 \
		nl_after_close_parenthesis_def		1 \
		nl_before_open_parenthesis_expr		0 \
		nl_after_open_parenthesis_expr		0 \
		nl_before_close_parenthesis_expr	0 \
		nl_after_close_parenthesis_expr		0 \
		nl_after_logical_blocks_of_query	1 \
		nl_after_comma						1 \
		nl_after_comma_in_func_args			0 \
		nl_after_semicolon					1 \
		nl_never_before_semicolon			1 \
		sp_before_comma						0 \
		sp_after_comma						1 \
		sp_before_open_parenthesis			1 \
		sp_after_open_parenthesis			1 \
		sp_before_close_parenthesis			1 \
		sp_after_close_parenthesis			1 \
		sp_before_dot_oper					0 \
		sp_after_dot_oper					0 \
		sp_before_math_oper					1 \
		sp_after_math_oper					1 \
		sp_never_before_semicolon			1 \
		nam_uppercase_keywords				1 \
		nam_uppercase_datatype_names		1 \
		nam_force_wrapper					0 \
		nam_preffered_wrapper				"" \
		com_expand_one_line					1 \
		com_indent_multiline				1 \
		com_star_indent_multiline			1 \
		nam_preffered_wrapper [lindex $wrappers 0] \
	] {
		if {![info exists config($varName)]} {
			set config($varName) $val
		}
	}
}

body EnterpriseSqlFormattingPlugin::formatSql {tokenizedQuery originalQuery {db ""}} {
	if {![catch {formatSqlInternal $originalQuery $db} res]} {
		return $res
	} else {
		error "Error while formatting SQL:\n$originalQuery\n\nDetails:\n\n$::errorInfo"
	}
}

body EnterpriseSqlFormattingPlugin::formatSqlInternal {originalQuery db} {
	# Initializing
	FormatStatement::reset

	# Determinating dialect
	set dialect "sqlite3"
	if {$db != ""} {
		set dialect [$db getDialect]
	}

	# Splitting queries
	set queries [SqlUtils::splitSqlQueries [string trimright [string trimright $originalQuery] ";"]]

	# Getting parser
	set parser [UniversalParser ::#auto $db]

	# Determinating configuration variable to use
	set configVar config
	if {[set ${configVar}(useUiVar)]} {
		set configVar uiVar
	}

	# Parsing SQL
	$parser configure -tolerateLacksForStdParsing true
	set sqls [list]
	set commentsSqls [list]
	foreach query $queries {
		set parsedDict [lindex [$parser parseSql $query] 0]
		if {[dict get $parsedDict returnCode] != 0} {
			debug "Error while parsing SQL for formatting process.\nParsed SQL: $query\nMessage from parser: [dict get $parsedDict errorMessage]\n"
			lappend sqls $query
		} else {
			set obj [dict get $parsedDict object]

			# Formatting
			set fmtStmt [FormatStatement::createGenericFormatStatement $obj]
			$fmtStmt setDialect $dialect
			set sql [$fmtStmt formatSql]
			if {[set ${configVar}(nl_never_before_semicolon)]} {
				set sql [string trimright $sql]
			}

			set commentsSql [$fmtStmt formatComments]
			if {$commentsSql != ""} {
				lappend commentsSqls $commentsSql
			}

			if {[string trim $sql] != ""} {
				lappend sqls $sql
			}
			delete object {*}[find objects * -isa FormatStatement]
		}
		$parser freeObjects
	}

	set sep ";"
	if {[set ${configVar}(nl_after_semicolon)]} {
		append sep "\n\n"
	}

	set sql ""
	if {[llength $commentsSqls] > 0} {
		append sql [join $commentsSqls \n]
		append sql "\n"
	}
	append sql "[string trimright [join $sqls $sep]$sep]\n"

	delete object $parser
	return $sql
}

body EnterpriseSqlFormattingPlugin::getName {} {
	return "Enterprise"
}

body EnterpriseSqlFormattingPlugin::createConfigUI {path} {
	array set uiVar [array get config]

	# Left
	set _notebook [ttk::notebook $path.nb]
	foreach {w label func} [list \
		indent [mc {Indentation}] createIndent \
		newlines [mc {New lines}] createNewlines \
		spaces [mc {White spaces}] createSpaces \
		names [mc {Names}] createNames \
		comments [mc {Comments}] createComments \
	] {
		set tab [ttk::frame $_notebook.$w]
		$_notebook add $tab -text $label
		$func $tab
	}
	pack $_notebook -side top -fill both -expand 1
	bind $_notebook <<NotebookTabChanged>> [list EnterpriseSqlFormattingPlugin::tabChanged]

	updateConfigState
}

body EnterpriseSqlFormattingPlugin::tabChanged {} {
	set idx [lindex [split [$_notebook select] .] end]
	updatePreview $idx
}

body EnterpriseSqlFormattingPlugin::updatePreview {index} {
	$_editWidget($index) configure -state normal
	set config(useUiVar) 1
	$_edit($index) setContents [formatSqlInternal $_previewSql($index) ""]
	set config(useUiVar) 0
	$_editWidget($index) configure -state disabled
}

body EnterpriseSqlFormattingPlugin::createFrameContents {path data previewSqlIndex} {
	ttk::panedwindow $path.pw -orient horizontal
	set left [ttk::frame $path.pw.l]
	set right [ttk::frame $path.pw.r]
	$path.pw add $path.pw.l -weight 2
	$path.pw add $path.pw.r -weight 3
	pack $path.pw -side top -fill both -expand 1

	foreach {w lab type} $data {
		ttk::frame $left.$w
		if {$type == "ttk::checkbutton"} {
			set _widget(edit:$w) [$type $left.$w.e -variable EnterpriseSqlFormattingPlugin::uiVar($w) -text $lab]
			pack $left.$w.e -side left -fill x
		} else {
			ttk::label $left.$w.l -text $lab
			set _widget(edit:$w) [$type $left.$w.e -textvariable EnterpriseSqlFormattingPlugin::uiVar($w)]
			pack $left.$w.l -side left
			pack $left.$w.e -side right
		}

		# Binding updatePreview
		switch -- $type {
			"ttk::combobox" {
				bind $left.$w.e <<ComboboxSelected>> [list EnterpriseSqlFormattingPlugin::updatePreview $previewSqlIndex]
			}
			"ttk::checkbutton" {
				$left.$w.e configure -command [list EnterpriseSqlFormattingPlugin::updatePreview $previewSqlIndex]
			}
			"ttk::spinbox" - "spinbox" {
				$left.$w.e configure -command [list EnterpriseSqlFormattingPlugin::updatePreview $previewSqlIndex] -validate all -validatecommand {validateInt %P}
			}
		}

		pack $left.$w -side top -fill x -padx 3 -pady 3
	}

	set _edit($previewSqlIndex) [SQLEditor $path.pw.r.edit]
	set _editWidget($previewSqlIndex) [$_edit($previewSqlIndex) getWidget]
	updatePreview $previewSqlIndex
	$_editWidget($previewSqlIndex) configure -state disabled -height 10 -width 60
	pack $_edit($previewSqlIndex) -side top -fill both -expand 1
}

body EnterpriseSqlFormattingPlugin::createIndent {path} {
	set list [list]
	lappend list ind_tabsize				[mc {Tab size:}]								ttk::spinbox
	lappend list ind_lineup					[mc {Line up keywords in multi-line queries}]	ttk::checkbutton
	lappend list ind_inside_of_parenthesis	[mc {Ident contents of parenthesis block}]		ttk::checkbutton
	lappend list ind_parenthesis			[mc {Ident parenthesis block in new line}]		ttk::checkbutton
	createFrameContents $path $list indent

	# Customization
	$_widget(edit:ind_tabsize) configure -from 0 -to 50
}

body EnterpriseSqlFormattingPlugin::createNewlines {path} {
	set list [list]
	lappend list nl_before_open_parenthesis_def		[mc {Before opening parenthesis in column definitions}]		ttk::checkbutton
	lappend list nl_after_open_parenthesis_def		[mc {After opening parenthesis in column definitions}]		ttk::checkbutton
	lappend list nl_before_close_parenthesis_def	[mc {Before closinging parenthesis in column definitions}]	ttk::checkbutton
	lappend list nl_after_close_parenthesis_def		[mc {After closinging parenthesis in column definitions}]	ttk::checkbutton
	lappend list nl_before_open_parenthesis_expr	[mc {Before opening parenthesis in expressions}]			ttk::checkbutton
	lappend list nl_after_open_parenthesis_expr		[mc {After opening parenthesis in expressions}]				ttk::checkbutton
	lappend list nl_before_close_parenthesis_expr	[mc {Before closinging parenthesis in expressions}]			ttk::checkbutton
	lappend list nl_after_close_parenthesis_expr	[mc {After closinging parenthesis in expressions}]			ttk::checkbutton
	lappend list nl_after_comma						[mc {After comma}]											ttk::checkbutton
	lappend list nl_after_comma_in_func_args		[mc {After comma in function arguments list}]				ttk::checkbutton
	#lappend list nl_after_logical_blocks_of_query	[mc {After logical block of query}]							ttk::checkbutton ;# makes no sense to allow disabling it
	lappend list nl_after_semicolon					[mc {After semicolon}]										ttk::checkbutton
	lappend list nl_never_before_semicolon			[mc {Never before semicolon}]								ttk::checkbutton
	createFrameContents $path $list newlines
}

body EnterpriseSqlFormattingPlugin::createSpaces {path} {
	set list [list]
	lappend list sp_before_comma				[mc {Before comma in lists}]							ttk::checkbutton
	lappend list sp_after_comma					[mc {After comma in lists}]								ttk::checkbutton
	lappend list sp_before_open_parenthesis		[mc {Before opening parenthesis}]						ttk::checkbutton
	lappend list sp_after_open_parenthesis		[mc {After opening parenthesis}]						ttk::checkbutton
	lappend list sp_before_close_parenthesis	[mc {Before closing parenthesis}]						ttk::checkbutton
	lappend list sp_after_close_parenthesis		[mc {After closing parenthesis}]						ttk::checkbutton
	lappend list sp_before_dot_oper				[mc {Before dot operator (in path to database object)}]	ttk::checkbutton
	lappend list sp_after_dot_oper				[mc {After dot operator (in path to database object)}]	ttk::checkbutton
	lappend list sp_before_math_oper			[mc {Before mathematical operator}]						ttk::checkbutton
	lappend list sp_after_math_oper				[mc {After mathematical operator}]						ttk::checkbutton
	lappend list sp_never_before_semicolon		[mc {Never before semicolon}]							ttk::checkbutton
	createFrameContents $path $list spaces
}

body EnterpriseSqlFormattingPlugin::createNames {path} {
	set name [mc {name}]
	set list [list]
	lappend list nam_uppercase_keywords			[mc {Uppercase keywords}]						ttk::checkbutton
	lappend list nam_uppercase_datatype_names	[mc {Uppercase datatype names}]					ttk::checkbutton
	lappend list nam_force_wrapper				[mc {Always use name wrapping}]					ttk::checkbutton
	lappend list nam_preffered_wrapper			[mc {Preferred name wrapper}]					ttk::combobox
	createFrameContents $path $list names

	# Customization
	$_widget(edit:nam_preffered_wrapper) configure -values $wrappers -state readonly

	set idx [lsearch -glob $wrappers "[string index [set EnterpriseSqlFormattingPlugin::config(nam_preffered_wrapper)] 0]*"]
	set EnterpriseSqlFormattingPlugin::uiVar(nam_preffered_wrapper) [lindex $wrappers $idx]

	#$path.nam_force_wrapper.e configure -command "[$path.nam_force_wrapper.e cget -command]; EnterpriseSqlFormattingPlugin::updateConfigState"
}

body EnterpriseSqlFormattingPlugin::createComments {path} {
	set list [list]
	lappend list com_expand_one_line			[mc {Expand one line comments (/* ... */) to multiline}]			ttk::checkbutton
	lappend list com_indent_multiline			[mc {Indent multi line comments}]									ttk::checkbutton
	lappend list com_star_indent_multiline		[mc {Use "*" character for each line}]								ttk::checkbutton
	createFrameContents $path $list comments

	# Customization
	#$_widget(edit:com_indent_multiline) configure -command "EnterpriseSqlFormattingPlugin::updateConfigState"
}

body EnterpriseSqlFormattingPlugin::updateConfigState {} {
	# Names
	#$_widget(edit:nam_preffered_wrapper) configure -state [expr {$uiVar(nam_force_wrapper) ? "readonly" : "disabled"}]

	# Comments
# 	if {$uiVar(com_indent_multiline)} {
# 		$_widget(edit:com_star_indent_multiline) configure -state "normal"
# 	} else {
# 		set uiVar(com_star_indent_multiline) 0
# 		$_widget(edit:com_star_indent_multiline) configure -state "disabled"
# 	}
}

body EnterpriseSqlFormattingPlugin::applyConfig {path} {
	array set config [array get uiVar]
	saveConfig
}

body EnterpriseSqlFormattingPlugin::configurable {} {
	return true
}

body EnterpriseSqlFormattingPlugin::saveConfig {} {
	set lst [list]
	foreach idx [array names config] {
		lappend lst EnterpriseSqlFormattingPlugin::config($idx) [set EnterpriseSqlFormattingPlugin::config($idx)]
	}
	CfgWin::save $lst
}
