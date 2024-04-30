; nasm asm file 
; Orm legacy BIOS bootloader | FAT12 load kernel from file
; ----------------------------------------------------------
; this file contains the basic facilities to identify and load a file from the root directory of a FAT-12 partition.
; this is used by the second stage of the boot loader to first check for, then to load and jump to, the kernel code.

; ------ GetPartitionSector ------------------------------------------------------------
; loads the bpb into memory and checks that it is a probably valid fat12 partition.
msg_fat_noPartition: db "Could not find an active partition on the drive.", 13, 10,0
msg_fat_starting db "Reading partition metadata...", 13, 10,0
msg_fat_not_fat db "The active partition may not have a FAT filesystem. ", 13, 10, 0
msg_fat_not_fat12 db "The active partition uses a FAT filesystem, but it is not FAT12. ",13, 10, 0
msg_fat_fs_error db "Orm must boot from a FAT12 partition.", 13, 10, 0


r_getFATbpb:
    mov si, partition_table

getFATbpb_loop:
    mov al, [si]
    and al, 0b10000000  
    cmp al, 0x80
    je getFATbpb_foundActive 
    add si, 0x10
    cmp si, partition_table_end
    jl getFATbpb_loop

    ; no active partition
    push msg_fat_noPartition
	mov ah, 0
	jmp r_error


getFATbpb_foundActive:
    ;mov rax, [si+0x8] ; apparently it's 4 bytes...

    ; the next step is to create a disk access packet for the bios call.
    mov word [disk_access_packet+0x2], 0x01  ; transfer 1 sector
    mov dword [disk_access_packet+0x4], FREE_SECTOR ; location to transfer to in memory

    ;sector to read from (qword). This wasn't annoying to do, no.
    mov ax, [si+0x8] 
    mov word [disk_access_packet+0x8], ax
    mov ax, [si+0xA]
    mov word [disk_access_packet+0xA], ax
    mov dword [disk_access_packet+0xC], 0x0 

    mov si, msg_fat_starting
    call r_printstr

    mov ah, 0x42
    mov dl, [driveBooted]
    mov si, disk_access_packet
    int 0x13
    
    ; we now have the basic info about the partition.
    ; is it fat?

    mov ax, [FREE_SECTOR+11]
    cmp ax, 512
    jne getFATbpb_notFat

    ; sector size is good.
    ; check for aa55
    mov ax, [FREE_SECTOR+510]
    cmp ax, 0xAA55
    jne getFATbpb_notFat

getFATbpb_notFat:
    mov si, msg_fat_not_fat
    call r_printstr
    mov si, msg_fat_fs_error
    mov ah, 0
    call r_error


    ret

