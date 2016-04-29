#!/bin/sh

BASE=$(dirname $(readlink -f $0))
echo "linux-grsec build base ${BASE}"

KERN_VERSION=4.1.20
KERN_BUILD_DIR=${BASE}/kernel
KERN_SOURCE_DIR=${BASE}/kernel/linux-${KERN_VERSION}

# Use as many cores as we have available
CORES=$(cat /proc/cpuinfo | grep processor | wc -l)

# Export the compiler to use...
export CC=arm-linux-gnueabihf-
