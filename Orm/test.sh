nasm -f bin -W+all -o drive.bin stage2.s
qemu-system-x86_64 drive.bin
