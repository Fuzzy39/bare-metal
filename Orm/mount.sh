LOOP=$(losetup -f)
echo "Mounting to: ${LOOP}"
sudo losetup -Pf drive.iso
sudo mount -o uid=$UID "${LOOP}p1" mnt
