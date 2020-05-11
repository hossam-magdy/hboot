@ECHO OFF

:: Run this file as:
:: - install.bat [TARGET_DEVICE] [SIZE_BOOT_GIB=10]
:: - install.bat E: 17
:: - install.bat 1 17

::SETLOCAL (disabled to enable gloibal vars in calling :Section_CopyFiles)
SET _SCRIPT_DRIVE=%~d0
SET _SCRIPT_DIR=%~dp0
SET ROOT_DIR=%_SCRIPT_DIR%\..
CD %ROOT_DIR%
SET ROOT_DIR=%CD%
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
ECHO ... running from volume^:  %CURRENT_VOLUME%

CALL :_ListRemovableDisks
SET REMOVABLE_DISKS=%RESULT%
CALL :_ListRemovableVolumeLetter
SET REMOVABLE_VOLUMELETTERS=%RESULT%
ECHO Removable disks and volumes detected^:            %REMOVABLE_DISKS%, %REMOVABLE_VOLUMELETTERS%
:CheckTargetVolume
IF "%TARGET_VOLUME%" == "" (
    ECHO %REMOVABLE_VOLUMELETTERS%| FIND "%CURRENT_VOLUME%">Nul && (
       SET TARGET_VOLUME=%CURRENT_VOLUME%
    ) || (
       SET /p TARGET_VOLUME="Enter the target disk# or volume (e.g: 1 or E:): "
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
IF NOT EXIST %TARGET_VOLUME%\ ( ECHO ERROR^: volume %TARGET_VOLUME% does not exist, try to pass the disk number instead && PAUSE && EXIT /B 1 )
CALL :_VolumeLetterToDiskID %TARGET_VOLUME%
SET TARGET_DISK_INDEX=%RESULT%
:TargetDiskNumberIsSet
::::::::: TARGET_DISK_INDEX (number after //./PHYSICALDRIVE{HERE} : 1,2,...)
IF %TARGET_DISK_INDEX% == 0 ( ECHO ERROR^: should not run on device 0 && PAUSE && EXIT /B 1 )
CALL :_GetDiskSizeInGB %TARGET_DISK_INDEX%
SET TARGET_DISK_SIZE_GB=%RESULT%
IF "%TARGET_DISK_SIZE_GB%" == "" ( ECHO ERROR^: unknown size of device %TARGET_DISK_INDEX% && PAUSE && EXIT /B 1 )

::###################### SIZE_BOOT_GIB (in GiB)
SET DEFAULT_SIZE_BOOT_GIB=17
SET MINIMUM_SIZE_BOOT_GIB=2
:: TODO: Take it from input, or fallback to DEFAULT_SIZE_BOOT
SET SIZE_BOOT_GIB=%2
IF NOT "%TARGET_VOLUME%" == "%CURRENT_VOLUME%" (
    IF "%SIZE_BOOT_GIB%" == "" SET /p SIZE_BOOT_GIB="Enter the boot partition size in GiB [default = %DEFAULT_SIZE_BOOT_GIB%]: "
)
IF "%SIZE_BOOT_GIB%" == "" SET SIZE_BOOT_GIB=%DEFAULT_SIZE_BOOT_GIB%
SET /a SIZE_BOOT_GIB=%SIZE_BOOT_GIB% * 1
IF %SIZE_BOOT_GIB% EQU 0 ( ECHO ERROR^: invalid value of SIZE_BOOT_GIB && PAUSE && EXIT /B 1 )
IF %SIZE_BOOT_GIB% LSS %MINIMUM_SIZE_BOOT_GIB% ( ECHO ERROR^: value of SIZE_BOOT_GIB must be at least 2 GB && PAUSE && EXIT /B 1 )
IF %SIZE_BOOT_GIB% GTR %TARGET_DISK_SIZE_GB% ( ECHO ERROR^: value of SIZE_BOOT_GIB must not exceed %TARGET_DISK_SIZE_GB% GB && PAUSE && EXIT /B 1 )
SET /a SIZE_BOOT_MIB=%SIZE_BOOT_GIB% * 1024
:::::::::
::###################### CMD_PARTITION

:::::::::::::::::::::::::::::::: Partitioning Using Diskpart
:: https://www.diskpart.com/de/help/cmd.html
:: https://commandwindows.com/diskpart.htm
:: https://www.tech-recipes.com/rx/9910/how-to-automate-windows-diskpart-commands-in-a-script/
SET DISKPART_SCRIPT=%TEMP%\hboot_diskpart_script
SET DISKPART_OUTPUT=%TEMP%\hboot_diskpart_output

ECHO SELECT DISK %TARGET_DISK_INDEX% >"%DISKPART_SCRIPT%"
ECHO DETAIL DISK >>"%DISKPART_SCRIPT%"
:: ECHO AUTOMOUNT DISABLE >>"%DISKPART_SCRIPT%"
IF "%TARGET_VOLUME:~1,1%" == ":" (
ECHO SELECT VOLUME %TARGET_VOLUME:~0,1% >>"%DISKPART_SCRIPT%"
ECHO REMOVE >>"%DISKPART_SCRIPT%"
)
ECHO CLEAN >>"%DISKPART_SCRIPT%"
ECHO RESCAN >>"%DISKPART_SCRIPT%"
ECHO.>>"%DISKPART_SCRIPT%"
ECHO CREATE PARTITION PRIMARY SIZE=%SIZE_BOOT_MIB% >>"%DISKPART_SCRIPT%"
ECHO FORMAT FS=NTFS LABEL=HBoot QUICK >>"%DISKPART_SCRIPT%"
ECHO ACTIVE >>"%DISKPART_SCRIPT%"
ECHO ASSIGN >>"%DISKPART_SCRIPT%"
ECHO DETAIL DISK >>"%DISKPART_SCRIPT%"
ECHO.>>"%DISKPART_SCRIPT%"
ECHO CREATE PARTITION PRIMARY >>"%DISKPART_SCRIPT%"
ECHO FORMAT FS=NTFS LABEL=HData QUICK >>"%DISKPART_SCRIPT%"
ECHO ASSIGN >>"%DISKPART_SCRIPT%"
ECHO DETAIL DISK >>"%DISKPART_SCRIPT%"
ECHO RESCAN >>"%DISKPART_SCRIPT%"
:: ECHO EXIT >>"%DISKPART_SCRIPT%"
:: ECHO AUTOMOUNT ENABLE >>"%DISKPART_SCRIPT%"

SET CMD_PARTITION=diskpart /s "%DISKPART_SCRIPT%" >"%DISKPART_OUTPUT%"
::::::::::::::::::::::::::::::::::::: 

::###################### CMD_WRITE_MBR
:::::::::::::::::::::::::::::::: BOOTICE [/boot_file=grldr]
SET CMD_WRITE_MBR1="%_BooticeEXETool%" /DEVICE=%TARGET_DISK_INDEX% /mbr /install /type=GRUB4DOS /v045 /quiet
SET CMD_WRITE_MBR2="%_BooticeEXETool%" /DEVICE=%TARGET_DISK_INDEX%^:0 /partitions /activate /quiet
::::::::::::::::::::::::::::::::


::#######################################################################
::####################################################################### LOGGING AND CONFIRMATION
::####################################################################### ( "^" for skipping ":", ">", "(" and ")" )
ECHO.
IF "%TARGET_VOLUME%" == "%CURRENT_VOLUME%" (
ECHO WARNING: all data on the target device will be completely lost
ECHO.
)
IF "%TARGET_VOLUME:~1,1%" == ":" (
ECHO - Target device^:   Disk#%TARGET_DISK_INDEX% ^(~%TARGET_DISK_SIZE_GB%GB^) [%TARGET_VOLUME%]
) ELSE (
ECHO - Target device^:   Disk#%TARGET_DISK_INDEX% ^(~%TARGET_DISK_SIZE_GB%GB^)
)
IF NOT "%TARGET_VOLUME%" == "%CURRENT_VOLUME%" (
ECHO - Boot partition:  %SIZE_BOOT_MIB%MiB ^(%SIZE_BOOT_GIB%GiB^) / ~%TARGET_DISK_SIZE_GB%GB
)
ECHO.
IF NOT "%TARGET_VOLUME%" == "%CURRENT_VOLUME%" (
ECHO ... Partitioning Command^:       %CMD_PARTITION%
) ELSE (
ECHO ... will skip "Partitioning & Formatting", because the target volume is the current one
)
ECHO ... MBR-Writing Command^:        %CMD_WRITE_MBR1%

:: ECHO Target disk^:           Disk#%TARGET_DISK_INDEX% - ~%TARGET_DISK_SIZE_GB%GB
IF "%TARGET_VOLUME%" == "%CURRENT_VOLUME%" (
ECHO ... Boot activation Command^:    %CMD_WRITE_MBR2%
)

ECHO.
ECHO Confirm?
PAUSE
ECHO.

::#######################################################################
::####################################################################### EXECUTION
::#######################################################################
ECHO Starting ...
IF NOT "%TARGET_VOLUME%" == "%CURRENT_VOLUME%" (
    ECHO Partitioning ^& Formatting ...
    CALL %CMD_PARTITION%
    IF %ERRORLEVEL% == 0 ( DEL %DISKPART_OUTPUT%>Nul 2>&1 ) ELSE ECHO.... partitioning errorlevel ^= %ERRORLEVEL%
)
DEL %DISKPART_SCRIPT%>Nul 2>&1

:: Get HBoot volume letter
CALL :_GetHBootVolumeLetter
SET HBOOT_VOLUME=%RESULT%
IF %HBOOT_VOLUME% == "" ( ECHO ERROR^: can not find HBoot volume && PAUSE && EXIT /B 1 )

ECHO Writing MBR ...
CALL %CMD_WRITE_MBR1%
IF NOT %ERRORLEVEL% == 0 ( ECHO ERROR^: writing MBR was not successful ^(%ERRORLEVEL%^) && PAUSE && EXIT /B %ERRORLEVEL% )
IF "%TARGET_VOLUME%" == "%CURRENT_VOLUME%" (
    ECHO Activating current volume ...
    CALL %CMD_WRITE_MBR2%
)
IF NOT %ERRORLEVEL% == 0 ( ECHO ERROR^: activating boot partition was not successful ^(%ERRORLEVEL%^) && PAUSE && EXIT /B %ERRORLEVEL% )

REM Prepare "hboot_xcopy_exclude" file and its short path in var XCOPY_EXCLUDE
SET XCOPY_EXCLUDE=%TEMP%\hboot_xcopy_exclude
ECHO %ROOT_DIR%\^.git>"%XCOPY_EXCLUDE%"
ECHO ^.iso>>"%XCOPY_EXCLUDE%"
CALL :_ToShortPath "%XCOPY_EXCLUDE%"
SET XCOPY_EXCLUDE=%RESULT%
IF NOT "%HBOOT_VOLUME%" == "%CURRENT_VOLUME%" (
    ECHO Copying files ...
    REM :: XCOPY
    XCOPY /H /S /V /Y /I /Q /EXCLUDE:%XCOPY_EXCLUDE% "%ROOT_DIR%" "%HBOOT_VOLUME%">Nul 2>&1
)
DEL %XCOPY_EXCLUDE%>Nul 2>&1

ECHO Finished!
PAUSE
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

::###################### _GetDiskSize
:_ToShortPath
SET RESULT=%~s1
EXIT /B 0

::###################### _GetHBootVolumeLetter
:_GetHBootVolumeLetter
SET RESULT=
FOR /F "usebackq tokens=1,2,3 " %%i in (`wmic logicaldisk where "VolumeName='HBoot'" get DeviceID^,VolumeName 2^>NUL`) DO IF "%%j" == "HBoot" CALL SET "RESULT=%%i"
IF "%RESULT%" == "" EXIT /B 1
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

::###################### _ListRemovableDisks => 1 (~62GB), 2 (~32GB)
:_ListRemovableDisks
SET RESULT=
FOR /F "usebackq tokens=1,2,3,4 " %%i in (`wmic diskdrive where "MediaType='Removable Media'" get index^,partitions^,serialnumber^,size 2^>NUL`) DO (
    IF "%%i" NEQ "Index" IF "%%l" GEQ "0" (
        CALL SET "SIZE=%%l"
        CALL SET "RESULT=%%RESULT%%, %%i ^^(~%%SIZE:~0,-9%%GB^^)"
    )
)
    :: ECHO %%i is a USB drive.
IF NOT "%RESULT%" == "" SET RESULT=%RESULT:~2%
EXIT /B 0

::###################### _ListRemovableVolumeLetter
:_ListRemovableVolumeLetter
:: Call this like: CALL _ListRemovableVolumeLetter
SET RESULT=
FOR /F "usebackq tokens=1,2,3,4 " %%i in (`wmic logicaldisk get caption^,drivetype^,size 2^>NUL`) DO (
    IF %%j EQU 2 (
        CALL SET "SIZE=%%k"
        CALL SET "RESULT=%%RESULT%%, %%i ^^(~%%SIZE:~0,-9%%GB^^)"
    )
)
    :: ECHO %%i is a USB drive.
IF NOT "%RESULT%" == "" SET RESULT=%RESULT:~2%
EXIT /B 0

:EOF
