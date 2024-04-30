
test: make
	qemu-system-x86_64 -drive file=drive.iso,format=raw

make: drive.iso driveContent
	

	@./mount.sh
	cp -r driveContents/* mnt
	@./unmount.sh


drive.iso: bootloader/*.s
	nasm -f bin -W+all -o drive.iso bootloader/bootloader.s
	
driveContent: driveContents/*
	$(info no content compilation...)