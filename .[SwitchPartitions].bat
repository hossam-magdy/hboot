@echo off
SETLOCAL
SET _SCRIPT_DRIVE=%~d0
SET _SCRIPT_PATH=%~dp0
SET _BooticeEXETool=%CD%/.BOOTICE.exe
IF ["%_SCRIPT_DRIVE%\"] NEQ ["%_SCRIPT_PATH%"] (GOTO FileNotInRoot_InSecure)
%_SCRIPT_DRIVE%
CD %_SCRIPT_PATH%


echo Are you sure you want to swap partitions?

:: If CHOICE command is not defined (propably running from WinPE), VerifyWithSetP
CHOICE /? >nul 2>&1
::echo %ERRORLEVEL%
IF [%ERRORLEVEL%] NEQ [0] (GOTO VerifyWithSetP)
::WHERE CHOICE >nul


:VerifyWithCHOICE
CHOICE /C YN /T 20 /D N
IF [%ERRORLEVEL%] NEQ [1] (GOTO Exit)
GOTO StartSwitching


:VerifyWithSetP
set /P Verify="(Type 'y' for 'Yes', otherwise 'No'): "
IF ["%Verify%"] NEQ ["y"] (GOTO Exit)
GOTO StartSwitching


:StartSwitching
cls
echo Switching partitions ...
CALL "%_BooticeEXETool%" /DEVICE=%_SCRIPT_DRIVE% /partitions /firstpart=1
echo Done, press any key to open the new partition ...
pause >nul
::sleep 3 >nul 2>&1
START %_SCRIPT_DRIVE%
GOTO Exit

:FileNotInRoot_InSecure
::echo The file is not in root path of the drive.
cls
echo.
echo Propably, you are running this file from main HDD,
echo which is INSECURE and MAY DAMAGE YOUR HDD.
echo ... Press any key to exit ...
pause >nul
GOTO Exit



::echo.
::set /P PASS="Enter partition-swap code: "
::IF ["%PASS%"] NEQ ["6236"] (GOTO Wrong_Code)
:Wrong_Code
cls
echo.
echo Sorry, wrong code entered.
echo ... Press any key to exit ...
pause >nul
::sleep 3
GOTO Exit




:Exit
::pause >nul

