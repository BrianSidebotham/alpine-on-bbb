#!/bin/sh

BASE=$(dirname $(readlink -f $0))

UBOOT_VERSION=2016.03
UBOOT_BUILD_DIR=${BASE}/u-boot
UBOOT_SOURCE_DIR=${BASE}/u-boot/u-boot-git
UBOOT_GIT=https://github.com/u-boot/u-boot

KERN_BUILD_DIR=${BASE}/kernel
KERN_SOURCE_DIR=${BASE}/kernel/bb-kernel
KERN_GIT=https://github.com/RobertCNelson/bb-kernel
KERN_VERSION=am33x-v4.5

ROOTFS_BUILD_DIR=${BASE}/rootfs
ROOTFS_FILE=debian-8.4-bare-armhf-2016-04-22.tar.xz
ROOTFS_URL=https://rcn-ee.com/rootfs/eewiki/barefs/${ROOTFS_FILE}

# Export the compiler to use...
export CC=arm-linux-gnueabihf-

