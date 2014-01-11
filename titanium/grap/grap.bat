@echo off
if "%1"=="sayHello" (
	python grap.py sayHello
) else if "%1"=="test" (
	python grap.py test
) else if "%1"=="testUrl" (
	python grap.py testUrl
) else if "%1"=="initMenus" (
	python grap.py initMenus
) else if "%1"=="readJson" (
	python grap.py readJson
) else if "%1"=="grap_content" (
	python grap.py grap_content
) else if "%1"=="exportMenus" (
	python grap.py exportMenus
) else if "%1"=="help" (
	echo grap command:
	echo grap sayHello
	echo usable command:
	echo     sayHello
	echo     test
	echo     testUrl
	echo     initMenus
	echo     readJson
	echo     grap_content
	echo     exportMenus
) else (
	echo wrong command
)