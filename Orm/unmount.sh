#!/bin/bash
set -u


if mountpoint -q mnt; then
    sudo umount mnt
fi

while read p; do
    echo "closing ${p}"
    sudo losetup -d $p
done <openLoops.txt

> openLoops.txt

