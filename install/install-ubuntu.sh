#!/bin/bash

# Run this file as:
# - install-ubuntu.sh [TARGET_DEVICE] [BOOT_SIZE_GB=10]
# - install-ubuntu.sh /dev/sdd 15

# Dependency commands:
# - sudo
# - parted
# - read -p
# - umount
# - mkfs.ntfs
# - dd
# - mount
# - mountpoint
# - rsync

[ "$EUID" -eq 0 ] || {
  # echo "Runnig with 'sudo'"
  exec sudo "$0" "$@"
  exit $?
}

# to run COMMAND as a user within sudo: sudo -H -u $ORIGINAL_USER COMMAND
ROOT_DIR=$(readlink -f $(dirname "$0")/..)
cd $ROOT_DIR

ORIGINAL_USER=$(logname)
DEFAULT_MOUNTPOINT="/media/$ORIGINAL_USER/HBoot"

MBR_FILEPATH="$ROOT_DIR/install/grub_mbr"
DEFAULT_SIZE_BOOT_GB="18" # in GB (1MB = 1000KB , 1MiB = 1024KiB)

# # TODO
# function list_removable_disks() {
#   lsblk -d | cut -d ' ' -f 2
# }

function get_disk_size() {
  SIZE_TOTAL=$(parted -l $1 | grep "Disk $1: ")
  [ -z "$SIZE_TOTAL" ] && exit 1
  echo ${SIZE_TOTAL/#Disk $1: /}
}

function get_mountpoint() {
  MOUNTPOINT=$(grep "^$1 " /proc/mounts | cut -d ' ' -f 2)
  [ -z "$MOUNTPOINT" ] && (
    # keep looping as long as the iterated dir is a current mount point (a device is mounted to it)
    while mountpoint "${DEFAULT_MOUNTPOINT}${i}" >/dev/nul 2>&1; do i=$((i + 1)); done
    MOUNTPOINT=${DEFAULT_MOUNTPOINT}${i}
    [ ! -d $MOUNTPOINT ] && mkdir -p $MOUNTPOINT
    mount ${1} $MOUNTPOINT
    echo ${MOUNTPOINT}
  )
  echo ${MOUNTPOINT}
}

TARGET_DEV="${1:-$(read -e -i "/dev/sd" -p "Enter the target device (e.g: /dev/sdX) … (hint: check cmd \`df\`): " && echo $REPLY)}"
SIZE_BOOT="${2:-$(read -e -i $DEFAULT_SIZE_BOOT_GB -p "Enter the boot partition size in GB: " && echo $REPLY)}GB" # second arg in GB, or prompt with default=10GB
SIZE_TOTAL=$(get_disk_size $TARGET_DEV)
# CURRENT_DEV=$(df --output=source . | sed -n '2 p' | sed 's/.$//') # e.g: /dev/sdc

[ -z "$SIZE_TOTAL" ] && echo "Error: unrecognized device/size of $TARGET_DEV" && exit 1
[ ! -f "$MBR_FILEPATH" ] && echo "Error: MBR file not found: $MBR_FILEPATH" && exit 1
[ "9216" != "$(stat -c%s $MBR_FILEPATH)" ] && echo "Error: size of MBR file is not equal 9216 bytes" && exit 1
[ "/dev/sda" == "$TARGET_DEV" ] && echo "Error: target device must not be '/dev/sda'" && exit 1

echo
echo "WARNING: all data on the target device will be completely lost"
echo
echo "- Target device:   $TARGET_DEV"
echo "- Boot partition:  $SIZE_BOOT / $SIZE_TOTAL"
# echo "- MBR file: $MBR_FILEPATH"
echo

read -s -p "Press [Enter] to continue …" _

echo -e "\b\r\b\r                              " # to overwrite the "Please … line above"
echo "Starting …"
################ WIPE/ERASE the device, create new PartitionTable
# Unmount
echo "Unmounting …"
umount $TARGET_DEV? &>/dev/nul
# Partition: 1 NTFS
echo "Partitioning …"
parted --align optimal --script $TARGET_DEV \
  mklabel msdos \
  mkpart primary ntfs 0% $SIZE_BOOT \
  mkpart primary ntfs $SIZE_BOOT 100% \
  set 1 boot on >/dev/nul
# Format (quick)
echo "Formatting …"
mkfs.ntfs -QL "HBoot" ${TARGET_DEV}1 &>/dev/nul
mkfs.ntfs -QL "HData" ${TARGET_DEV}2 &>/dev/nul

################ Write (MBR … and more)
### Write 9KB to the first sectors (MBR + GRUB boot sectors)
### while maintaining the created PartitionTable
# 0 - 440 - 512 - 952 - 1024 - 9216
#  MBR   P_T   GRU   P_T    GRU     (Goal)
#  MBR   P_T   0000000000000000     (Initial)
echo "Writing MBR …"
dd of=$TARGET_DEV if=$MBR_FILEPATH seek=0 skip=0 bs=1 count=440 2>/dev/nul
dd of=$TARGET_DEV if=$MBR_FILEPATH seek=512 skip=512 bs=1 count=440 2>/dev/nul
dd of=$TARGET_DEV if=$MBR_FILEPATH seek=1024 skip=1024 bs=1 count=8192 2>/dev/nul
# Clone P_T for GRUB
dd if=$TARGET_DEV of=$TARGET_DEV skip=440 seek=952 bs=1 count=72 2>/dev/nul
# echo "MBR and GRUB was written to the disk successfully"

echo "Mounting …"
MOUNTPOINT=$(get_mountpoint ${TARGET_DEV}1)

echo "Copying files …"
rsync -aq "$ROOT_DIR/" "$MOUNTPOINT" --exclude ".git" # the "/" after $ROOT_DIR is crucial
# cp -r "$ROOT_DIR" "$TARGET_DEV"

# ################ Dev Reference Commands:
# ### BK FULL
# dd if=/dev/sdb of=./grub1_32gbFull.mbr skip=0 ibs=1 count=9216
# ### DUMP
# dd if=$TARGET_DEV of=./grub1Dump.mbr skip=0 ibs=1 count=9216
# ### ERASE the first 9216 bytes in device (the bytes where MBR, PT, GRUB will be located)
# dd of=$TARGET_DEV if=/dev/zero bs=1 count=9216
# ################
echo "Finished!"
