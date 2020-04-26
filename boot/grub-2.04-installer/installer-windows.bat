@echo off
setLocal

:: Refs:
:: https://www.aioboot.com/en/install-grub2-from-windows/
:: http://ftp.gnu.org/gnu/grub/
:: https://www.systutorials.com/docs/linux/man/8-grub-install/

::###################### TARGET_VOLUME (current volume if it is removable, otherwise prompt user)
SET THIS_VOLUME=%~d0
FOR /F "tokens=* USEBACKQ" %%F IN (`CALL _ListRemovableVolumes.bat`) DO SET REMOVABLE_VOLUMES=%%F
ECHO %REMOVABLE_VOLUMES%| FINDSTR /C:"%THIS_VOLUME%">Nul && SET TARGET_VOLUME=%THIS_VOLUME%|| (
  ECHO %REMOVABLE_VOLUMES%
  SET /p TARGET_VOLUME="Choose target USB volume: "
)
SET TARGET_VOLUME=%TARGET_VOLUME:~0,1%:

::###################### TARGET_DRIVE (number after //./PHYSICALDRIVE{HERE} : 1,2,...)
FOR /F "tokens=* USEBACKQ" %%F IN (`CALL _VolumeLetterToDiskID.bat %TARGET_VOLUME%`) DO SET TARGET_DRIVE=%%F

::###################### INSTALL_CMD
SET BOOT_DIR=%TARGET_VOLUME%\boot
SET INSTALL_CMD=grub-install.exe --boot-directory=%BOOT_DIR% --target=i386-pc //./PHYSICALDRIVE%TARGET_DRIVE%
ECHO INSTALL_CMD=%INSTALL_CMD%
ECHO 'Confirm?'
PAUSE

CALL %INSTALL_CMD% && copy grub.cfg %BOOT_DIR%\grub
:: PAUSE
