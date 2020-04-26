@echo off
setLocal
:: Call this file like: _ListRemovableVolumes.bat

SET USB_VOLUMES=
for /F "usebackq tokens=1,2,3,4 " %%i in (`wmic logicaldisk get caption^,description^,drivetype 2^>NUL`) do if %%l equ 2 call SET "USB_VOLUMES=%%USB_VOLUMES%%, %%i"
    :: echo %%i is a USB drive.

SET USB_VOLUMES=%USB_VOLUMES:~2%
ECHO %USB_VOLUMES%
