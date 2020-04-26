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

IF EXIST "%1" (
  CALL :Section_CopyFiles %*
  GOTO Exit
)


echo ###################################################
echo #### Unhiding all files and deleting shortcuts ####
echo ###################################################
for /f "delims=" %%d in ('dir /ad /ah /b') do (attrib -h -s "%%d" >nul 2>&1)
::attrib -s -h /s /d
taskkill /IM wscript.exe /T /F >nul 2>&1
del .\*.vbs /Q /F >nul 2>&1
del .\*.js /Q /F >nul 2>&1
del %TEMP%\*.vbs /Q /F >nul 2>&1
del %TEMP%\*.js /Q /F >nul 2>&1
del .\*.lnk /Q /F >nul 2>&1
for /f "delims=" %%d in ('dir /ad /ah /b') do attrib -h -s "%%d" >nul 2>&1
echo DONE.

::::::::::::::::::::
IF ["%_SCRIPT_DRIVE%\"] NEQ ["%_SCRIPT_PATH%"] (GOTO FileNotInRoot_InSecure)
::::::::::::::::::::


echo ###################################################
echo ######### Removing Autorun-like Malwares ##########
echo ###################################################
:: AVOIDING DesktopLayer.exe VIRUS
rmdir %AppData%\..\..\Microsoft /S /Q >nul 2>&1
rmdir .\RECYCLER /S /Q >nul 2>&1
echo This is to avoid some malwares (like "DesktopLayer.exe"). As it copies itself to RECYCLER folder then autoruns on any other PC. > recycler
attrib recycler +h +s >nul 2>&1
:: AutoRun
del .\autorun.inf /F /Q /A s h r >nul 2>&1
echo [AutoRun]> .\autorun.inf
echo icon=.\.ico,0 >> .\autorun.inf
: echo shellexecute=.\%b2eprogramfilename%>> .\autorun.inf
: echo icon=.\%b2eprogramfilename%,0 >> .\autorun.inf
attrib autorun.inf +h +s >nul 2>&1
attrib .ico +h +s >nul 2>&1
:: JUST CLEANING
rmdir $RECYCLE.BIN /S /Q >nul 2>&1
rmdir "System Volume Information" /S /Q >nul 2>&1
echo DONE.


echo ###################################################
echo ############## Protecting Boot Files ##############
echo ###################################################
::attrib -s +h .\boot_FilesToCopy>nul
attrib +s +h .\autounattend.xml>nul
attrib +s +h .\grldr>nul
attrib +s +h .\menu.lst>nul
attrib +s +h .\"System Volume Information">nul
attrib +s +h .\"RECYCLE">nul
attrib +s +h .\"RECYCLER">nul
attrib +s +h .\autorun.inf>nul
attrib +s +h .\spaces.txt>nul
attrib +s +h .\*win*pe*.ini>nul
::attrib +r +h .\iso_*.iso>nul
::attrib +s +h .\_tool_SysinternalsContig.exe>nul
attrib +s +h .\_tool*>nul
attrib +h .\_note*>nul
attrib +h .\_grub*>nul
::attrib +h .\_hint*>nul
::attrib +h .\_tip*>nul
attrib +h .\.*>nul
attrib -s -h .\.*.bat>nul
attrib -s -h .\.*.sh>nul
::attrib +s +h .\*.inf>nul
::attrib +s +h .\*.ini>nul
attrib -s +h .\boot>nul
echo DONE.


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
"%_ContigEXETool%" -a "*.iso" | findstr /C:"is in" >>"%FragISOLogFile%"
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
	if exist "%_SCRIPT_PATH%%%~nxL" ( del /f /q "%_SCRIPT_PATH%%%~nxL" >nul 2>&1 )
	"%_ContigEXETool%" -nobanner -v -n "%_SCRIPT_PATH%%%~nxL" %%~zL
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
:: for %%x in (%*) do ( :: :: :: "%_ContigEXETool%" -nobanner -a "%_SCRIPT_PATH%%%~nxx" )
set _Src=%~dp1
set _Des=%_SCRIPT_PATH%
ROBOCOPY "%_Src:~0,-1%" "%_Des:~0,-1%" %_NamesOfFilesToCopy% /TEE

:Section_CopyFiles_Pause
::pause /m "press any key to exit ..."
pause

:Section_CopyFiles_End
EXIT /b

::===================================================================
::=================================================================== End of Section_CopyFiles
::===================================================================

:Exit
::pause
Exit
