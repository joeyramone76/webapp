#>
# @class SqlParser
# Parses SQLite SQL code and produces Tcl objects representing relations
# and containing all necessary informations about SQL being parsed.
# Uses syntax definitions from src/syntaxes/sqlite_*.tcl files
# and stores informations in instances of classes from src/syntaxes/s_*.tcl (for SQLite3)
# and src/syntaxes/s2_*.tcl (for SQLite2).<br><br>
#
# To parse SQL and get ready to use containers tree, execute these lines:
# @example
# Parser3 parser ;# Parser3 is wrapper class for sqlite3 dialect.
# parser parse $sql
# set obj [dict get $parsedDict object]
# $obj setBaseDatabase $db ;# db is instance of class DB
# $obj callAfterParsing ;# after this command we have ready to use tree with $obj as a root
# $obj debugPrint ;# this one to see parsing results on stdout
# delete object parser
# @endofexample
#<
class SqlParser {
	#>
	# @method constructor
	# @param lexerCommand Command which will be used to tokenize SQL code. It has to accept one argument - a SQL code.
	# @param dialect SQL dialect. Currently <code>sqlite3</code> or <code>sqlite2</code>.
	#<
	constructor {lexerCommand dialect} {}

	#>
	# @method destructor
	# Cleans up parser objects.
	#<
	destructor {}

	#>
	# @var recurentionLimit
	# This is just security limit to avoid infinite recurention.
	# Parser should not reach this limit for normal processing.
	# When it's reached then requested recurention step will fail,
	# so parsing process will report parsing error.
	#
	# Windows XP seems to be limiting us to recursion at 160.
	# Just for safety we're setting it to 150. It should still be enough
	# for most of complicated queries.
	#
	# This is not actual recurention limit from OS, it's recurention
	# of parser, which produces way more of elements on OS's stack
	# per recurention.
	#<
	common recurentionLimit 150

	#>
	# @var PARSER_MAX_OCCURS
	# Constant value used to mark "infinity" for number of possible occurances
	# of some SQL statement. We can easly assume that there won't be more than that.
	#>
	final common PARSER_MAX_OCCURS 9999999

	protected {
		#>
		# @var _parserDepth
		# This depth defines how deep parser went inside of syntax tree.
		# Each enterance into GROUP, ALTER or SUBST increments this variable
		# and decrements is when leaving that GROUP, ALTER, or SUBST.
		#<
		variable _parserDepth 0

		#>
		# @var _recurentionDepth
		# Keeps track of recurention depth.
		#<
		variable _recurentionDepth 0

		#>
		# @var _tokens
		# Keeps current list of tokens being parsed.
		#<
		variable _tokens [list]

		#>
		# @var _tokensPtr
		# Index of current token to be processed.
		#<
		variable _tokensPtr 0

		#>
		# @var _parserObjects
		# List of container objects created by parser.
		# They will be deleted by {@method freeParserObjects}.
		#<
		variable _parserObjects [list]

		#>
		# @var _lexerCommand
		# Command to use to tokenize input data.
		#<
		variable _lexerCommand ""

		#>
		# @var _dialect
		# Dialect to use while parsing. Currently <code>sqlite3</code> or <code>sqlite2</code>.
		#<
		variable _dialect ""

		#>
		# @var _expectedTokenIdx
		# Keeps index of character to look for context (expected token) at given index of parsed sql.
		#<
		variable _expectedTokenIdx ""

		#>
		# @var _expectedTokens
		# List of expected tokens at defined position (by {@var _checkForExpectedTokenAt}).
		#<
		variable _expectedTokens [list]

		#>
		# @var _tolerateLacks
		# Deciedes whether tolerate lacks of tokens other than KEYWORD.
		# <code>true</code> here is useful to parse SQL query with missing table names, columns, etc,
		# so even then it's possible to provide some information of context.
		#<
		variable _tolerateLacks false

		#>
		# @var _deepestParsedToken
		# Keeps pointer (position index) of token that was parsed in any syntax branch as deepest.
		# In other words it points to token which is the last valid one for SQL syntax definition.
		#<
		variable _deepestParsedToken -1

		#>
		# @var _notReservedKeywords
		# Keeps list of keywords that are not reserved in current dialect.
		# It's defined in constructor, basing on dialect.
		#<
		variable _notReservedKeywords [list]

		#>
		# @method parserShift
		# Pops first token from {@var _tokens} and returns it.
		# @return First token from queue.
		#<
		method parserShift {}
		method parserShiftPossible {}

		#>
		# @method parseGroup
		# @param handlerObject Current container object.
		# @param syntax Syntax definition node.
		# @param groupCode Tcl code to be executed for matched branch.
		# @param isAlter If <code>true</code> then group is threated as ALTER, not GROUP.
		# Parses next tokens for tokens expected by the GROUP given in <i>syntax</i> parameter.
		# @return Tcl dict with keys: returnCode and codes.
		#<
		method parseGroup {handlerObject syntax groupCode {isAlter 0}}

		#>
		# @method parseSyntaxGroupNode
		# Internal method used by {@method parseGroup}.
		#<
		method parseSyntaxGroupNode {handlerObject exp value code min max isAlter}

		#>
		# @method parseSyntaxTokenNode
		# Internal method used by {@method parseGroup}.
		#<
		method parseSyntaxTokenNode {handlerObject exp value code min max isAlter}

		#>
		# @method parseSyntaxSubstNode
		# Internal method used by {@method parseGroup}.
		#<
		method parseSyntaxSubstNode {handlerObject exp value code min max isAlter}

		#>
		# @method parseToken
		# @param handlerObject Current container object.
		# @param value Token value to parse. Currently it's 4-element list: type, value, startIndex and endIndex.
		# @param code Tcl code to be executed for matched branch.
		# Checks if given token from input (the <i>value</i> parameter) matches expected syntax.
		# @return Tcl dict with keys: returnCode and codes.
		#<
		method parseToken {handlerObject value code}

		#>
		# @method parseTokenized
		# Processes all tokens from {@var _tokens} and creates hierarchy of container objects.
		# @return Tcl Dict with keys: object, returnCode and errorMessage. Return code = 0 means success. Object is the top container for informations of parsed SQL.
		#<
		method parseTokenized {}

		#>
		# @method tokenize
		# @param sql SQL to tokenize.
		# @param index Unsigned integer, or empty string. It's optional (default empty).
		# Produces tokens from given SQL using {@var _lexerCommand} and stores results in {@var _tokens}.
		# If <i>index</i> is given, then only one statement is stored in {@var _tokens}, which the index is enclosed in.
		#<
		method tokenize {sql {index ""}}

		#>
		# @method parserDepthSpaces
		# @return Set of whitespace characters. Number of characters is determinated by {@var _parserDepth}.
		#<
		method parserDepthSpaces {}

		#>
		# @method convertParserOccurances
		# @param occur Occurances marker.
		# Converts given occurances marker into list of minimum and maximum occurances.
		# It support following input formats: N, N-M, ?, +, *.<br>
		# For {@var _tolerateLacks} it looks for alternative occurance definition for all tokens except KEYWORD type.
		# Alternative occurance definition is second list element in general occurance definition. If there is only
		# one definition, then alternative definition will be same as standard.
		# @return List of 2 elements: min and max.
		#<
		method convertParserOccurances {occur}

		#>
		# @method rememberDeepestTokenPtr
		# Checks if current tokens pointer is greater than value stored in {@var _deepestParsedToken} and if so,
		# then sets it as a new value of {@var _deepestParsedToken}.
		#<
		method rememberDeepestTokenPtr {}

		method handleKeyword {}
		method handleOperator {}
		method handleString {}
		method handleIntOrFloat {}
		method handleParenthesis {}
		method handleComment {}
		method handleOther {}
		method handleBindParam {}
		method handleCommentsOnly {handlerObject}

		#>
		# @method validateSqlDefinitionInternalList
		# @param stmt Syntax statement name (an array index).
		# @param defList List of syntax definition nodes to validate.
		# Used for recurent validation of syntax definitions.
		#<
		proc validateSqlDefinitionInternalList {stmt defList}
	}

	public {
		#>
		# @method parse
		# @param sql SQL code to parse.
		# @param idx Index of character to parse statement for.
		# Processes all tokens from lexer and creates hierarchy of container objects.
		# Lexer produces tokens using {@var _lexerCommand}.
		# If there are more statements in <i>sql</i>, then use <i>index</i> to specify which statement
		# are you interested in - it has to be position (in <i>sql</i>) of any character in that statement.<br>
		# Result dictionary contains following keys:<br>
		# <ul>
		# <li><code>object</code> - the top container for informations of parsed SQL.
		# <li><code>allTokens</code> - list of all tokens as returned from lexer.
		# <li><code>returnCode</code> - value 0 means success, other values means error.
		# <li><code>errorMessage</code> - optional error message, can be empty.
		# <li><code>tokensLeft</code> - tokens that couldn't be parsed (incorrect syntax). It depends on syntax definition groups, so some tokens parsed correctly might appera here as well! To find out where parsing really failed use <code>lastValidTokenIndex</code>.
		# <li><code>lastValidTokenIndex</code> - position index of last token that is correct for syntax definition. Use this index and <code>allTokens</code> to findout last valid tokena and first invalid one.
		# </ul>
		# @return Tcl dict as described above.
		#<
		method parse {sql {index ""}}

		#>
		# @method parseTokens
		# @param tokens Tokens from {@class Lexer}.
		# This method takes tokens instead of contents. It's useful when you needed tokens before parsing,
		# but it would be waste of resources to tokenize contents again inside of parser.
		#<
		method parseTokens {tokens {index ""}}

		#>
		# @method freeParserObjects
		# Deletes objects from {@var _parserObjects}.
		#<
		method freeParserObjects {}

		#>
		# @method checkForExpectedTokens
		# @param sql SQL code to parse.
		# @param idx Index of character to check context at.
		# Finds out what token or keyword is expected at given index of given sql.
		# Result dictionary contains following keys:<br>
		# <ul>
		# <li><code>expectedTokens</code> - list of tokens expected at given position. Each expected token is sublist of: token_type, tokenValue (only KEYWORD tokens have constant expected values).
		# <li><code>tokenPartialValue</code> - if given position is in the middle of some token, then this value contains characters from begining of the token to specified position.
		# <li><code>allTokens</code> - list of tokens as returned from lexer limited to last full token before given position.
		# </ul>
		# @return Tcl dict as described above.
		#<
		method checkForExpectedTokens {sql idx}

		#>
		# @method checkForExpectedTokensInTokens
		# @param tokens Tokens from {@class Lexer}.
		# This is just alternative to {@method checkForExpectedTokens} which takes already tokenized SQL.
		#<
		method checkForExpectedTokensInTokens {tokens idx}

		#>
		# @method setLacksTolerantion
		# @param bool Boolean value to be set for toleration of lacks.
		# This value is set to {@var _tolerateLacks}. See it's descritpion for details.
		#<
		method setLacksTolerantion {bool}

		#>
		# @method validateSqlDefinitions
		# Performs basic validation of SQL syntax definitions.
		#<
		proc validateSqlDefinitions {}
	}
}

#>
# @class SqlParser3
# Shortcut class for {@class SqlParser} with <code>sqlite3</code> dialect and lexer {@class Lexer3}.
#<
class SqlParser3 {
	inherit SqlParser

	constructor {} {
		SqlParser::constructor [Lexer3 ::#auto] sqlite3
	} {}

	destructor {
		delete object $_lexerCommand
	}
}

#>
# @class SqlParser2
# Shortcut class for {@class SqlParser} with <code>sqlite2</code> dialect and lexer {@class Lexer2}.
#<
class SqlParser2 {
	inherit SqlParser

	constructor {} {
		SqlParser::constructor [Lexer2 ::#auto] sqlite2
	} {}

	destructor {
		delete object $_lexerCommand
	}
}

##########################################################

body SqlParser::constructor {lexerCommand dialect} {
	set _recurentionDepth 0
	set _lexerCommand $lexerCommand
	set _dialect $dialect

	set _notReservedKeywords [set ::${_dialect}::NOT_RESERVED_KEYWORDS]
}

body SqlParser::destructor {} {
	freeParserObjects
}

body SqlParser::parserShift {} {
	set token [lindex $_tokens $_tokensPtr]
	if {$::DEBUG(parser) > 2} {
		if {$::DEBUG(parser_tree)} {
			debugStep "Token shifted: $token"
		} else {
			puts "[parserDepthSpaces]Token shifted: $token"
		}
	}
	incr _tokensPtr
	return $token
}

body SqlParser::parserShiftPossible {} {
	return [expr {[llength $_tokens] > $_tokensPtr}]
}

body SqlParser::convertParserOccurances {occur} {
	if {$_tolerateLacks} {
		if {$::DEBUG(parser) >= 2 && [lindex $occur 0] != [lindex $occur end]} {
			if {$::DEBUG(parser_tree)} {
				debugStep "Lacks tolerantion: Using [lindex $occur end] instead of [lindex $occur 0]"
			} else {
				puts "[parserDepthSpaces]Lacks tolerantion: Using [lindex $occur end] instead of [lindex $occur 0]"
			}
		}
		set occur [lindex $occur end]
	} else {
		set occur [lindex $occur 0]
	}
	switch -regexp -- $occur {
		{^\d+\-\d+$} {
			return [split $occur -]
		}
		{^\d+\-$} {
			return [list [string range $occur 0 end-1] $PARSER_MAX_OCCURS]
		}
		{^\-\d+$} {
			return [list 0 [string range $occur 1 end]]
		}
		{^\?$} {
			return [list 0 1]
		}
		{^\*$} {
			return [list 0 $PARSER_MAX_OCCURS]
		}
		{\d+} {
			return [list $occur $occur]
		}
		{^\+$} {
			return [list 1 $PARSER_MAX_OCCURS]
		}
		default {
			upvar exp exp value value
			error "Cannot interpretate occurances expression in SQL syntax definition: $occur (context: $exp $value)"
		}
	}
}

body SqlParser::parseTokens {tokens {index ""}} {
	set _tokens $tokens
	set resDict [parseTokenized]
	return $resDict
}

body SqlParser::parse {sql {index ""}} {
	if {$::DEBUG(parser) > 1} {
		puts ""
		puts "******** Standard parser:"
		printStackTrace
		puts ""
	}
	tokenize $sql $index
	set resDict [parseTokenized]

	if {[dict get $resDict returnCode] != 0} {
		set idx [dict get $resDict lastValidTokenIndex]
		set parsedSql [Lexer::detokenize [lrange [dict get $resDict allTokens] 0 $idx]]
		dict set resDict errorMessage [format "SQL parsing error after: %s" $parsedSql]
	}

	return $resDict
}

body SqlParser::tokenize {sql {index ""}} {
	# Tokenize
	set tokenized [{*}$_lexerCommand tokenizeSql $sql $index]
	set resultCode [dict get $tokenized returnCode]
	if {$resultCode != 0} {
		return [dict create object "" returnCode $returnCode errorMessage [dict get $tokenized errorMessage]]
	}
	set _tokens [dict get $tokenized tokens]
}

body SqlParser::parseTokenized {} {
	set _tokensPtr 0
	set _deepestParsedToken -1
	if {$::DEBUG(parser)} {
		if {$::DEBUG(parser_tree)} {
			debugStepReset
		} else {
			puts "Tokens: $_tokens"
		}
	}

	# Create statement object to store this level data in.
	set handlerObject [[lindex [set ::${_dialect}::statementSyntax(sqlStmt)] 0] ::#auto]
	lappend _parserObjects $handlerObject

	# Handle comments only
	if {![handleCommentsOnly $handlerObject]} {
		return [dict create object $handlerObject returnCode 0 errorMessage "" \
			tokensLeft [list] allTokens $_tokens lastValidTokenIndex [expr {[llength $_tokens]-1}]]
	}

	# Parse
	set excludes [dict create] ;# excludes list empty for begining
	set errorMessage ""
	set resDict [parseGroup $handlerObject [lindex [set ::${_dialect}::statementSyntax(sqlStmt)] 1] {}]
	set codes [dict get $resDict codes]
	if {$::DEBUG(parser)} {
		puts "------------"
	}
	foreach code $codes {
		if {$::DEBUG(parser)} {
			puts "$code"
		}
		{*}$code
	}

	if {$::DEBUG(parser) >= 2} {
		puts "Parsed objects:\n[join $_parserObjects \n]"
	}

	set resCode [dict get $resDict returnCode]
	set tokensLeft [lrange $_tokens $_tokensPtr end]
	set fakeToken [lsearch -inline -index 0 $tokensLeft "FAKE_TOKEN_TYPE"]
	if {$fakeToken != ""} {
		set tokensLeft [ldelete $tokensLeft $fakeToken]
	}

	if {[llength $_tokens] > $_tokensPtr} {
		if {$::DEBUG(parser)} {
			puts "tokens left: $tokensLeft"
		}
		set resCode 1
	}
	return [dict create object $handlerObject returnCode $resCode errorMessage $errorMessage \
		tokensLeft $tokensLeft allTokens $_tokens lastValidTokenIndex $_deepestParsedToken]
}

body SqlParser::handleCommentsOnly {handlerObject} {
	foreach token $_tokens {
		if {[lindex $token 0] != "COMMENT"} {
			return 1
		}
	}
	$handlerObject configure -allTokens $_tokens
	return 0
}

body SqlParser::checkForExpectedTokens {sql idx} {
	tokenize $sql $idx
	return [checkForExpectedTokensInTokens $_tokens $idx]
}

body SqlParser::checkForExpectedTokensInTokens {tokens idx} {
	if {$::DEBUG(parser) > 1} {
		puts ""
		puts "******** Expected token parser:"
		printStackTrace
		puts ""
	}
	set _expectedTokenIdx $idx
	set _expectedTokens [list]
	set _tokens $tokens
	# Commented for now - when not commented then completion for first statement keyword doesn't work.
# 	if {[llength $_tokens] == 0} {
# 		return [dict create allTokens [list] tokenPartialValue "" expectedTokens [list]]
# 	}

	set partialValue ""

	# Adding end token so we can always match token after all tokens
	set tempTokens $_tokens
	if {[llength $tempTokens] > 0} {
		set startIndex [expr {[lindex $tempTokens end 2]+1}]
	} else {
		set startIndex 0
	}
	lappend tempTokens [list FAKE_END_TOKEN_TYPE "" $startIndex 99999999]

	# Searching in tokens for our expected index
	set newTokensList ""
	set matchedToken ""
	foreach token $tempTokens {
		lassign $token tokenType tokenValue tokenBegin tokenEnd

		# Manual correction by expanding end by 1 char to right, except for specified tokens
		if {$tokenType ni [list "PAR_RIGHT"]} {
			incr tokenEnd
		}

		# Manual correction by cutting end by 1 char to left, for all specified tokens
		if {$tokenType in [list "OPERATOR" "PAR_LEFT"]} {
			incr tokenEnd -1
		}

		set previousToken [lindex $newTokensList end]
		if {$tokenBegin <= $idx && $idx <= $tokenEnd} {
			set matchedToken $token
			break
		} elseif {$idx < $tokenBegin} {
			break
		}
		lappend newTokensList $token
	}

	if {$matchedToken != ""} {
		lassign $matchedToken tokenType tokenValue tokenBegin tokenEnd
		set diff [expr {$_expectedTokenIdx-$tokenBegin-1}]
		set partialValue [string range $tokenValue 0 $diff]
		lappend newTokensList [list FAKE_TOKEN_TYPE $partialValue $tokenBegin $tokenEnd]
	} elseif {[llength $newTokensList] > 0} {
		set token [lindex $newTokensList end]
		lassign $token tokenType tokenValue tokenBegin tokenEnd
		set partialValue ""
		set newPosition [expr {$tokenEnd + 1}]
		lappend newTokensList [list FAKE_TOKEN_TYPE $partialValue $newPosition $newPosition]
	} else {
		lappend newTokensList [list FAKE_TOKEN_TYPE "" 0 0]
	}

	set _tokens $newTokensList
	#puts "tokens: $_tokens, idx=$idx"

	set res [parseTokenized]
	set _expectedTokens [lsort -unique $_expectedTokens]
	#puts "expected tokens: $_expectedTokens"
	dict append res tokenPartialValue $partialValue
	dict append res expectedTokens $_expectedTokens

	delete object [dict get $res object]
	lremove _parserObjects [dict get $res object]

	dict set res allTokens [lrange [dict get $res allTokens] 0 end-1]

	set res [dict remove $res returnCode errorMessage tokensLeft object lastValidTokenIndex]
	return $res
}

body SqlParser::parserDepthSpaces {} {
	return [string repeat "|  " $_parserDepth]
}

body SqlParser::rememberDeepestTokenPtr {} {
	# After token was parsed correctly, the pointer is increased to next token
	# (which we don't know anything about), so we need to remember position decreased by 1.
	set ptr [expr {$_tokensPtr - 1}]
	if {$ptr > $_deepestParsedToken} {
		set _deepestParsedToken $ptr
	}
}

body SqlParser::parseGroup {handlerObject syntax groupCode {isAlter 0}} {
	upvar excludes excludes
	incr _parserDepth

	set transactionCodes [list]
	set matchedAlter 0

	foreach {exp value occur code} $syntax {
		if {$::DEBUG(parser) >= 3} {
			#puts ""
			if {$::DEBUG(parser_tree)} {
				debugStep "exp: $exp | $value | $occur | $code"
			} else {
				puts "[parserDepthSpaces]exp: $exp | $value | $occur | $code"
			}
		}
		lassign [convertParserOccurances $occur] min max
		set syntaxNodeCommand ""
		switch -- $exp {
			"TOKEN" {
				set syntaxNodeCommand "parseSyntaxTokenNode"
			}
			"GROUP" - "ALTER" {
				set syntaxNodeCommand "parseSyntaxGroupNode"
			}
			"SUBST" {
				set syntaxNodeCommand "parseSyntaxSubstNode"
			}
			default {
				error "Unknown syntax node type: $exp"
			}
		}
		set returnDict [$syntaxNodeCommand $handlerObject $exp $value $code $min $max $isAlter]
		if {[dict exists $returnDict continue]} {
			# "continue" key in dict is set when any of parseSyntax* subcomands wants to call [continue] on this loop
			continue
		} elseif {[dict exists $returnDict returnCode]} {
			# "returnCode" key in dict is set when any of parseSyntax* subcomands wants to return to upper level
			return $returnDict
		}
	}
	incr _parserDepth -1
	if {$isAlter} {
		return [dict create returnCode [expr {!$matchedAlter}] codes $transactionCodes]
	} else {
		return [dict create returnCode 0 codes $transactionCodes]
	}
}

body SqlParser::parseSyntaxGroupNode {handlerObject exp value code min max isAlter} {
	upvar transactionCodes transactionCodes matchedAlter matchedAlter excludes excludes

	set alt [expr {$exp == "ALTER" ? 1 : 0}]
	set transactionCodesCopy $transactionCodes
	for {set i 0} {$i < $max} {incr i} {
		set tokensCopy $_tokensPtr
		if {$::DEBUG(parser) >= 2} {
			if {$::DEBUG(parser_tree)} {
				debugStepEnter "entering $exp"
			} else {
				puts "[parserDepthSpaces]entering $exp"
			}
		}
		set resDict [parseGroup $handlerObject $value $code $alt]
		set retCode [dict get $resDict returnCode]
		if {$::DEBUG(parser) >= 2} {
			if {$::DEBUG(parser_tree)} {
				debugStepLeave "left $exp with retCode $retCode" $retCode
			} else {
				puts "[parserDepthSpaces]left $exp with retCode $retCode"
			}
		}
		if {$retCode != 0} {
			set _tokensPtr $tokensCopy
			break
		} else {
			set matchedAlter 1
			lappend transactionCodes {*}[dict get $resDict codes]
			if {$code != ""} {
				set transactionCodes [linsert $transactionCodes 0 [concat $handlerObject [subst $code]]]
			}
		}
	}
	if {$isAlter} {
		if {$i < $min} {
			set transactionCodes $transactionCodesCopy
			return [dict create continue 1]
		} else {
			incr _parserDepth -1
			return [dict create returnCode 0 codes $transactionCodes]
		}
	} else {
		if {$i < $min} {
			incr _parserDepth -1
			return [dict create returnCode 1 codes $transactionCodes]
		}
	}
}

body SqlParser::parseSyntaxTokenNode {handlerObject exp value code min max isAlter} {
	upvar transactionCodes transactionCodes matchedAlter matchedAlter excludes excludes

	set transactionCodesCopy $transactionCodes
	for {set i 0} {$i < $max} {incr i} {
		set tokensCopy $_tokensPtr

		# Cleaning up comments at begining and middle
		while {[lindex $_tokens $_tokensPtr 0] == "COMMENT"} {
			lappend transactionCodes [list $handlerObject appendToken [parserShift]]
		}
		if {![parserShiftPossible]} {
			break
		}

		set resDict [parseToken $handlerObject $value $code]
		set retCode [dict get $resDict returnCode]
		if {$retCode != 0} {
			set _tokensPtr $tokensCopy
			break
		} else {
			# Comments at end
			while {[lindex $_tokens $_tokensPtr 0] == "COMMENT"} {
				lappend transactionCodes [list $handlerObject appendToken [parserShift]]
			}

			rememberDeepestTokenPtr
			set matchedAlter 1
			lappend transactionCodes {*}[dict get $resDict codes]
		}
	}

	if {$isAlter} {
		if {$i < $min} {
			set transactionCodes $transactionCodesCopy
			return [dict create continue 1]
		} else {
			incr _parserDepth -1
			return [dict create returnCode 0 codes $transactionCodes]
		}
	} else {
		lassign $value syntaxTokenType syntaxTokenValue
		if {$i < $min} {
			incr _parserDepth -1
			return [dict create returnCode 1 codes $transactionCodes]
		}
	}
}

body SqlParser::parseSyntaxSubstNode {handlerObject exp value code min max isAlter} {
	upvar transactionCodes transactionCodes matchedAlter matchedAlter excludes upperExcludes

	set transactionCodesCopy $transactionCodes
	set substSyntax [lindex $value 1]

	# Support for #exclude()
	set excludes [dict create]
	set maxRecursionIngeritance false
	if {[string match "*#exclude(*)" $substSyntax]} {
		set sp [split $substSyntax "#"]
		foreach excl [lrange $sp 1 end] {
			# Append {key value} from single exclude to dict
			set excludeDescription [lindex [regexp -inline -- {exclude\((.*?)\)} $excl] 1]
			if {$excludeDescription == "inheritWithMaxRecursion"} {
				set maxRecursionIngeritance true
				continue
			} elseif {[llength $excludeDescription] < 3} {
				lappend excludeDescription 0
			}
			lassign $excludeDescription excludeType excludeValue excludeRecursion
			dict set excludes "${excludeType}&$excludeValue" $excludeRecursion
		}
		set substSyntax [lindex $sp 0]
	}

	# Copying necessary upper excludes
	dict for {upperExcludeKey upperExcludeValue} $upperExcludes {
		set upperExcludeRecursions [dict get $upperExcludes $upperExcludeKey]
		if {$upperExcludeRecursions > 0 || $maxRecursionIngeritance} {
			if {!$maxRecursionIngeritance} {
				incr upperExcludeRecursions -1
			}
			dict set excludes $upperExcludeKey $upperExcludeRecursions
		}
	}

	if {![info exists ::${_dialect}::statementSyntax($substSyntax)]} {
		error "Missing syntax definition for '$substSyntax'."
	}
	for {set i 0} {$i < $max} {incr i} {
		set tokensCopy $_tokensPtr
		set $substSyntax [[lindex [set ::${_dialect}::statementSyntax($substSyntax)] 0] ::#auto]

		# Entering SUBST
		# Recurention counter is separated for each subsyntax, which lets us to take care
		# of cross referented recurentions (expr->something->expr), not only direct ones (expr->expr)
		incr _recurentionDepth
		if {$::DEBUG(parser) >= 2} {
			if {$::DEBUG(parser_tree)} {
				debugStepEnter "entering subst $substSyntax"
			} else {
				puts "[parserDepthSpaces]entering subst $substSyntax"
			}
		}
		if {$_recurentionDepth <= $recurentionLimit} {
			set resDict [parseGroup [set $substSyntax] [lindex [set ::${_dialect}::statementSyntax($substSyntax)] 1] [subst $code]]
		} else {
			if {$::DEBUG(parser)} {
				if {$::DEBUG(parser_tree)} {
					debugStepLeave "Recursion limit reached ($recurentionLimit)" 1
				} else {
					puts "[parserDepthSpaces]Recursion limit reached ($recurentionLimit)"
				}
			}
			set resDict [dict create returnCode 1 codes [list]]
		}
		set retCode [dict get $resDict returnCode]
		if {$::DEBUG(parser) >= 2} {
			if {$::DEBUG(parser_tree)} {
				debugStepLeave "left subst $substSyntax with retCode $retCode" $retCode
			} else {
				puts "[parserDepthSpaces]left subst $substSyntax with retCode $retCode"
			}
		}
		incr _recurentionDepth -1
		# Leaving SUBST

		if {$retCode != 0} {
			delete object [set $substSyntax]
			set _tokensPtr $tokensCopy
			break
		} else {
			lappend _parserObjects [set $substSyntax]
			$handlerObject addChildStatement [set $substSyntax]
			[set $substSyntax] setParentStatement $handlerObject

			set matchedAlter 1
			lappend transactionCodes {*}[dict get $resDict codes]
			if {$code != ""} {
				set transactionCodes [linsert $transactionCodes 0 [concat $handlerObject [subst $code]]]
			}
		}
	}
	if {$isAlter} {
		if {$i < $min} {
			return [dict create continue 1]
		} else {
			incr _parserDepth -1
			return [dict create returnCode 0 codes $transactionCodes]
		}
	} else {
		if {$i < $min} {
			incr _parserDepth -1
			return [dict create returnCode 1 codes $transactionCodes]
		}
	}
	if {[llength $_tokens] == $_tokensPtr} {
		incr _parserDepth -1
		return [dict create returnCode 0 codes $transactionCodes]
	}
}

body SqlParser::parseToken {handlerObject value code} {
	upvar min min max max excludes excludes
	set transactionCodes [list]

	# Token as defined in syntax
	lassign $value syntaxTokenType syntaxTokenValue

	# Syntax token type can be OR'ed
	set syntaxTokenType [split $syntaxTokenType |]

	# Temporary cross-usage of "" and '' is disabled. Just uncomment it to reenable it.
	# This is done manually in syntax definitions for places where it should be.
	# Anyway this code is kept, just in case.
# 	# We allow using '' for indentifiers as well
# 	if {"OTHER" in $syntaxTokenType && "STRING" ni $syntaxTokenType} {
# 		lappend syntaxTokenType "STRING"
# 	}
# 	# ...and we allo using "" for strings as well
# 	if {"STRING" in $syntaxTokenType && "OTHER" ni $syntaxTokenType} {
# 		lappend syntaxTokenType "OTHER"
# 	}

	# "Not reserved keywords" are allowed as OTHER or STRING
	# 6.01.2013 - Due to BUG 1804 the "STRING" is removed from here, because the plain
	# keyword cannot be treated as STRING value. Not sure why it was included before.
	#if {("OTHER" in $syntaxTokenType || "STRING" in $syntaxTokenType) && "KEYWORD" ni $syntaxTokenType} {}
	if {"OTHER" in $syntaxTokenType && "KEYWORD" ni $syntaxTokenType} {
		lappend syntaxTokenType "KEYWORD"
	}

	# Numbers are allowed as literal value (OTHER or STRING)
	if {"OTHER" in $syntaxTokenType || "STRING" in $syntaxTokenType} {
		if {"INTEGER" ni $syntaxTokenType} {
			lappend syntaxTokenType "INTEGER"
		}
		if {"FLOAT" ni $syntaxTokenType} {
			lappend syntaxTokenType "FLOAT"
		}
	}

	# Token from parsed SQL
# 	set isComment true
# 	while {$isComment} { ;# we need to add all comments to tokenList, but they should not be parsed
		set token [parserShift]

		if {$::DEBUG(parser) >= 2} {
			if {$::DEBUG(parser_tree)} {
				debugStep "Trying token: $token , expecting $syntaxTokenType $syntaxTokenValue ($min\-$max times)"
			} else {
				puts "[parserDepthSpaces]Trying token: $token , expecting $syntaxTokenType $syntaxTokenValue ($min\-$max times)"
			}
		}

		# No more tokens on input
		if {[llength $token] == 0} {
			if {$::DEBUG(parser) > 3} {
				if {$::DEBUG(parser_tree)} {
					debugStep "Empty token."
				} else {
					puts "[parserDepthSpaces]Empty token."
				}
			}
			return [dict create returnCode 0 codes $transactionCodes]
		}

		# Assign token parameters
		lassign $token tokenType tokenValue tokenBegin tokenEnd

		# Expected tokens handling
		if {$tokenType == "FAKE_TOKEN_TYPE"} {
			lappend _expectedTokens $value
			if {$::DEBUG(parser) > 3} {
				if {$::DEBUG(parser_tree)} {
					debugStep "Reached fake token type."
				} else {
					puts "[parserDepthSpaces]Reached fake token type."
				}
			}
			return [dict create returnCode 1 codes ""]
		}

		# Comments handling
# 		if {$tokenType == "COMMENT"} {
# # 			return [dict create returnCode 0 codes ""]
# 			lappend transactionCodes [list $handlerObject appendToken $token]
# 		} else {
# 			set isComment false
# 		}
# 	}

	# Basic token validation - by type
#	lappend syntaxTokenType "COMMENT"
	if {$tokenType ni $syntaxTokenType} {
		if {$::DEBUG(parser) > 3} {
			if {$::DEBUG(parser_tree)} {
				debugStep "Different type: |$tokenType| ni |$syntaxTokenType|"
			} else {
				puts "[parserDepthSpaces]Different type: |$tokenType| ni |$syntaxTokenType|"
			}
		}
		# Different token types, so here matching this syntax token ends.
		return [dict create returnCode 1 codes $transactionCodes]
	}

	# Handle excludes
	if {$::DEBUG(parser) >= 2 && $::DEBUG(parser_tree)} {
		debugStep "Excludes: $excludes"
	}
	if {[dict size $excludes] > 0} {
		dict for {excludeKey excludeValue} $excludes {
			if {"${tokenType}&$tokenValue" == $excludeKey} {
				if {$::DEBUG(parser) > 3} {
					if {$::DEBUG(parser_tree)} {
						debugStep "Token value excluded: ${tokenType}&$tokenValue"
					} else {
						puts "[parserDepthSpaces]Token value excluded: ${tokenType}&$tokenValue"
					}
				}
				return [dict create returnCode 1 codes $transactionCodes]
			}
		}
	}

	# Assigning real token value to symbolic token name defined in syntax defs
	set $syntaxTokenValue $token

	set results [dict create returnCode 0]
	switch -- $tokenType {
		"KEYWORD" {
			set results [handleKeyword]
		}
		"OPERATOR" {
			set results [handleOperator]
		}
		"STRING" {
			set results [handleString]
		}
		"INTEGER" - "FLOAT" {
			set results [handleIntOrFloat]
		}
		"PAR_LEFT" {
			set results [handleParenthesis]
		}
		"PAR_RIGHT" {
			set results [handleParenthesis]
		}
		"COMMENT" {
			set results [handleComment]
		}
		"OTHER" {
			set results [handleOther]
		}
		"BIND_PARAM" {
			set results [handleBindParam]
		}
	}
	if {[dict get $results returnCode] != 0} {
		if {$::DEBUG(parser) > 3} {
			if {$::DEBUG(parser_tree)} {
				debugStep "Handled with returnCode 1."
			} else {
				puts "[parserDepthSpaces]Handled with returnCode 1."
			}
		}
		return $results
	}

	return [dict create returnCode 0 codes $transactionCodes]
}

body SqlParser::handleKeyword {} {
	upvar tokenValue tokenValue syntaxTokenValue syntaxTokenValue code code handlerObject handlerObject
	upvar transactionCodes transactionCodes tokenType tokenType token token syntaxTokenType syntaxTokenType

	# KEYWORD * in syntax definition matches any keyword
	if {$syntaxTokenValue != "*"} {
		# Support for #exclude()
		set excludeType ""
		set excludeValue ""
		if {[string match "*#exclude(*)" $syntaxTokenValue]} {
			set sp [split $syntaxTokenValue "#"]
			foreach excl [lrange $sp 1 end] {
				set excludeDescription [lindex [regexp -inline -- {exclude\((.*?)\)} $excl] 1]
				lassign $excludeDescription excludeType excludeValue
				set excludeType [split $excludeType |]
				set excludeValue [split $excludeValue |]
			}
			set syntaxTokenValue [lindex $sp 0]
		}

		if {![string equal $tokenValue $syntaxTokenValue]} {
			if {
				("STRING" in $syntaxTokenType || "OTHER" in $syntaxTokenType) && [string toupper $tokenValue] in $_notReservedKeywords
				&&
				($excludeType == "" || $tokenType ni $excludeType && $tokenValue ni $excludeValue)
			} {
				# This is not expected keyword and we can try to interprete it as OTHER
				return [uplevel 1 {handleOther}]
			} else {
				# Keyword tokens must match, if not, then this is where token matching ends.
				return [dict create returnCode 1 codes $transactionCodes]
			}
		}
	}

	if {$::DEBUG(parser) >= 2} {
		if {$::DEBUG(parser_tree)} {
			debugStep "MATCHED token: $tokenType $tokenValue, doing $handlerObject [uplevel [list subst $code]]"
		} else {
			puts "[parserDepthSpaces]MATCHED token: $tokenType $tokenValue, doing $handlerObject [uplevel [list subst $code]]"
		}
	}
	if {$code != ""} {
		set transactionCodes [linsert $transactionCodes 0 [concat $handlerObject [uplevel [list subst $code]]]]
	}
	lappend transactionCodes [list $handlerObject appendToken $token]
	return [dict create returnCode 0]
}

body SqlParser::handleOperator {} {
	upvar tokenValue tokenValue syntaxTokenValue syntaxTokenValue code code handlerObject handlerObject
	upvar transactionCodes transactionCodes tokenType tokenType token token

	# OPERATOR ANY in syntax definition matches any operator
	if {$syntaxTokenValue != "ANY"} {
		if {![string equal $tokenValue $syntaxTokenValue]} {
			# Operators must match, if not, then this is where token matching ends.
			return [dict create returnCode 1 codes $transactionCodes]
		}
	}
	if {$::DEBUG(parser) >= 2} {
		if {$::DEBUG(parser_tree)} {
			debugStep "MATCHED token: $tokenType $tokenValue, doing $handlerObject [uplevel [list subst $code]]"
		} else {
			puts "[parserDepthSpaces]MATCHED token: $tokenType $tokenValue, doing $handlerObject [uplevel [list subst $code]]"
		}
	}

	# Support for #exclude()
	set excludeType ""
	set excludeValue ""
	if {[string match "*#exclude(*)" $syntaxTokenValue]} {
		set sp [split $syntaxTokenValue "#"]
		foreach excl [lrange $sp 1 end] {
			set excludeDescription [lindex [regexp -inline -- {exclude\((.*?)\)} $excl] 1]
			lassign $excludeDescription excludeType excludeValue
			set excludeType [split $excludeType |]
			set excludeValue [split $excludeValue |]
		}
		set syntaxTokenValue [lindex $sp 0]

		# New we have proper variable name to set token value to.
		uplevel 1 [list set $syntaxTokenValue $token]
	}

	if {$code != ""} {
		set transactionCodes [linsert $transactionCodes 0 [concat $handlerObject [uplevel [list subst $code]]]]
	}
	lappend transactionCodes [list $handlerObject appendToken $token]
	return [dict create returnCode 0]
}

body SqlParser::handleString {} {
	upvar tokenValue tokenValue syntaxTokenValue syntaxTokenValue code code handlerObject handlerObject
	upvar transactionCodes transactionCodes tokenType tokenType token token

	if {$::DEBUG(parser) >= 2} {
		if {$::DEBUG(parser_tree)} {
			debugStep "MATCHED token: $tokenType $tokenValue, doing $handlerObject [uplevel [list subst $code]]"
		} else {
			puts "[parserDepthSpaces]MATCHED token: $tokenType $tokenValue, doing $handlerObject [uplevel [list subst $code]]"
		}
	}

	# Support for #exclude()
	set excludeType ""
	set excludeValue ""
	if {[string match "*#exclude(*)" $syntaxTokenValue]} {
		set sp [split $syntaxTokenValue "#"]
		foreach excl [lrange $sp 1 end] {
			set excludeDescription [lindex [regexp -inline -- {exclude\((.*?)\)} $excl] 1]
			lassign $excludeDescription excludeType excludeValue
			set excludeType [split $excludeType |]
			set excludeValue [split $excludeValue |]
		}
		set syntaxTokenValue [lindex $sp 0]

		# New we have proper variable name to set token value to.
		uplevel 1 [list set $syntaxTokenValue $token]
	}

	if {$code != ""} {
		set transactionCodes [linsert $transactionCodes 0 [concat $handlerObject [uplevel [list subst $code]]]]
	}
	lappend transactionCodes [list $handlerObject appendToken $token]
	return [dict create returnCode 0]
}

body SqlParser::handleIntOrFloat {} {
	upvar tokenValue tokenValue syntaxTokenValue syntaxTokenValue code code handlerObject handlerObject
	upvar transactionCodes transactionCodes tokenType tokenType token token

	if {$::DEBUG(parser) >= 2} {
		if {$::DEBUG(parser_tree)} {
			debugStep "MATCHED token: $tokenType $tokenValue, doing $handlerObject [uplevel [list subst $code]]"
		} else {
			puts "[parserDepthSpaces]MATCHED token: $tokenType $tokenValue, doing $handlerObject [uplevel [list subst $code]]"
		}
	}

	# Support for #exclude()
	set excludeType ""
	set excludeValue ""
	if {[string match "*#exclude(*)" $syntaxTokenValue]} {
		set sp [split $syntaxTokenValue "#"]
		foreach excl [lrange $sp 1 end] {
			set excludeDescription [lindex [regexp -inline -- {exclude\((.*?)\)} $excl] 1]
			lassign $excludeDescription excludeType excludeValue
			set excludeType [split $excludeType |]
			set excludeValue [split $excludeValue |]
		}
		set syntaxTokenValue [lindex $sp 0]

		# New we have proper variable name to set token value to.
		uplevel 1 [list set $syntaxTokenValue $token]
	}

	if {$code != ""} {
		set transactionCodes [linsert $transactionCodes 0 [concat $handlerObject [uplevel [list subst $code]]]]
	}
	lappend transactionCodes [list $handlerObject appendToken $token]
	return [dict create returnCode 0]
}

body SqlParser::handleParenthesis {} {
	upvar tokenValue tokenValue syntaxTokenValue syntaxTokenValue code code handlerObject handlerObject
	upvar transactionCodes transactionCodes tokenType tokenType token token

	if {![string equal $tokenValue $syntaxTokenValue]} {
		# Braces must match, if not, then this is where token matching ends.
		return [dict create returnCode 1 codes $transactionCodes]
	}
	if {$::DEBUG(parser) >= 2} {
		if {$::DEBUG(parser_tree)} {
			debugStep "MATCHED token: $tokenType $tokenValue, doing $handlerObject [uplevel [list subst $code]]"
		} else {
			puts "[parserDepthSpaces]MATCHED token: $tokenType $tokenValue, doing $handlerObject [uplevel [list subst $code]]"
		}
	}

	# Support for #exclude()
	set excludeType ""
	set excludeValue ""
	if {[string match "*#exclude(*)" $syntaxTokenValue]} {
		set sp [split $syntaxTokenValue "#"]
		foreach excl [lrange $sp 1 end] {
			set excludeDescription [lindex [regexp -inline -- {exclude\((.*?)\)} $excl] 1]
			lassign $excludeDescription excludeType excludeValue
			set excludeType [split $excludeType |]
			set excludeValue [split $excludeValue |]
		}
		set syntaxTokenValue [lindex $sp 0]

		# New we have proper variable name to set token value to.
		uplevel 1 [list set $syntaxTokenValue $token]
	}

	if {$code != ""} {
		#set transactionCodes [linsert $transactionCodes 0 [concat uplevel [list subst $code]]]
		set transactionCodes [linsert $transactionCodes 0 [concat $handlerObject [uplevel [list subst $code]]]]
	}
	lappend transactionCodes [list $handlerObject appendToken $token]
	return [dict create returnCode 0]
}

body SqlParser::handleComment {} {
	upvar tokenValue tokenValue syntaxTokenValue syntaxTokenValue code code handlerObject handlerObject
	upvar transactionCodes transactionCodes tokenType tokenType token token

	if {$::DEBUG(parser) >= 2} {
		if {$::DEBUG(parser_tree)} {
			debugStep "MATCHED token: $tokenType $tokenValue, doing $handlerObject [uplevel [list subst $code]]"
		} else {
			puts "[parserDepthSpaces]MATCHED token: $tokenType $tokenValue, doing $handlerObject [uplevel [list subst $code]]"
		}
	}

	# Support for #exclude()
	set excludeType ""
	set excludeValue ""
	if {[string match "*#exclude(*)" $syntaxTokenValue]} {
		set sp [split $syntaxTokenValue "#"]
		foreach excl [lrange $sp 1 end] {
			set excludeDescription [lindex [regexp -inline -- {exclude\((.*?)\)} $excl] 1]
			lassign $excludeDescription excludeType excludeValue
			set excludeType [split $excludeType |]
			set excludeValue [split $excludeValue |]
		}
		set syntaxTokenValue [lindex $sp 0]

		# New we have proper variable name to set token value to.
		uplevel 1 [list set $syntaxTokenValue $token]
	}

	if {$code != ""} {
		set transactionCodes [linsert $transactionCodes 0 [concat $handlerObject [uplevel [list subst $code]]]]
	}
	lappend transactionCodes [list $handlerObject appendToken $token]
	return [dict create returnCode 0]
}

body SqlParser::handleOther {} {
	upvar tokenValue tokenValue syntaxTokenValue syntaxTokenValue code code handlerObject handlerObject
	upvar transactionCodes transactionCodes tokenType tokenType token token

	if {$::DEBUG(parser) >= 2} {
		if {$::DEBUG(parser_tree)} {
			debugStep "MATCHED token: $tokenType $tokenValue, doing $handlerObject [uplevel [list subst $code]]"
		} else {
			puts "[parserDepthSpaces]MATCHED token: $tokenType $tokenValue, doing $handlerObject [uplevel [list subst $code]]"
		}
	}

	# Support for #exclude()
	set excludeType ""
	set excludeValue ""
	if {[string match "*#exclude(*)" $syntaxTokenValue]} {
		set sp [split $syntaxTokenValue "#"]
		foreach excl [lrange $sp 1 end] {
			set excludeDescription [lindex [regexp -inline -- {exclude\((.*?)\)} $excl] 1]
			lassign $excludeDescription excludeType excludeValue
			set excludeType [split $excludeType |]
			set excludeValue [split $excludeValue |]
		}
		set syntaxTokenValue [lindex $sp 0]

		# New we have proper variable name to set token value to.
		uplevel 1 [list set $syntaxTokenValue $token]

		if {$tokenValue in $excludeValue && $tokenType in $excludeType} {
			# This is excluded match.
			if {$::DEBUG(parser) >= 2} {
				if {$::DEBUG(parser_tree)} {
					debugStep "Matched token but excluded by: $sp"
				} else {
					puts "[parserDepthSpaces]Matched token but excluded by: $sp"
				}
			}
			return [dict create returnCode 1 codes $transactionCodes]
		}
	}

	if {$code != ""} {
		set transactionCodes [linsert $transactionCodes 0 [concat $handlerObject [uplevel [list subst $code]]]]
	}
	lappend transactionCodes [list $handlerObject appendToken $token]
	return [dict create returnCode 0]
}

body SqlParser::handleBindParam {} {
	upvar tokenValue tokenValue syntaxTokenValue syntaxTokenValue code code handlerObject handlerObject
	upvar transactionCodes transactionCodes tokenType tokenType token token

	# Support for #exclude()
	set excludeType ""
	set excludeValue ""
	if {[string match "*#exclude(*)" $syntaxTokenValue]} {
		set sp [split $syntaxTokenValue "#"]
		foreach excl [lrange $sp 1 end] {
			set excludeDescription [lindex [regexp -inline -- {exclude\((.*?)\)} $excl] 1]
			lassign $excludeDescription excludeType excludeValue
			set excludeType [split $excludeType |]
			set excludeValue [split $excludeValue |]
		}
		set syntaxTokenValue [lindex $sp 0]

		# New we have proper variable name to set token value to.
		uplevel 1 [list set $syntaxTokenValue $token]
	}

	if {$::DEBUG(parser) >= 2} {
		if {$::DEBUG(parser_tree)} {
			debugStep "MATCHED token: $tokenType $tokenValue, doing $handlerObject [uplevel [list subst $code]]"
		} else {
			puts "[parserDepthSpaces]MATCHED token: $tokenType $tokenValue, doing $handlerObject [uplevel [list subst $code]]"
		}
	}
	if {$code != ""} {
		set transactionCodes [linsert $transactionCodes 0 [concat $handlerObject [uplevel [list subst $code]]]]
	}
	lappend transactionCodes [list $handlerObject appendToken $token]
	return [dict create returnCode 0]
}

body SqlParser::freeParserObjects {} {
	if {[llength $_parserObjects] == 0} return
	delete object {*}$_parserObjects
	set _parserObjects [list]
}

body SqlParser::validateSqlDefinitions {} {
	foreach idx [array names ::${_dialect}::statementSyntax] {
		validateSqlDefinitionInternalList $idx [lindex [set ::${_dialect}::statementSyntax($idx)] 1]
	}
}

body SqlParser::validateSqlDefinitionInternalList {stmt defList} {
	foreach {exp value occur code} $defList {
		if {$exp ni "ALTER GROUP TOKEN SUBST"} {
			puts "Invalid expression: $exp in statement: $stmt"
			continue
		}
		if {[catch {convertParserOccurances $occur}]} {
			puts "Invalid occurance definition: $occur in statement: $stmt / $exp"
			continue
		}
		switch -- $exp {
			"GROUP" {
				validateSqlDefinitionInternalList $stmt $value
			}
			"ALTER" {
				validateSqlDefinitionInternalList $stmt $value
			}
		}
	}
}

body SqlParser::setLacksTolerantion {bool} {
	if {![string is boolean $bool] || $bool == ""} {
		error "Expected boolean but got: $bool"
	}
	set _tolerateLacks $bool
}
