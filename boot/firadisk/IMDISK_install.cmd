pushd "%~dp0"
net stop imdsksvc 2> nul
net stop awealloc 2> nul
net stop imdisk 2> nul

rundll32 setupapi.dll,InstallHinfSection DefaultInstall 132 .\imdisk.inf

if errorlevel 1 (
  echo ImDisk Setup failed. Please try to reboot the computer and then try to run the setup package again." 16 "ImDisk Virtual Disk Driver setup"
  goto :eof
)

net start imdsksvc > nul
net start imdisk > nul
echo ImDisk Setup finished successfully.
popd
