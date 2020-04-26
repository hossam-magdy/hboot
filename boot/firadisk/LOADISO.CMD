TITLE LOADISO.CMD
color 1f
@echo off
cls
SET BIT=32
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" SET BIT=64

if "%BIT%"=="32" \boot\firadisk\slp.exe 5
if "%BIT%"=="64" type x:\windows\system32\shell32.dll > nul
if "%BIT%"=="64" type x:\windows\system32\shell32.dll > nul
if "%BIT%"=="64" type x:\windows\system32\shell32.dll > nul
if "%BIT%"=="64" type x:\windows\system32\shell32.dll > nul
if "%BIT%"=="64" type x:\windows\system32\shell32.dll > nul

SET USBDRIVE=
FOR %%i IN (C D E F G H I J K L N M O P Q R S T U V W X Y Z) DO IF EXIST %%i:\BOOT\FIRADISK\LOADISO.CMD SET USBDRIVE=%%i:
cls


REM CHECKS!

If "%USBDRIVE%"=="" (echo FIRADISK\LOADISO.CMD NOT FOUND ON ANY DRIVE!) & goto :MYEND

IF "%BIT%"=="32" (
if not exist %USBDRIVE%\BOOT\FIRADISK\firadisk.inf (echo FIRADISK\FIRADISK.INF NOT FOUND ON %USBDRIVE%!) & goto :MYEND
if not exist %USBDRIVE%\BOOT\FIRADISK\firadisk.sys (echo FIRADISK\FIRADISK.SYS NOT FOUND ON %USBDRIVE%!) & goto :MYEND
if not exist %USBDRIVE%\BOOT\FIRADISK\i386\devcon.exe (echo FIRADISK\i386\DEVCON.EXE NOT FOUND ON %USBDRIVE%!) & goto :MYEND
)

IF "%BIT%"=="64" (
if not exist %USBDRIVE%\BOOT\FIRADISK\firadisk.inf (echo FIRADISK\FIRADI64.INF NOT FOUND ON %USBDRIVE%!) & goto :MYEND
if not exist %USBDRIVE%\BOOT\FIRADISK\firadisk.sys (echo FIRADISK\FIRADISK.SYS NOT FOUND ON %USBDRIVE%!) & goto :MYEND
if not exist %USBDRIVE%\BOOT\FIRADISK\ia64\devcon64.exe (echo FIRADISK\ia64\DEVCON64.EXE NOT FOUND ON %USBDRIVE%!) & goto :MYEND
)


@echo FOUND USB DRIVE AT DRIVE %USBDRIVE%
cd /d %USBDRIVE%\
TITLE LOAD WINDOWS ISO USING FIRADISK
color 1f

REM Load driver
if "%BIT%"=="64" \BOOT\FIRADISK\ia64\devcon64  install \BOOT\FIRADISK\firadisk.inf   root\firadisk
if "%BIT%"=="32" \BOOT\FIRADISK\i386\devcon    install \BOOT\FIRADISK\firadisk.inf   root\firadisk




REM The driver takes a few seconds to load the ISO file
echo Waiting until ISO is loaded...
if "%BIT%"=="32" \BOOT\FIRADISK\slp.exe 5
if "%BIT%"=="64" type x:\windows\system32\shell32.dll > nul
if "%BIT%"=="64" type x:\windows\system32\shell32.dll > nul
if "%BIT%"=="64" type x:\windows\system32\shell32.dll > nul

SET USBDRIVE=
FOR %%i IN (C D E F G H I J K L N M O P Q R S T U V W X Y Z) DO IF EXIST %%i:\SOURCES\INSTALL.WIM SET USBDRIVE=%%i:

IF "%BIT%%USBDRIVE%"=="32" \BOOT\FIRADISK\slp.exe 5
IF "%BIT%%USBDRIVE%"=="64"  type x:\windows\system32\shell32.dll > nul


IF NOT "%USBDRIVE%"=="" goto :skipimdsk
REM Load ISO using ImDisk
call \BOOT\FIRADISK\IMDISK_install.cmd
call \BOOT\FIRADISK\IMDISK_instiso.cmd
:skipimdsk


IF "%USBDRIVE%"=="" FOR %%i IN (C D E F G H I J K L N M O P Q R S T U V W X Y Z) DO IF EXIST %%i:\SOURCES\INSTALL.WIM SET USBDRIVE=%%i:

IF "%USBDRIVE%"=="" echo WARNING: \SOURCES\INSTALL.WIM not found!
IF NOT "%USBDRIVE%"=="" echo FOUND %USBDRIVE%\SOURCES\INSTALL.WIM
if "%BIT%"=="32" \BOOT\FIRADISK\slp.exe 2
if "%BIT%"=="64" type x:\windows\system32\shell32.dll > nul




echo cls
goto :INSTALL
::if not exist x:\sources\recovery\RecEnv.exe  if not exist x:\sources\recovery\startrep.exe   goto :INSTALL
echo.
echo ************** REPAIR WINDOWS? **************
echo.
set /P ASK="Do you want to install Windows ? (Y = install  |  N = repair) : "
if /I "%ASK%"=="Y" goto :INSTALL


:REPAIR
echo.
echo Opening repair enviroment ...
echo.
IF EXIST x:\sources\recovery\RecEnv.exe (x:\sources\recovery\RecEnv.exe) & goto :MYEND
IF EXIST x:\sources\recovery\startrep.exe (x:\sources\recovery\startrep.exe) & goto :MYEND
goto :MYEND

:INSTALL
exit


:MYEND
@echo.
echo You should restart your computer now.
pause
exit
