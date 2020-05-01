@ECHO OFF

:: Run this file as:
:: - install-windows.bat [TARGET_DEVICE] [BOOT_SIZE=10GB]
:: - install-windows.bat E: 17GB
:: - install-windows.bat 1 17GB

::SETLOCAL (disabled to enable gloibal vars in calling :Section_CopyFiles)
SET _SCRIPT_DRIVE=%~d0
SET _SCRIPT_DIR=%~dp0
SET ROOT_DIR=%_SCRIPT_DIR%..
CD %ROOT_DIR%
SET _BooticeEXETool=%ROOT_DIR%\tools\BOOTICE.exe
:: Normalize path, see: https://stackoverflow.com/a/6591601
FOR /F "delims=" %%F IN ("%_BooticeEXETool%") DO SET "_BooticeEXETool=%%~fF"

::###################### TARGET_DISK_INDEX
::::::::: TARGET_VOLUME priorities of setting:
:: 1st arg if passed
:: OR current volume if it is removable
:: OR prompt user
SET TARGET_VOLUME=%1

SET CURRENT_VOLUME=%_SCRIPT_DRIVE%

CALL :_ListRemovableVolumeLetter
SET REMOVABLE_VOLUMELETTERS=%RESULT%
ECHO Removable volumes detected^: %REMOVABLE_VOLUMELETTERS%
:CheckTargetVolume
IF "%TARGET_VOLUME%" == "" (
    ECHO %REMOVABLE_VOLUMELETTERS%| FIND "%CURRENT_VOLUME%">Nul && (
       SET TARGET_VOLUME=%CURRENT_VOLUME%
    ) || (
       SET /p TARGET_VOLUME="Choose target USB volume: "
       GOTO :CheckTargetVolume
    )
) ELSE (
    IF 1%TARGET_VOLUME% EQU +1%TARGET_VOLUME% (
       :: %TARGET_VOLUME% is numeric and positive
       SET TARGET_DISK_INDEX=%TARGET_VOLUME%
       GOTO :TargetDiskNumberIsSet
    )
)

SET TARGET_VOLUME=%TARGET_VOLUME:~0,1%:
IF NOT EXIST %TARGET_VOLUME%\ ( ECHO ERROR^: volume %TARGET_VOLUME% does not exist, try to pass the disk number instead && EXIT /B 1 )
CALL :_VolumeLetterToDiskID %TARGET_VOLUME%
SET TARGET_DISK_INDEX=%RESULT%
:TargetDiskNumberIsSet
::::::::: TARGET_DISK_INDEX (number after //./PHYSICALDRIVE{HERE} : 1,2,...)
IF %TARGET_DISK_INDEX% == 0 ( ECHO ERROR^: should not run on device 0 && EXIT /B 1 )
CALL :_GetDiskSizeInGB %TARGET_DISK_INDEX%
SET TARGET_DISK_SIZE_GB=%RESULT%
IF "%TARGET_DISK_SIZE_GB%" == "" ( ECHO ERROR^: unknown size of device %TARGET_DISK_INDEX% && EXIT /B 1 )

::###################### SIZE_BOOT_GB
SET DEFAULT_SIZE_BOOT_GB=62
SET MINIMUM_SIZE_BOOT_GB=2
:: TODO: Take it from input, or fallback to DEFAULT_SIZE_BOOT
SET SIZE_BOOT_GB=%2
IF "%SIZE_BOOT_GB%" == "" SET SIZE_BOOT_GB=%DEFAULT_SIZE_BOOT_GB%
SET /a SIZE_BOOT_GB=%SIZE_BOOT_GB% * 1
IF %SIZE_BOOT_GB% EQU 0 ( ECHO ERROR^: invalid value of SIZE_BOOT_GB && EXIT /B 1 )
IF %SIZE_BOOT_GB% LSS %MINIMUM_SIZE_BOOT_GB% ( ECHO ERROR^: value of SIZE_BOOT_GB must be at least 2 GB && EXIT /B 1 )
IF %SIZE_BOOT_GB% GTR %TARGET_DISK_SIZE_GB% ( ECHO ERROR^: value of SIZE_BOOT_GB must not exceed %TARGET_DISK_SIZE_GB% GB && EXIT /B 1 )
SET /a SIZE_BOOT_MB=%SIZE_BOOT_GB% * 1024
:::::::::

::###################### CMD_PARTITION

:::::::::::::::::::::::::::::::: Partitioning Using Diskpart
:: https://www.diskpart.com/de/help/cmd.html
:: https://commandwindows.com/diskpart.htm
:: https://www.tech-recipes.com/rx/9910/how-to-automate-windows-diskpart-commands-in-a-script/
SET DISKPART_SCRIPT=%TEMP%\hboot_diskpart_script

ECHO.>%DISKPART_SCRIPT%
ECHO SELECT DISK %TARGET_DISK_INDEX% >>%DISKPART_SCRIPT%
ECHO CLEAN >>%DISKPART_SCRIPT%
ECHO.>>%DISKPART_SCRIPT%
ECHO CREATE PARTITION PRIMARY SIZE=%SIZE_BOOT_MB% NOERR >>%DISKPART_SCRIPT%
ECHO ACTIVE >>%DISKPART_SCRIPT%
ECHO FORMAT FS=NTFS LABEL=HBoot QUICK OVERRIDE NOERR >>%DISKPART_SCRIPT%
ECHO ASSIGN NOERR >>%DISKPART_SCRIPT%
ECHO.>>%DISKPART_SCRIPT%
ECHO CREATE PARTITION PRIMARY NOERR >>%DISKPART_SCRIPT%
ECHO FORMAT FS=NTFS LABEL=HData QUICK OVERRIDE NOERR >>%DISKPART_SCRIPT%
ECHO ASSIGN NOERR >>%DISKPART_SCRIPT%

SET CMD_PARTITION=diskpart /s "%DISKPART_SCRIPT%"
::::::::::::::::::::::::::::::::::::: 

::###################### CMD_WRITE_MBR
:::::::::::::::::::::::::::::::: BOOTICE [/boot_file=grldr]
SET CMD_WRITE_MBR1="%_BooticeEXETool%" /DEVICE=%TARGET_VOLUME% /mbr /install /type=GRUB4DOS /v045 /quiet
SET CMD_WRITE_MBR2="%_BooticeEXETool%" /DEVICE=%TARGET_VOLUME% /partitions /activate /quiet
::::::::::::::::::::::::::::::::


::#######################################################################
::####################################################################### LOGGING AND CONFIRMATION
::####################################################################### ( "^" for skipping ":", ">", "(" and ")" )
ECHO Current volume^:        %CURRENT_VOLUME%
IF "%TARGET_VOLUME:~1,1%" == ":" (
ECHO Target volume^:         %TARGET_VOLUME%
)
ECHO Target disk^:           Disk#%TARGET_DISK_INDEX% - ~%TARGET_DISK_SIZE_GB%GB
IF NOT "%TARGET_VOLUME%" == "%CURRENT_VOLUME%" (
ECHO Boot partition size^:   %SIZE_BOOT_MB%MB ^(%SIZE_BOOT_GB%GB^)
ECHO Partitioning Command^:  %CMD_PARTITION%
)
ECHO MBR-Writing Command^:   %CMD_WRITE_MBR1%
ECHO.
IF "%TARGET_VOLUME%" == "%CURRENT_VOLUME%" ECHO ... will skip "Partitioning & Formatting", as current volume is the target

ECHO Confirm?
PAUSE
ECHO.

::#######################################################################
::####################################################################### EXECUTION
::#######################################################################
IF NOT "%TARGET_VOLUME%" == "%CURRENT_VOLUME%" (
    ECHO Partitioning ^& Formatting ...
    CALL %CMD_PARTITION%
    IF NOT %ERRORLEVEL% == 0 ( ECHO ERROR^: partitioning was not successful && EXIT /B %ERRORLEVEL% )
)
DEL %DISKPART_SCRIPT%>Nul 2>&1
:: ELSE ECHO Skipping "Partitioning & Formatting ..."
ECHO Writing MBR ...
CALL %CMD_WRITE_MBR1%
IF "%TARGET_VOLUME%" == "%CURRENT_VOLUME%" (
    ECHO Activating current volume ...
    CALL %CMD_WRITE_MBR2%
)
IF NOT %ERRORLEVEL% == 0 ( ECHO ERROR^: writing MBR was not successful && EXIT /B %ERRORLEVEL% )
COPY /V /Y menu.lst %TARGET_VOLUME%\menu.lst>Nul 2>&1
ECHO Finished!
GOTO :EOF

::#######################################################################
::####################################################################### HELPERS
::#######################################################################


::###################### _GetDiskSize
:_GetDiskSizeInGB
SET RESULT=
FOR /F "usebackq tokens=1,2,3,4 " %%i in (`wmic diskdrive where "MediaType='Removable Media'" get index^,partitions^,serialnumber^,size 2^>NUL`) DO IF "%%i" == "%~1" CALL SET "RESULT=%%l"
    :: ECHO %%i is a USB drive.
IF NOT "%RESULT%" == "" SET RESULT=%RESULT:~0,-9%
EXIT /B 0

::###################### _VolumeLetterToDiskID
:_VolumeLetterToDiskID
:: Call this like: CALL _VolumeLetterToDiskID E
SET RESULT=
SET VOLUME=%~1
SET VOLUME=%VOLUME:~0,1%

:: The next lines call `wmic` and invokes ":ProcessFoundLine" with the o/p line THAT CONTAINS "Disk#"
SET CMD=wmic logicaldisk where 'DeviceID LIKE '%VOLUME%%%'' Assoc /AssocClass:Win32_LogicalDiskToPartition 2>NUL
FOR /F "tokens=* USEBACKQ" %%I IN (`%CMD%`) DO ECHO %%~I| FIND "Disk #">Nul && CALL :ProcessFoundLine "%%~I"
EXIT /B 1

:: This "batch function" takes string containing "AnyStr1 Disk#5, AnyStr2" and returns "5" (without quoutes)
:ProcessFoundLine
SET RESULT=%*
::              "5, AnyStr2"
SET RESULT=%RESULT:*Disk #=%
::              "5"
FOR /f "tokens=1 delims=," %%i in ("%RESULT%") DO SET RESULT=%%i
EXIT /B 0

::###################### _ListRemovableVolumeLetter
:_ListRemovableVolumeLetter
:: Call this like: CALL _ListRemovableVolumeLetter
SET RESULT=
FOR /F "usebackq tokens=1,2,3,4 " %%i in (`wmic logicaldisk get caption^,description^,drivetype 2^>NUL`) DO IF %%l EQU 2 CALL SET "RESULT=%%RESULT%%, %%i"
    :: ECHO %%i is a USB drive.
SET RESULT=%RESULT:~2%
EXIT /B 0

:EOF
