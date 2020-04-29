:: @echo off

:: Run this file as:
:: - install-windows.bat [TARGET_DEVICE] [BOOT_SIZE=10GB]
:: - install-windows.bat 1 15GB

::SETLOCAL (disabled to enable gloibal vars in calling :Section_CopyFiles)
SET _SCRIPT_DRIVE=%~d0
SET _SCRIPT_DIR=%~dp0
SET ROOT_DIR=%_SCRIPT_DIR%/..
CD %ROOT_DIR%
SET _BooticeEXETool="%ROOT_DIR%/tools/BOOTICE.exe"

::###################### SIZE_BOOT_GB
SET DEFAULT_SIZE_BOOT=10
:: TODO: Take it from input, or fallback to DEFAULT_SIZE_BOOT
SET SIZE_BOOT_GB=10
:::::::::

::###################### TARGET_DISK_NUMBER
::::::::: TARGET_VOLUME (current volume if it is removable, otherwise prompt user)
SET THIS_VOLUME=%~d0
:: TODO: fix CALL
FOR /F "tokens=* USEBACKQ" %%F IN (`CALL "%~f0" :_ListRemovableVolumes`) DO SET REMOVABLE_VOLUMES=%%F
ECHO %REMOVABLE_VOLUMES%| FINDSTR /C:"%THIS_VOLUME%">Nul && SET TARGET_VOLUME=%THIS_VOLUME%|| (
  ECHO %REMOVABLE_VOLUMES%
  SET /p TARGET_VOLUME="Choose target USB volume: "
)
SET TARGET_VOLUME=%TARGET_VOLUME:~0,1%:
::::::::: TARGET_DISK_NUMBER (number after //./PHYSICALDRIVE{HERE} : 1,2,...)
FOR /F "tokens=* USEBACKQ" %%F IN (`CALL "%~f0" :_VolumeLetterToDiskID %TARGET_VOLUME%`) DO SET TARGET_DISK_NUMBER=%%F
IF %TARGET_DISK_NUMBER% equ 0 ( ECHO "Exiting… should not run on device 0" && EXIT 1 )


echo THIS_VOLUME = %THIS_VOLUME%
echo TARGET_VOLUME = %TARGET_VOLUME%
echo TARGET_DISK_NUMBER = %TARGET_DISK_NUMBER%

ECHO 'Confirm?'
PAUSE


::###################### CMD_PARTITION

echo "Partitioning & Formatting ..."
:::::::::::::::::::::::::::::::: Partitioning Using Diskpart
:: https://www.diskpart.com/de/help/cmd.html
:: https://commandwindows.com/diskpart.htm
:: https://www.tech-recipes.com/rx/9910/how-to-automate-windows-diskpart-commands-in-a-script/
SET /a SIZE_BOOT_MB="SIZE_BOOT_GB * 1024"
SET diskpart_script=diskpart_script

echo.>%diskpart_script%
echo SELECT DISK %TARGET_DISK_NUMBER% >>%diskpart_script%
echo CLEAN >>%diskpart_script%
echo.>>%diskpart_script%
echo CREATE PARTITION PRIMARY SIZE=%SIZE_BOOT_MB% NOERR >>%diskpart_script%
echo ACTIVE >>%diskpart_script%
echo FORMAT FS=NTFS LABEL=HBoot QUICK OVERRIDE NOERR >>%diskpart_script%
echo ASSIGN NOERR >>%diskpart_script%
echo.>>%diskpart_script%
echo CREATE PARTITION PRIMARY NOERR >>%diskpart_script%
echo FORMAT FS=NTFS LABEL=HData QUICK OVERRIDE NOERR >>%diskpart_script%
echo ASSIGN NOERR >>%diskpart_script%

SET CMD_PARTITION=diskpart /s %diskpart_script%
ECHO CMD_PARTITION=%CMD_PARTITION%
PAUSE
:: CALL %CMD_PARTITION%
::::::::::::::::::::::::::::::::::::: 

::###################### CMD_WRITE_MBR
echo "Writing MBR ..."
:::::::::::::::::::::::::::::::: BOOTICE
SET CMD_WRITE_MBR="%_BooticeEXETool%" /DEVICE=%_SCRIPT_DRIVE% /mbr /install /type=GRUB4DOS /v045
ECHO CMD_WRITE_MBR=%CMD_WRITE_MBR% [/boot_file=grldr]
PAUSE
:: CALL %CMD_WRITE_MBR%
::::::::::::::::::::::::::::::::

COPY menu.lst %ROOT_DIR%\

ECHO "Finished!"
GOTO :EOF

::#######################################################################
::####################################################################### HELPERS
::#######################################################################

::###################### _VolumeLetterToDiskID
:_VolumeLetterToDiskID
:: Call this like: CALL _VolumeLetterToDiskID E

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

::###################### _ListRemovableVolumes
:_ListRemovableVolumes
:: Call this like: CALL _ListRemovableVolumes
SET USB_VOLUMES=
for /F "usebackq tokens=1,2,3,4 " %%i in (`wmic logicaldisk get caption^,description^,drivetype 2^>NUL`) do if %%l equ 2 call SET "USB_VOLUMES=%%USB_VOLUMES%%, %%i"
    :: echo %%i is a USB drive.
SET USB_VOLUMES=%USB_VOLUMES:~2%
ECHO %USB_VOLUMES%
EXIT /B 0
