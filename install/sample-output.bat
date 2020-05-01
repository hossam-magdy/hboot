REM :: SAME VOLUME :: cd install && install-windows.bat
REM Removable volumes detected: E:, F:
REM Current volume:        F:
REM Target volume:         F:
REM Target disk:           Disk#1 - ~62GB
REM MBR-Writing Command:   "F:\tools\BOOTICE.exe" /DEVICE=F: /mbr /install /type=GRUB4DOS /v045 /quiet

REM ... will skip "Partitioning & Formatting", as current volume is the target
REM Confirm?
REM Press any key to continue . . .

REM Writing MBR ...
REM Activating current volume ...
REM Finished!






REM :: DIFFERENT VOLUME :: cd install && install-windows.bat
REM Removable volumes detected: E:, F:
REM Choose target USB volume: E
REM Current volume:        C:
REM Target volume:         E:
REM Target disk:           Disk#1 - ~62GB
REM Boot partition size:   17408MB (17GB)
REM Partitioning Command:  diskpart /s "C:\Users\hossa\AppData\Local\Temp\hboot_diskpart_script"
REM MBR-Writing Command:   "C:\Users\hossa\Desktop\hboot\tools\BOOTICE.exe" /DEVICE=E: /mbr /install /type=GRUB4DOS /v045 /quiet

REM Confirm?
REM Press any key to continue . . .

REM Partitioning & Formatting ...
REM Writing MBR ...
REM Finished!






REM :: DIFFERENT VOLUME :: cd install && install-windows.bat 1 25
REM Removable volumes detected: E:, F:
REM Current volume:        C:
REM Target disk:           Disk#1 - ~62GB
REM Boot partition size:   25600MB (25GB)
REM Partitioning Command:  diskpart /s "C:\Users\hossa\AppData\Local\Temp\hboot_diskpart_script"
REM MBR-Writing Command:   "C:\Users\hossa\Desktop\hboot\tools\BOOTICE.exe" /DEVICE=1 /mbr /install /type=GRUB4DOS /v045 /quiet

REM Confirm?
REM Press any key to continue . . .

REM Partitioning & Formatting ...
REM Writing MBR ...
REM Finished!
