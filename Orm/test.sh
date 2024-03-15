nasm -f bin -W+all -o drive.iso stage2.s
qemu-system-x86_64 -drive file=drive.iso,format=raw
