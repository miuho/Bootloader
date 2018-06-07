#!/bin/sh
# @file  mkimage.sh
# @brief Generate the disk image.
#
# Create a properly formatted disk image with boot0, boot1, & kernel.
#
# The kernel image size is artificially limited by a single byte to simply
# the script (e.g., the last expr & dd operations operate on one byte
# instead of zero).  Since this is well beyond the maximum loadable kernel
# size, it's unlikely to be an issue except in the most corner of cases.
#
# @author Mike Kasick <mkasick@andrew.cmu.edu>

BOOT0_SIZE=512
BOOT1_MAX_SIZE=8704
KERNEL_WARN_SIZE=589824

CYL0_REM=17920   # (17+18)*512
DISK_REM=1456128 # 79*2*18*512

verify_file_exists() {
	file="$1"

	if [ ! -f "$file" ]; then
		echo "Error: File \"$file\" does not exist."
		exit 1
	fi
}

set -e

if [ "$#" -ne 4 ]; then
	echo "Usage: `basename \"$0\"` disk_img boot0 boot1 kernel"
	exit
fi

disk_img="$1"
boot0="$2"
boot1="$3"
kernel="$4"

verify_file_exists "$boot0"
verify_file_exists "$boot1"
verify_file_exists "$kernel"

boot0_size=`ls -l "$boot0" | awk '{print $5}'`
boot1_size=`ls -l "$boot1" | awk '{print $5}'`
kernel_size=`ls -l "$kernel" | awk '{print $5}'`

if [ "$boot0_size" -ne "$BOOT0_SIZE" ]; then
	echo "Error: boot0 size ($boot0_size bytes) != $BOOT0_SIZE bytes."
	echo "       boot0 must be exactly $BOOT0_SIZE bytes, cannot create disk image."
	exit 1
fi

if [ "$boot1_size" -gt "$BOOT1_MAX_SIZE" ]; then
	echo "Error: boot1 size ($boot1_size bytes) > $BOOT1_MAX_SIZE bytes."
	echo "       boot1 must be <= $BOOT1_MAX_SIZE bytes, cannot create disk image."
	exit 1
fi

if [ "$kernel_size" -ge "$DISK_REM" ]; then
	echo "Error: kernel size ($kernel_size bytes) >= $DISK_REM bytes."
	echo "       kernel must be < $DISK_REM to fit in the disk image."
	exit 1
elif [ "$kernel_size" -gt "$KERNEL_WARN_SIZE" ]; then
# figlet -m 0
cat << 'EOF'
__        __                   _               
\ \      / /__ _  _ __  _ __  (_) _ __    __ _ 
 \ \ /\ / // _` || '__|| '_ \ | || '_ \  / _` |
  \ V  V /| (_| || |   | | | || || | | || (_| |
   \_/\_/  \__,_||_|   |_| |_||_||_| |_| \__, |
                                         |___/ 
EOF
	echo "Warning: kernel size ($kernel_size bytes) > $KERNEL_WARN_SIZE bytes."
	echo "         Too large of a kernel is unlikely to work properly."
	sleep 2
fi

cyl0_pad=`expr "$CYL0_REM" - "$boot1_size"`
disk_pad=`expr "$DISK_REM" - "$kernel_size"`

cat "$boot0" > "$disk_img"
cat "$boot1" >> "$disk_img"
dd if=/dev/zero bs="$cyl0_pad" count=1 >> "$disk_img"
cat "$kernel" >> "$disk_img"
dd if=/dev/zero bs="$disk_pad" count=1 >> "$disk_img"
