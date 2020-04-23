@echo off

TITLE MYSETUP.CMD
REM run wpeinit after loading ISO file
:findload
SET USBDRIVE=
echo Looking for a drive containing \boot\firadisk\LOADISO.CMD...
cmd /q /c  "FOR %%i IN (C D E F G H I J K L N M O P Q R S T U V W X Y Z) DO IF EXIST %%i:\boot\firadisk\LOADISO.CMD  cmd /k %%i:\boot\firadisk\LOADISO.cmd"
::if "%USBDRIVE%"=="" goto :findload


REM find RAMDRIVE with ISO contents
for %%I in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist %%I:\sources\install.wim set RAMdrive=%%I:
If NOT "%RAMdrive%"=="" echo Found Install.wim at %RAMdrive%\sources\install.wim
IF "%RAMdrive%"=="" (
echo ERROR - COULD NOT FIND INSTALL.WIM!
pause
pause
REM Retry
goto :findload
)

echo Trying to run setup (with Repair option) from X: drive
if exist X:\Setup.exe X:\setup.exe

echo X:\Setup.exe not found!
echo Looking for setup.exe in \sources on DVD ISO
If exist %RAMdrive%\sources\setup.exe  (
%RAMdrive%
REM setup will use its path to find the install.wim
echo Launching %RAMdrive%\sources\setup.exe
%RAMdrive%\sources\setup.exe
goto :RBT
)


echo looking for setup in root of DVD ISO
If exist %RAMdrive%\setup.exe  (
%RAMdrive%
REM setup will use its path to find the install.wim
%RAMdrive%\setup.exe
goto :RBT
)


REM if not then just call setup in root of boot.wim and point it at install.wim

if exist X:\sources\Setup.exe X:\sources\setup.exe /installfrom:%RAMdrive%\sources\install.wim
if exist X:\Setup.exe X:\setup.exe /installfrom:%RAMdrive%\sources\install.wim
goto :RBT


:BAD
dir X:\ /b
echo Cannot find X:\Setup.exe !
@echo Press a key to reboot now...
pause

:RBT
wpeutil reboot
pause



