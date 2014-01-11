proc MENU_STRUCTURE {} {
	list \
	[dict create \
		type		menu \
		label		[mc {Databases}] \
		states		[dict create \
			default		1 \
		] \
		widgets		[list \
			[dict create \
				type		command \
				image		img_DB_open \
				label		[mc "Connect"] \
				command		"DBTREE connectToSelected" \
				states		[dict create \
					default		0 \
					closed		1 \
				] \
			] \
			[dict create \
				type		command \
				image		img_DB_close \
				label		[mc "Disconnect"] \
				command		"DBTREE disconnectFromSelected" \
				states		[dict create \
					default		1 \
					closed		0 \
					none		0 \
				] \
			] \
			[dict create \
				type		separator \
			] \
			[dict create \
				type		command \
				image		img_DB_new \
				label		[mc "Add database"] \
				command		"DBTREE createNewDB" \
				states		[dict create \
					default		1 \
				] \
			] \
			[dict create \
				type		command \
				image		img_DB_edit \
				label		[mc "Edit database"] \
				command		"DBTREE editDB" \
				states		[dict create \
					default		1 \
					none		0 \
				] \
			] \
			[dict create \
				type		command \
				image		img_DB_remove \
				label		[mc "Remove from list"] \
				command		"DBTREE delSelectedDB" \
				states		[dict create \
					default		0 \
					closed		1 \
				] \
			] \
			[dict create \
				type		separator \
			] \
			[dict create \
				type		command \
				image		img_export_db \
				label		[mc "Export database"] \
				command		"MAIN exportDatabase" \
				states		[dict create \
					default		0 \
					open		1 \
				] \
			] \
			[dict create \
				type		command \
				image		img_import_db \
				label		[mc "Import schema from other database"] \
				command		"DBTREE importSchemaFromOtherDb" \
				states		[dict create \
					default		0 \
					open		1 \
				] \
			] \
			[dict create \
				type		command \
				image		img_convert \
				label		[mc "Convert database"] \
				command		"DBTREE convertDb" \
				states		[dict create \
					default		0 \
					open		1 \
				] \
			] \
			[dict create \
				type		command \
				image		img_vacuum \
				label		[mc "Vacuum"] \
				command		"DBTREE vacuumDB" \
				states		[dict create \
					default		0 \
					open		1 \
				] \
			] \
			[dict create \
				type		command \
				image		img_integrity_check \
				label		[mc "Integrity check"] \
				command		"DBTREE integrityCheck" \
				states		[dict create \
					default		0 \
					open		1 \
				] \
			] \
			[dict create \
				type		command \
				image		img_execute_from_file \
				label		[mc "Execute SQL from file"] \
				command		"DBTREE executeSqlFromFile" \
				states		[dict create \
					default		0 \
					open		1 \
				] \
			] \
			[dict create \
				type		separator \
			] \
			[dict create \
				type		command \
				image		img_tree_refresh \
				label		[mc "Refresh databases tree"] \
				command		"DBTREE refreshSchema" \
				shortcut	::Shortcuts::refresh \
				states		[dict create \
					default		0 \
					open		1 \
				] \
			] \
		] \
	] \
	[dict create \
		type		menu \
		label		[mc {Tables}] \
		states		[dict create \
			default		0 \
			open		1 \
		] \
		widgets [list \
			[dict create \
				type		command \
				image		img_new_table \
				label		[mc "New table"] \
				command		"DBTREE newTable" \
				states		[dict create \
					default		0 \
					open		1 \
				] \
			] \
			[dict create \
				type		command \
				image		img_table_edit \
				label		[mc "Edit table"] \
				command		"DBTREE editTable" \
				states		[dict create \
					default		0 \
					table		1 \
				] \
			] \
			[dict create \
				type		command \
				image		img_del_table \
				label		[mc "Drop table"] \
				command		"DBTREE delTable" \
				states		[dict create \
					default		0 \
					table		1 \
				] \
			] \
			[dict create \
				type		separator \
			] \
			[dict create \
				type		command \
				image		img_table_similar \
				label		[mc "Create similar table"] \
				command		"DBTREE createSimilarTable" \
				states		[dict create \
					default		0 \
					table		1 \
				] \
			] \
			[dict create \
				type		command \
				image		img_reset_incr \
				label		[mc "Reset autoincrement"] \
				command		"DBTREE resetAutoIncrement" \
				states		[dict create \
					default		0 \
					autoincr	1 \
				] \
			] \
			[dict create \
				type		command \
				image		img_whisk \
				label		[mc "Erase table data"] \
				command		"DBTREE eraseTableData" \
				states		[dict create \
					default		0 \
					table		1 \
				] \
			] \
			[dict create \
				type		separator \
			] \
			[dict create \
				type		command \
				image		img_table_export \
				label		[mc "Export table or view"] \
				command		"DBTREE exportTable" \
				states		[dict create \
					default		0 \
					table		1 \
					view		1 \
				] \
			] \
			[dict create \
				type		command \
				image		img_table_import \
				label		[mc "Import data to a table"] \
				command		"MAIN importTable" \
				states		[dict create \
					default		0 \
					table		1 \
				] \
			] \
			[dict create \
				type		command \
				image		img_populate_table \
				label		[mc "Populate table"] \
				command		"DBTREE populateTable" \
				states		[dict create \
					default		0 \
					table		1 \
				] \
			] \
		] \
	] \
	[dict create \
		type		menu \
		label		[mc {Indexes}] \
		states		[dict create \
			default		0 \
			open		1 \
		] \
		widgets [list \
			[dict create \
				type		command \
				image		img_new_index \
				label		[mc "New index"] \
				command		"DBTREE newIndex" \
				states		[dict create \
					default		0 \
					open		1 \
				] \
			] \
			[dict create \
				type		command \
				image		img_index_edit \
				label		[mc "Edit index"] \
				command		"DBTREE editIndex" \
				states		[dict create \
					default		0 \
					index		1 \
				] \
			] \
			[dict create \
				type		command \
				image		img_del_index \
				label		[mc "Drop index"] \
				command		"DBTREE delIndex" \
				states		[dict create \
					default		0 \
					index		1 \
				] \
			] \
		] \
	] \
	[dict create \
		type		menu \
		label		[mc {Triggers}] \
		states		[dict create \
			default		0 \
			open		1 \
		] \
		widgets [list \
			[dict create \
				type		command \
				image		img_new_trigger \
				label		[mc "New trigger"] \
				command		"DBTREE newTrigger" \
				states		[dict create \
					default		0 \
					open		1 \
				] \
			] \
			[dict create \
				type		command \
				image		img_trigger_edit \
				label		[mc "Edit trigger"] \
				command		"DBTREE editTrigger" \
				states		[dict create \
					default		0 \
					trigger		1 \
				] \
			] \
			[dict create \
				type		command \
				image		img_del_trigger \
				label		[mc "Drop trigger"] \
				command		"DBTREE delTrigger" \
				states		[dict create \
					default		0 \
					trigger		1 \
				] \
			] \
		] \
	] \
	[dict create \
		type		menu \
		label		[mc {Views}] \
		states		[dict create \
			default		0 \
			open		1 \
		] \
		widgets [list \
			[dict create \
				type		command \
				image		img_new_view \
				label		[mc "New view"] \
				command		"DBTREE newView" \
				states		[dict create \
					default		0 \
					open		1 \
				] \
			] \
			[dict create \
				type		command \
				image		img_view_edit \
				label		[mc "Edit view"] \
				command		"DBTREE editView" \
				states		[dict create \
					default		0 \
					view		1 \
				] \
			] \
			[dict create \
				type		command \
				image		img_del_view \
				label		[mc "Drop view"] \
				command		"DBTREE delView" \
				states		[dict create \
					default		0 \
					view		1 \
				] \
			] \
			[dict create \
				type		separator \
			] \
			[dict create \
				type		command \
				image		img_table_export \
				label		[mc "Export view"] \
				command		"DBTREE exportTable" \
				states		[dict create \
					default		0 \
					view		1 \
				] \
			] \
			[dict create \
				type		command \
				image		img_show_view_data \
				label		[mc "Show view data"] \
				command		"DBTREE showViewData" \
				states		[dict create \
					default		0 \
					view		1 \
				] \
			] \
		] \
	] \
	[dict create \
		type		menu \
		label		[mc {Window}] \
		states		[dict create \
			default		1 \
		] \
		widgets [list \
			[dict create \
				type		checkbutton \
				label		[mc "View main toolbar"] \
				variable	::VIEW(main_toolbar) \
				command		"MAIN updateToolbarVisibility main_toolbar db" \
				states		[dict create \
					default		1 \
				] \
			] \
			[dict create \
				type		checkbutton \
				label		[mc "View structure toolbar"] \
				variable	::VIEW(struct_toolbar) \
				command		"MAIN updateToolbarVisibility struct_toolbar tree" \
				states		[dict create \
					default		1 \
				] \
			] \
			[dict create \
				type		checkbutton \
				label		[mc "View windows toolbar"] \
				variable	::VIEW(wins_toolbar) \
				command		"MAIN updateToolbarVisibility wins_toolbar wins" \
				states		[dict create \
					default		1 \
				] \
			] \
			[dict create \
				type		checkbutton \
				label		[mc "View tools toolbar"] \
				variable	::VIEW(tools_toolbar) \
				command		"MAIN updateToolbarVisibility tools_toolbar tools" \
				states		[dict create \
					default		1 \
				] \
			] \
			[dict create \
				type		checkbutton \
				label		[mc "View configuration toolbar"] \
				variable	::VIEW(config_toolbar) \
				command		"MAIN updateToolbarVisibility config_toolbar config" \
				states		[dict create \
					default		1 \
				] \
			] \
			[dict create \
				type		separator \
			] \
			[dict create \
				type		command \
				image		img_win_restore \
				label		[mc "Restore last closed window"] \
				command		"MDIWin::restoreLastClosedWindow" \
				shortcut	::Shortcuts::restoreLastWindow \
				states		[dict create \
					default		1 \
				] \
			] \
			[dict create \
				type		command \
				image		img_win_cascade \
				label		[mc "Arrange cascade windows layout"] \
				command		"MDIWin::cascadeWins" \
				states		[dict create \
					default		1 \
				] \
			] \
			[dict create \
				type		command \
				image		img_win_intell \
				label		[mc "Arrange intelligent windows layout"] \
				command		"MDIWin::intellWins" \
				states		[dict create \
					default		1 \
				] \
			] \
		] \
	] \
	[dict create \
		type		menu \
		label		[mc {Tools}] \
		states		[dict create \
			default		1 \
		] \
		widgets [list \
			[dict create \
				type		command \
				image		img_configure \
				label		[mc "Settings"] \
				command		"MAIN openSettings" \
				shortcut	::Shortcuts::openSettings \
				states		[dict create \
					default		1 \
				] \
			] \
			[dict create \
				type		command \
				image		img_sql_function \
				label		[mc "Custom SQL functions"] \
				command		"MAIN functionsEditor" \
				states		[dict create \
					default		1 \
				] \
			] \
			[dict create \
				type		command \
				image		img_edit \
				label		[mc "Open SQL query editor"] \
				command		"MAIN openSqlEditor" \
				shortcut	::Shortcuts::openEditor \
				states		[dict create \
					default		1 \
				] \
			] \
		] \
	] \
	[dict create \
		type		menu \
		label		[mc {Help}] \
		states		[dict create \
			default		1 \
		] \
		widgets [list \
			[dict create \
				type		command \
				image		img_sqlitestudio \
				label		[mc "SQLiteStudio home page"] \
				command		"MAIN sqliteStudioHomePage" \
				states		[dict create \
					default		1 \
				] \
			] \
			[dict create \
				type		command \
				image		img_manual \
				label		[mc "SQLiteStudio manual"] \
				command		"MAIN sqliteStudioDocsOnline" \
				states		[dict create \
					default		1 \
				] \
				visibility	[dict create \
					macosx		0 \
				] \
			] \
			[dict create \
				type		command \
				image		img_documentation \
				label		[mc "SQLite documentation"] \
				command		"MAIN sqliteDocs" \
				states		[dict create \
					default		1 \
				] \
			] \
			[dict create \
				type		command \
				image		img_forum \
				label		[mc "SQLiteStudio support forum"] \
				command		"MAIN openForum" \
				states		[dict create \
					default		1 \
				] \
			] \
			[dict create \
				type		separator \
			] \
			[dict create \
				type		command \
				image		img_bug \
				label		[mc "Report a bug"] \
				command		"MAIN reportCustomBug" \
				states		[dict create \
					default		1 \
				] \
			] \
			[dict create \
				type		command \
				image		img_new_feature \
				label		[mc "Send feature"] \
				command		"MAIN reportFeatureRequest" \
				states		[dict create \
					default		1 \
				] \
			] \
			[dict create \
				type		command \
				image		img_bug_history \
				label		[mc "Show bug reports history"] \
				command		"MAIN showBugHistory" \
				states		[dict create \
					default		1 \
				] \
			] \
			[dict create \
				type		separator \
			] \
			[dict create \
				type		command \
				image		img_tips \
				label		[mc "Show tips window"] \
				command		"MAIN showTipsWindow" \
				states		[dict create \
					default		1 \
				] \
			] \
			[dict create \
				type		command \
				image		img_history2 \
				label		[mc "ChangeLog"] \
				command		"MAIN changelog" \
				states		[dict create \
					default		1 \
				] \
			] \
			[dict create \
				type		command \
				image		img_roadmap \
				label		[mc "Roadmap"] \
				command		"MAIN todo" \
				states		[dict create \
					default		1 \
				] \
			] \
			[dict create \
				type		command \
				image		img_check_updates \
				label		[mc "Check for new version"] \
				command		"MAIN checkVersion true" \
				states		[dict create \
					default		1 \
				] \
			] \
			[dict create \
				type		command \
				image		img_donate \
				label		[mc "Donate"] \
				command		"MAIN donate" \
				states		[dict create \
					default		1 \
				] \
			] \
			[dict create \
				type		command \
				image		img_about \
				label		[mc "About"] \
				command		"MAIN about" \
				states		[dict create \
					default		1 \
				] \
			] \
		] \
	] \
}
