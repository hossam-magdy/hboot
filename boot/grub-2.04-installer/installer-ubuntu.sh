#!/bin/sh

# Ref: http://manpages.ubuntu.com/manpages/focal/man8/grub-install.8.html

PLATFORM="i386-pc"
BASEDIR=$(dirname $(realpath "$0"))
DEVICE=$(df --output=source . | sed -n '2 p' | sed 's/.$//') # e.g: /dev/sdc
BOOT_DIR=$(df --output=target . | sed -n '2 p')/boot         # e.g: /mount/MyUsb/boot

INSTALL_CMD="grub-install --boot-directory=$BOOT_DIR --directory=$BASEDIR/$PLATFORM $DEVICE"
echo INSTALL_CMD=$INSTALL_CMD
echo "Press [Enter] key to continue...";
read _

sh -c "$INSTALL_CMD" && cp "$BASEDIR/grub.cfg" "$BOOT_DIR/grub"

