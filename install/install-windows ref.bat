@echo off

:: Run this file as:
:: - install-ubuntu.bat [TARGET_DEVICE] [BOOT_SIZE=10GB]
:: - install-ubuntu.bat /dev/sdd 15GB

::SETLOCAL (disabled to enable gloibal vars in calling :Section_CopyFiles)
SET _SCRIPT_DRIVE=%~d0
SET _SCRIPT_PATH=%~dp0
SET ROOT_DIR=%_SCRIPT_PATH%/..
CD %ROOT_DIR%
SET _BooticeEXETool="%ROOT_DIR%/tools/BOOTICE.exe"

::::::::: SIZE_BOOT_GB
SET SIZE_BOOT_GB=10
:::::::::

::::::::: TARGET_DISK_NUMBER
REM https://social.microsoft.com/Forums/en-US/5355b6d6-8a2a-4d24-a5b4-774557dca084/how-do-i-find-the-diskpart-diskpartition-numbers-by-drive-letter-in-batch-files?forum=Offtopic
REM get-partition -DriveLetter C | get-disk
SET TARGET_DISK_NUMBER=1
:::::::::

:: TARGET_DEV=${1:-$(read -e -i "/dev/sd" -p "Enter the target device (e.g: /dev/sdX) � (hint: check cmd \`df\`): " && echo $REPLY)}
:: DEFAULT_SIZE_BOOT="10GB"  # 1KB = 1000B , 1KiB = 1024B
:: SIZE_BOOT="${2:-$DEFAULT_SIZE_BOOT}" # second arg or 10GB

echo "Partitioning & Formatting ..."
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::: Partitioning Using Diskpart
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
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
:: CLEAN [ALL] :: ::oves any and all partition or volume formatting from the disk with focus
:: CREATE PARTITION PRIMARY [SIZE=<N>] [OFFSET=<N>] [ID={<BYTE> | <GUID>}] [ALIGN=<N>] [NOERR]
:: ACTIVE: On MBR disk, marks the partition with focus as active
:: FORMAT [[FS=<FS>] [REVISION=<X.XX>] | RECOMMENDED] [LABEL=<"label">] [UNIT=<N>] [QUICK] [COMPRESS] [OVERRIDE] [DUPLICATE] [NOWAIT] [NOERR]
diskpart /s %diskpart_script%
::::::::::::::::::::::::::::::::::::: 

echo "Writing MBR ..."
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::: BOOTICE
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
CALL "%_BooticeEXETool%" /DEVICE=%_SCRIPT_DRIVE% /mbr /install /type=GRUB4DOS /v045 [/boot_file=grldr]
:: CALL "%_BooticeEXETool%" /DEVICE=%_SCRIPT_DRIVE% /partitions /repartition /usb-hdd /fstype==ntfs /vollabel=HBoot /startlba=nnn /quiet
:: CALL "%_BooticeEXETool%" /DEVICE=%_SCRIPT_DRIVE% /partitions /firstpart=1
:: ===========================================
:: Usage:
:: BOOTICE [DEVICE] [/mbr, /pbr, /sectors, /partitions] [parameters]

:: @ DEVICE
:: ===========================================
:: /DEVICE=[m:n | m | X:]
::   m:n >> partition n of disk m. (m: 0,1,2...; n: Grub4Dos style, 0,1,2...)
::   X:  >> specify the disk and partition by its drive letter.
::   When n is specified, n=0.

:: @ MBR operation
:: ===========================================
:: BOOTICE [DEVICE] /mbr [/install /backup /restore] [parameters]

:: /install >> Install some kind of MBR, requires /type parameter.
::     /type=[wee, GRUB4DOS, grub2, 1jf9z, 1jf9k, plop, usbhdd+, usbzip+, nt52, nt60]
::     If /type= is missed, the program will stop at the MBR screen.
::     /menu=xxx.lst >> Load menu file for WEE.
:: /backup >> Backup MBR to a file. Requires /file= parameter.
::     /file=xxx:  File name. Could be a rel. path or full path name.
::     /sectors=n: Sectors to backup.
:: /restore >> Restore MBR from a file. Requires /file= parameter.
::     /file=xxx: File name. Could be a rel. path or full path name.
::     /keep_dpt: Keep disk signature and partition table untouched.
:: /boot_file=xxx >> Specify the boot file of GRUB4DOS boot record.

:: @ PBR Operation
:: ===========================================
:: BOOTICE [DEVICE] /pbr [/install /backup /restore] [parameters]

:: /install >> Install some kind of PBR, requires /type parameter.
::     /type=[msdos | GRUB4DOS | ntldr | bootmgr | syslinux]
::     If /type= is missed, the program will stop at the PBR screen.
:: /backup >> Backup PBR to a file. Requires /file= parameter.
::     /file=xxx  >> File name. Could be a rel. path or full path name.
::     /sectors=n >> Specify the sectors number to be backupped.
:: /restore >> Restore PBR from a file. Requires /file= parameter.
::     /file=xxx >> File name. Could be a rel. path or full path name.
::     /keep_bpb: Keep BPB(Bios Parameter Block) untouched.
:: /boot_file=xxx >> Specify the boot file of GRUB4DOS, NTLDR or BOOTMGR boot record.
:: /v4            >> Install SYSLINUX v4.07 (default: v5.10).


:: @ Sectors backup & restore
:: ===========================================
:: BOOTICE [DEVICE] /sectors [/backup /restore] [parameters]

:: /backup  >> Backup sectors to a file.
:: /restore >> Restore sectors from a file.
:: /lba=n   >> Specify the start sector LBA.
:: /sectors=n >> Sectors to backup or restore.
:: /file=xxx >> File name. Could be a rel. path or full path name.
:: /keep_dpt >> Keep disk signature and partition table untouched.
:: /keep_bpb >> Keep BPB untouched.

:: @ Partitioning & Format
:: ===========================================
:: BOOTICE [DEVICE] /partitions [operation]

:: /backup_dpt=xxx  >> Backup the partition table to file xxx.
:: /restore_dpt=xxx >> Restore the partition table from file xxx.
:: /hide      >> Hide a partition.
:: /unhide    >> UnHide a partition.
:: /eisahide  >> Hide a partition by setting its ID to 0x12.
:: /set_id=XX >> Modify the ID of a partition
:: /activate  >> Activate a partition.
:: /firstpart=n     >> Set as the 1st entry in the MBR DPT, n=1,2,3.
::     When n=0, resorts partition entries by start LBA.
:: /assign_letter   >> Assign a drive letter for the partition.
:: /assign_letter=X >> Assign a specified letter X for the partition.
:: /delete_letter   >> Delete the partition's drive letter.
:: /repartition     >> RePartition and Format an USB disk.
::   [/usb-fdd, /usb-zip, /usb-hdd] [/vollabel=xxx] [/fstype=xxx].
::   [/vollabel=xxx]: specify new volume label, 11 chars max.
::   [/fstype=]: /fstype=[fat16 | fat32 | ntfs | exfat].
::   [/startlba=nnn]: specify the LBA of the partition.

:: @ Special parameters
:: ===========================================
:: 1. /quiet
:: With /quiet parameter, BOOTICE will automatically start the
:: installation rather than stopping and waiting for the user's
:: operation (except when formatting a disk).

:: 2. /nodriveletters
:: If /nodriveletters exists, BOOTICE will not detect any drive letters.

:: 3. /diskinfo
:: This parameter acts as RMPARTUSB.EXE, and requires /file=xxx.cmd.
:: /diskinfo /list: list disks;
:: /diskinfo /find: report disk number and drive letter of the 1st drive;
:: /diskinfo /getdrv /drive=n: report drive letter+size+description;
:: If /usbonly is specified, list USB disks only, otherwise, all disks.

:: 4. /edit_bcd
:: Used to edit BCD file of MS Windows Vista or later.
::   /easymode: Use easy mode. If missed, use professional mode.
::   /file=xxx: Specify the BCD file to edit. If missed, edit the system BCD.

:: 5. /edit_g4dmenu
:: Used to edit GRUB4DOS menu file (grldr or menu.lst).
::   /file=xxx: Specify the file to edit.

:: 6. Parameters for GRUB4DOS
:: Because of widely using of GRUB4DOS, BOOTICE supports these
:: special parameters for GRUB4DOS:
:: /v045: Install GRUB4DOS v0.4.5
:: /v046: Install GRUB4DOS v0.4.6
:: /mbr-bpb: Copy the BPB of the leading FAT partition to MBR
:: /mbr-disable-floppy: don't search floppy for grldr
:: /mbr-disable-osbr: don't boot from old MBR with an invalid partition table
:: /duce: disable the unconditional console entrance
:: /chs-no-tune: disable geometry tune
:: /boot-prevmbr-first: boot previous MBR first
:: /preferred-drive=m: preferred boot drive number
:: /preferred-partition=n: preferred partition number
:: /hot-key=SSAA: hot-key, four hex numbers.
::     SS=scan code, AA=ASCII. e.g.: 3920 = Space key
:: /time-out=n: count down
:: /boot_file=xxx: rename the boot file (default value is grldr)


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
echo "Finished!"




::::::::::::::::::::::::::::::::::::
:_VolumeLetterToDiskID
:: Call this file like: _VolumeLetterToDiskID.bat E

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
