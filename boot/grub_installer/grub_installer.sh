#!/bin/bash
################
#X BK FULL
sudo dd if=/dev/sdb of=./grub1_32gbFull.mbr skip=0 ibs=1 count=9216
################

export TARGET_DEV=/dev/sdb
export SIGNATURE_BK=./grub1Attempt6sig.mbr
export FULL_MBR=./grub1_32gb.mbr

################

# ERASE
sudo dd of=$TARGET_DEV if=/dev/zero bs=1M count=10

sudo fdisk $TARGET_DEV
# o n a t7 w
sudo mkfs.ntfs -QFL HNew ${TARGET_DEV}1

#X DUMP
sudo dd if=$TARGET_DEV of=./grub1Dump.mbr skip=0 ibs=1 count=9216

################ METHOD 1: don't overwrite P_T
# 0 - 440 - 512 - 952 - 1024 - 9216
#  MBR   P_T   GRU   P_T    GRU     (Goal)
#  MBR   P_T   0000000000000000     (Initial)
sudo dd of=$TARGET_DEV if=$FULL_MBR seek=0    skip=0    bs=1 count=440
sudo dd of=$TARGET_DEV if=$FULL_MBR seek=512  skip=512  bs=1 count=440
sudo dd of=$TARGET_DEV if=$FULL_MBR seek=1024 skip=1024 bs=1 count=8192
# Clone P_T for GRUB
sudo dd if=$TARGET_DEV of=$TARGET_DEV skip=440 seek=952 bs=1 count=72

################ METHOD 2: bk P_T, overwrite all, restore P_T
# EXTRACT SIGNATURE
sudo dd if=$TARGET_DEV of=$SIGNATURE_BK skip=440 ibs=1 count=72
# RESTORE FULL
sudo dd of=$TARGET_DEV if=$FULL_MBR seek=0 ibs=1 count=9216
# WRITE SIGNATURE
sudo dd of=$TARGET_DEV if=$SIGNATURE_BK seek=440 obs=1 count=72
sudo dd of=$TARGET_DEV if=$SIGNATURE_BK seek=952 obs=1 count=72

################
