#!/usr/bin/env bash

#tool=./boot/.tool_defragfs

#cp -v /mnt/Data/SystemUtilities/{win10_x64,ubuntu,win7_x64}.iso ./ && sudo filefrag ./*.iso
#dd if=/mnt/Data/SystemUtilities/win10_x64.iso of=win10_x64.iso
#dd if=/mnt/Data/SystemUtilities/win7_x64.iso of=win7_x64.iso
#dd if=/mnt/Data/SystemUtilities/ubuntu.iso of=ubuntu.iso

sudo filefrag ./*.iso

