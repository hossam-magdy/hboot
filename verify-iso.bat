@echo off
::SETLOCAL (disabled to enable gloibal vars in calling :Section_CopyFiles)
SET _SCRIPT_DRIVE=%~d0
SET _SCRIPT_PATH=%~dp0
SET _ZipBootFilesInRoot=%_SCRIPT_DRIVE%/boot/.bootfiles-rootdir.zip
SET _ContigEXETool=%_SCRIPT_DRIVE%/boot/.tool_SysinternalsContig.exe
SET FragISOLogFile=%TEMP%/.(Fragmented_ISO_Files).log
SET menuISOFileList=%_SCRIPT_DRIVE%/boot/.menuISOFileList.lst
%_SCRIPT_DRIVE%
CD %_SCRIPT_PATH%
SET ISO_DIR=iso


if not exist "%_SCRIPT_DRIVE%/boot" ( GOTO DoneISOContig )
if not exist "%_ContigEXETool%" ( GOTO SkipISOContig )
echo ###################################################
echo ######### Verifying that all ISO files ############
echo ######## are Contiguous (not fragmented) ##########
echo ###################################################
echo XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX>"%FragISOLogFile%"
echo XXXXXXXXXX Fragmented files found: XXXXXXXXXX>>"%FragISOLogFile%"
echo.>>"%FragISOLogFile%"
reg ADD "HKCU\SOFTWARE\Sysinternals\Contig" /f /v EulaAccepted /d 1 >nul 2>&1
"%_ContigEXETool%" -a "%ISO_DIR%\*.iso" | findstr /C:"is in" >>"%FragISOLogFile%"
reg DELETE "HKCU\SOFTWARE\Sysinternals\Contig" /f /v EulaAccepted >nul 2>&1
echo.>>"%FragISOLogFile%"
echo XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX>>"%FragISOLogFile%"
echo.>>"%FragISOLogFile%"
echo.- To boot from the above ISO files:>>"%FragISOLogFile%"
echo.  (DEFRAG^) ^|^| (DELETE ^& RE-COPY^) them ...>>"%FragISOLogFile%"
find /C "is in" "%FragISOLogFile%" >nul 2>&1
::(0== frag files FOUND, 1 not found)
IF [%ERRORLEVEL%] EQU [0] (
	cls
	type "%FragISOLogFile%"
	::start "" "%FragISOLogFile%" >nul 2>&1
	::timeout /t 10
) ELSE (
	del "%FragISOLogFile%" >nul 2>&1
)
::pause
echo DONE.
GOTO DoneISOContig
:SkipISOContig
echo Skipping ISO contiguous check.
pause
:DoneISOContig


if not exist "%_SCRIPT_DRIVE%/boot" ( GOTO DonemenuISOFileList )
if not exist "%menuISOFileList%" ( GOTO skipmenuISOFileList )
echo ###################################################
echo ################ Listing ISO files ################
echo ###################################################
set menuISOChooseType=/boot/.menuISOChooseType.lst
echo.>%menuISOFileList%
for /f "delims=" %%d in ('dir *.iso /b') do (
	echo.>>%menuISOFileList%
	echo title Set ISO="%%d">>%menuISOFileList%
	echo set MYISO=%%d>>%menuISOFileList%
	echo configfile %menuISOChooseType%>>%menuISOFileList%
)
echo DONE.
GOTO DonemenuISOFileList
::pause
:skipmenuISOFileList
echo Skipped
pause
:DonemenuISOFileList


:Exit
::pause
Exit
