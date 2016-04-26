#!/bin/sh

. ./settings.sh

echo "Starting Build..."

# If u-boot doesn't exist yet, make sure it does now...
if [ ! -d ${UBOOT_SOURCE_DIR} ]; then
    git clone ${UBOOT_GIT} ${UBOOT_SOURCE_DIR}
fi

# Checkout the required branch of u-boot
cd ${UBOOT_SOURCE_DIR}
echo "Checking out u-boot ${UBOOT_VERSION}"
branch=$(git branch | grep -o -m 1 "^\*(.*)$")
echo "Branch: ${branch}"
git checkout v${UBOOT_VERSION} -b tmp

#if [ ! -e ${UBOOT_SOURCE}/patched ]; then
#    echo "Patching u-boot..."
#    wget -c https://rcn-ee.com/repos/git/u-boot-patches/v${UBOOT_VERSION}/0001-am335x_evm-uEnv.txt-bootz-n-fixes.patch
#    patch -p1 < 0001-am335x_evm-uEnv.txt-bootz-n-fixes.patch
#    touch ${UBOOT_SOURCE}/patched
#fi

echo "Building u-boot..."
make ARCH=arm CROSS_COMPILE=${CC} distclean
#make ARCH=arm CROSS_COMPILE=${CC} am335x_evm_defconfig
make ARCH=arm CROSS_COMPILE=${CC} am335x_boneblack_config
make ARCH=arm CROSS_COMPILE=${CC}

# u-boot is build
exit 0