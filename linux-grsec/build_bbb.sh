#!/bin/sh

SCRIPTDIR=$(dirname $(readlink -f $0))
. ${SCRIPTDIR}/settings.sh

echo "Starting Build..."
patches="fix-spi-nor-namespace-clash.patch
    imx6q-no-unclocked-sleep.patch
    keys-fixes.patch
    ovl-fix-getcwd-failure-after-unsuccessful-rmdir.patch
    ovl-fix-permission-checking-for-setattr.patch
    staging-dgnc-fix-info-leak-in-ioctl.patch
    via-velocity-length-check.patch
    xsa155-linux-xsa155-0001-xen-Add-RING_COPY_REQUEST.patch
    xsa155-linux-xsa155-0002-xen-netback-don-t-use-last-request-to-determine-mini.patch
    xsa155-linux-xsa155-0003-xen-netback-use-RING_COPY_REQUEST-throughout.patch
    xsa155-linux-xsa155-0004-xen-blkback-only-read-request-operation-from-shared-.patch
    xsa155-linux-xsa155-0006-xen-scsiback-safely-copy-requests.patch
    xsa155-linux43-0005-xen-blkback-read-from-indirect-descriptors-only-once.patch
    xsa157-0001-xen-pciback-Return-error-on-XEN_PCI_OP_enable_msi-wh.patch
    xsa157-0003-xen-pciback-Do-not-install-an-IRQ-handler-for-MSI-in.patch
    xsa157-0004-xen-pciback-For-XEN_PCI_OP_disable_msi-x-only-disabl.patch
    "
if [ ! -d ${KERN_BUILD_DIR} ]; then
    mkdir -p ${KERN_BUILD_DIR}
fi

cd ${KERN_BUILD_DIR}

# If u-boot doesn't exist yet, make sure it does now...
if [ ! -d ${KERN_SOURCE_DIR} ]; then
    # Get the source code from a tarball
    if [ ! -f ${KERNEL_BUILD_DIR}/${KERNEL_SOURCE_ARCHIVE} ]; then
        echo "Downloading Kernel Source"
        KERNEL_SOURCE_ARCHIVE=linux-${KERN_VERSION}.tar.xz
        wget -c http://ftp.kernel.org/pub/linux/kernel/v4.x/${KERNEL_SOURCE_ARCHIVE}
        tar xJf ${KERN_BUILD_DIR}/${KERNEL_SOURCE_ARCHIVE}
    fi

    if [ ! -f ${KERNEL_BUILD_DIR}/${KERNEL_SOURCE_ARCHIVE} ]; then
        echo "Downloading GRSEC Patch"
        GRSEC_PATCH="grsec-4.1.18-3.1-201509201149-alpine.patch"
        wget -c http://dev.alpinelinux.org/~tteras/grsec/${GRSEC_PATCH}
    fi

    if [ ! -f ${KERN_SOURCE_DIR}/patched ]; then
        echo "Patching source to GRSEC"
        tar xJf ${KERN_BUILD_DIR}/${KERNEL_SOURCE_ARCHIVE}
        cd ${KERN_SOURCE_DIR}
        patch -p1 < ${KERN_BUILD_DIR}/${GRSEC_PATCH}
        echo "Patching alpine patches..."
        for p in ${patches}; do
            patch -p1 < ${SCRIPTDIR}/patches/${p}
        done
        touch ${KERN_SOURCE_DIR}/patched
    fi
fi

echo "Building the kernel..."
cd ${KERN_SOURCE_DIR}
#make ARCH=arm CROSS_COMPILE=${CC} distclean DISABLE_PAX_PLUGINS=y LOCALVERSION=-grsec
cp -v ${BASE}/config-grsec.armhf ${KERN_SOURCE_DIR}/.config
#cp -v ${BASE}/config-grsec.bbb ${KERN_SOURCE_DIR}/.config
#make ARCH=arm CROSS_COMPILE=${CC} omap2plus_defconfig DISABLE_PAX_PLUGINS=y LOCALVERSION=-grsec
#make ARCH=arm CROSS_COMPILE=${CC} silentoldconfig DISABLE_PAX_PLUGINS=y
make ARCH=arm CROSS_COMPILE=${CC} menuconfig DISABLE_PAX_PLUGINS=y LOCALVERSION=-grsec
make -j${CORES} ARCH=arm CROSS_COMPILE=${CC} DISABLE_PAX_PLUGINS=y LOCALVERSION=-grsec

if [ $? -ne 0 ]; then
    echo "Kernel failed to compile properly!"
    exit 1
fi

KERNEL_DEPLOY=${KERN_BUILD_DIR}/deploy
rm -rf ${KERNEL_DEPLOY}
mkdir -p ${KERNEL_DEPLOY}/boot/dtbs
mkdir -p ${KERNEL_DEPLOY}/boot/modloop
mkdir -p ${KERNEL_DEPLOY}/modules
mkdir -p ${KERNEL_DEPLOY}/firmware

cp -v ${KERN_SOURCE_DIR}/arch/arm/boot/zImage ${KERNEL_DEPLOY}/boot/vmlinuz-grsec
cp -v ${KERN_SOURCE_DIR}/System.map ${KERNEL_DEPLOY}/boot/system.map-grsec
cp -v ${KERN_SOURCE_DIR}/.config ${KERNEL_DEPLOY}/boot/config-grsec
cp -v ${KERN_SOURCE_DIR}/arch/arm/boot/dts/*.dtb ${KERNEL_DEPLOY}/boot/dtbs

# TODO: Make modloop from modules_install step...
make -j1 ARCH=arm CROSS_COMPILE=${CC} modules_install firmware_install DISABLE_PAX_PLUGINS=y \
    INSTALL_MOD_PATH=${KERNEL_DEPLOY}/modules \
    INSTALL_PATH=${KERNEL_DEPLOY}/firmware \
    LOCALVERSION=-grsec

mv ${KERNEL_DEPLOY}/modules/lib ${KERNEL_DEPLOY}/boot/modloop/modules
mksquashfs ${KERNEL_DEPLOY}/boot/modloop ${KERNEL_DEPLOY}/boot/modloop-grsec -comp xz
#rm -rf ${KERNEL_DEPLOY}/boot/modloop

# TODO: Make initramfs to suit

# kernel is build
exit 0
