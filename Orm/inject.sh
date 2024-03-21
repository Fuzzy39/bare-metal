#!/bin/bash  

# attempt to inject a file into drive.iso


# don't really know how I can unmount the iso...


LOOP=$(losetup -f)
echo "Mounting to: ${LOOP}"
sudo losetup -Pf drive.iso
sudo mount -o uid=$UID "${LOOP}p1" mnt
echo "attempting to inject..."
echo "Hello! This is a test! how exciting." > "mnt/test.txt"
sleep .5
sudo umount mnt
sudo losetup -d $LOOP


