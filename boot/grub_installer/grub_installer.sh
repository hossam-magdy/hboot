#!/bin/bash

TARGET_DEV=$(df --output=source . | sed -n '2 p' | sed 's/.$//') # e.g: /dev/sdc
FULL_MBR="./grub_mbr"
LABEL="HNew"
# export TARGET_DEV=/dev/sdb
# export SIGNATURE_BK=./grub1Attempt6sig.mbr

[ "$TARGET_DEV" == "/dev/sda" ] && echo 'Exiting… should not run on device "/dev/sda"' && exit 1
echo "Target device: $TARGET_DEV … Press [Enter] to continue…"
read _

################ WIPE/ERASE the device, create new PartitionTable
# Completely erase first 10MB sectors
sudo dd of=$TARGET_DEV if=/dev/zero bs=1M count=10
# Unmount
sudo umount $TARGET_DEV?
# Partition: 1 NTFS
sudo parted --align optimal --script $TARGET_DEV \
  mklabel msdos \
  mkpart primary ntfs 0% 100% \
  set 1 boot on
# Format (quick)
sudo mkfs.ntfs -QFL $LABEL ${TARGET_DEV}1

################ Write (MBR… and more)
### Write 9KB to the first sectors (MBR + GRUB boot sectors)
### while maintaining the created PartitionTable
# 0 - 440 - 512 - 952 - 1024 - 9216
#  MBR   P_T   GRU   P_T    GRU     (Goal)
#  MBR   P_T   0000000000000000     (Initial)
sudo dd of=$TARGET_DEV if=$FULL_MBR seek=0    skip=0    bs=1 count=440
sudo dd of=$TARGET_DEV if=$FULL_MBR seek=512  skip=512  bs=1 count=440
sudo dd of=$TARGET_DEV if=$FULL_MBR seek=1024 skip=1024 bs=1 count=8192
# Clone P_T for GRUB
sudo dd if=$TARGET_DEV of=$TARGET_DEV skip=440 seek=952 bs=1 count=72

# ################
# #X BK FULL
# sudo dd if=/dev/sdb of=./grub1_32gbFull.mbr skip=0 ibs=1 count=9216
# ################
# #X DUMP
# sudo dd if=$TARGET_DEV of=./grub1Dump.mbr skip=0 ibs=1 count=9216
# ################ METHOD 2: bk P_T, overwrite all, restore P_T
# # EXTRACT SIGNATURE
# sudo dd if=$TARGET_DEV of=$SIGNATURE_BK skip=440 ibs=1 count=72
# # RESTORE FULL
# sudo dd of=$TARGET_DEV if=$FULL_MBR seek=0 ibs=1 count=9216
# # WRITE SIGNATURE
# sudo dd of=$TARGET_DEV if=$SIGNATURE_BK seek=440 obs=1 count=72
# sudo dd of=$TARGET_DEV if=$SIGNATURE_BK seek=952 obs=1 count=72
# ################
