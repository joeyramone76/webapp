#######################################################################
#
# action [list TYPE value] occurences code
#
# action = TOKEN | GROUP | ALTER | SUBST
# occurances = n | n-m | ? | * | +
# Types: KEYWORD, OPERATOR, STRING, INTEGER, FLOAT, PAR_LEFT,
#        PAR_RIGHT, OTHER, COMMENT
#
# ALTER [list \
#		action [list TYPE value] occurences code \
#		action [list TYPE value] occurences code \
# ] occurences code
#
# GROUP [list \
# 		action [list TYPE value] occurences code \
# 		action [list TYPE value] occurences code \
# ] occurences code
#
# SUBST [list SYNTAX syntaxKey] occurences code
#
#######################################################################

use src/parser/decls.tcl

set ::sqlite3::statementSyntax(createIndexStmt) [list \
	StatementCreateIndex [list \
		TOKEN [list KEYWORD CREATE] 1 {} \
		TOKEN [list KEYWORD UNIQUE] ? [list configure -isUnique 1] \
		TOKEN [list KEYWORD INDEX] 1 {} \
		GROUP [list \
			TOKEN [list KEYWORD IF] 1 {} \
			TOKEN [list KEYWORD NOT] 1 {} \
			TOKEN [list KEYWORD EXISTS] 1 {} \
		] ? [list configure -ifNotExists 1] \
		ALTER [list \
			GROUP [list \
				TOKEN [list OTHER|STRING databaseName] 1 [list configure -databaseName \$databaseName] \
				TOKEN [list OPERATOR "."] 1 {} \
				TOKEN [list OTHER|STRING indexName] {1 ?} [list configure -indexName \$indexName] \
			] 1 {} \
			TOKEN [list OTHER|STRING indexName] 1 [list configure -indexName \$indexName] \
		] 1 {} \
		TOKEN [list KEYWORD ON] 1 {} \
		ALTER [list \
			TOKEN [list OTHER|STRING tableName] 1 [list configure -onTable \$tableName] \
		] 1 {} \
		TOKEN [list PAR_LEFT "("] 1 {} \
		SUBST [list SYNTAX indexedColumn] {1 ?} [list addIndexColumn \$indexedColumn] \
		GROUP [list \
			TOKEN [list OPERATOR ","] 1 {} \
			SUBST [list SYNTAX indexedColumn] {1 ?} [list addIndexColumn \$indexedColumn] \
		] * {} \
		TOKEN [list PAR_RIGHT ")"] {1 ?} {} \
	] \
]

set ::sqlite3::statementSyntax(indexedColumn) [list \
	StatementIndexedColumn [list \
		TOKEN [list OTHER|STRING columnName] 1 [list configure -columnName \$columnName] \
		GROUP [list \
			TOKEN [list KEYWORD COLLATE] 1 {} \
			ALTER [list \
				TOKEN [list OTHER|STRING collationName] 1 [list configure -collationName \$collationName -collation 1] \
				TOKEN [list KEYWORD *] 1 [list configure -collationName \$tokenValue -collation 1] \
			] 1 {} \
		] ? {} \
		ALTER [list \
			TOKEN [list KEYWORD ASC] 1 [list configure -order ASC] \
			TOKEN [list KEYWORD DESC] 1 [list configure -order DESC] \
		] ? {} \
	] \
]

set ::sqlite3::statementSyntax(selectStmt) [list \
	StatementSelect [list \
		SUBST [list SYNTAX selectCore] 1 [list addSelectCore \$selectCore] \
		GROUP [list \
			SUBST [list SYNTAX compoundOperator] 1 [list addCompoundOperator \$compoundOperator] \
			SUBST [list SYNTAX selectCore] 1 [list addSelectCore \$selectCore] \
		] * {} \
		GROUP [list \
			TOKEN [list KEYWORD ORDER] 1 {} \
			TOKEN [list KEYWORD BY] 1 {} \
			SUBST [list SYNTAX orderingTerm] {1 ?} [list addOrderBy \$orderingTerm] \
			GROUP [list \
				TOKEN [list OPERATOR ","] 1 {} \
				SUBST [list SYNTAX orderingTerm] {1 ?} [list addOrderBy \$orderingTerm] \
			] * {} \
		] ? {} \
		GROUP [list \
			TOKEN [list KEYWORD LIMIT] 1 {} \
			SUBST [list SYNTAX expr] 1 [list configure -limit \$expr] \
			GROUP [list \
				ALTER [list \
					TOKEN [list KEYWORD OFFSET] 1 [list configure -offsetKeyword 1] \
					TOKEN [list OPERATOR ","] 1 [list configure -offsetKeyword 2] \
				] 1 {} \
				SUBST [list SYNTAX expr] 1 [list configure -offset \$expr] \
			] ? {} \
		] ? {} \
	] \
]

set ::sqlite3::statementSyntax(selectCore) [list \
	StatementSelectCore [list \
		TOKEN [list KEYWORD SELECT] 1 {} \
		ALTER [list \
			TOKEN [list KEYWORD DISTINCT] 1 [list configure -allOrDistinct "DISTINCT"] \
			TOKEN [list KEYWORD ALL] 1 [list configure -allOrDistinct "ALL"] \
		] ? {} \
		SUBST [list SYNTAX resultColumn] {1 ?} [list addResultColumn \$resultColumn] \
		GROUP [list \
			TOKEN [list OPERATOR ","] 1 {} \
			SUBST [list SYNTAX resultColumn] {1 ?} [list addResultColumn \$resultColumn] \
		] * {} \
		GROUP [list \
			TOKEN [list KEYWORD FROM] 1 {} \
			SUBST [list SYNTAX joinSource] 1 [list configure -from \$joinSource] \
		] ? {} \
		GROUP [list \
			TOKEN [list KEYWORD WHERE] 1 {} \
			SUBST [list SYNTAX expr] {1 ?} [list configure -where \$expr] \
		] ? {} \
		GROUP [list \
			TOKEN [list KEYWORD GROUP] 1 {} \
			TOKEN [list KEYWORD BY] 1 {} \
			SUBST [list SYNTAX orderingTerm] {1 ?} [list addGroupBy \$orderingTerm] \
			GROUP [list \
				TOKEN [list OPERATOR ","] 1 {} \
				SUBST [list SYNTAX orderingTerm] {1 ?} [list addGroupBy \$orderingTerm] \
			] * {} \
			GROUP [list \
				TOKEN [list KEYWORD HAVING] 1 {} \
				SUBST [list SYNTAX expr] {1 ?} [list configure -having \$expr] \
			] ? {} \
		] ? {} \
	] \
]

set ::sqlite3::statementSyntax(resultColumn) [list \
	StatementResultColumn [list \
		ALTER [list \
			TOKEN [list OPERATOR "*"] 1 [list configure -star 1] \
			GROUP [list \
				TOKEN [list OTHER|STRING tableName] 1 [list configure -tableName \$tableName] \
				TOKEN [list OPERATOR "."] 1 {} \
				TOKEN [list OPERATOR "*"] 1 [list configure -star 1] \
			] 1 {} \
			GROUP [list \
				SUBST [list SYNTAX expr] 1 [list configure -expr \$expr] \
				GROUP [list \
					TOKEN [list KEYWORD AS] ? [list configure -asKeyword 1] \
					TOKEN [list OTHER|STRING columnAlias] 1 [list configure -columnAlias \$columnAlias] \
				] ? {} \
			] 1 {} \
		] 1 {} \
	] \
]

set ::sqlite3::statementSyntax(joinSource) [list \
	StatementJoinSource [list \
		SUBST [list SYNTAX singleSource] 1 [list configure -singleSource \$singleSource] \
		GROUP [list \
			SUBST [list SYNTAX joinOp] 1 [list addJoinOp \$joinOp] \
			SUBST [list SYNTAX singleSource] 1 [list addSingleSource \$singleSource] \
			SUBST [list SYNTAX joinConstraint] 1 [list addJoinConstraint \$joinConstraint] \
		] * {} \
	] \
]

set ::sqlite3::statementSyntax(singleSource) [list \
	StatementSingleSource [list \
		ALTER [list \
			GROUP [list \
				ALTER [list \
					GROUP [list \
						TOKEN [list OTHER|STRING databaseName] 1 [list configure -databaseName \$databaseName] \
						TOKEN [list OPERATOR "."] 1 {} \
						TOKEN [list OTHER|STRING tableName] {1 ?} [list configure -tableName \$tableName] \
					] 1 {} \
					TOKEN [list OTHER|STRING tableName] 1 [list configure -tableName \$tableName] \
				] 1 {} \
				GROUP [list \
					TOKEN [list KEYWORD AS] ? [list configure -asKeyword 1] \
					TOKEN [list OTHER|STRING {tableAlias#exclude(KEYWORD LEFT|INNER|CROSS|NATURAL)}] 1 [list configure -tableAlias \$tableAlias] \
				] ? {} \
				ALTER [list \
					GROUP [list \
						TOKEN [list KEYWORD INDEXED] 1 [list configure -indexedKeyword 1] \
						TOKEN [list KEYWORD BY] 1 [list configure -byKeyword 1] \
						TOKEN [list OTHER|STRING indexName] 1 [list configure -indexName \$indexName] \
					] 1 {} \
					GROUP [list \
						TOKEN [list KEYWORD NOT] 1 [list configure -notKeyword 1] \
						TOKEN [list KEYWORD INDEXED] 1 [list configure -indexedKeyword 1] \
					] 1 {} \
				] ? {} \
			] 1 [list configure -branchIndex 0] \
			GROUP [list \
				TOKEN [list PAR_LEFT "("] 1 {} \
				SUBST [list SYNTAX selectStmt] 1 [list configure -selectStmt \$selectStmt] \
				TOKEN [list PAR_RIGHT ")"] 1 {} \
				GROUP [list \
					TOKEN [list KEYWORD AS] ? [list configure -asKeyword 1] \
					TOKEN [list OTHER|STRING {tableAlias#exclude(KEYWORD LEFT|INNER|CROSS|NATURAL)}] 1 [list configure -tableAlias \$tableAlias] \
				] ? {} \
			] 1 [list configure -branchIndex 1] \
			GROUP [list \
				TOKEN [list PAR_LEFT "("] 1 {} \
				SUBST [list SYNTAX joinSource] 1 [list configure -joinSource \$joinSource] \
				TOKEN [list PAR_RIGHT ")"] 1 {} \
				GROUP [list \
					TOKEN [list KEYWORD AS] ? [list configure -asKeyword 1] \
					TOKEN [list OTHER|STRING {tableAlias#exclude(KEYWORD LEFT|INNER|CROSS|NATURAL)}] 1 [list configure -tableAlias \$tableAlias] \
				] ? {} \
			] 1 [list configure -branchIndex 2] \
		] 1 {} \
	] \
]

set ::sqlite3::statementSyntax(joinOp) [list \
	StatementJoinOp [list \
		ALTER [list \
			TOKEN [list OPERATOR ","] 1 [list configure -period 1] \
			GROUP [list \
				TOKEN [list KEYWORD NATURAL] ? [list configure -naturalKeyword 1] \
				ALTER [list \
					GROUP [list \
						TOKEN [list KEYWORD LEFT] 1 [list configure -leftKeyword 1] \
						TOKEN [list KEYWORD OUTER] ? [list configure -outerKeyword 1] \
					] 1 {} \
					GROUP [list \
						TOKEN [list KEYWORD OUTER] 1 [list configure -outerKeyword 1] \
						TOKEN [list KEYWORD LEFT] 1 [list configure -leftKeyword 1] \
					] 1 {} \
					TOKEN [list KEYWORD INNER] 1 [list configure -innerKeyword 1] \
					TOKEN [list KEYWORD CROSS] 1 [list configure -crossKeyword 1] \
				] ? {} \
				TOKEN [list KEYWORD JOIN] 1 [list configure -joinKeyword 1] \
			] 1 {} \
		] 1 {} \
	] \
]

set ::sqlite3::statementSyntax(joinConstraint) [list \
	StatementJoinConstraint [list \
		ALTER [list \
			GROUP [list \
				TOKEN [list KEYWORD ON] 1 [list configure -onKeyword 1] \
				SUBST [list SYNTAX expr] 1 [list configure -expr \$expr] \
			] 1 {} \
			GROUP [list \
				TOKEN [list KEYWORD USING] 1 [list configure -usingKeyword 1] \
				TOKEN [list PAR_LEFT "("] 1 {} \
				TOKEN [list OTHER|STRING columnName] 1 [list addColumnName \$columnName] \
				GROUP [list \
					TOKEN [list OPERATOR ","] 1 {} \
					TOKEN [list OTHER|STRING columnName] 1 [list addColumnName \$columnName] \
				] * {} \
				TOKEN [list PAR_RIGHT ")"] 1 {} \
			] 1 {} \
		] ? {} \
	] \
]

set ::sqlite3::statementSyntax(orderingTerm) [list \
	StatementOrderingTerm [list \
		SUBST [list SYNTAX expr] 1 [list configure -expr \$expr] \
		GROUP [list \
			TOKEN [list KEYWORD COLLATE] 1 [list configure -collateKeyword 1] \
			ALTER [list \
				TOKEN [list OTHER|STRING collationName] 1 [list configure -collationName \$collationName] \
				TOKEN [list KEYWORD *] 1 [list configure -collationName \$tokenValue] \
			] 1 {} \
		] ? {} \
		ALTER [list \
			TOKEN [list KEYWORD ASC] 1 [list configure -order "ASC"] \
			TOKEN [list KEYWORD DESC] 1 [list configure -order "DESC"] \
		] ? {} \
	] \
]

set ::sqlite3::statementSyntax(compoundOperator) [list \
	StatementCompoundOperator [list \
		ALTER [list \
			GROUP [list \
				TOKEN [list KEYWORD UNION] 1 [list configure -type "UNION"] \
				TOKEN [list KEYWORD ALL] ? [list configure -allKeyword 1] \
			] 1 {} \
			TOKEN [list KEYWORD INTERSECT] 1 [list configure -type "INTERSECT"] \
			TOKEN [list KEYWORD EXCEPT] 1 [list configure -type "EXCEPT"] \
		] 1 {} \
	] \
]


set ::sqlite3::statementSyntax(expr) [list \
	StatementExpr [list \
		SUBST [list SYNTAX exprOnly] 1 [list configure -exprOnly \$exprOnly] \
		SUBST [list SYNTAX {exprSuffix#exclude(inheritWithMaxRecursion)}] * [list addExprSuffix \$exprSuffix] \
	] \
]

set ::sqlite3::statementSyntax(exprOnly) [list \
	StatementExprOnly [list \
		ALTER [list \
			TOKEN [list BIND_PARAM bindParameter] 1 [list configure -branchIndex 1 -bindParameter \$bindParameter] \
			SUBST [list SYNTAX raiseFunction] 1 [list configure -branchIndex 16 -raiseFunction \$raiseFunction] \
			GROUP [list \
				TOKEN [list KEYWORD CAST] 1 [list configure -castKeyword 1] \
				TOKEN [list PAR_LEFT "("] 1 {} \
				SUBST [list SYNTAX expr] 1 [list configure -expr1 \$expr] \
				TOKEN [list KEYWORD AS] 1 [list configure -asKeyword 1] \
				SUBST [list SYNTAX typeName] 1 [list configure -typeName \$typeName] \
				TOKEN [list PAR_RIGHT ")"] 1 {} \
			] 1 [list configure -branchIndex 7] \
			GROUP [list \
				TOKEN [list PAR_LEFT "("] 1 {} \
				SUBST [list SYNTAX expr] 1 [list configure -expr1 \$expr] \
				TOKEN [list PAR_RIGHT ")"] 1 {} \
			] 1 [list configure -branchIndex 6] \
			GROUP [list \
				GROUP [list \
					TOKEN [list KEYWORD NOT] ? [list configure -notKeyword 1] \
					TOKEN [list KEYWORD EXISTS] 1 [list configure -existsKeyword 1] \
				] ? {} \
				TOKEN [list PAR_LEFT "("] 1 {} \
				SUBST [list SYNTAX selectStmt] 1 [list configure -subSelect \$selectStmt] \
				TOKEN [list PAR_RIGHT ")"] 1 {} \
			] 1 [list configure -branchIndex 14] \
			GROUP [list \
				TOKEN [list OTHER|STRING functionName] 1 [list configure -functionName \$functionName] \
				TOKEN [list PAR_LEFT "("] 1 {} \
				ALTER [list \
					TOKEN [list OPERATOR "*"] 1 [list configure -star 1] \
					GROUP [list \
						TOKEN [list KEYWORD DISTINCT] ? [list configure -distinctKeyword 1] \
						SUBST [list SYNTAX expr] ? [list addExpr \$expr] \
						GROUP [list \
							TOKEN [list OPERATOR ","] 1 {} \
							SUBST [list SYNTAX expr] 1 [list addExpr \$expr] \
						] * {} \
					] 1 {} \
				] ? {} \
				TOKEN [list PAR_RIGHT ")"] 1 {} \
			] 1 [list configure -branchIndex 5] \
			ALTER [list \
				GROUP [list \
					ALTER [list \
						TOKEN [list OPERATOR "+"] 1 [list appendLiteralValue \$token] \
						TOKEN [list OPERATOR "-"] 1 [list appendLiteralValue \$token] \
					] ? {} \
					TOKEN [list STRING|INTEGER|FLOAT literalValue] 1 [list appendLiteralValue \$literalValue] \
				] 1 {} \
				TOKEN [list KEYWORD NULL] 1 [list configure -literalValueKeyword "NULL"] \
				TOKEN [list KEYWORD CURRENT_TIME] 1 [list configure -literalValueKeyword "CURRENT_TIME"] \
				TOKEN [list KEYWORD CURRENT_DATE] 1 [list configure -literalValueKeyword "CURRENT_DATE"] \
				TOKEN [list KEYWORD CURRENT_TIMESTAMP] 1 [list configure -literalValueKeyword "CURRENT_TIMESTAMP"] \
			] 1 [list configure -branchIndex 0] \
			GROUP [list \
				ALTER [list \
					GROUP [list \
						TOKEN [list OTHER|STRING databaseName] 1 [list configure -databaseName \$databaseName] \
						TOKEN [list OPERATOR "."] 1 {} \
						TOKEN [list OTHER|STRING tableName] 1 [list configure -tableName \$tableName] \
						TOKEN [list OPERATOR "."] 1 {} \
						TOKEN [list OTHER|STRING columnName] {1 ?} [list configure -columnName \$columnName] \
					] 1 {} \
					GROUP [list \
						TOKEN [list OTHER|STRING tableName] 1 [list configure -tableName \$tableName] \
						TOKEN [list OPERATOR "."] 1 {} \
						TOKEN [list OTHER|STRING columnName] {1 ?} [list configure -columnName \$columnName] \
					] 1 {} \
					TOKEN [list OTHER|STRING columnName] 1 [list configure -columnName \$columnName] \
				] 1 {} \
			] 1 [list configure -branchIndex 2] \
			GROUP [list \
				ALTER [list \
					TOKEN [list OPERATOR "+"] 1 [list configure -unaryOperator "+"] \
					TOKEN [list OPERATOR "-"] 1 [list configure -unaryOperator "-"] \
					TOKEN [list OPERATOR "~"] 1 [list configure -unaryOperator "~"] \
					TOKEN [list KEYWORD NOT] 1 [list configure -unaryOperator "NOT"] \
				] 1 {} \
				SUBST [list SYNTAX expr] 1 [list configure -expr1 \$expr] \
			] 1 [list configure -branchIndex 3] \
			GROUP [list \
				TOKEN [list KEYWORD CASE] 1 [list configure -caseKeyword 1] \
				SUBST [list SYNTAX expr] ? [list configure -expr1 \$expr] \
				GROUP [list \
					TOKEN [list KEYWORD WHEN] 1 {} \
					SUBST [list SYNTAX expr] 1 [list addWhenExpr \$expr] \
					TOKEN [list KEYWORD THEN] 1 {} \
					SUBST [list SYNTAX expr] 1 [list addThenExpr \$expr] \
				] * {} \
				GROUP [list \
					TOKEN [list KEYWORD ELSE] 1 [list configure -elseKeyword 1] \
					SUBST [list SYNTAX expr] 1 [list configure -expr2 \$expr] \
				] ? {} \
				TOKEN [list KEYWORD END] 1 [list configure -endKeyword 1] \
			] 1 [list configure -branchIndex 15] \
		] 1 {} \
	] \
]

set ::sqlite3::statementSyntax(exprSuffix) [list \
	StatementExprSuffix [list \
		ALTER [list \
			GROUP [list \
				TOKEN [list KEYWORD COLLATE] 1 [list configure -collateKeyword 1] \
				ALTER [list \
					TOKEN [list OTHER|STRING collationName] 1 [list configure -collationName \$collationName] \
					TOKEN [list KEYWORD *] 1 [list configure -collationName \$tokenValue] \
				] 1 {} \
			] 1 [list configure -branchIndex 8] \
			GROUP [list \
				TOKEN [list KEYWORD NOT] ? [list configure -notKeyword 1] \
				ALTER [list \
					TOKEN [list KEYWORD LIKE] 1 [list configure -binaryOperator "LIKE" -binOpWord 1] \
					TOKEN [list KEYWORD GLOB] 1 [list configure -binaryOperator "GLOB" -binOpWord 1] \
					TOKEN [list KEYWORD REGEXP] 1 [list configure -binaryOperator "REGEXP" -binOpWord 1] \
					TOKEN [list KEYWORD MATCH] 1 [list configure -binaryOperator "MATCH" -binOpWord 1] \
				] 1 {} \
				SUBST [list SYNTAX expr] 1 [list configure -expr2 \$expr] \
				GROUP [list \
					TOKEN [list KEYWORD ESCAPE] 1 [list configure -escapeKeyword 1] \
					SUBST [list SYNTAX expr] 1 [list configure -expr3 \$expr] \
				] ? {} \
			] 1 [list configure -branchIndex 9] \
			GROUP [list \
				ALTER [list \
					GROUP [list \
						TOKEN [list KEYWORD IS] 1 {} \
						TOKEN [list KEYWORD NOT] 1 {} \
						TOKEN [list KEYWORD NULL] 1 {} \
					] 1 [list configure -nullDefinition "IS NOT NULL"] \
					GROUP [list \
						TOKEN [list KEYWORD NOT] 1 {} \
						TOKEN [list KEYWORD NULL] 1 {} \
					] 1 [list configure -nullDefinition "NOT NULL"] \
					GROUP [list \
						TOKEN [list KEYWORD IS] 1 {} \
						TOKEN [list KEYWORD NULL] 1 {} \
					] 1 [list configure -nullDefinition "IS NULL"] \
					TOKEN [list KEYWORD ISNULL] 1 [list configure -nullDefinition "ISNULL"] \
					TOKEN [list KEYWORD NOTNULL] 1 [list configure -nullDefinition "NOTNULL"] \
				] 1 {} \
			] 1 [list configure -branchIndex 10] \
			GROUP [list \
				TOKEN [list KEYWORD IS] 1 {} \
				TOKEN [list KEYWORD NOT] ? [list configure -notKeyword 1] \
				SUBST [list SYNTAX expr] 1 [list configure -expr2 \$expr] \
			] 1 [list configure -branchIndex 11] \
			GROUP [list \
				TOKEN [list KEYWORD NOT] ? [list configure -notKeyword 1] \
				TOKEN [list KEYWORD BETWEEN] 1 [list configure -betweenKeyword 1] \
				SUBST [list SYNTAX {expr#exclude(KEYWORD AND 1)}] 1 [list configure -expr2 \$expr] \
				TOKEN [list KEYWORD AND] 1 [list configure -andKeyword 1] \
				SUBST [list SYNTAX expr] 1 [list configure -expr3 \$expr] \
			] 1 [list configure -branchIndex 12] \
			GROUP [list \
				TOKEN [list KEYWORD NOT] ? [list configure -notKeyword 1] \
				TOKEN [list KEYWORD IN] 1 [list configure -inKeyword 1] \
				ALTER [list \
					GROUP [list \
						TOKEN [list PAR_LEFT "("] 1 {} \
						ALTER [list \
							SUBST [list SYNTAX selectStmt] 1 [list configure -subSelect \$selectStmt] \
							GROUP [list \
								SUBST [list SYNTAX expr] 1 [list addExpr \$expr] \
								GROUP [list \
									TOKEN [list OPERATOR ","] 1 {} \
									SUBST [list SYNTAX expr] 1 [list addExpr \$expr] \
								] * {} \
							] 1 {} \
						] ? {} \
						TOKEN [list PAR_RIGHT ")"] 1 {} \
					] 1 {} \
					ALTER [list \
						GROUP [list \
							TOKEN [list OTHER|STRING databaseName] 1 [list configure -databaseName \$databaseName] \
							TOKEN [list OPERATOR "."] 1 {} \
							TOKEN [list OTHER|STRING tableName] {1 ?} [list configure -tableName \$tableName] \
						] 1 {} \
						TOKEN [list OTHER|STRING tableName] 1 [list configure -tableName \$tableName] \
					] 1 {} \
				] 1 {} \
			] 1 [list configure -branchIndex 13] \
			GROUP [list \
				ALTER [list \
					TOKEN [list OPERATOR "||"] 1 [list configure -binaryOperator "||"] \
					TOKEN [list OPERATOR "+"] 1 [list configure -binaryOperator "+"] \
					TOKEN [list OPERATOR "-"] 1 [list configure -binaryOperator "-"] \
					TOKEN [list OPERATOR "*"] 1 [list configure -binaryOperator "*"] \
					TOKEN [list OPERATOR "/"] 1 [list configure -binaryOperator "/"] \
					TOKEN [list OPERATOR "%"] 1 [list configure -binaryOperator "%"] \
					TOKEN [list OPERATOR "<<"] 1 [list configure -binaryOperator "<<"] \
					TOKEN [list OPERATOR ">>"] 1 [list configure -binaryOperator ">>"] \
					TOKEN [list OPERATOR "&"] 1 [list configure -binaryOperator "&"] \
					TOKEN [list OPERATOR "|"] 1 [list configure -binaryOperator "|"] \
					TOKEN [list OPERATOR "<"] 1 [list configure -binaryOperator "<"] \
					TOKEN [list OPERATOR "<="] 1 [list configure -binaryOperator "<="] \
					TOKEN [list OPERATOR ">"] 1 [list configure -binaryOperator ">"] \
					TOKEN [list OPERATOR ">="] 1 [list configure -binaryOperator ">="] \
					TOKEN [list OPERATOR "="] 1 [list configure -binaryOperator "="] \
					TOKEN [list OPERATOR "=="] 1 [list configure -binaryOperator "=="] \
					TOKEN [list OPERATOR "!="] 1 [list configure -binaryOperator "!="] \
					TOKEN [list OPERATOR "<>"] 1 [list configure -binaryOperator "<>"] \
					TOKEN [list KEYWORD IN] 1 [list configure -binaryOperator "IN" -binOpWord 1] \
					TOKEN [list KEYWORD LIKE] 1 [list configure -binaryOperator "LIKE" -binOpWord 1] \
					TOKEN [list KEYWORD GLOB] 1 [list configure -binaryOperator "GLOB" -binOpWord 1] \
					TOKEN [list KEYWORD MATCH] 1 [list configure -binaryOperator "MATCH" -binOpWord 1] \
					TOKEN [list KEYWORD REGEXP] 1 [list configure -binaryOperator "REGEXP" -binOpWord 1] \
					TOKEN [list KEYWORD AND] 1 [list configure -binaryOperator "AND" -binOpWord 1] \
					TOKEN [list KEYWORD OR] 1 [list configure -binaryOperator "OR" -binOpWord 1] \
				] 1 {} \
				SUBST [list SYNTAX expr] 1 [list configure -expr2 \$expr] \
			] 1 [list configure -branchIndex 4] \
		] 1 {} \
	] \
]

set ::sqlite3::statementSyntax(raiseFunction) [list \
	StatementRaiseFunction [list \
		TOKEN [list KEYWORD RAISE] 1 [list configure -raiseKeyword 1] \
		TOKEN [list PAR_LEFT "("] 1 {} \
		ALTER [list \
			TOKEN [list KEYWORD IGNORE] 1 [list configure -ignoreKeyword 1] \
			GROUP [list \
				ALTER [list \
					TOKEN [list KEYWORD ROLLBACK] 1 [list configure -rollbackKeyword 1] \
					TOKEN [list KEYWORD ABORT] 1 [list configure -abortKeyword 1] \
					TOKEN [list KEYWORD FAIL] 1 [list configure -failKeyword 1] \
				] 1 {} \
				TOKEN [list OPERATOR ","] 1 {} \
				TOKEN [list STRING|OTHER|INTEGER|FLOAT errorMessage] 1 [list configure -errorMessage \$errorMessage] \
			] 1 {} \
		] 1 {} \
		TOKEN [list PAR_RIGHT ")"] 1 {} \
	] \
]

set ::sqlite3::statementSyntax(createTableStmt) [list \
	StatementCreateTable [list \
		TOKEN [list KEYWORD CREATE] 1 {} \
		ALTER [list \
			TOKEN [list KEYWORD TEMP] 1 [list configure -temporary "TEMP"] \
			TOKEN [list KEYWORD TEMPORARY] 1 [list configure -temporary "TEMPORARY"] \
		] ? {} \
		TOKEN [list KEYWORD TABLE] 1 {} \
		GROUP [list \
			TOKEN [list KEYWORD IF] 1 {} \
			TOKEN [list KEYWORD NOT] 1 {} \
			TOKEN [list KEYWORD EXISTS] 1 {} \
		] ? [list configure -ifNotExists 1] \
		ALTER [list \
			GROUP [list \
				TOKEN [list OTHER|STRING databaseName] 1 [list configure -databaseName \$databaseName] \
				TOKEN [list OPERATOR "."] 1 {} \
				TOKEN [list OTHER|STRING tableName] {1 ?} [list configure -tableName \$tableName] \
			] 1 {} \
			TOKEN [list OTHER|STRING tableName] 1 [list configure -tableName \$tableName] \
		] 1 {} \
		ALTER [list \
			GROUP [list \
				TOKEN [list PAR_LEFT "("] 1 {} \
				SUBST [list SYNTAX columnDef] 1 [list addColumnDef \$columnDef] \
				GROUP [list \
					TOKEN [list OPERATOR ","] 1 {} \
					SUBST [list SYNTAX columnDef] 1 [list addColumnDef \$columnDef] \
				] * {} \
				SUBST [list SYNTAX tableConstraint] ? [list addTableConstraint \$tableConstraint] \
				GROUP [list \
					TOKEN [list OPERATOR ","] ? {} \
					SUBST [list SYNTAX tableConstraint] 1 [list addTableConstraint \$tableConstraint] \
				] * {} \
				TOKEN [list PAR_RIGHT ")"] 1 {} \
			] 1 {} \
			GROUP [list \
				TOKEN [list KEYWORD AS] 1 [list configure -asKeyword 1] \
				SUBST [list SYNTAX selectStmt] 1 [list configure -subSelect \$selectStmt] \
			] 1 {} \
		] 1 {} \
	] \
]

set ::sqlite3::statementSyntax(columnDef) [list \
	StatementColumnDef [list \
		TOKEN [list OTHER|STRING columnName] 1 [list configure -columnName \$columnName] \
		SUBST [list SYNTAX typeName] ? [list configure -typeName \$typeName] \
		SUBST [list SYNTAX columnConstraint] * [list addColumnConstraint \$columnConstraint] \
	] \
]


# 			TOKEN [list OTHER|STRING name] 1 [list addNameWord \$name] \
# 			TOKEN [list KEYWORD "NUMERIC"] 1 [list addNameKeyword \$token] \
# 			TOKEN [list KEYWORD "REAL"] 1 [list addNameKeyword \$token] \
# 			TOKEN [list KEYWORD "NONE"] 1 [list addNameKeyword \$token] \
# 			TOKEN [list KEYWORD "INTEGER"] 1 [list addNameKeyword \$token] \
# 			TOKEN [list KEYWORD "INT"] 1 [list addNameKeyword \$token] \
# 			TOKEN [list KEYWORD "TEXT"] 1 [list addNameKeyword \$token] \
# 			TOKEN [list KEYWORD "BLOB"] 1 [list addNameKeyword \$token] \
# 			TOKEN [list KEYWORD "VARCHAR"] 1 [list addNameKeyword \$token] \
# 			TOKEN [list KEYWORD "CHAR"] 1 [list addNameKeyword \$token] \
# 			TOKEN [list KEYWORD "DATE"] 1 [list addNameKeyword \$token] \
# 			TOKEN [list KEYWORD "DATETIME"] 1 [list addNameKeyword \$token]

set ::sqlite3::statementSyntax(typeName) [list \
	StatementTypeName [list \
		ALTER [list \
			TOKEN [list OTHER|STRING name] 1 [list addNameWord \$name] \
			TOKEN [list KEYWORD "NUMERIC"] 1 [list addNameWord \$token] \
			TOKEN [list KEYWORD "REAL"] 1 [list addNameWord \$token] \
			TOKEN [list KEYWORD "NONE"] 1 [list addNameWord \$token] \
			TOKEN [list KEYWORD "INTEGER"] 1 [list addNameWord \$token] \
			TOKEN [list KEYWORD "INT"] 1 [list addNameWord \$token] \
			TOKEN [list KEYWORD "TEXT"] 1 [list addNameWord "TEXT"] \
			TOKEN [list KEYWORD "BLOB"] 1 [list addNameWord \$token] \
			TOKEN [list KEYWORD "VARCHAR"] 1 [list addNameWord \$token] \
			TOKEN [list KEYWORD "CHAR"] 1 [list addNameWord \$token] \
			TOKEN [list KEYWORD "DATE"] 1 [list addNameWord \$token] \
			TOKEN [list KEYWORD "DATETIME"] 1 [list addNameWord \$token] \
		] + {} \
		ALTER [list \
			GROUP [list \
				TOKEN [list PAR_LEFT "("] 1 {} \
				ALTER [list \
					TOKEN [list OPERATOR "+"] 1 [list appendSize \$token] \
					TOKEN [list OPERATOR "-"] 1 [list appendSize \$token] \
				] ? {} \
				TOKEN [list INTEGER size] 1 [list appendSize \$size] \
				TOKEN [list PAR_RIGHT ")"] 1 {} \
			] 1 {} \
			GROUP [list \
				TOKEN [list PAR_LEFT "("] 1 {} \
				ALTER [list \
					TOKEN [list OPERATOR "+"] 1 [list appendSize \$token] \
					TOKEN [list OPERATOR "-"] 1 [list appendSize \$token] \
				] ? {} \
				TOKEN [list INTEGER size] 1 [list appendSize \$size] \
				TOKEN [list OPERATOR ","] 1 {} \
				ALTER [list \
					TOKEN [list OPERATOR "+"] 1 [list appendPrecision \$token] \
					TOKEN [list OPERATOR "-"] 1 [list appendPrecision \$token] \
				] ? {} \
				TOKEN [list INTEGER precision] 1 [list appendPrecision \$precision] \
				TOKEN [list PAR_RIGHT ")"] 1 {} \
			] 1 {} \
		] ? {} \
	] \
]

set ::sqlite3::statementSyntax(columnConstraint) [list \
	StatementColumnConstraint [list \
		GROUP [list \
			TOKEN [list KEYWORD CONSTRAINT] 1 {} \
			TOKEN [list OTHER|STRING name] 1 [list configure -constraintName \$name] \
		] ? [list configure -namedConstraint 1] \
		ALTER [list \
			GROUP [list \
				TOKEN [list KEYWORD PRIMARY] 1 {} \
				TOKEN [list KEYWORD KEY] 1 {} \
				ALTER [list \
					TOKEN [list KEYWORD ASC] 1 [list configure -order "ASC"] \
					TOKEN [list KEYWORD DESC] 1 [list configure -order "DESC"] \
				] ? {} \
				SUBST [list SYNTAX conflictClause] ? [list configure -conflictClause \$conflictClause] \
				TOKEN [list KEYWORD AUTOINCREMENT] ? [list configure -autoincrement 1] \
			] 1 [list configure -branchIndex 0] \
			GROUP [list \
				TOKEN [list KEYWORD NOT] ? [list configure -notKeyword 1] \
				TOKEN [list KEYWORD NULL] 1 {} \
				SUBST [list SYNTAX conflictClause] ? [list configure -conflictClause \$conflictClause] \
			] 1 [list configure -branchIndex 1] \
			GROUP [list \
				TOKEN [list KEYWORD UNIQUE] 1 {} \
				SUBST [list SYNTAX conflictClause] ? [list configure -conflictClause \$conflictClause] \
			] 1 [list configure -branchIndex 2] \
			GROUP [list \
				TOKEN [list KEYWORD CHECK] 1 {} \
				TOKEN [list PAR_LEFT "("] 1 {} \
				SUBST [list SYNTAX expr] 1 [list configure -expr \$expr] \
				TOKEN [list PAR_RIGHT ")"] 1 {} \
			] 1 [list configure -branchIndex 3] \
			GROUP [list \
				TOKEN [list KEYWORD DEFAULT] 1 {} \
				ALTER [list \
					GROUP [list \
						TOKEN [list PAR_LEFT "("] 1 {} \
						SUBST [list SYNTAX expr] 1 [list configure -expr \$expr] \
						TOKEN [list PAR_RIGHT ")"] 1 {} \
					] 1 {} \
					GROUP [list \
						ALTER [list \
							TOKEN [list OPERATOR "-"] 1 [list appendLiteralValue \$token] \
							TOKEN [list OPERATOR "+"] 1 [list appendLiteralValue \$token] \
						] ? {} \
						TOKEN [list STRING|INTEGER|FLOAT|OTHER literalValue] 1 [list appendLiteralValue \$literalValue] \
					] 1 {} \
					TOKEN [list KEYWORD NULL] 1 [list appendLiteralValue \$token] \
					TOKEN [list KEYWORD CURRENT_DATE] 1 [list appendLiteralValue \$token] \
					TOKEN [list KEYWORD CURRENT_TIME] 1 [list appendLiteralValue \$token] \
					TOKEN [list KEYWORD CURRENT_TIMESTAMP] 1 [list appendLiteralValue \$token] \
				] 1 {} \
			] 1 [list configure -branchIndex 4] \
			GROUP [list \
				TOKEN [list KEYWORD COLLATE] 1 {} \
				ALTER [list \
					TOKEN [list OTHER|STRING collationName] 1 [list configure -collationName \$collationName] \
					TOKEN [list KEYWORD *] 1 [list configure -collationName \$tokenValue] \
				] 1 {} \
			] 1 [list configure -branchIndex 5] \
			SUBST [list SYNTAX foreignKeyClause] 1 [list configure -branchIndex 6 -foreignKey \$foreignKeyClause] \
		] 1 {} \
	] \
]

set ::sqlite3::statementSyntax(tableConstraint) [list \
	StatementTableConstraint [list \
		GROUP [list \
			TOKEN [list KEYWORD CONSTRAINT] 1 {} \
			TOKEN [list OTHER|STRING name] 1 [list configure -constraintName \$name] \
		] ? [list configure -namedConstraint 1] \
		ALTER [list \
			GROUP [list \
				TOKEN [list KEYWORD PRIMARY] 1 {} \
				TOKEN [list KEYWORD KEY] 1 {} \
				TOKEN [list PAR_LEFT "("] 1 {} \
				ALTER [list \
					GROUP [list \
						SUBST [list SYNTAX indexedColumn] 1 [list addIndexedColumn \$indexedColumn] \
						TOKEN [list KEYWORD AUTOINCREMENT] 1 [list configure -autoincrement 1] \
					] 1 {} \
					GROUP [list \
						SUBST [list SYNTAX indexedColumn] 1 [list addIndexedColumn \$indexedColumn] \
						GROUP [list \
							TOKEN [list OPERATOR ","] 1 {} \
							SUBST [list SYNTAX indexedColumn] 1 [list addIndexedColumn \$indexedColumn] \
						] * {} \
					] 1 {} \
				] 1 {} \
				TOKEN [list PAR_RIGHT ")"] 1 {} \
				SUBST [list SYNTAX conflictClause] ? [list configure -conflictClause \$conflictClause] \
			] 1 [list configure -branchIndex 0] \
			GROUP [list \
				TOKEN [list KEYWORD UNIQUE] 1 {} \
				TOKEN [list PAR_LEFT "("] 1 {} \
				SUBST [list SYNTAX indexedColumn] 1 [list addIndexedColumn \$indexedColumn] \
				GROUP [list \
					TOKEN [list OPERATOR ","] 1 {} \
					SUBST [list SYNTAX indexedColumn] 1 [list addIndexedColumn \$indexedColumn] \
				] * {} \
				TOKEN [list PAR_RIGHT ")"] 1 {} \
				SUBST [list SYNTAX conflictClause] ? [list configure -conflictClause \$conflictClause] \
			] 1 [list configure -branchIndex 1] \
			GROUP [list \
				TOKEN [list KEYWORD CHECK] 1 {} \
				TOKEN [list PAR_LEFT "("] 1 {} \
				SUBST [list SYNTAX expr] 1 [list configure -expr \$expr] \
				TOKEN [list PAR_RIGHT ")"] 1 {} \
			] 1 [list configure -branchIndex 2] \
			GROUP [list \
				TOKEN [list KEYWORD FOREIGN] 1 {} \
				TOKEN [list KEYWORD KEY] 1 {} \
				TOKEN [list PAR_LEFT "("] 1 {} \
				TOKEN [list STRING|OTHER columnName] 1 [list addColumnName \$columnName] \
				GROUP [list \
					TOKEN [list OPERATOR ","] 1 {} \
					TOKEN [list STRING|OTHER columnName] 1 [list addColumnName \$columnName] \
				] * {} \
				TOKEN [list PAR_RIGHT ")"] 1 {} \
				SUBST [list SYNTAX foreignKeyClause] 1 [list configure -foreignKey \$foreignKeyClause] \
			] 1 [list configure -branchIndex 3] \
		] 1 {} \
		GROUP [list \
			TOKEN [list KEYWORD CONSTRAINT] 1 {} \
			TOKEN [list OTHER|STRING name] 1 [list configure -constraintName \$name] \
		] ? [list configure -namedConstraint 1] \
	] \
]

set ::sqlite3::statementSyntax(foreignKeyClause) [list \
	StatementForeignKeyClause [list \
		TOKEN [list KEYWORD REFERENCES] 1 {} \
		TOKEN [list OTHER|STRING tableName] 1 [list configure -tableName \$tableName] \
		GROUP [list \
			TOKEN [list PAR_LEFT "("] 1 {} \
			TOKEN [list STRING|OTHER columnName] ? [list addColumnName \$columnName] \
			GROUP [list \
				TOKEN [list OPERATOR ","] 1 {} \
				TOKEN [list STRING|OTHER columnName] {1 ?} [list addColumnName \$columnName] \
			] * {} \
			TOKEN [list PAR_RIGHT ")"] 1 {} \
		] ? {} \
		GROUP [list \
			ALTER [list \
				GROUP [list \
					TOKEN [list KEYWORD ON] 1 {} \
					ALTER [list \
						TOKEN [list KEYWORD DELETE] 1 [list setNextAction onDelete] \
						TOKEN [list KEYWORD UPDATE] 1 [list setNextAction onUpdate] \
						TOKEN [list KEYWORD INSERT] 1 {} \
					] 1 {} \
					ALTER [list \
						GROUP [list \
							TOKEN [list KEYWORD SET] 1 {} \
							TOKEN [list KEYWORD NULL] 1 {} \
						] 1 [list setActionValue "SET NULL"] \
						GROUP [list \
							TOKEN [list KEYWORD SET] 1 {} \
							TOKEN [list KEYWORD DEFAULT] 1 {} \
						] 1 [list setActionValue "SET DEFAULT"] \
						TOKEN [list KEYWORD CASCADE] 1 [list setActionValue "CASCADE"] \
						TOKEN [list KEYWORD RESTRICT] 1 [list setActionValue "RESTRICT"] \
						GROUP [list \
							TOKEN [list KEYWORD NO] 1 {} \
							TOKEN [list KEYWORD ACTION] 1 {} \
						] 1 [list setActionValue "NO ACTION"] \
					] 1 {} \
				] 1 {} \
				GROUP [list \
					TOKEN [list KEYWORD MATCH] 1 [list configure -matchKeyword 1] \
					ALTER [list \
						TOKEN [list OTHER|STRING name] 1 [list configure -matchName \$name] \
						TOKEN [list KEYWORD FULL] 1 [list configure -matchName "FULL"] \
					] 1 {} \
				] 1 {} \
			] * {} \
		] ? {} \
		GROUP [list \
			TOKEN [list KEYWORD NOT] ? [list configure -notKeyword 1] \
			TOKEN [list KEYWORD DEFERRABLE] 1 [list configure -deferrableKeyword 1] \
			ALTER [list \
				GROUP [list \
					TOKEN [list KEYWORD INITIALLY] 1 [list configure -initiallyKeyword 1] \
					TOKEN [list KEYWORD DEFERRED] 1 [list configure -deferredKeyword 1] \
				] 1 {} \
				GROUP [list \
					TOKEN [list KEYWORD INITIALLY] 1 [list configure -initiallyKeyword 1] \
					TOKEN [list KEYWORD IMMEDIATE] 1 [list configure -immediateKeyword 1] \
				] 1 {} \
			] ? {} \
		] ? {} \
	] \
]

set ::sqlite3::statementSyntax(conflictClause) [list \
	StatementConflictClause [list \
		GROUP [list \
			TOKEN [list KEYWORD ON] 1 [list configure -onKeyword 1] \
			TOKEN [list KEYWORD CONFLICT] 1 [list configure -conflictKeyword 1] \
			ALTER [list \
				TOKEN [list KEYWORD ROLLBACK] 1 [list configure -clause "ROLLBACK"] \
				TOKEN [list KEYWORD ABORT] 1 [list configure -clause "ABORT"] \
				TOKEN [list KEYWORD FAIL] 1 [list configure -clause "FAIL"] \
				TOKEN [list KEYWORD IGNORE] 1 [list configure -clause "IGNORE"] \
				TOKEN [list KEYWORD REPLACE] 1 [list configure -clause "REPLACE"] \
			] 1 {} \
		] 1 {} \
	] \
]

set ::sqlite3::statementSyntax(createTriggerStmt) [list \
	StatementCreateTrigger [list \
		TOKEN [list KEYWORD CREATE] 1 {} \
		ALTER [list \
			TOKEN [list KEYWORD TEMP] 1 [list configure -temporary "TEMP"] \
			TOKEN [list KEYWORD TEMPORARY] 1 [list configure -temporary "TEMPORARY"] \
		] ? {} \
		TOKEN [list KEYWORD TRIGGER] 1 {} \
		GROUP [list \
			TOKEN [list KEYWORD IF] 1 {} \
			TOKEN [list KEYWORD NOT] 1 {} \
			TOKEN [list KEYWORD EXISTS] 1 {} \
		] ? [list configure -ifNotExists 1] \
		ALTER [list \
			GROUP [list \
				TOKEN [list OTHER|STRING databaseName] 1 [list configure -databaseName \$databaseName] \
				TOKEN [list OPERATOR "."] 1 {} \
				TOKEN [list OTHER|STRING trigName] {1 ?} [list configure -trigName \$trigName] \
			] 1 {} \
			TOKEN [list OTHER|STRING trigName] 1 [list configure -trigName \$trigName] \
		] 1 {} \
		ALTER [list \
			TOKEN [list KEYWORD BEFORE] 1 [list configure -afterBefore "BEFORE"] \
			TOKEN [list KEYWORD AFTER] 1 [list configure -afterBefore "AFTER"] \
			GROUP [list \
				TOKEN [list KEYWORD INSTEAD] 1 {} \
				TOKEN [list KEYWORD OF] 1 {} \
			] 1 [list configure -afterBefore "INSTEAD OF"] \
		] ? {} \
		ALTER [list \
			TOKEN [list KEYWORD DELETE] 1 [list configure -action "DELETE"] \
			TOKEN [list KEYWORD INSERT] 1 [list configure -action "INSERT"] \
			GROUP [list \
				TOKEN [list KEYWORD UPDATE] 1 [list configure -action "UPDATE"] \
				GROUP [list \
					TOKEN [list KEYWORD OF] 1 [list configure -ofKeyword 1] \
					TOKEN [list STRING|OTHER columnName] 1 [list addColumn \$columnName] \
					GROUP [list \
						TOKEN [list OPERATOR ","] 1 {} \
						TOKEN [list STRING|OTHER columnName] 1 [list addColumn \$columnName] \
					] * {} \
				] ? {} \
			] 1 {} \
		] 1 {} \
		TOKEN [list KEYWORD ON] 1 {} \
		ALTER [list \
			GROUP [list \
				TOKEN [list OTHER|STRING databaseName] 1 [list configure -databaseName \$databaseName] \
				TOKEN [list OPERATOR "."] 1 {} \
				TOKEN [list OTHER|STRING tableName] {1 ?} [list configure -trigName \$tableName] \
			] 1 {} \
			TOKEN [list OTHER|STRING tableName] {1 ?} [list configure -tableName \$tableName] \
		] 1 {} \
		GROUP [list \
			TOKEN [list KEYWORD FOR] 1 {} \
			TOKEN [list KEYWORD EACH] 1 {} \
			TOKEN [list KEYWORD ROW] 1 {} \
		] ? [list configure -forEachRow 1] \
		GROUP [list \
			TOKEN [list KEYWORD WHEN] 1 {} \
			SUBST [list SYNTAX expr] 1 [list configure -whenExpr \$expr] \
		] ? {} \
		TOKEN [list KEYWORD BEGIN] 1 {} \
		GROUP [list \
			ALTER [list \
				SUBST [list SYNTAX updateStmt] 1 [list addBodyStatement \$updateStmt] \
				SUBST [list SYNTAX insertStmt] 1 [list addBodyStatement \$insertStmt] \
				SUBST [list SYNTAX deleteStmt] 1 [list addBodyStatement \$deleteStmt] \
				SUBST [list SYNTAX selectStmt] 1 [list addBodyStatement \$selectStmt] \
			] 1 {} \
			TOKEN [list OPERATOR ";"] 1 {} \
		] + {} \
		TOKEN [list KEYWORD END] 1 {} \
	] \
]

set ::sqlite3::statementSyntax(updateStmt) [list \
	StatementUpdate [list \
		TOKEN [list KEYWORD UPDATE] 1 {} \
		GROUP [list \
			TOKEN [list KEYWORD OR] 1 [list configure -orKeyword 1] \
			ALTER [list \
				TOKEN [list KEYWORD ROLLBACK] 1 [list configure -orAction "ROLLBACK"] \
				TOKEN [list KEYWORD ABORT] 1 [list configure -orAction "ABORT"] \
				TOKEN [list KEYWORD REPLACE] 1 [list configure -orAction "REPLACE"] \
				TOKEN [list KEYWORD FAIL] 1 [list configure -orAction "FAIL"] \
				TOKEN [list KEYWORD IGNORE] 1 [list configure -orAction "IGNORE"] \
			] 1 {} \
		] ? {} \
		SUBST [list SYNTAX qualifiedTableName] 1 [list configure -qualifiedTableName \$qualifiedTableName] \
		TOKEN [list KEYWORD SET] 1 {} \
		GROUP [list \
			TOKEN [list OTHER|STRING columnName] 1 [list addColumnName \$columnName] \
			TOKEN [list OPERATOR "="] 1 {} \
			SUBST [list SYNTAX expr] 1 [list addColumnValue \$expr] \
		] {1 ?} {} \
		GROUP [list \
			TOKEN [list OPERATOR ","] 1 {} \
			GROUP [list \
				TOKEN [list OTHER|STRING columnName] 1 [list addColumnName \$columnName] \
				TOKEN [list OPERATOR "="] 1 {} \
				SUBST [list SYNTAX expr] 1 [list addColumnValue \$expr] \
			] {1 ?} {} \
		] * {} \
		GROUP [list \
			TOKEN [list KEYWORD WHERE] 1 {} \
			SUBST [list SYNTAX expr] {1 ?} [list configure -whereExpr \$expr] \
		] ? {} \
		GROUP [list \
			GROUP [list \
				TOKEN [list KEYWORD ORDER] 1 {} \
				TOKEN [list KEYWORD BY] 1 [list configure -orderByKeyword 1] \
				SUBST [list SYNTAX orderingTerm] 1 [list addOrderingTerm \$orderingTerm] \
				GROUP [list \
					TOKEN [list OPERATOR ","] 1 {} \
					SUBST [list SYNTAX orderingTerm] 1 [list addOrderingTerm \$orderingTerm] \
				] * {} \
			] ? {} \
			TOKEN [list KEYWORD LIMIT] 1 [list configure -limitKeyword 1] \
			SUBST [list SYNTAX expr] 1 [list configure -limit \$expr] \
			GROUP [list \
				ALTER [list \
					TOKEN [list KEYWORD OFFSET] 1 [list configure -offsetKeyword 1] \
					TOKEN [list OPERATOR ","] 1 [list configure -offsetKeyword 2] \
				] 1 {} \
				SUBST [list SYNTAX expr] 1 [list configure -offset \$expr] \
			] ? {} \
		] ? {} \
	] \
]

set ::sqlite3::statementSyntax(qualifiedTableName) [list \
	StatementQualifiedTableName [list \
		ALTER [list \
			GROUP [list \
				TOKEN [list OTHER|STRING databaseName] 1 [list configure -databaseName \$databaseName] \
				TOKEN [list OPERATOR "."] 1 {} \
				TOKEN [list OTHER|STRING tableName] {1 ?} [list configure -tableName \$tableName] \
			] 1 {} \
			TOKEN [list OTHER|STRING tableName] 1 [list configure -tableName \$tableName] \
		] 1 {} \
		ALTER [list \
			GROUP [list \
				TOKEN [list KEYWORD INDEXED] 1 [list configure -indexedKeyword 1] \
				TOKEN [list KEYWORD BY] 1 {} \
				TOKEN [list OTHER|STRING indexName] 1 [list configure -indexName \$indexName] \
			] 1 {} \
			GROUP [list \
				TOKEN [list KEYWORD NOT] 1 [list configure -notKeyword 1] \
				TOKEN [list KEYWORD INDEXED] 1 [list configure -indexedKeyword 1]
			] 1 {} \
		] ? {} \
	] \
]

set ::sqlite3::statementSyntax(insertStmt) [list \
	StatementInsert [list \
		ALTER [list \
			GROUP [list \
				TOKEN [list KEYWORD INSERT] 1 [list configure -insertKeyword 1] \
				GROUP [list \
					TOKEN [list KEYWORD OR] 1 [list configure -orKeyword 1] \
					ALTER [list \
						TOKEN [list KEYWORD ROLLBACK] 1 [list configure -orAction "ROLLBACK"] \
						TOKEN [list KEYWORD ABORT] 1 [list configure -orAction "ABORT"] \
						TOKEN [list KEYWORD REPLACE] 1 [list configure -orAction "REPLACE"] \
						TOKEN [list KEYWORD FAIL] 1 [list configure -orAction "FAIL"] \
						TOKEN [list KEYWORD IGNORE] 1 [list configure -orAction "IGNORE"] \
					] 1 {} \
				] ? {} \
			] 1 {} \
			TOKEN [list KEYWORD REPLACE] 1 [list configure -replaceKeyword 1] \
		] 1 {} \
		TOKEN [list KEYWORD INTO] 1 {} \
		ALTER [list \
			GROUP [list \
				TOKEN [list OTHER|STRING databaseName] 1 [list configure -databaseName \$databaseName] \
				TOKEN [list OPERATOR "."] 1 {} \
				TOKEN [list OTHER|STRING tableName] {1 ?} [list configure -tableName \$tableName] \
			] 1 {} \
			TOKEN [list OTHER|STRING tableName] 1 [list configure -tableName \$tableName] \
		] 1 {} \
		ALTER [list \
			GROUP [list \
				GROUP [list \
					TOKEN [list PAR_LEFT "("] 1 {} \
					TOKEN [list OTHER|STRING columnName] {1 ?} [list addColumnName \$columnName] \
					GROUP [list \
						TOKEN [list OPERATOR ","] 1 {} \
						TOKEN [list OTHER|STRING columnName] {1 ?} [list addColumnName \$columnName] \
					] * {} \
					TOKEN [list PAR_RIGHT ")"] {1 ?} {} \
				] ? {} \
				ALTER [list \
					GROUP [list \
						TOKEN [list KEYWORD VALUES] 1 [list configure -valuesKeyword 1] \
						GROUP [list \
							TOKEN [list PAR_LEFT "("] 1 {} \
							SUBST [list SYNTAX expr] {1 ?} [list addColumnValue \$expr] \
							GROUP [list \
								TOKEN [list OPERATOR ","] 1 {} \
								SUBST [list SYNTAX expr] {1 ?} [list addColumnValue \$expr] \
							] * {} \
							TOKEN [list PAR_RIGHT ")"] 1 [list columnValueSetEnd] \
						] 1 {} \
						GROUP [list \
							TOKEN [list OPERATOR ","] 1 {} \
							TOKEN [list PAR_LEFT "("] 1 {} \
							SUBST [list SYNTAX expr] {1 ?} [list addColumnValue \$expr] \
							GROUP [list \
								TOKEN [list OPERATOR ","] 1 {} \
								SUBST [list SYNTAX expr] {1 ?} [list addColumnValue \$expr] \
							] * {} \
							TOKEN [list PAR_RIGHT ")"] 1 [list columnValueSetEnd] \
						] * {} \
					] 1 {} \
					SUBST [list SYNTAX selectStmt] 1 [list configure -subSelect \$selectStmt] \
				] {1 ?} {} \
			] 1 {} \
			GROUP [list \
				TOKEN [list KEYWORD DEFAULT] 1 {} \
				TOKEN [list KEYWORD VALUES] 1 {} \
			] 1 [list configure -defaultValues 1] \
		] 1 {} \
	] \
]

set ::sqlite3::statementSyntax(deleteStmt) [list \
	StatementDelete [list \
		TOKEN [list KEYWORD DELETE] 1 {} \
		TOKEN [list KEYWORD FROM] 1 {} \
		SUBST [list SYNTAX qualifiedTableName] 1 [list configure -qualifiedTableName \$qualifiedTableName] \
		GROUP [list \
			TOKEN [list KEYWORD WHERE] 1 {} \
			SUBST [list SYNTAX expr] {1 ?} [list configure -whereExpr \$expr] \
		] ? {} \
		GROUP [list \
			GROUP [list \
				TOKEN [list KEYWORD ORDER] 1 {} \
				TOKEN [list KEYWORD BY] 1 [list configure -orderByKeyword 1] \
				SUBST [list SYNTAX orderingTerm] {1 ?} [list addOrderingTerm \$orderingTerm] \
				GROUP [list \
					TOKEN [list OPERATOR ","] 1 {} \
					SUBST [list SYNTAX orderingTerm] {1 1} [list addOrderingTerm \$orderingTerm] \
				] * {} \
			] ? {} \
			TOKEN [list KEYWORD LIMIT] 1 [list configure -limitKeyword 1] \
			SUBST [list SYNTAX expr] 1 [list configure -limit \$expr] \
			GROUP [list \
				ALTER [list \
					TOKEN [list KEYWORD OFFSET] 1 [list configure -offsetKeyword 1] \
					TOKEN [list OPERATOR ","] 1 [list configure -offsetKeyword 2] \
				] 1 {} \
				SUBST [list SYNTAX expr] 1 [list configure -offset \$expr] \
			] ? {} \
		] ? {} \
	] \
]

set ::sqlite3::statementSyntax(alterTableStmt) [list \
	StatementAlterTable [list \
		TOKEN [list KEYWORD ALTER] 1 {} \
		TOKEN [list KEYWORD TABLE] 1 {} \
		ALTER [list \
			GROUP [list \
				TOKEN [list OTHER|STRING databaseName] 1 [list configure -databaseName \$databaseName] \
				TOKEN [list OPERATOR "."] 1 {} \
				TOKEN [list OTHER|STRING tableName] {1 ?} [list configure -tableName \$tableName] \
			] 1 {} \
			TOKEN [list OTHER|STRING tableName] 1 [list configure -tableName \$tableName] \
		] 1 {} \
		ALTER [list \
			GROUP [list \
				TOKEN [list KEYWORD RENAME] 1 [list configure -renameKeyword 1] \
				TOKEN [list KEYWORD TO] 1 {} \
				TOKEN [list OTHER|STRING newTableName] 1 [list configure -newTableName \$newTableName] \
			] 1 {} \
			GROUP [list \
				TOKEN [list KEYWORD ADD] 1 [list configure -addKeyword 1] \
				TOKEN [list KEYWORD COLUMN] ? {} \
				SUBST [list SYNTAX columnDef] 1 [list configure -columnDefinition \$columnDef] \
			] 1 {} \
		] 1 {} \
	] \
]

set ::sqlite3::statementSyntax(analyzeStmt) [list \
	StatementAnalyze [list \
		TOKEN [list KEYWORD ANALYZE] 1 {} \
		ALTER [list \
			GROUP [list \
				TOKEN [list OTHER|STRING databaseName] 1 [list configure -databaseName \$databaseName] \
				TOKEN [list OPERATOR "."] 1 {} \
				TOKEN [list OTHER|STRING tableName] {1 ?} [list configure -tableName \$tableName] \
			] 1 {} \
			TOKEN [list OTHER|STRING tableOrDatabaseName] 1 [list configure -tableOrDatabaseName \$tableOrDatabaseName] \
		] ? {} \
	] \
]

set ::sqlite3::statementSyntax(attachStmt) [list \
	StatementAttach [list \
		TOKEN [list KEYWORD ATTACH] 1 {} \
		TOKEN [list KEYWORD DATABASE] ? [list configure -databaseKeyword 1] \
		TOKEN [list STRING fileName] 1 [list configure -fileName \$fileName] \
		TOKEN [list KEYWORD AS] 1 {} \
		TOKEN [list OTHER|STRING databaseName] 1 [list configure -databaseName \$databaseName] \
	] \
]

set ::sqlite3::statementSyntax(beginTransactionStmt) [list \
	StatementBeginTransaction [list \
		TOKEN [list KEYWORD BEGIN] 1 {} \
		ALTER [list \
			TOKEN [list KEYWORD DEFERRED] 1 [list configure -type DEFERRED] \
			TOKEN [list KEYWORD IMMEDIATE] 1 [list configure -type IMMEDIATE] \
			TOKEN [list KEYWORD EXCLUSIVE] 1 [list configure -type EXCLUSIVE] \
		] ? {} \
		TOKEN [list KEYWORD TRANSACTION] ? [list configure -transactionKeyword 1] \
	] \
]

set ::sqlite3::statementSyntax(commitStmt) [list \
	StatementCommit [list \
		ALTER [list \
			TOKEN [list KEYWORD COMMIT] 1 [list configure -commitOrEnd "COMMIT"] \
			TOKEN [list KEYWORD END] 1 [list configure -commitOrEnd "END"] \
		] 1 {} \
		TOKEN [list KEYWORD TRANSACTION] ? [list configure -transactionKeyword 1] \
	] \
]

set ::sqlite3::statementSyntax(createView) [list \
	StatementCreateView [list \
		TOKEN [list KEYWORD CREATE] 1 {} \
		ALTER [list \
			TOKEN [list KEYWORD TEMP] 1 [list configure -temporary "TEMP"] \
			TOKEN [list KEYWORD TEMPORARY] 1 [list configure -temporary "TEMPORARY"] \
		] ? {} \
		TOKEN [list KEYWORD VIEW] 1 {} \
		GROUP [list \
			TOKEN [list KEYWORD IF] 1 {} \
			TOKEN [list KEYWORD NOT] 1 {} \
			TOKEN [list KEYWORD EXISTS] 1 {} \
		] ? [list configure -ifNotExists 1] \
		ALTER [list \
			GROUP [list \
				TOKEN [list OTHER|STRING databaseName] 1 [list configure -databaseName \$databaseName] \
				TOKEN [list OPERATOR "."] 1 {} \
				TOKEN [list OTHER|STRING viewName] {1 ?} [list configure -viewName \$viewName] \
			] 1 {} \
			TOKEN [list OTHER|STRING viewName] 1 [list configure -viewName \$viewName] \
		] 1 {} \
		TOKEN [list KEYWORD AS] 1 {} \
		SUBST [list SYNTAX selectStmt] 1 [list configure -subSelect \$selectStmt] \
	] \
]

set ::sqlite3::statementSyntax(createVirtualTableStmt) [list \
	StatementCreateVirtualTable [list \
		TOKEN [list KEYWORD CREATE] 1 {} \
		TOKEN [list KEYWORD VIRTUAL] 1 {} \
		TOKEN [list KEYWORD TABLE] 1 {} \
		ALTER [list \
			GROUP [list \
				TOKEN [list OTHER|STRING databaseName] 1 [list configure -databaseName \$databaseName] \
				TOKEN [list OPERATOR "."] 1 {} \
				TOKEN [list OTHER|STRING tableName] {1 ?} [list configure -tableName \$tableName] \
			] 1 {} \
			TOKEN [list OTHER|STRING tableName] 1 [list configure -tableName \$tableName] \
		] 1 {} \
		TOKEN [list KEYWORD USING] 1 {} \
		TOKEN [list OTHER|STRING moduleName] 1 [list configure -moduleName \$moduleName] \
		GROUP [list \
			TOKEN [list PAR_LEFT "("] 1 {} \
			GROUP [list \
				SUBST [list SYNTAX moduleArgument] 1 [list addModuleArgument \$moduleArgument] \
				GROUP [list \
					TOKEN [list OPERATOR ","] 1 {} \
					SUBST [list SYNTAX moduleArgument] 1 [list addModuleArgument \$moduleArgument] \
				] * {} \
			] ? {} \
			TOKEN [list PAR_RIGHT ")"] 1 {} \
		] ? {} \
	] \
]

# Operators in this statement are listed as ordinary (not as ANY), because we have to ommit "," operator.
set ::sqlite3::statementSyntax(moduleArgument) [list \
	StatementModuleArgument [list \
		ALTER [list \
			GROUP [list \
				TOKEN [list PAR_LEFT "("] 1 [list addArgumentWord "("] \
				SUBST [list SYNTAX moduleArgument] ? [list addArgumentObject \$moduleArgument] \
				GROUP [list \
					TOKEN [list OPERATOR ","] 1 {} \
					SUBST [list SYNTAX moduleArgument] 1 [list addArgumentObject \$moduleArgument] \
				] * {} \
				TOKEN [list PAR_RIGHT ")"] 1 [list addArgumentWord ")"] \
			] 1 {} \
			TOKEN [list STRING|INTEGER|FLOAT|OTHER|BIND_PARAM arg] 1 [list addArgumentWord \$arg] \
			TOKEN [list KEYWORD *] 1 [list addArgumentWord \$token] \
			TOKEN [list OPERATOR "+"] 1 [list addArgumentWord "+"] \
			TOKEN [list OPERATOR "-"] 1 [list addArgumentWord "-"] \
			TOKEN [list OPERATOR "/"] 1 [list addArgumentWord "/"] \
			TOKEN [list OPERATOR "*"] 1 [list addArgumentWord "*"] \
			TOKEN [list OPERATOR "."] 1 [list addArgumentWord "."] \
			TOKEN [list OPERATOR ";"] 1 [list addArgumentWord ";"] \
			TOKEN [list OPERATOR "%"] 1 [list addArgumentWord "%"] \
			TOKEN [list OPERATOR "~"] 1 [list addArgumentWord "~"] \
			TOKEN [list OPERATOR "&"] 1 [list addArgumentWord "&"] \
			TOKEN [list OPERATOR "<"] 1 [list addArgumentWord "<"] \
			TOKEN [list OPERATOR ">"] 1 [list addArgumentWord ">"] \
			TOKEN [list OPERATOR "<<"] 1 [list addArgumentWord "<<"] \
			TOKEN [list OPERATOR ">>"] 1 [list addArgumentWord ">>"] \
			TOKEN [list OPERATOR "<>"] 1 [list addArgumentWord "<>"] \
			TOKEN [list OPERATOR "<="] 1 [list addArgumentWord "<="] \
			TOKEN [list OPERATOR ">="] 1 [list addArgumentWord ">="] \
			TOKEN [list OPERATOR "|"] 1 [list addArgumentWord "|"] \
			TOKEN [list OPERATOR "||"] 1 [list addArgumentWord "||"] \
			TOKEN [list OPERATOR "!"] 1 [list addArgumentWord "!"] \
			TOKEN [list OPERATOR "!="] 1 [list addArgumentWord "!="] \
			TOKEN [list OPERATOR "="] 1 [list addArgumentWord "="] \
			TOKEN [list OPERATOR "=="] 1 [list addArgumentWord "=="] \
		] + {} \
	] \
]

set ::sqlite3::statementSyntax(detachStmt) [list \
	StatementDetach [list \
		TOKEN [list KEYWORD DETACH] 1 {} \
		TOKEN [list KEYWORD DATABASE] ? [list configure -databaseKeyword 1] \
		TOKEN [list OTHER|STRING databaseName] 1 [list configure -databaseName \$databaseName] \
	] \
]

set ::sqlite3::statementSyntax(dropIndexStmt) [list \
	StatementDropIndex [list \
		TOKEN [list KEYWORD DROP] 1 {} \
		TOKEN [list KEYWORD INDEX] 1 {} \
		GROUP [list \
			TOKEN [list KEYWORD IF] 1 {} \
			TOKEN [list KEYWORD EXISTS] 1 {} \
		] ? [list configure -ifExists 1] \
		ALTER [list \
			GROUP [list \
				TOKEN [list OTHER|STRING databaseName] 1 [list configure -databaseName \$databaseName] \
				TOKEN [list OPERATOR "."] 1 {} \
				TOKEN [list OTHER|STRING indexName] {1 ?} [list configure -indexName \$indexName] \
			] 1 {} \
			TOKEN [list OTHER|STRING indexName] 1 [list configure -indexName \$indexName] \
		] 1 {} \
	] \
]

set ::sqlite3::statementSyntax(dropTableStmt) [list \
	StatementDropTable [list \
		TOKEN [list KEYWORD DROP] 1 {} \
		TOKEN [list KEYWORD TABLE] 1 {} \
		GROUP [list \
			TOKEN [list KEYWORD IF] 1 {} \
			TOKEN [list KEYWORD EXISTS] 1 {} \
		] ? [list configure -ifExists 1] \
		ALTER [list \
			GROUP [list \
				TOKEN [list OTHER|STRING databaseName] 1 [list configure -databaseName \$databaseName] \
				TOKEN [list OPERATOR "."] 1 {} \
				TOKEN [list OTHER|STRING tableName] {1 ?} [list configure -tableName \$tableName] \
			] 1 {} \
			TOKEN [list OTHER|STRING tableName] 1 [list configure -tableName \$tableName] \
		] 1 {} \
	] \
]

set ::sqlite3::statementSyntax(dropTriggerStmt) [list \
	StatementDropTrigger [list \
		TOKEN [list KEYWORD DROP] 1 {} \
		TOKEN [list KEYWORD TRIGGER] 1 {} \
		GROUP [list \
			TOKEN [list KEYWORD IF] 1 {} \
			TOKEN [list KEYWORD EXISTS] 1 {} \
		] ? [list configure -ifExists 1] \
		ALTER [list \
			GROUP [list \
				TOKEN [list OTHER|STRING databaseName] 1 [list configure -databaseName \$databaseName] \
				TOKEN [list OPERATOR "."] 1 {} \
				TOKEN [list OTHER|STRING trigName] {1 ?} [list configure -trigName \$trigName] \
			] 1 {} \
			TOKEN [list OTHER|STRING trigName] 1 [list configure -trigName \$trigName] \
		] 1 {} \
	] \
]

set ::sqlite3::statementSyntax(dropViewStmt) [list \
	StatementDropView [list \
		TOKEN [list KEYWORD DROP] 1 {} \
		TOKEN [list KEYWORD VIEW] 1 {} \
		GROUP [list \
			TOKEN [list KEYWORD IF] 1 {} \
			TOKEN [list KEYWORD EXISTS] 1 {} \
		] ? [list configure -ifExists 1] \
		ALTER [list \
			GROUP [list \
				TOKEN [list OTHER|STRING databaseName] 1 [list configure -databaseName \$databaseName] \
				TOKEN [list OPERATOR "."] 1 {} \
				TOKEN [list OTHER|STRING viewName] {1 ?} [list configure -viewName \$viewName] \
			] 1 {} \
			TOKEN [list OTHER|STRING viewName] 1 [list configure -viewName \$viewName] \
		] 1 {} \
	] \
]

set ::sqlite3::statementSyntax(pragmaStmt) [list \
	StatementPragma [list \
		TOKEN [list KEYWORD PRAGMA] 1 {} \
		ALTER [list \
			GROUP [list \
				TOKEN [list OTHER|STRING databaseName] 1 [list configure -databaseName \$databaseName] \
				TOKEN [list OPERATOR "."] 1 {} \
				TOKEN [list OTHER|STRING pragmaName] {1 ?} [list configure -pragmaName \$pragmaName] \
			] 1 {} \
			TOKEN [list OTHER|STRING pragmaName] 1 [list configure -pragmaName \$pragmaName] \
		] 1 {} \
		ALTER [list \
			GROUP [list \
				TOKEN [list OPERATOR "="] 1 {} \
				SUBST [list SYNTAX pragmaValue] 1 [list configure -pragmaValue \$pragmaValue] \
			] 1 [list configure -equalOperator 1] \
			GROUP [list \
				TOKEN [list PAR_LEFT "("] 1 {} \
				SUBST [list SYNTAX pragmaValue] 1 [list configure -pragmaValue \$pragmaValue] \
				TOKEN [list PAR_RIGHT ")"] 1 {} \
			] 1 [list configure -parenthesis 1] \
		] ? {} \
	] \
]

set ::sqlite3::statementSyntax(pragmaValue) [list \
	StatementPragmaValue [list \
		ALTER [list \
			TOKEN [list INTEGER|FLOAT number] 1 [list configure -signedNumber \$number] \
			TOKEN [list OTHER name] 1 [list configure -name \$name] \
			TOKEN [list STRING str] 1 [list configure -stringLiteral \$str] \
		] 1 {} \
	] \
]

set ::sqlite3::statementSyntax(reindexStmt) [list \
	StatementReindex [list \
		TOKEN [list KEYWORD REINDEX] 1 {} \
		ALTER [list \
			GROUP [list \
				TOKEN [list OTHER|STRING databaseName] 1 [list configure -databaseName \$databaseName] \
				TOKEN [list OPERATOR "."] 1 {} \
				TOKEN [list OTHER|STRING name] {1 ?} [list configure -name \$name] \
			] 1 {} \
			TOKEN [list OTHER|STRING name] 1 [list configure -name \$name] \
		] 1 {} \
	] \
]

set ::sqlite3::statementSyntax(releaseStmt) [list \
	StatementRelease [list \
		TOKEN [list KEYWORD RELEASE] 1 {} \
		TOKEN [list KEYWORD SAVEPOINT] ? [list configure -savepointKeyword 1] \
		TOKEN [list STRING|OTHER name] 1 [list configure -name \$name] \
	] \
]

set ::sqlite3::statementSyntax(rollbackStmt) [list \
	StatementRollback [list \
		TOKEN [list KEYWORD ROLLBACK] 1 {} \
		TOKEN [list KEYWORD TRANSACTION] ? [list configure -transactionKeyword 1] \
		GROUP [list \
			TOKEN [list KEYWORD TO] 1 {} \
			TOKEN [list KEYWORD SAVEPOINT] ? [list configure -savepointKeyword 1] \
			TOKEN [list STRING|OTHER savepointName] 1 [list configure -savepointName \$savepointName] \
		] ? [list configure -rollbackToSavepoint 1] \
	] \
]

set ::sqlite3::statementSyntax(savepointStmt) [list \
	StatementSavepoint [list \
		TOKEN [list KEYWORD SAVEPOINT] 1 {} \
		TOKEN [list STRING|OTHER name] 1 [list configure -name \$name] \
	] \
]

set ::sqlite3::statementSyntax(vacuumStmt) [list \
	StatementVacuum [list \
		TOKEN [list KEYWORD VACUUM] 1 {} \
	] \
]

set ::sqlite3::statementSyntax(sqlStmt) [list \
	StatementSql [list \
		GROUP [list \
			TOKEN [list KEYWORD EXPLAIN] 1 [list configure -explainKeyword 1] \
			GROUP [list \
				TOKEN [list KEYWORD QUERY] 1 {} \
				TOKEN [list KEYWORD PLAN] 1 {} \
			] ? [list configure -queryPlanKeywords 1] \
		] ? {} \
		ALTER [list \
			SUBST [list SYNTAX alterTableStmt] 1 [list configure -branchName alterTableStmt -subStatement \$alterTableStmt] \
			SUBST [list SYNTAX analyzeStmt] 1 [list configure -branchName analyzeStmt -subStatement \$analyzeStmt] \
			SUBST [list SYNTAX attachStmt] 1 [list configure -branchName attachStmt -subStatement \$attachStmt] \
			SUBST [list SYNTAX beginTransactionStmt] 1 [list configure -branchName beginTransactionStmt -subStatement \$beginTransactionStmt] \
			SUBST [list SYNTAX commitStmt] 1 [list configure -branchName commitStmt -subStatement \$commitStmt] \
			SUBST [list SYNTAX createIndexStmt] 1 [list configure -branchName createIndexStmt -subStatement \$createIndexStmt] \
			SUBST [list SYNTAX createTableStmt] 1 [list configure -branchName createTableStmt -subStatement \$createTableStmt] \
			SUBST [list SYNTAX createTriggerStmt] 1 [list configure -branchName createTriggerStmt -subStatement \$createTriggerStmt] \
			SUBST [list SYNTAX createView] 1 [list configure -branchName createView -subStatement \$createView] \
			SUBST [list SYNTAX createVirtualTableStmt] 1 [list configure -branchName createVirtualTableStmt -subStatement \$createVirtualTableStmt] \
			SUBST [list SYNTAX deleteStmt] 1 [list configure -branchName deleteStmt -subStatement \$deleteStmt] \
			SUBST [list SYNTAX detachStmt] 1 [list configure -branchName detachStmt -subStatement \$detachStmt] \
			SUBST [list SYNTAX dropIndexStmt] 1 [list configure -branchName dropIndexStmt -subStatement \$dropIndexStmt] \
			SUBST [list SYNTAX dropTableStmt] 1 [list configure -branchName dropTableStmt -subStatement \$dropTableStmt] \
			SUBST [list SYNTAX dropTriggerStmt] 1 [list configure -branchName dropTriggerStmt -subStatement \$dropTriggerStmt] \
			SUBST [list SYNTAX dropViewStmt] 1 [list configure -branchName dropViewStmt -subStatement \$dropViewStmt] \
			SUBST [list SYNTAX insertStmt] 1 [list configure -branchName insertStmt -subStatement \$insertStmt] \
			SUBST [list SYNTAX pragmaStmt] 1 [list configure -branchName pragmaStmt -subStatement \$pragmaStmt] \
			SUBST [list SYNTAX reindexStmt] 1 [list configure -branchName reindexStmt -subStatement \$reindexStmt] \
			SUBST [list SYNTAX releaseStmt] 1 [list configure -branchName releaseStmt -subStatement \$releaseStmt] \
			SUBST [list SYNTAX rollbackStmt] 1 [list configure -branchName rollbackStmt -subStatement \$rollbackStmt] \
			SUBST [list SYNTAX savepointStmt] 1 [list configure -branchName savepointStmt -subStatement \$savepointStmt] \
			SUBST [list SYNTAX selectStmt] 1 [list configure -branchName selectStmt -subStatement \$selectStmt] \
			SUBST [list SYNTAX updateStmt] 1 [list configure -branchName updateStmt -subStatement \$updateStmt] \
			SUBST [list SYNTAX vacuumStmt] 1 [list configure -branchName vacuumStmt -subStatement \$vacuumStmt] \
		] 1 {} \
	] \
]
