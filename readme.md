# Alpine Linux on the BeagleBoneBlack

The bootloader is put in place using the instructions at

u-boot is re-compiled from the 2016.03 vanilla source which fixes a problem with Alpine Linux's
u-boot attempting to scan inappropriuate mmc partitions.

If you don't compile u-boot using `uboot/build_bbb.sh` then the original Alpine bootloader will be
used. Otherwise the compiled version will be installed on the card image.

A single ext-4 (non-journaling) partition is created on the disk image to keep the boot files

