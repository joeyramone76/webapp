set ::collationTypes [list {} BINARY NOCASE]
set ::sortOrders [list {} ASC DESC]
set ::dataTypes [list NONE BLOB BOOLEAN CHAR DATE DATETIME INT INTEGER NUMERIC REAL TEXT VARCHAR]
set ::dataTypes_numeric [list NUMERIC INTEGER INT REAL]
set ::conflictAlgorithms_v2 [list {} ABORT ROLLBACK FAIL IGNORE REPLACE]
set ::conflictAlgorithms_v3 [list {} ABORT ROLLBACK FAIL IGNORE REPLACE]
set ::conflictAlgorithms $::conflictAlgorithms_v3
set ::deferredValues [list "" "DEFERRABLE" "NOT DEFERRABLE"]
set ::deferredInitiallyValues [list "" "INITIALLY DEFERRED" "INITIALLY IMMEDIATE"]
