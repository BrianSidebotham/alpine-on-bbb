#!/bin/sh

BASE=$(dirname $(readlink -f $0))

KERN_VERSION=4.4.8
KERN_BUILD_DIR=${BASE}/kernel
KERN_SOURCE_DIR=${BASE}/kernel/linux-${KERN_VERSION}

CORES=8

# Export the compiler to use...
export CC=arm-linux-gnueabihf-

