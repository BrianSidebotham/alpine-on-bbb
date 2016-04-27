#!/bin/sh

if [ ! -e alpine-uboot-3.3.3-armhf.tar.gz ]; then
    wget -c http://wiki.alpinelinux.org/cgi-bin/dl.cgi/v3.3/releases/armhf/alpine-uboot-3.3.3-armhf.tar.gz
fi

tar xzf ./alpine-uboot-3.3.3-armhf.tar.gz

# The size of the card image in MiB
IMAGE_SIZE=256
IMAGE_NAME=./alpine-3.3.3.img

# Create an image file of appropriate size (1GiB)
dd if=/dev/zero of=${IMAGE_NAME} bs=1M count=${IMAGE_SIZE}

# Sorry if you were using any loop devices!
sudo losetup -D
sudo kpartx -av ${IMAGE_NAME}
DISK=`sudo losetup | grep -o -m 1 "/dev/loop[0-9].*${IMAGE_NAME}\$" | grep -o "/dev/loop[0-9]"`
echo "Using ${DISK} as the target device!"
if [ "N" = "N${DISK}" ]; then
    echo "No Target Found!"
    exit 1
fi

# Use the original supplied Alpine Linux built bootloader, or our fresh built one if it exists
uboot_MLO=./u-boot/am335x_boneblack/MLO
uboot_img=./u-boot/am335x_boneblack/u-boot.img

if [ -d uboot/u-boot/u-boot-git ]; then
    uboot_MLO=./uboot/u-boot/u-boot-git/MLO
    uboot_img=./uboot/u-boot/u-boot-git/u-boot.img
fi

# See: http://elinux.org/Beagleboard:U-boot_partitioning_layout_2.0
# The above is a bit out of date though, as u-boot can now handle ext4 filesystems so long as
# journalling is disabled. Disabling journalling for a flash filesystem is a good idea anyway.
sudo dd if=${uboot_MLO} of=${DISK} count=1 seek=1 bs=128k
sudo dd if=${uboot_img} of=${DISK} count=2 seek=1 bs=384k

sudo parted ${DISK} mklabel msdos
sudo parted ${DISK} mkpart primary ext4 1M ${IMAGE_SIZE}

# I'm paranoid with syncs when working with images and SD Cards!
sync

sudo partprobe ${DISK}

sync

sudo mkfs.ext4 -O ^has_journal ${DISK}p1 -L rootfs

sudo mkdir -p /media/rootfs/

sudo mount ${DISK}p1 /media/rootfs/

sudo cp -rv ./apks /media/rootfs/boot/
sudo cp -rv ./extlinux /media/rootfs/boot/

if [ -f ./linux-grsec/kernel/deploy/boot/vmlinuz-4.4.8-grsec ]; then
    sudo cp -rv ./linux-grsec/kernel/deploy/boot/* /media/rootfs/boot/
fi

sync
sudo umount /media/rootfs
