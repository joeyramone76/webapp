array set ::FONT_DEPENDENCY_TREE {}
set ::FONT_UPDATE_LIST [list]

proc copyFont {fnt newFnt args} {
	font create $newFnt {*}[font actual $fnt]
	if {[llength $args] > 0} {
		font configure $newFnt {*}$args
	}
}

proc checkForFontMigration {varname value} {
	set fontName [set $varname]
	if {$fontName ni [font names]} {
		return false
	}
	
	if {$value == $fontName} {
		return true
	}

	font configure $fontName {*}[font actual $value]
	return true
}

proc oldFontFormatToNew {oldFont newName} {
	font configure $newName {*}[font actual $oldFont]
}

proc fontTree {def} {
	set allFonts [font names]
	_fontTreeInternal $def $allFonts
}

proc _fontTreeInternal {def allFonts {parent ""}} {
	foreach {fName opts doUpdate subDef} $def {
		if {$fName ni $allFonts} {
			copyFont $parent $fName {*}$opts
		}
		lappend ::FONT_DEPENDENCY_TREE($parent) [list $fName $opts]
		set ::FONT_DEPENDENCY_TREE($fName) [list]
		if {$doUpdate} {
			lappend ::FONT_UPDATE_LIST $fName
		}
		
		_fontTreeInternal $subDef $allFonts $fName
	}
}

proc initFonts {} {
	treectrl .temp_for_tree
	set treeFontTmp [.temp_for_tree cget -font]
	destroy .temp_for_tree

	# Immutable fonts
	copyFont $treeFontTmp TkTreeFontUndefined
	
	fontTree {
		TkTreeFontUndefined {} 0 {
			TkTreeFont {-weight normal} 0 {
				TkTreeFontBold {-weight bold} 0 {}
			}
		}
		TkDefaultFont {} 0 {
			TkDefaultFontBold {-weight bold} 0 {}
			TkDefaultFontUnderline {-underline true} 0 {}
			TkDefaultFontBoldUnderline {-weight bold -underline true} 0 {}
		}
		TkTooltipFont {} 0 {
			TkTooltipFontBold {-weight bold} 0 {}
		}
		TkTextFont {} 0 {
			TkTextFontBold {-weight bold} 0 {}
		}
	}

	# Mutable fonts
	fontTree {
		TkFixedFont {} 0 {
			StatusFont {} 1 {
				StatusFontBold {-weight bold} 1 {}
			}
			SqlEditorFont {} 1 {
				SqlEditorFontBold {-weight bold} 1 {}
				SqlEditorFontUnderline {-underline true} 1 {}
				SqlEditorFontItalic {-slant italic} 1 {}
			}
		}
		TkTreeFont {} 0 {
			GridFont {} 1 {
				GridFontBold {-weight bold} 1 {}
				GridFontUnderline {-underline true} 1 {}
				GridFontItalic {-slant italic} 1 {}
				GridFontBoldUnderline {-weight bold -underline true} 1 {}
			}
			TreeFont {} 1 {
				TreeFontBold {-weight bold} 1 {}
			}
			TreeLabelFont {} 1 {}
		}
		TkTooltipFont {} 1 {
			HintFont {} 1 {}
		}
	}
}

proc updateFonts {} {
	foreach fnt $::FONT_UPDATE_LIST {
		_updateFontsInternal $fnt
	}
}

proc _updateFontsInternal {parent} {
	if {![info exists ::FONT_DEPENDENCY_TREE($parent)]} return
	foreach it $::FONT_DEPENDENCY_TREE($parent) {
		lassign $it child opts
		font configure $child {*}[font actual $parent]
		font configure $child {*}$opts
		_updateFontsInternal $child
	}
}
