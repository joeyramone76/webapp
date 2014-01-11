use src/plugins/export_plugin.tcl

class HtmlExportPlugin {
	inherit ExportPlugin

	constructor {} {}

	common styleContents ""

	private {
		variable _header 0
		variable _rownum 0
		variable _num 0
		variable _fullnames 0
		variable _types 0
		variable _encoding [encoding system]

		method getStyle {}
	}

	public {
		variable checkState

		proc getName {}
		proc configurable {context}
		proc isContextSupported {context}
		method createConfigUI {path context}
		method applyConfig {path context}
		method validateConfig {context}
		method exportResults {columns totalRows}
		method exportResultsRow {cellsData columns}
		method exportResultsEnd {}
		method exportTable {name columns ddl totalRows}
		method exportTableRow {cellsData columns}
		method exportTableEnd {name}
		method exportIndex {name table columns unique ddl}
		method exportTrigger {name table when event condition code ddl}
		method exportView {name code ddl}
		method updateState {path}
		method exportFileSchema {context}
		method getEncoding {}
		method autoFileExtension {}
	}
}

body HtmlExportPlugin::constructor {} {
	foreach w {
		header
		rownum
		fullnames
		types
		encoding
	} {
		set checkState($w) [set _$w]
	}
}

body HtmlExportPlugin::getName {} {
	return "HTML"
}

body HtmlExportPlugin::autoFileExtension {} {
	return ".html"
}

body HtmlExportPlugin::getEncoding {} {
	return $_encoding
}

body HtmlExportPlugin::configurable {context} {
	return true
}

body HtmlExportPlugin::createConfigUI {path context} {
	foreach {w label hint} [list \
		header [mc {Column names as first row}] [mc "First row of exported data will be header\nwith names of columns, just like in results grid."] \
		rownum [mc {Row numbers as first column}] [mc "First column of exported data\nwill contain row order number."] \
		fullnames [mc {Full column names}] [mc {Column names in header will be prepended with "table_name." prefix.}] \
		types [mc {Show types}] [mc {Column headers will contain data types.}] \
	] {
		set checkState($w) [set _$w]
		ttk::frame $path.$w
		ttk::checkbutton $path.$w.c -text $label -variable [scope checkState($w)]
		helpHint $path.$w.c $hint
		pack $path.$w -side top -fill x -padx 2 -pady 2
		pack $path.$w.c -side left
	}
	$path.header.c configure -command [list $this updateState $path]

	# Encoding
	set w enc
	ttk::frame $path.$w
	ttk::label $path.$w.l -text [mc {Encoding:}]
	ttk::combobox $path.$w.c -values [lsort -dictionary [encoding names]] -state readonly -textvariable [scope checkState(encoding)]
	pack $path.$w -side top -fill x -padx 2 -pady 2
	pack $path.$w.l -side left
	pack $path.$w.c -side right

	updateState $path
}

body HtmlExportPlugin::applyConfig {path context} {
	foreach {w} [list header rownum fullnames types encoding] {
		set _$w $checkState($w)
	}
}

body HtmlExportPlugin::exportResults {columns totalRows} {
	# Body
	write "		<TABLE>\n"
	if {$_header} {
		write "			<TR class=\"header\">\n"
		if {$_rownum} {
			write "				<TD align=\"right\">\n"
			write "					<B><I>#</I></B>\n"
			write "				</TD>\n"
		}
		foreach c $columns {
			set table [dict get $c table]
			set name [dict get $c column]
			set type [dict get $c type]
			write "				<TD>\n"
			set column "<B>"
			if {$_fullnames && $name != "" && $table != ""} {
				append column "<font color=\"#777777\">$table.</font>$name</B>\n"
			} else {
				if {$name == ""} {
					set name $table
				}
				append column "$name</B>\n"
			}
			if {$_types} {
				if {$type == ""} {
					set type [mc {no type}]
				} else {
					set type [string toupper $type]
				}
				append column "<BR>($type)\n"
			}
			write "					$column\n"
			write "				</TD>\n"
		}
		write "			</TR>\n"
	}

	set _num 1
}

body HtmlExportPlugin::exportResultsRow {cellsData columns} {
	write "			<TR>\n"
	if {$_rownum} {
		write "				<TD class=\"rownum\">\n"
		write "					<I>$_num</I>\n"
		write "				</TD>\n"
		incr _num
	}
	foreach cell $cellsData c $columns {
		set type [dict get $c type]
		lassign $cell cellValue isNull
		set ct [lindex [regexp -inline -- {(?i)(\w+)(\s*\(.*\))?} $type] 1]
		set ct [string toupper $ct]
		if {$ct in $::dataTypes_numeric} {
			set align right
		} else {
			set align left
		}
		if {$isNull} {
			set cellValue "<i>NULL</i>"
			set cellStyle " class=\"null\""
		} else {
			set cellStyle ""
			set cellValue [escapeHTML $cellValue]
			if {[string length [string trim $cellValue]] == 0} {
				set cellValue "&nbsp;"
			}
		}
		write "				<TD align=\"$align\"$cellStyle>\n"
		write "					$cellValue\n"
		write "				</TD>\n"
	}
	write "			</TR>\n"
}

body HtmlExportPlugin::exportResultsEnd {} {
	write "		</TABLE>\n"
	write "		<BR><BR>\n"
}

body HtmlExportPlugin::exportTable {name columns ddl totalRows} {
	# Body
	write "		<TABLE>\n"

	set lgt [llength $columns]
	write "			<TR class=\"title\">\n"
	write "				<TD colspan=\"[expr {$_rownum ? $lgt+1 : $lgt}]\" align=\"center\">\n"
	write "					[mc {Table: %s} <B>$name</B>]\n"
	write "				</TD>\n"
	write "			</TR>\n"

	if {$_header} {
		write "			<TR class=\"header\">\n"
		if {$_rownum} {
			write "				<TD align=\"right\">\n"
			write "					<B><I>#</I></B>\n"
			write "				</TD>\n"
		}
		foreach c $columns {
			lassign $c colName type pk notnull dflt_value
			write "				<TD>\n"
			set column "<B>"
			if {$_fullnames && $name != ""} {
				append column "<font color=\"#777777\">$name.</font>"
			}
			append column "$colName</B>\n"
			if {$_types} {
				if {$type == ""} {
					set type [mc {no type}]
				} else {
					set type [string toupper $type]
				}
				append column "<BR>($type)\n"
			}
			write "					$column\n"
			write "				</TD>\n"
		}
		write "			</TR>\n"
	}

	set _num 1
}

body HtmlExportPlugin::exportTableRow {cellsData columns} {
	write "			<TR>\n"
	if {$_rownum} {
		write "				<TD class=\"rownum\">\n"
		write "					<I>$_num</I>\n"
		write "				</TD>\n"
		incr _num
	}
	foreach cell $cellsData c $columns {
		lassign $c name type pk notnull dflt_value
		lassign $cell cellValue isNull
		set ct [lindex [regexp -inline -- {(?i)(\w+)(\s*\(.*\))?} $type] 1]
		set ct [string toupper $ct]
		if {$ct in $::dataTypes_numeric} {
			set align right
		} else {
			set align left
		}
		if {$isNull} {
			set cellValue "<i>NULL</i>"
			set cellStyle " class=\"null\""
		} else {
			set cellStyle ""
			set cellValue [escapeHTML $cellValue]
			if {[string length [string trim $cellValue]] == 0} {
				set cellValue "&nbsp;"
			}
		}
		write "				<TD align=\"$align\"$cellStyle>\n"
		write "					$cellValue\n"
		write "				</TD>\n"
	}
	write "			</TR>\n"
}

body HtmlExportPlugin::exportTableEnd {name} {
	write "		</TABLE>\n"
	write "		<BR><BR>\n"
}

body HtmlExportPlugin::exportIndex {name table columns unique ddl} {
	write "		<TABLE>\n"
	write "			<TR class=\"title\">\n"
	write "				<TD align=\"center\" colspan=\"3\">\n"
	write "					[mc {Index: %s} <B>$name</B>]\n"
	write "				</TD>\n"
	write "			</TR>\n"
	write "			<TR>\n"
	write "				<TD align=\"right\" class=\"rownum\">\n"
	write "					[mc {For table:}]\n"
	write "				</TD>\n"
	write "				<TD colspan=\"2\">\n"
	write "					$table\n"
	write "				</TD>\n"
	write "			</TR>\n"
	write "			<TR>\n"
	write "				<TD align=\"right\" class=\"rownum\">\n"
	write "					[mc {Unique:}]\n"
	write "				</TD>\n"
	write "				<TD colspan=\"2\">\n"
	write "					[expr {$unique ? [mc {Yes}] : [mc {No}]}]\n"
	write "				</TD>\n"
	write "			</TR>\n"
	write "			<TR class=\"header\">\n"
	write "				<TD>\n"
	write "					<B>[mc {Column}]</B>\n"
	write "				</TD>\n"
	write "				<TD>\n"
	write "					<B>[mc {Collating}]</B>\n"
	write "				</TD>\n"
	write "				<TD>\n"
	write "					<B>[mc {Sort order}]</B>\n"
	write "				</TD>\n"
	write "			</TR>\n"

	foreach col $columns {
		lassign $col colName collation sorting
		write "			<TR>\n"
		write "				<TD>\n"
		write "					[escapeHTML $colName]\n"
		write "				</TD>\n"
		if {$collation != ""} {
			write "				<TD align=\"center\">\n"
			write "					$collation\n"
			write "				</TD>\n"
		} else {
			write "				<TD>\n"
			write "					&nbsp;\n"
			write "				</TD>\n"
		}
		if {$sorting != ""} {
			write "				<TD align=\"center\">\n"
			write "					$sorting\n"
			write "				</TD>\n"
		} else {
			write "				<TD>\n"
			write "					&nbsp;\n"
			write "				</TD>\n"
		}
		write "			</TR>\n"
	}

	write "		</TABLE>\n"
	write "		<BR><BR>\n"
}

body HtmlExportPlugin::exportTrigger {name table when event condition code ddl} {
	write "		<TABLE>\n"
	write "			<TR class=\"title\">\n"
	write "				<TD align=\"center\" colspan=\"2\">\n"
	write "					[mc {Trigger: %s} <B>$name</B>]\n"
	write "				</TD>\n"
	write "			</TR>\n"
	write "			<TR>\n"
	write "				<TD align=\"right\" class=\"rownum\">\n"
	write "					[mc {Activated:}]\n"
	write "				</TD>\n"
	write "				<TD>\n"
	write "					<CODE>$when</CODE>\n"
	write "				</TD>\n"
	write "			</TR>\n"
	write "			<TR>\n"
	write "				<TD align=\"right\" class=\"rownum\">\n"
	write "					[mc {Action:}]\n"
	write "				</TD>\n"
	write "				<TD>\n"
	write "					<CODE>$event</CODE>\n"
	write "				</TD>\n"
	write "			</TR>\n"
	write "			<TR>\n"
	write "				<TD align=\"right\" class=\"rownum\">\n"
	write "					[mc {Activate condition:}]\n"
	write "				</TD>\n"
	write "				<TD>\n"
	write "					<CODE>[escapeHTML $condition]</CODE>\n"
	write "				</TD>\n"
	write "			</TR>\n"
	write "			<TR>\n"
	write "				<TD colspan=\"2\" class=\"separator\">\n"
	write "					[mc {Code executed:}]\n"
	write "				</TD>\n"
	write "			</TR>\n"
	write "			<TR>\n"
	write "				<TD colspan=\"2\">\n"
	write "					<PRE>[escapeHTML $code]</PRE>\n"
	write "				</TD>\n"
	write "			</TR>\n"
	write "		</TABLE>\n"
	write "		<BR><BR>\n"
}

body HtmlExportPlugin::exportView {name code ddl} {
	write "		<TABLE>\n"
	write "			<TR class=\"title\">\n"
	write "				<TD align=\"center\">\n"
	write "					[mc {View: %s} <B>$name</B>]\n"
	write "				</TD>\n"
	write "			</TR>\n"
	write "			<TR>\n"
	write "				<TD>\n"
	write "					<PRE>[escapeHTML $code]</PRE>\n"
	write "				</TD>\n"
	write "			</TR>\n"
	write "		</TABLE>\n"
	write "		<BR><BR>\n"
}

body HtmlExportPlugin::validateConfig {context} {
}

body HtmlExportPlugin::getStyle {} {
	return $styleContents
}

body HtmlExportPlugin::updateState {path} {
	if {$checkState(header)} {
		$path.fullnames.c configure -state normal
		$path.types.c configure -state normal
	} else {
		set checkState(fullnames) 0
		set checkState(types) 0
		$path.fullnames.c configure -state disabled
		$path.types.c configure -state disabled
	}
}

body HtmlExportPlugin::exportFileSchema {context} {
	set sqlitestudio "<A href=\"${::MainWindow::homepage}\">SQLiteStudio v${::version}</A>\n"
	switch -- $context {
		"DATABASE" {
			append output "<HTML>\n"
			append output "	<HEAD>\n"
			append output "		<META http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n"
			append output "		<TITLE>[mc {Exported database: %s} %DATABASE_NAME%]</TITLE>\n"
			append output "		<STYLE type=\"text/css\">\n"
			append output [getStyle]
			append output "		</STYLE>\n"
			append output "	</HEAD>\n"
			append output "	<BODY>\n"
			append output "%TABLES%\n"
			append output "%INDEXES%\n"
			append output "%TRIGGERS%\n"
			append output "%VIEWS%\n"
			append output "	<I>[mc {Generated on %s with %s} [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}] $sqlitestudio]</I>\n"
			append output "	</BODY>\n"
			append output "</HTML>\n"
			return $output
		}
		"TABLE" {
			append output "<HTML>\n"
			append output "	<HEAD>\n"
			append output "		<META http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n"
			append output "		<TITLE>[mc {Exported table: %s} %TABLE_NAME%]</TITLE>\n"
			append output "		<STYLE type=\"text/css\">\n"
			append output [getStyle]
			append output "		</STYLE>\n"
			append output "	</HEAD>\n"
			append output "	<BODY>\n"
			append output "%TABLE%\n"
			append output "	<I>[mc {Generated on %s with %s} [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}] $sqlitestudio]</I>\n"
			append output "	</BODY>\n"
			append output "</HTML>\n"
			return $output
		}
		"QUERY" {
			append output "<HTML>\n"
			append output "	<HEAD>\n"
			append output "		<META http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n"
			append output "		<TITLE>[mc {Results of SQL query}]</TITLE>\n"
			append output "		<STYLE type=\"text/css\">\n"
			append output [getStyle]
			append output "		</STYLE>\n"
			append output "	</HEAD>\n"
			append output "	<BODY>\n"
			append output "%RESULT%\n"
			append output "	<I>[mc {Generated on %s with %s} [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}] $sqlitestudio]</I>\n"
			append output "	</BODY>\n"
			append output "</HTML>\n"
			return $output
		}
	}
}

body HtmlExportPlugin::isContextSupported {context} {
	return true
}


set HtmlExportPlugin::styleContents {
	TABLE
	{
		border-style: solid;
		border-width: 1;
		border-color: black;
		border-collapse: collapse;
	}
	TABLE TR
	{
		background-color: white;
	}
	TABLE TR.header
	{
		background-color: #DDDDDD;
	}
	TABLE TR.title
	{
		background-color: #EEEEEE;
	}
	TABLE TR TD
	{
		padding: 0px 3px 0px 3px;
		border-style: solid;
		border-width: 1;
		border-color: #666666;
	}
	TABLE TR TD.null
	{
		color: #999999;
		text-align: center;
		padding: 0px 3px 0px 3px;
		border-style: solid;
		border-width: 1;
		border-color: #666666;
	}
	TABLE TR TD.separator
	{
		padding: 0px 3px 0px 3px;
		border-style: solid;
		border-width: 1;
		border-color: #666666;
		background-color: #DDDDDD;
	}
	TABLE TR TD.rownum
	{
		padding: 0px 3px 0px 3px;
		border-style: solid;
		border-width: 1;
		border-color: #666666;
		background-color: #DDDDDD;
		text-align: right;
	}
}
