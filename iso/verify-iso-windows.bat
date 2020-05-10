@echo off
::SETLOCAL (disabled to enable gloibal vars in calling :Section_CopyFiles)
SET _SCRIPT_DRIVE=%~d0
SET _SCRIPT_PATH=%~dp0
SET ROOT_DIR=%_SCRIPT_PATH%\..
CD %ROOT_DIR%
SET ROOT_DIR=%CD%

SET ISO_DIR=%ROOT_DIR%\iso
SET _ContigEXETool=%ROOT_DIR%\tools\SysinternalsContig.exe
SET FragISOLogFile=%TEMP%\hboot_fragmented_iso_files
SET menuISOFileList=%ROOT_DIR%\boot\.menuISOFileList.lst
set menuISOChooseTypeGRUBPath=/boot/.menuISOChooseType.lst


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
for /f "delims=" %%d in (`dir %ISO_DIR%/*.iso /b`) do (
    echo.>>%menuISOFileList%
    echo title Set ISO="%%d">>%menuISOFileList%
    echo set MYISO=%%d>>%menuISOFileList%
    echo configfile %menuISOChooseTypeGRUBPath%>>%menuISOFileList%
)
echo DONE.
GOTO DonemenuISOFileList
::pause
:skipmenuISOFileList
echo Skipped
:DonemenuISOFileList


:Exit
pause
Exit /B
