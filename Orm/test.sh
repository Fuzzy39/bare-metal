#nasm -f bin -W+all -o drive.iso bootloader.s
qemu-system-x86_64 -drive file=drive.iso,format=raw
