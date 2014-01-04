@echo off
if "%1"=="sayHello" (
	python updateHtml.py sayHello
) else if "%1"=="test" (
	python updateHtml.py test
) else if "%1"=="update" (
	python updateHtml.py update
) else if "%1"=="searchHtmlFile" (
	python updateHtml.py searchHtmlFile
) else if "%1"=="testUpdate" (
	python updateHtml.py testUpdate
) else if "%1"=="getPrefixPath" (
	python updateHtml.py getPrefixPath
) else if "%1"=="help" (
	echo updateHtml command:
	echo updateHtml sayHello
	echo usable command:
	echo     sayHello
	echo     test
	echo     update
	echo     searchHtmlFile
	echo     testUpdate
	echo     getPrefixPath
) else (
	echo wrong command
)