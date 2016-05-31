#!/bin/sh

SCRIPTDIR=$(dirname $(readlink -f $0))
. ${SCRIPTDIR}/settings.sh

# Define whether we build or download alpine
BUILD=0

# The size of the card image in MiB
IMAGE_SIZE=64
IMAGE_NAME=./alpine-${VERSION}.img

# Create an image file of appropriate size
dd if=/dev/zero of=${IMAGE_NAME} bs=1M count=${IMAGE_SIZE}

# Sorry if you were using any loop devices (Not all losetup supports option -D)!
sudo losetup -D > /dev/null 2>&1
sudo kpartx -av ${IMAGE_NAME}
DISK=`sudo losetup -a | grep -o -m 1 "/dev/loop[0-9].*${IMAGE_NAME}" | grep -o "/dev/loop[0-9]"`
echo "Using ${DISK} as the target device!"
if [ "N" = "N${DISK}" ]; then
    echo "No Target Found!"
    exit 1
fi

if [ ${BUILD} -eq 1 ]; then

    # Make sure u-boot has been built, otherwise build it now
    if [ ! -f uboot/u-boot/u-boot-git/MLO ]; then
        echo "u-boot has not been built, building now..."
        uboot/build_bbb.sh
        if [ ! -f uboot/u-boot/u-boot-git/MLO ]; then
            echo "u-boot did not build successfully!"
            exit 1
        fi
    fi

    # Check the linux build is complete, otherwise attempt to build it now...
    if [ ! -f ./linux-grsec/kernel/deploy/boot/vmlinuz-grsec ]; then
        echo "The kernel has not been built, building now..."
        linux-grsec/build_bbb.sh
        if [ ! -f ./linux-grsec/kernel/deploy/boot/vmlinuz-grsec ]; then
            echo "The kernel didn't built. Awww shucks!"
            exit 1
        fi
    fi

    # The u-boot binaries we're going to boot from
    uboot_MLO=${SCRIPTDIR}/build/u-boot/am335x_boneblack/MLO
    uboot_img=${SCRIPTDIR}/build/u-boot/am335x_boneblack/u-boot.img

else

    echo "Downloading Alpine ${VERSION}"

    mkdir -p ${SCRIPTDIR}/build/dl
    wget -P ${SCRIPTDIR}/build/dl -c http://dl-cdn.alpinelinux.org/alpine/v3.4/releases/armhf/alpine-uboot-3.4.0-armhf.tar.gz
    cd ${SCRIPTDIR}/build
    tar -xzf ${SCRIPTDIR}/build/dl/alpine-uboot-3.4.0-armhf.tar.gz

    # The u-boot binaries we're going to boot from
    uboot_MLO=${SCRIPTDIR}/build/u-boot/am335x_boneblack/MLO
    uboot_img=${SCRIPTDIR}/build/u-boot/am335x_boneblack/u-boot.img

fi

# See: http://elinux.org/Beagleboard:U-boot_partitioning_layout_2.0
# The above is a bit out of date though, as u-boot can now handle ext4 filesystems so long as
# journalling is disabled. Disabling journalling for a flash filesystem is a good idea anyway.
sudo dd if=${uboot_MLO} of=${DISK} count=1 seek=1 bs=128k
sudo dd if=${uboot_img} of=${DISK} count=2 seek=1 bs=384k

sudo parted -s ${DISK} mklabel msdos
sudo parted -s ${DISK} mkpart primary ext4 1M ${IMAGE_SIZE}

# I'm paranoid with syncs when working with images and SD Cards!
sync
sudo partprobe ${DISK}

sync
sudo mkfs.ext4 -O ^has_journal ${DISK}p1 -L rootfs
sudo mkdir -p /media/rootfs/
sudo mount ${DISK}p1 /media/rootfs/

sudo cp -rv ${SCRIPTDIR}/build/boot /media/rootfs/
sudo cp -rv ${SCRIPTDIR}/build/apks /media/rootfs/boot/
sudo cp -rv ${SCRIPTDIR}/build/extlinux /media/rootfs/boot/

sync
sudo umount /media/rootfs

# Remove the disk we've used
sudo losetup -d ${DISK}

exit 0
