set ::DB_FILE_TYPES [list]
proc initDbFileTypes {} {
	set ::DB_FILE_TYPES [list \
			[list [mc {All SQLite Databases}]	{.db .db2 .db3 .sdb .s3db .s2db .sqlite .sqlite2 .sqlite3 .sl2 .sl3 .DB .DB2 .DB3 .SDB .S3DB .S2DB .SQLITE .SQLITE2 .SQLITE3 .SL2 .SL3}] \
			[list [mc {SQLite 3 Databases}]		{.db3 .s3db .sqlite3 .sl3 .DB3 .S3DB .SQLITE3 .SL3}] \
			[list [mc {SQLite 2 Databases}]		{.db2 .s2db .sqlite2 .sl2 .DB2 .S2DB .SQLITE2 .SL2}] \
			[list [mc {All files}]				{*}] \
		]
}
