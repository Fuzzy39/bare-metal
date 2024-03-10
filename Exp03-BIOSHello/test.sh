nasm -f bin -W+all -o mbr.bin mbr.s
qemu-system-x86_64 mbr.bin
