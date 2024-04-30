#!/bin/bash
set -u

if mountpoint -q mnt; then
    echo "Already Mounted."
    exit 1
fi


if LOOP=$(losetup -f); then
    echo "Mounting to: ${LOOP}"
else
    exit 1
fi

if sudo losetup -Pf drive.iso; then
    echo "loop device created."
else
    echo "failed to create loop device."
    exit 1
fi


if sudo mount -o uid=$UID "${LOOP}p1" mnt; then
    echo "sucessfully mounted."
    echo $LOOP >> openLoops.txt
else
    echo "failed to mount."
    losetup -d $LOOP
    exit 1
fi

