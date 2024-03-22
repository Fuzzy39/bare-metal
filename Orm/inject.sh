#!/bin/bash  

LOOP=$(losetup -f)

echo "Mounting to: ${LOOP}"
sudo losetup -Pf drive.iso
sudo mount -t vfat -o uid=$UID "${LOOP}p1" mnt

echo "Hello! This is a test! how exciting." >> "mnt/test.txt"
sleep .5

sudo umount mnt
sudo losetup -d $LOOP

S
