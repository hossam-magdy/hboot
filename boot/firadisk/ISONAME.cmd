@echo off
:: SET MYISO=\boot\ISOs\win10_x64.iso

SET ENV_FILE=%~d0\boot\grub\grubenv
::::::::::::::::::::::::::::::::::::::::::::::::::::
:: "\boot\grub\grubenv" is expected to include line:
:: ISO_FILE=some/path/file.iso
::::::::::::::::::::::::::::::::::::::::::::::::::::

FOR /F "tokens=*" %%i in (%ENV_FILE%) DO CALL :ProcessLine %%i
:: SET MYISO=%ISO_FILE%
GOTO End

:ProcessLine
SET line=%*
IF "%line:~0,8%" == "ISO_FILE" CALL :VarFound %line%
GOTO :eof

:VarFound
SET %*
SET MYISO=%ISO_FILE:/=\%
::IF "%MYISO:~0,1%" == "/" SET MYISO=%MYISO:~1%
GOTO :eof

:End
::echo %MYISO%
::pause
