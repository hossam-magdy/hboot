@echo off
setlocal ENABLEDELAYEDEXPANSION

::SETLOCAL (disabled to enable gloibal vars in calling :Section_CopyFiles)
SET _SCRIPT_DRIVE=%~d0
SET _SCRIPT_PATH=%~dp0

CALL :NORMALIZEPATH "%_SCRIPT_PATH%.."
SET ROOT_DIR=%RETVAL%

REM remove trailing backslash
IF %ROOT_DIR:~-1%==\ SET ROOT_DIR=%ROOT_DIR:~0,-1%

SET ISO_DIRNAME=iso
SET ISO_DIR=%ROOT_DIR%\%ISO_DIRNAME%
SET _ContigEXETool=%ROOT_DIR%\tools\SysinternalsContig.exe
SET FragISOLogFile=%TEMP%\hboot_fragmented_iso_files
SET menuISOFileList=%ROOT_DIR%\boot\.menuISOFileList.lst
set menuISOChooseTypeGRUBPath=/boot/.menuISOChooseType.lst

IF EXIST "%1" (
  CALL :Section_CopyFiles %*
  REM GOTO Exit
)

:Verify_ISO_Contiguous
if not exist "%ROOT_DIR%/boot" ( GOTO DoneISOContig )
if not exist "%_ContigEXETool%" ( GOTO SkipISOContig )
echo ###################################################
echo ######### Verifying that all ISO files ############
echo ######## are Contiguous (not fragmented) ##########
echo ###################################################
reg ADD "HKCU\SOFTWARE\Sysinternals\Contig" /f /v EulaAccepted /d 1 >nul 2>&1
"%_ContigEXETool%" -a "%ISO_DIR%\*.iso" | findstr /R /C:"[ ]is[ ][id]" >%FragISOLogFile%
reg DELETE "HKCU\SOFTWARE\Sysinternals\Contig" /f /v EulaAccepted >nul 2>&1
REM (0== frag files FOUND, 1 not found)
findstr /R /C:"[ ]is[ ]in" "%FragISOLogFile%" >nul 2>&1
IF "%ERRORLEVEL%" == "0" (
    cls
    type "%FragISOLogFile%"
    echo.
    echo.- To boot from the currntly-fragmented ISO files:
    echo.  (DEFRAG^) ^|^| (DELETE ^& RE-COPY^) them ...
    pause
    cls
) ELSE (
    REM start "" "%FragISOLogFile%" >nul 2>&1
    REM timeout /t 10
    type "%FragISOLogFile%"
)
del %FragISOLogFile% >nul 2>&1
::pause
echo DONE.
GOTO DoneISOContig
:SkipISOContig
echo Skipping ISO contiguous check.
pause
:DoneISOContig


if not exist "%ROOT_DIR%/boot" ( GOTO DonemenuISOFileList )
if not exist "%menuISOFileList%" ( GOTO skipmenuISOFileList )
echo ###################################################
echo ################ Listing ISO files ################
echo ###################################################
echo.>%menuISOFileList%
for /f "delims=" %%d in ('dir /b "%ISO_DIR%\*.iso"') do (
    echo.>>%menuISOFileList%
    echo iftitle [if exist /%ISO_DIRNAME%/%%d] Set ISO="/%ISO_DIRNAME%/%%d">>%menuISOFileList%
    echo set MYISO=/%ISO_DIRNAME%/%%d>>%menuISOFileList%
    echo configfile %menuISOChooseTypeGRUBPath%>>%menuISOFileList%
)
echo DONE.
GOTO DonemenuISOFileList
::pause
:skipmenuISOFileList
echo Skipped
:DonemenuISOFileList


GOTO Exit


:NORMALIZEPATH
SET RETVAL=%~f1
EXIT /B


::===================================================================
::=================================================================== Start of Section_CopyFiles
::===================================================================

:Section_CopyFiles


:: GLOBALLY SET BEFORE
::SET _SCRIPT_PATH=%~dp0
::SET _ContigTool=%CD%/_tool_SysinternalsContig.exe
SET _NamesOfFilesToCopy=

REG ADD "HKCU\SOFTWARE\Sysinternals\Contig" /f /v EulaAccepted /d 1 >nul 2>&1
for %%L in (%*) do (
	call set "_NamesOfFilesToCopy=%%_NamesOfFilesToCopy%% "%%~nxL""
	if exist "%ISO_DIR%\%%~nxL" ( del /f /q "%ISO_DIR%\%%~nxL" >nul 2>&1 )
	"%_ContigEXETool%" -nobanner -v -n "%ISO_DIR%\%%~nxL" %%~zL
)
REG DELETE "HKCU\SOFTWARE\Sysinternals\Contig" /f /v EulaAccepted >nul 2>&1

echo.
echo.
echo =================================================================
echo =================================================================
echo === Contiguous empty files were created (check above results) ===
echo ========== you can now COPY and OVERWRITE/REPLACE them ==========
echo =================================================================
echo =================================================================
echo.

ROBOCOPY /? >nul 2>&1
IF [%ERRORLEVEL%] EQU [9009] (GOTO Section_CopyFiles_Pause)

echo Start copying files (via robocopy)?
CHOICE /? >nul 2>&1
IF [%ERRORLEVEL%] EQU [9009] (GOTO VerifyWithSetP)
:VerifyWithCHOICE
CHOICE /C YN /T 20 /D N
IF [%ERRORLEVEL%] NEQ [1] (GOTO Section_CopyFiles_End)
GOTO startCopy
:VerifyWithSetP
set /P Verify="(Type 'y' for 'Yes', otherwise 'No'): "
IF ["%Verify%"] NEQ ["y"] (GOTO Section_CopyFiles_End)
GOTO startCopy


:startCopy
cls
:: for %%x in (%*) do ( :: :: :: "%_ContigEXETool%" -nobanner -a "%ISO_DIR%\%%~nxx" )
set _Src=%~dp1
set _Des=%ISO_DIR%
ROBOCOPY "%_Src:~0,-1%" "%_Des%" %_NamesOfFilesToCopy% /TEE

:Section_CopyFiles_Pause
::pause /m "press any key to exit ..."
pause

:Section_CopyFiles_End
EXIT /b

::===================================================================
::=================================================================== End of Section_CopyFiles
::===================================================================

:Exit
pause
Exit /B
