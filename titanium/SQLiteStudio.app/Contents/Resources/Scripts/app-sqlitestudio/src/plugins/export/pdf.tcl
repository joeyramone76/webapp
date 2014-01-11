use src/plugins/export_plugin.tcl

class PdfExportPlugin {
	inherit ExportPlugin

	constructor {} {}

	private {
		common _loadedFonts [list]
		common _encodedFonts [list]
		common _fontsDir "src/plugins/export/pdf_fonts"
		common _ttfEncodings [ldelete [encoding names] identity]

		variable _pdf ""
		variable _width 0
		variable _height 0
		variable _cellInPad 0
		variable _maxColWidth 0
		variable _emptySpaceMinHeight 0
		variable _configStates
		variable _availableFonts [list]
		variable _ttfFonts [list]

		#
		# { ;# row
		# 	type {header/data}
		# 	data {
		# 		{cell value1}
		# 		{cell value2}
		# 		{cell value3}
		# 	}
		# 	heights {
		# 		10
		# 		50
		# 		30
		# 	}
		# 	attributes {
		# 		colors {
		# 			black
		# 			grey
		# 			black
		# 		}
		# 		nulls {
		# 			false
		# 			true
		# 			false
		# 		}
		# 	}
		# 	maxHeight 300
		# }
		#
		variable _rows [list]
		variable _headerRow [dict create]
		variable _rowsToPrebuffer 0
		variable _colWidths [list]
		variable _colAlign [list]
		variable _rowNum ""
		variable _rowNumMaxWidth 0
		variable _pagesPerDataPage 1

		# Configurable variables
		variable _font "Helvetica"
		variable _ttfFile ""
		variable _ttfEncoding "utf-8"
		variable _fontType "builtin"
		variable _cellInPadSize "2mm"
		variable _fontSize 10
		variable _headerBackground "#DDDDDD"
		variable _fillBigEmptySpaces 0
		variable _emptySpaceBackground "#EEEEEE"
		variable _rowNumColumn 1
		variable _paper "a4"
		variable _margin "15mm"
		variable _fullColumnNames 0
		variable _maxColumnWidth "4cm"
		variable _maxColDataLength 1000
		variable _minHeightForEmptySpaceFill "3cm"
		
		variable _fontHeight ""
		variable _lastColor ""

		method setFillColor {color}
		method emptyRow {}
		method renderCell {x y cellData colWidth align color bgcolor isNull cellHeight maxHeight rowType totalHeight totalWidth}
		method renderRow {row colWidths aligns totalHeight totalWidth}
		method renderRowsOnPage {colsInPage}
		method exportDataInit {columns totalRows}
		method exportDataRow {cellsData}
		method readConfig {}
		method storeConfig {}
		method getFont {}
	}

	public {
		variable checkState

		proc getName {}
		proc configurable {context}
		proc isContextSupported {context}
		method createConfigUI {path context}
		method applyConfig {path context}
		method validateConfig {context}
		method provideColumnWidths {}
		method provideTotalRows {}
		method exportResults {columns totalRows}
		method exportResultsRow {cellsData columns}
		method exportResultsEnd {}
		method exportTable {name columns ddl totalRows}
		method exportTableRow {cellsData columns}
		method exportTableEnd {name}
		method exportIndex {name table columns unique ddl}
		method exportTrigger {name table when event condition code ddl}
		method exportView {name code ddl}
		method getEncoding {}
		method beforeStart {}
		method afterExport {exportFile}
		method finished {}
		method renderRows {{toEnd false}}
		method updateFontConfig {}
		method browseTtfFile {}
		method autoFileExtension {}
	}
}

body PdfExportPlugin::constructor {} {
	# To convert human-readable-units to points
	readConfig
	storeConfig

	set _availableFonts $::pdf4tcl::Fonts

	array set _configStates {}
}

body PdfExportPlugin::readConfig {} {
	set _ttfFile [CfgWin::get "pdf_export_plugin" "last_ttf_file"]

	foreach var {
		cellInPadSize
		font
		fontSize
		ttfFile
		ttfEncoding
		fontType
		headerBackground
		fillBigEmptySpaces
		emptySpaceBackground
		rowNumColumn
		paper
		fullColumnNames
		maxColDataLength
	} {
		set checkState($var) [set _$var]
	}

	foreach {var valueVar unitVar} {
		cellInPadSize cellInPadSize cellInPadUnit
		margin marginSize marginUnit
		maxColumnWidth maxColumnWidthSize maxColumnWidthUnit
		minHeightForEmptySpaceFill minHeightForEmptySpaceFillSize minHeightForEmptySpaceFillUnit
	} {
		lassign [regexp -inline -- {(\d+)(\w+)} [set _$var]] all value unit
		set checkState($valueVar) $value
		set checkState($unitVar) $unit
	}
}

body PdfExportPlugin::storeConfig {} {
	foreach var {
		font
		fontSize
		ttfFile
		ttfEncoding
		fontType
		headerBackground
		fillBigEmptySpaces
		emptySpaceBackground
		rowNumColumn
		paper
		fullColumnNames
		maxColDataLength
	} {
		set _$var $checkState($var)
	}

	foreach {var valueVar unitVar targetVar} {
		cellInPadSize cellInPadSize cellInPadUnit cellInPad
		margin marginSize marginUnit fake_margin
		maxColumnWidth maxColumnWidthSize maxColumnWidthUnit maxColWidth
		minHeightForEmptySpaceFill minHeightForEmptySpaceFillSize minHeightForEmptySpaceFillUnit emptySpaceMinHeight
	} {
		set _$var "$checkState($valueVar)$checkState($unitVar)"
		set _$targetVar [pdf4tcl::getPoints $checkState($valueVar) $::pdf4tcl::units($checkState($unitVar))]
	}

	CfgWin::store "pdf_export_plugin" "last_ttf_file" $_ttfFile
}

body PdfExportPlugin::getName {} {
	return "PDF"
}

body PdfExportPlugin::autoFileExtension {} {
	return ".pdf"
}

body PdfExportPlugin::configurable {context} {
	expr {$context in [list TABLE QUERY]}
}

body PdfExportPlugin::isContextSupported {context} {
	expr {$context in [list TABLE QUERY]}
}

body PdfExportPlugin::beforeStart {} {
	set _pdf [pdf4tcl::new ${this}_pdf -paper $_paper -margin $_margin]
	lassign [$_pdf getDrawableArea] _width _height

	$_pdf setFont $_fontSize [getFont]
	set _fontHeight [$_pdf getFontMetric height]

	set _rowsToPrebuffer [expr {int(ceil($_height / $_fontHeight))}]

	return true
}

body PdfExportPlugin::createConfigUI {path context} {
	readConfig

	set nb [ttk::notebook $path.nb]
	pack $nb -side top -fill both -expand 1
	set sectionPadding 5
	
	#
	# SECTION dimensions
	#
	set sec $nb.dim
	ttk::frame $sec
	$nb add $sec -text [mc {Dimensions}] -padding $sectionPadding
	
	# Paper size
	set w $sec.paper
	ttk::frame $w
	ttk::label $w.l -text [mc {Paper size:}]
	ttk::combobox $w.cb -justify center -width 8 -state readonly -values [lsort -dictionary [array names pdf4tcl::paper_sizes]] -textvariable [scope checkState(paper)]
	pack $w -side top -fill x -padx 2 -pady 2
	pack $w.l -side left
	pack $w.cb -side right
	
	# Margin
	set w $sec.margin
	ttk::frame $w
	ttk::label $w.l -text [mc {Margin size:}]
	ttk::spinbox $w.s -width 3 -from 0 -to 999 -textvariable [scope checkState(marginSize)] -validatecommand [list validateIntInRange 0 999 %P]
	ttk::combobox $w.cb -width 3 -state readonly -values [list mm cm i] -textvariable [scope checkState(marginUnit)]
	pack $w -side top -fill x -padx 2 -pady 2
	pack $w.l -side left
	pack $w.cb -side right
	pack $w.s -side right -padx 1
	
	# Cell padding
	set w $sec.cellPad
	ttk::frame $w
	ttk::label $w.l -text [mc {Cell padding:}]
	ttk::spinbox $w.s -width 3 -from 0 -to 999 -textvariable [scope checkState(cellInPadSize)] -validatecommand [list validateIntInRange 0 999 %P]
	ttk::combobox $w.cb -width 3 -state readonly -values [list mm cm i] -textvariable [scope checkState(cellInPadUnit)]
	pack $w -side top -fill x -padx 2 -pady 2
	pack $w.l -side left
	pack $w.cb -side right
	pack $w.s -side right -padx 1

	# Max column width
	set w $sec.maxColWidth
	ttk::frame $w
	ttk::label $w.l -text [mc {Maximum column width:}]
	ttk::spinbox $w.s -width 3 -from 1 -to 999 -textvariable [scope checkState(maxColumnWidthSize)] -validatecommand [list validateIntInRange 1 999 %P]
	ttk::combobox $w.cb -width 3 -state readonly -values [list mm cm i] -textvariable [scope checkState(maxColumnWidthUnit)]
	pack $w -side top -fill x -padx 2 -pady 2
	pack $w.l -side left
	pack $w.cb -side right
	pack $w.s -side right -padx 1

	# Max cell data length
	set w $sec.maxDataSize
	ttk::frame $w
	ttk::label $w.l -text [mc {Limit amount of data bytes in single cell to:}]
	ttk::spinbox $w.s -width 6 -from 1 -to 99999 -textvariable [scope checkState(maxColDataLength)] -validatecommand [list validateIntInRange 1 99999 %P]
	pack $w -side top -fill x -padx 2 -pady 2
	pack $w.l -side left
	pack $w.s -side right -padx 1

	#
	# SECTION font
	#
	set sec $nb.font
	ttk::frame $sec
	$nb add $sec -text [mc {Fonts}] -padding $sectionPadding
	
	# Font size
	set w $sec.fontSize
	ttk::frame $w
	ttk::label $w.l -text [mc {Font size:}]
	ttk::spinbox $w.s -width 3 -from 1 -to 999 -textvariable [scope checkState(fontSize)] -validatecommand [list validateIntInRange 1 999 %P]
	pack $w -side top -fill x -padx 2 -pady 2
	pack $w.l -side left
	pack $w.s -side right -padx 1

	# Built-in fonts
	set subSec $sec.builtIn
	ttk::labelframe $subSec -text [mc {Built-in font}]
	ttk::radiobutton $subSec.r -text [mc {Built-in font}] -variable [scope checkState(fontType)] -value "builtin" -command [list $this updateFontConfig]
	pack $subSec.r -side top -fill x
	pack $subSec -side top -fill x -pady 10 -padx 3
	
	# Font
	set w $subSec.font
	ttk::frame $w
	ttk::label $w.l -text [mc {Font:}]
	ttk::combobox $w.cb -justify center -width 16 -state readonly -values $_availableFonts -textvariable [scope checkState(font)]
	pack $w -side top -fill x -padx 2 -pady 2
	pack $w.l -side left
	pack $w.cb -side right -padx 1
	set _configStates(builtin:$w.l:normal) "normal"
	set _configStates(builtin:$w.cb:normal) "readonly"
	set _configStates(builtin:$w.l:disabled) "disabled"
	set _configStates(builtin:$w.cb:disabled) "disabled"

	# TTF fonts
	set subSec $sec.ttf
	ttk::labelframe $subSec -text [mc {TrueType font}]
	ttk::radiobutton $subSec.r -text [mc {TrueType font}] -variable [scope checkState(fontType)] -value "ttf" -command [list $this updateFontConfig]
	pack $subSec.r -side top -fill x
	pack $subSec -side top -fill x -pady 10 -padx 3
	
	# TTF file
	set w $subSec.file
	ttk::frame $w
	ttk::label $w.l -text [mc {Font file:}]
	ttk::entry $w.e -textvariable [scope checkState(ttfFile)]
	ttk::button $w.b -image img_open -command [list $this browseTtfFile]
	pack $w.l -side left
	pack $w.e -side left -fill x -expand 1 -padx 2
	pack $w.b -side right
	pack $w -side top -fill x -padx 2 -pady 2
	set _configStates(ttf:$w.l:normal) "normal"
	set _configStates(ttf:$w.e:normal) "normal"
	set _configStates(ttf:$w.b:normal) "normal"
	set _configStates(ttf:$w.l:disabled) "disabled"
	set _configStates(ttf:$w.e:disabled) "disabled"
	set _configStates(ttf:$w.b:disabled) "disabled"
	
	# TTF encoding
	set w $subSec.enc
	ttk::frame $w
	ttk::label $w.l -text [mc {Font encoding:}]
	ttk::combobox $w.cb -values [lsort -dictionary $_ttfEncodings] -state readonly -textvariable [scope checkState(ttfEncoding)]
	pack $w.l -side left
	pack $w.cb -side right -padx 1
	pack $w -side top -fill x -padx 2 -pady 2
	set _configStates(ttf:$w.l:normal) "normal"
	set _configStates(ttf:$w.cb:normal) "readonly"
	set _configStates(ttf:$w.l:disabled) "disabled"
	set _configStates(ttf:$w.cb:disabled) "disabled"

	#
	# SECTION columns
	#
	set sec $nb.cols
	ttk::frame $sec
	$nb add $sec -text [mc {Columns and rows}] -padding $sectionPadding

	# Header background
	set w $sec.hdrBg
	ttk::frame $w
	ColorPicker $w.pick -label [mc {Header background}] -variable [scope checkState(headerBackground)]
	pack $w.pick -side left
	pack $w -side top -fill x -padx 2 -pady 2

	# Full column names
	set w $sec.fullNames
	ttk::frame $w
	ttk::checkbutton $w.c -text [mc {Full column names}] -variable [scope checkState(fullColumnNames)]
	helpHint $w.c  [mc {Column names in header will be prepended with "table_name." prefix.}]
	pack $w -side top -fill x -padx 2 -pady 2
	pack $w.c -side left

	# RowNum column
	set w $sec.rowNum
	ttk::frame $w
	ttk::checkbutton $w.c -text [mc {Row numbers as first column}] -variable [scope checkState(rowNumColumn)]
	helpHint $w.c [mc "First column of exported data\nwill contain row order number."]
	pack $w -side top -fill x -padx 2 -pady 2
	pack $w.c -side left

	#
	# SECTION empty space
	#
	set sec $nb.emptySpace
	ttk::frame $sec
	$nb add $sec -text [mc {Empty space}] -padding $sectionPadding

	# Fill empty spaces
	set w $sec.fill
	ttk::frame $w
	ttk::checkbutton $w.c -text [mc {Fill empty space in cells}] -variable [scope checkState(fillEmptySpace)]
	helpHint $w.c [mc "If one column in the same row has very long value\nand other columns have short values,\nthen this option makes empty space left below short values\nto be filled with coloured background."]
	pack $w -side top -fill x -padx 2 -pady 2
	pack $w.c -side left
	
	# Minimum height to apply empty space filling
	set w $sec.minHeight
	ttk::frame $w
	ttk::label $w.l -text [mc {Minimum height of empty space to fill:}]
	ttk::spinbox $w.s -width 3 -from 1 -to 999 -textvariable [scope checkState(minHeightForEmptySpaceFillSize)] -validatecommand [list validateIntInRange 1 999 %P]
	ttk::combobox $w.cb -width 3 -state readonly -values [list mm cm i] -textvariable [scope checkState(minHeightForEmptySpaceFillUnit)]
	set hint [mc "If the height of empty space in cell is smaller\nthan value specified here, then no special background will be drawn."]
	helpHint $w.s $hint
	helpHint $w.cb $hint
	pack $w -side top -fill x -padx 2 -pady 2
	pack $w.l -side left
	pack $w.cb -side right
	pack $w.s -side right -padx 1

	# Empty spaces background
	set w $sec.color
	ttk::frame $w
	ColorPicker $w.pick -label [mc {Empty space background}] -variable [scope checkState(emptySpaceBackground)]
	pack $w.pick -side left
	pack $w -side top -fill x -padx 2 -pady 2

	# Finish
	updateFontConfig
}

body PdfExportPlugin::getFont {} {
	switch -- $_fontType {
		"builtin" {
			return $_font
		}
		"ttf" {
			set fileOnly [lindex [file split $_ttfFile] end]

			set baseName Base$fileOnly
			if {$_ttfFile ni $_loadedFonts} {
				pdf4tcl::loadBaseTrueTypeFont $baseName $_ttfFile
				lappend _loadedFonts $_ttfFile
			}

			set encodedName ${fileOnly}_$_ttfEncoding
			if {$encodedName ni $_encodedFonts} {
				pdf4tcl::createFont $baseName $encodedName $_ttfEncoding
				lappend _encodedFonts $encodedName
			}

			return $encodedName
		}
	}
}

body PdfExportPlugin::updateFontConfig {} {
	foreach idx [array names _configStates *:*:disabled] {
		set sp [split $idx :]
		[lindex $sp 1] configure -state $_configStates($idx)
	}

	foreach idx [array names _configStates $checkState(fontType):*:normal] {
		set sp [split $idx :]
		[lindex $sp 1] configure -state $_configStates($idx)
	}
}

body PdfExportPlugin::browseTtfFile {} {
	set types [list \
		[list [mc {TTF Fonts}] {.ttf}] \
		[list [mc {All Files}] *] \
	]

	set args [list]
	lappend args -title [mc {Open TTF font}]
	if {[os] != "macosx"} {
		lappend args -filetypes $types
	}
	set f [GetOpenFile {*}$args]
	if {$f != ""} {
		set checkState(ttfFile) $f
	}
}

body PdfExportPlugin::applyConfig {path context} {
	storeConfig
}

body PdfExportPlugin::validateConfig {context} {
}

body PdfExportPlugin::exportResults {columns totalRows} {
	set newCols [list]
	foreach c $columns {
		set table [dict get $c table]
		set name [dict get $c column]
		set type [dict get $c type]
		set maxWidth [dict get $c maxDataWidth]
		lappend newCols [dict create name $name type $type prefix $table maxWidth $maxWidth]
	}
	exportDataInit $newCols $totalRows
}

body PdfExportPlugin::exportResultsRow {cellsData columns} {
	exportDataRow $cellsData
}

body PdfExportPlugin::exportResultsEnd {} {
	renderRows true
}

body PdfExportPlugin::exportTable {name columns ddl totalRows} {
	set newCols [list]
	foreach col $columns {
		lassign $col colName colType pk notnull dflt_value colDataMaxWidth
		lappend newCols [dict create name $colName type $colType prefix $name maxWidth $colDataMaxWidth]
	}
	exportDataInit $newCols $totalRows
}

body PdfExportPlugin::exportTableRow {cellsData columns} {
	exportDataRow $cellsData
}

body PdfExportPlugin::exportTableEnd {name} {
	renderRows true
}

body PdfExportPlugin::exportIndex {name table columns unique ddl} {
}

body PdfExportPlugin::exportTrigger {name table when event condition code ddl} {
}

body PdfExportPlugin::exportView {name code ddl} {
}

body PdfExportPlugin::finished {} {
	$_pdf finish
	write [$_pdf get]
}

body PdfExportPlugin::afterExport {exportFile} {
	$_pdf destroy
}

body PdfExportPlugin::getEncoding {} {
	return "binary"
}

body PdfExportPlugin::setFillColor {color} {
	if {$color != $_lastColor} {
		$_pdf setFillColor $color
		set _lastColor $color
	}
}

body PdfExportPlugin::provideColumnWidths {} {
	return true
}

body PdfExportPlugin::provideTotalRows {} {
	return $_rowNumColumn
}

body PdfExportPlugin::emptyRow {} {
	dict create \
		type "" \
		data [list] \
		heights [list] \
		maxHeight 0 \
		attributes [dict create \
			colors [list] \
			bgcolors [list] \
			nulls [list] \
		]
}

body PdfExportPlugin::exportDataInit {columns totalRows} {
	set _headerRow [emptyRow]
	dict set _headerRow type "header"
	set _rowNum 1
	set maxRowHeight 0
	set colors [list]
	set nulls [list]
	set heights [list]
	set datas [list]
	
	foreach c $columns {
		set colName [dict get $c name]
		set type [dict get $c type]
		set colNamePrefix [dict get $c prefix]
		set colDataMaxWidth [dict get $c maxWidth]

		if {[string trim $colName] == ""} {
			set colName "\"$colName\""
		}

		if {$colDataMaxWidth == 0} {
			set colDataMaxWidth 4 ;# NULL
		}
		if {$colDataMaxWidth > $_maxColDataLength} {
			set colDataMaxWidth $_maxColDataLength
		}
		if {$_fullColumnNames && $colNamePrefix != ""} {
			if {[string trim $colNamePrefix] == ""} {
				set colNamePrefix "\"$colNamePrefix\""
			}
			set colName "$colNamePrefix.$colName"
		}
		set type [string toupper $type]

		set maxDataWidth [expr {ceil([$_pdf getStringWidth [string repeat "x" $colDataMaxWidth]])}]
		set headerWidth [expr {max(ceil([$_pdf getStringWidth $colName]), ceil([$_pdf getStringWidth $type]))}]
		set maxWidth [expr {max($maxDataWidth, $headerWidth)}]
		
		# Alignment
		set typeForAlign [string toupper [lindex [split $type] 0]]
		if {$typeForAlign in $::dataTypes_numeric} {
			lappend _colAlign right
		} else {
			lappend _colAlign left
		}

		# Apply width limit and define final width
		set width [expr {min($maxWidth, $_maxColWidth)}]
		lappend _colWidths $width
		
		set value "$colName\n$type"
		lappend datas $value
		lappend colors black
		lappend bgcolors $_headerBackground
		lappend nulls false

		set height [pdf_getTextBoxHeight $_pdf $_fontSize $width $value]
		lappend heights $height

		set maxRowHeight [expr {max($maxRowHeight, $height)}]
	}

	if {$_rowNumColumn} {
		# Determinate maximum width of rownum
		set _rowNumMaxWidth [expr {ceil([$_pdf getStringWidth "#"])}]
		for {set i 0} {$i < 10} {incr i} {
			set width [expr {ceil([$_pdf getStringWidth [string repeat $i [string length $totalRows]]])}]
			set _rowNumMaxWidth [expr {max($_rowNumMaxWidth, $width)}]
			
		}
	}

	dict set _headerRow maxHeight $maxRowHeight
	dict set _headerRow heights $heights
	dict set _headerRow data $datas
	dict set _headerRow attributes colors $colors
	dict set _headerRow attributes bgcolors $bgcolors
	dict set _headerRow attributes nulls $nulls

	set totWidth [expr [join $_colWidths +]]
	set totalRequiredWidth [expr {$totWidth + [llength $_colWidths] * $_cellInPad * 2}]
	set _pagesPerDataPage [expr {int(ceil($totalRequiredWidth / $_width))}]
}

body PdfExportPlugin::exportDataRow {cellsData} {
	set row [emptyRow]
	dict set row type "data"
	set maxHeight 0
	set colors [list]
	set bgcolors [list]
	set nulls [list]
	set datas [list]
	set heights [list]

	set colIdx 0
	foreach cell $cellsData colWidth $_colWidths {
		lassign $cell cellValue isNull

		lappend nulls $isNull
		if {$isNull} {
			set value "NULL"
			set color grey
		} else {
			set value $cellValue
			set color black
		}
		if {[string length $value] > $_maxColDataLength} {
			set value [string range $value 0 [expr {$_maxColDataLength - 1}]]
			if {[string index $value end] ni [list " " "\n" "\t"]} {
				append value " "
			}
			append value "(...)"
		}
		lappend datas $value
		lappend colors $color
		lappend bgcolors white

		set height [pdf_getTextBoxHeight $_pdf $_fontSize $colWidth $value]
		lappend heights $height

		set maxHeight [expr {max($maxHeight, $height)}]
		incr colIdx
	}

	dict set row data $datas
	dict set row heights $heights
	dict set row maxHeight $maxHeight
	dict set row attributes colors $colors
	dict set row attributes bgcolors $bgcolors
	dict set row attributes nulls $nulls
	lappend _rows $row
	if {[llength $_rows] >= $_rowsToPrebuffer} {
		renderRows
	}
}

body PdfExportPlugin::renderCell {x y cellData colWidth align color bgcolor isNull cellHeight maxHeight rowType totalHeight totalWidth} {
	upvar rowIdx rowIdx pageNo pageNo colIdx colIdx

	set x [expr {$x + $_cellInPad}]

	# Cell background
	if {$bgcolor != "white"} {
		$_pdf setFillColor $bgcolor
		set cellX [expr {$x - $_cellInPad}]
		set cellY [expr {$y - $_cellInPad}]
		set cellWidth [expr {$colWidth + 2 * $_cellInPad}]
		set cellHeight [expr {$maxHeight + 2 * $_cellInPad}]
		$_pdf rectangle $cellX $cellY $cellWidth $cellHeight -filled true -stroke true
	}

	# Cell empty area background
	if {$_fillBigEmptySpaces && $cellHeight + $_cellInPad + $_emptySpaceMinHeight < $maxHeight} {
		$_pdf setFillColor $_emptySpaceBackground
		set cellX [expr {$x - $_cellInPad}]
		set cellWidth [expr {$colWidth + 2 * $_cellInPad}]
		if {$cellHeight == 0} {
			set cellY [expr {$y - $_cellInPad}]
			set cellHeight $maxHeight
		} else {
			set cellY [expr {$y + $_cellInPad + $cellHeight}]
			set cellHeight [expr {$maxHeight - $cellHeight}]
		}
		$_pdf rectangle $cellX $cellY $cellWidth $cellHeight -filled true -stroke false
	}

	# Header is always aligned to left
	if {$rowType == "header"} {
		set align left
	}

	# We order to drawTextBox with the height of entire page,
	# because pdf4tcl tends to cut off last line if called with minumum required height.
	$_pdf setFillColor $color
	set rest [$_pdf drawTextBox $x $y $colWidth $_height $cellData -align $align]
	if {$rest != ""} {
		debug "PDF rest ($pageNo / [expr {$rowIdx+2}] / [expr {$colIdx+1}]): $rest"
	}
	
	# Vertical line
	set lineX [expr {$x + $colWidth + $_cellInPad}]
	$_pdf setFillColor black
	$_pdf line $lineX 0 $lineX $totalHeight

	set x [expr {$x + $colWidth + $_cellInPad}]
	incr colIdx
	return $x
}

body PdfExportPlugin::renderRow {row colWidths aligns totalHeight totalWidth} {
	upvar y y rowIdx rowIdx rowNumPerPage rowNumPerPage startColIdx startColIdx endColIdx endColIdx pageNo pageNo

	set rowType [dict get $row type]
	set maxHeight [dict get $row maxHeight]
	if {$rowIdx > 0 && $y + $maxHeight + 2 * $_cellInPad > $_height} {
		# This row is not the first data row on page and it doesn't fit
		return false
	}
	
	set datas [lrange [dict get $row data] $startColIdx $endColIdx]
	set colors [lrange [dict get $row attributes colors] $startColIdx $endColIdx]
	set bgcolors [lrange [dict get $row attributes bgcolors] $startColIdx $endColIdx]
	set nulls [lrange [dict get $row attributes nulls] $startColIdx $endColIdx]
	set heights [lrange [dict get $row heights] $startColIdx $endColIdx]

	if {$_rowNumColumn} {
		if {$rowType == "header"} {
			set datas [linsert $datas 0 "#"]
		} else {
			set datas [linsert $datas 0 [expr {$_rowNum + $rowNumPerPage}]]
		}
		set colors [linsert $colors 0 black]
		set bgcolors [linsert $bgcolors 0 $_headerBackground]
		set nulls [linsert $nulls 0 false]
		set height [pdf_getTextBoxHeight $_pdf $_fontSize $_rowNumMaxWidth "#"]
		set heights [linsert $heights 0 $height]
	}
	
	# All columns visible on the page
	set x 0
	set y [expr {$y + $_cellInPad}]
	set colIdx 0
	foreach \
		cellData $datas \
		colWidth $colWidths \
		align $aligns \
		color $colors \
		bgcolor $bgcolors \
		isNull $nulls \
		cellHeight $heights \
	{
		set x [renderCell $x $y $cellData $colWidth $align $color $bgcolor $isNull $cellHeight $maxHeight $rowType $totalHeight $totalWidth]
	}

	# Horizontal line
	set lineY [expr {$y + $maxHeight + $_cellInPad}]
	$_pdf setFillColor black
	$_pdf line 0 $lineY $totalWidth $lineY

	set y [expr {$y + $maxHeight + $_cellInPad}]
	incr rowIdx
	if {$rowType != "header"} {
		incr rowNumPerPage
	}
	return true
}

body PdfExportPlugin::renderRowsOnPage {colsInPage} {
	upvar endColIdx endColIdx pageNo pageNo rowIdx rowIdx rowNumPerPage rowNumPerPage

	# Select columns that will fit on this page
	set startColIdx [expr {$endColIdx + 1}]
	set endColIdx [expr {$startColIdx + $colsInPage - 1}]
	set colWidths [lrange $_colWidths $startColIdx $endColIdx]
	set aligns [lrange $_colAlign $startColIdx $endColIdx]

	if {$_rowNumColumn} {
		set colWidths [linsert $colWidths 0 $_rowNumMaxWidth]
		set aligns [linsert $aligns 0 right]
	}

	# Calculate total height and total width for vertical and horizontal lines
	set totalHeight 0
	foreach row $_rows {
		set maxHeight [dict get $row maxHeight]
		if {($totalHeight + $maxHeight + 2 * $_cellInPad) > $_height} {
			if {$rowIdx <= 0} {
				set maxHeight [expr {$_height - 2 * $_cellInPad}]
			}
			break
		}
		set totalHeight [expr {$totalHeight + $maxHeight + 2 * $_cellInPad}]
	}
	set totalWidth [expr [join $colWidths +]]
	set totalWidth [expr {$totalWidth + [llength $colWidths] * 2 * $_cellInPad}]

	# Draw top horizontal and left vertical lines
	$_pdf setFillColor black
	$_pdf line 0 0 $totalWidth 0
	$_pdf line 0 0 0 $totalHeight

	# Draw the data cells
	set y 0
	set rowIdx -1
	set rowNumPerPage 0
	# All rows on the page
	foreach row $_rows {
		if {![renderRow $row $colWidths $aligns $totalHeight $totalWidth]} {
			break
		}
	}
}

body PdfExportPlugin::renderRows {{toEnd false}} {
	if {$_rowNumColumn} {
		set colWidthSum [expr {$_rowNumMaxWidth + 2 * $_cellInPad}]
	} else {
		set colWidthSum 0
	}
	set colsPerPage [list]
	set colsCnt 0
	foreach colWidth $_colWidths {
		set colWidthSum [expr {$colWidthSum + 2 * $_cellInPad + $colWidth}]
		if {$colWidthSum > $_width} {
			lappend colsPerPage $colsCnt
			set colWidthSum [expr {2 * $_cellInPad + $colWidth}]
			if {$_rowNumColumn} {
				set colWidthSum [expr {$colWidthSum + $_rowNumMaxWidth + 2 * $_cellInPad}]
			}
			set colsCnt 1
			continue
		}
		incr colsCnt
	}
	if {$colsCnt > 0} {
		lappend colsPerPage $colsCnt
	}

	set pageNo 0
	set rowNumPerPage 0
	while {[llength $_rows] >= $_rowsToPrebuffer || $toEnd && [llength $_rows] > 0} {
		set _rows [linsert $_rows 0 $_headerRow]
		set rowIdx -1

		# For each page we will process all rows for columns that fit on that page
		set endColIdx -1
		foreach colsInPage $colsPerPage {
			$_pdf startPage
			incr pageNo

			# All rows on the page
			renderRowsOnPage $colsInPage
		}

		incr _rowNum $rowNumPerPage
		set _rows [lrange $_rows [expr {$rowIdx + 1}] end]
	}
}
