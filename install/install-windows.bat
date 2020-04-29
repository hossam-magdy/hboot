@echo off

:: Run this file as:
:: - install-ubuntu.sh [TARGET_DEVICE] [BOOT_SIZE=10GB]
:: - install-ubuntu.sh /dev/sdd 15GB

::SETLOCAL (disabled to enable gloibal vars in calling :Section_CopyFiles)
SET _SCRIPT_DRIVE=%~d0
SET _SCRIPT_PATH=%~dp0
SET ROOT_DIR=%_SCRIPT_PATH%/..
CD %ROOT_DIR%

SET _BOOTICEEXETool=%ROOT_DIR%/tools/BOOTICE.exe

:: TARGET_DEV=${1:-$(read -e -i "/dev/sd" -p "Enter the target device (e.g: /dev/sdX) … (hint: check cmd \`df\`): " && echo $REPLY)}
:: DEFAULT_SIZE_BOOT="10GB"  # 1KB = 1000B , 1KiB = 1024B
:: SIZE_BOOT="${2:-$DEFAULT_SIZE_BOOT}" # second arg or 10GB

echo "Unmounting …"
echo "Partitioning …"
echo "Formatting …"
echo "Writing MBR …"
echo "Finished!"
