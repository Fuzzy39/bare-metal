nasm -f bin -W+all -o drive.bin mbr.s
qemu-system-x86_64 drive.bin
