use src/parser/statement.tcl

class StatementSql {
	inherit Statement

	public {
		variable explainKeyword 0
		variable queryPlanKeywords 0
		variable subStatement "" ;# object
		variable branchName "" ;# alterTableStmt analyzeStmt attachStmt beginTransactionStmt commitStmt
								# createIndexStmt createTableStmt createTriggerStmt createView createVirtualTableStmt
								# deleteStmt detachStmt dropIndexStmt dropTableStmt dropTriggerStmt dropViewStmt
								# insertStmt pragmaStmt reindexStmt releaseStmt rollbackStmt savepointStmt selectStmt
								# updateStmt vacuumStmt
	}
}
