; nasm asm file 
; Orm legacy BIOS bootloader | FAT12 load kernel from file
; ----------------------------------------------------------
; this file contains the basic facilities to identify and load a file from the root directory of a FAT-12 partition.
; this is used by the second stage of the boot loader to first check for, then to load and jump to, the kernel code.

; ------ GetPartitionSector ------------------------------------------------------------
; returns the sector number of the active partition in rax... ?
msg_fat_noPartition: db "Could not find an active partition on the drive.", 13, 10

r_getPartitionSector:
    mov si, partition_table

getPartitionSector_loop:
    mov al, [si]
    and al, 0b10000000
    cmp al, 0x80
    je getPartitionSector_foundActive 
    add si, 0x10
    cmp si, partition_table_end
    jl getPartitionSector_loop

    ; no active partition
    push msg_fat_noPartition
	mov ah, 0
	jmp r_error


getPartitionSector_foundActive:
    mov rax, [si+0x8] ; apparently it's 4 bytes...
    ret

    
