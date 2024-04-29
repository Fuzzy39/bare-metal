LOOP= $(shell losetup -f)
UID = $(shell id -u)

test: make
	qemu-system-x86_64 -drive file=drive.iso,format=raw

make: drive.iso driveContent
	
	$(info Mounting to: $(LOOP) )
	$(info UID: $(UID) )
	sudo losetup -Pf drive.iso
	sudo mount -o uid=$(UID) $(LOOP)p1 mnt
	
	cp -r driveContents/* mnt
	
	sudo umount mnt
	sudo losetup -d $(LOOP)

drive.iso: bootloader/*.s
	nasm -f bin -W+all -o drive.iso bootloader/bootloader.s
	
driveContent:
	echo "no content compilation..."
