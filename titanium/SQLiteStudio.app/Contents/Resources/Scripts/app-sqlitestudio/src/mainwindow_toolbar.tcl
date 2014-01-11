proc TOOLBAR_STRUCTURE {} {
	list \
	group [dict create \
		name db \
		widgets [list \
			[dict create \
				type		button \
				image		img_DB_open \
				label		[mc "Connect to selected database"] \
				command		"DBTREE connectToSelected" \
				states		[dict create \
					default		0 \
					closed		1 \
				] \
			] \
			[dict create \
				type		button \
				image		img_DB_close \
				label		[mc "Disconnect from selected database"] \
				command		"DBTREE disconnectFromSelected" \
				states		[dict create \
					default		1 \
					none		0 \
					closed		0 \
				] \
			] \
			[dict create \
				type		button \
				image		img_DB_new \
				label		[mc "Add database"] \
				command		"DBTREE createNewDB" \
				states		[dict create \
					default		1 \
				] \
			] \
			[dict create \
				type		button \
				image		img_DB_edit \
				label		[mc "Edit database"] \
				command		"DBTREE editDB" \
				states		[dict create \
					default		1 \
					none		0 \
				] \
			] \
			[dict create \
				type		button \
				image		img_DB_remove \
				label		[mc "Remove selected database from list"] \
				command		"DBTREE delSelectedDB" \
				states		[dict create \
					default		0 \
					closed		1 \
				] \
			] \
		] \
	] \
	group [dict create \
		name tree \
		widgets [list \
			[dict create \
				type		button \
				image		img_new_table \
				label		[mc "New table"] \
				command		"DBTREE newTable" \
				states		[dict create \
					default		0 \
					open		1 \
				] \
			] \
			[dict create \
				type		button \
				image		img_table_edit \
				label		[mc "Edit table"] \
				command		"DBTREE editTable" \
				states		[dict create \
					default		0 \
					table		1 \
				] \
			] \
			[dict create \
				type		button \
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
				type		button \
				image		img_new_index \
				label		[mc "New index"] \
				command		"DBTREE newIndex" \
				states		[dict create \
					default		0 \
					open		1 \
				] \
			] \
			[dict create \
				type		button \
				image		img_index_edit \
				label		[mc "Edit index"] \
				command		"DBTREE editIndex" \
				states		[dict create \
					default		0 \
					index		1 \
				] \
			] \
			[dict create \
				type		button \
				image		img_del_index \
				label		[mc "Drop index"] \
				command		"DBTREE delIndex" \
				states		[dict create \
					default		0 \
					index		1 \
				] \
			] \
			[dict create \
				type		separator \
			] \
			[dict create \
				type		button \
				image		img_new_trigger \
				label		[mc "New trigger"] \
				command		"DBTREE newTrigger" \
				states		[dict create \
					default		0 \
					open		1 \
				] \
			] \
			[dict create \
				type		button \
				image		img_trigger_edit \
				label		[mc "Edit trigger"] \
				command		"DBTREE editTrigger" \
				states		[dict create \
					default		0 \
					trigger		1 \
				] \
			] \
			[dict create \
				type		button \
				image		img_del_trigger \
				label		[mc "Drop trigger"] \
				command		"DBTREE delTrigger" \
				states		[dict create \
					default		0 \
					trigger		1 \
				] \
			] \
			[dict create \
				type		separator \
			] \
			[dict create \
				type		button \
				image		img_new_view \
				label		[mc "New view"] \
				command		"DBTREE newView" \
				states		[dict create \
					default		0 \
					open		1 \
				] \
			] \
			[dict create \
				type		button \
				image		img_view_edit \
				label		[mc "Edit view"] \
				command		"DBTREE editView" \
				states		[dict create \
					default		0 \
					view		1 \
				] \
			] \
			[dict create \
				type		button \
				image		img_del_view \
				label		[mc "Drop view"] \
				command		"DBTREE delView" \
				states		[dict create \
					default		0 \
					view		1 \
				] \
			] \
		] \
	] \
	group [dict create \
		name wins \
		widgets [list \
			[dict create \
				type		button \
				image		img_win_cascade \
				label		[mc "Arrange cascade windows layout"] \
				command		"MDIWin::cascadeWins" \
				states		[dict create \
					default		1 \
				] \
			] \
			[dict create \
				type		button \
				image		img_win_intell \
				label		[mc "Arrange intelligent windows layout"] \
				command		"MDIWin::intellWins" \
				states		[dict create \
					default		1 \
				] \
			] \
			[dict create \
				type		button \
				image		img_tree_refresh \
				label		[mc "Refresh databases tree (%s)" ${::Shortcuts::refresh}] \
				command		"DBTREE refreshSchema" \
				states		[dict create \
					default		1 \
				] \
			] \
		] \
	] \
	group [dict create \
		name tools \
		widgets [list \
			[dict create \
				type		button \
				image		img_edit \
				label		[mc "Open SQL query editor"] \
				command		"MAIN openSqlEditor" \
				states		[dict create \
					default		1 \
				] \
			] \
		] \
	] \
	group [dict create \
		name config \
		widgets [list \
			[dict create \
				type		button \
				image		img_configure \
				label		[mc "Settings (%s)" ${::Shortcuts::openSettings}] \
				command		"MAIN openSettings" \
				states		[dict create \
					default		1 \
				] \
			] \
			[dict create \
				type		button \
				image		img_sql_function \
				label		[mc "Open SQL functions editor"] \
				command		"MAIN functionsEditor" \
				states		[dict create \
					default		1 \
				] \
			] \
		] \
	] \
}
