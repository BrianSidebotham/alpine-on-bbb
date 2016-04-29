#!/bin/sh

VERSION=x.x.x

# The size of the card image in MiB
IMAGE_SIZE=256
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
if [ ! -f ./linux-grsec/kernel/deploy/boot/vmlinuz-4.4.8-grsec ]; then
    echo "The kernel has not been built, building now..."
    linux-grsec/build_bbb.sh
    if [ ! -f ./linux-grsec/kernel/deploy/boot/vmlinuz-4.4.8-grsec ]; then
        echo "The kernel didn't built. Awww shucks!"
        exit 1
    fi
fi

# The u-boot binaries we're going to boot from
uboot_MLO=./uboot/u-boot/u-boot-git/MLO
uboot_img=./uboot/u-boot/u-boot-git/u-boot.img

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

sudo cp -rv ./apks /media/rootfs/boot/
sudo cp -rv ./extlinux /media/rootfs/boot/

# Copy the kernel release over to the SD Card image
sudo cp -rv ./linux-grsec/kernel/deploy/boot/* /media/rootfs/boot/

# TODO: Fix the ramfs which isn't yet built here
sudo cp -v ./initramfs-grsec /media/rootfs/boot/

sync
sudo umount /media/rootfs

# Remove the disk we've used
sudo losetup -d ${DISK}

exit 0
