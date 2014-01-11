use src/parser/statement2.tcl

class Statement2Sql {
	inherit Statement2

	public {
		variable explainKeyword 0
		variable subStatement "" ;# object
		variable branchName "" ;# attachStmt beginTransactionStmt commitStmt copyStmt createIndexStmt
								# createTableStmt createTriggerStmt createView deleteStmt detachStmt
								# dropIndexStmt dropTableStmt dropTriggerStmt dropViewStmt insertStmt
								# pragmaStmt rollbackStmt selectStmt updateStmt vacuumStmt
	}
}
