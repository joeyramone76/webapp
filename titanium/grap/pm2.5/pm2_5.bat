@echo off
if "%1"=="sayHello" (
	python pm2_5.py sayHello
) else if "%1"=="test" (
	python pm2_5.py test
) else if "%1"=="testUrl" (
	python pm2_5.py testUrl
) else if "%1"=="readJson" (
	python pm2_5.py readJson %2
) else if "%1"=="getAllData" (
	python pm2_5.py getAllData %2
) else if "%1"=="getCities" (
	python pm2_5.py getCities %2
) else if "%1"=="help" (
	echo pm2_5 command:
	echo pm2_5 sayHello
	echo usable command:
	echo     sayHello
	echo     test
	echo     testUrl
	echo     readJson
	echo     getAllData
	echo     getCities
) else (
	echo wrong command
)