@echo off
setLocal
:: Call this file like: _VolumeLetterToDiskID.bat E

SET VOLUME=%~1
SET VOLUME=%VOLUME:~0,1%


:: The next lines call `wmic` and invokes ":ProcessFoundLine" with the o/p line THAT CONTAINS "Disk#"
SET CMD=wmic logicaldisk where 'DeviceID LIKE '%VOLUME%%%'' Assoc /AssocClass:Win32_LogicalDiskToPartition
FOR /F "tokens=* USEBACKQ" %%I IN (`%CMD%`) DO ECHO %%~I| FINDSTR /C:"Disk #">Nul && CALL :ProcessFoundLine "%%~I"
GOTO :End

:: This "batch function" takes string containing "AnyStr1 Disk#5, AnyStr2" and returns "5" (without quoutes)
:ProcessFoundLine
SET RESULT=%*
::              "5, AnyStr2"
SET RESULT=%RESULT:*Disk #=%
::              "5"
for /f "tokens=1 delims=," %%i in ("%RESULT%") do SET RESULT=%%i
ECHO %RESULT%
EXIT /B 0

:End