; nasm asm file 
; Orm legacy BIOS bootloader | FAT12 load kernel from file
; ----------------------------------------------------------
; this file contains the basic facilities to identify and load a file from the root directory of a FAT-12 partition.
; this is used by the second stage of the boot loader to first check for, then to load and jump to, the kernel code.


; ----- accessDisk ---------------------------------------------------------------------
; populates disk access packet and loads memory from disk using bios call 0x13 (ah = 0x42)
; ax = number of sectors. 
; di = word: memory location to copy to.
; [si] = dword: sector to copy from.

r_accessDisk:
    ; the next step is to create a disk access packet for the bios call.
    ; transfer ax sectors
    mov word [disk_access_packet+0x2], ax  

    ; memory location to copy to.
    mov [disk_access_packet+0x4], di
    mov word [disk_access_packet+0x6], 0   

    ;sector to read from (qword). This wasn't annoying to do, no.
    mov ax, [si] 
    mov word [disk_access_packet+0x8], ax
    mov ax, [si+0x2]
    mov word [disk_access_packet+0xA], ax
    mov dword [disk_access_packet+0xC], 0x0 

    ; get the data
    mov ah, 0x42
    mov dl, [driveBooted]
    mov si, disk_access_packet
    int 0x13
    
    ret

; ----- sectorOfCluster --------------------------------------------------------------
; gets the axth cluster and puts it in spare_mem
    dec ax
    dec ax
    mov bx, [fat_first_data_sector]
    add ax, bx
    mov [spare_mem], ax
    mov dx, [fat_first_data_sector+2]
    mov [spare_mem+2], dx
    ret



; ------ GetPartitionSector ------------------------------------------------------------
; loads the bpb into memory and checks that it is a probably valid fat12 partition.
msg_fat_noPartition: db "Could not find an active partition on the drive.", 13, 10,0
msg_fat_starting db "Reading partition metadata... first few bytes:", 13, 10,0
msg_fat_fs_error db "Active partiton is not FAT12.", 13, 10, 0
msg_fat_confirm db "Partition is FAT12.", 13, 10, 0 



r_getFAT:
    mov si, partition_table

getFAT_loop:
    mov al, [si]
    and al, 0b10000000  
    cmp al, 0x80
    je getFAT_foundActive 
    add si, 0x10
    cmp si, partition_table_end
    jl getFAT_loop

    ; no active partition
    push msg_fat_noPartition
	mov ah, 0
	jmp r_error


getFAT_foundActive:
    ;mov rax, [si+0x8] ; apparently it's 4 bytes...
    push si
    mov si, msg_fat_starting
    call r_printstr


    ; setup destination pointer in di.
    mov di, FREE_SECTOR
    pop si
    add si, 0x8 ; source sector pointer in si.
  
   
    ; quickly copy the starting sector
    mov ax, [si]
    mov [partition_start_sector], ax
    mov ax, [si+2]
    mov [partition_start_sector+2], ax

    mov ax, 1  ; number of sectors to transfer

    call r_accessDisk
    
    ; print it out
    mov si, FREE_SECTOR
	call r_miniDump

    ; we now have the basic info about the partition.
    ; is it fat?

    mov ax, [FREE_SECTOR+11]
    cmp ax, 512
    jne getFAT_notFat

    ; sector size is good.
    ; check for aa55
    mov ax, [FREE_SECTOR+510]
    cmp ax, 0xAA55
    jne getFAT_notFat





    ; it's probably fat. is it fat 12?
    



    ; calculate the size of the root directory
    ; RootDirSectors = ((BPB_RootEntCnt * 32) + (BPB_BytsPerSec – 1)) / BPB_BytsPerSec;
    mov ax, [FREE_SECTOR+17]    ; BPB_RootEntCnt
    mov bx, 32
    mul bx
    mov bx, [FREE_SECTOR+11]    ; BPB_BytesPerSec
    dec bx
    add ax, bx
    mov bx, [FREE_SECTOR+11]      ; BPB_BytesPerSec
    div bx
    ; ax contains size of root directory
    mov [spare_mem], ax
    mov [fat_root_dir_sectors], ax

    ; get size of the fat itself
    mov bx, [FREE_SECTOR+22]    ; BPB_FATSz16
    cmp bx, 0
    je getFAT_notFat            ; this is fat32. get lost.
    mov [fat_table_size], bx

    ; get size of partition
    mov bx, [FREE_SECTOR+19]     ; BPB_TotSec16  
    cmp bx, 0
    je getFAT_size32
    mov [fat_size_sectors], bx
    mov word [fat_size_sectors+2], 0
    jmp getFAT_getclusters

getFAT_size32:
    mov bx, [FREE_SECTOR+32]    ; BPB_TotSec32
    mov [fat_size_sectors], bx
    mov bx, [FREE_SECTOR+34]   
    mov [fat_size_sectors+2], bx


getFAT_getclusters:
    ; first data sector
    ;FirstDataSector 
    ;   = BPB_ResvdSecCnt + (BPB_NumFATs * FATSz) + RootDirSectors + partitionStartSector

    mov ax, [fat_table_size] ; 1
    mov bl, [FREE_SECTOR+16]    ; BPB_NumFATs ; 2
    mov bh, 0
    mul bx  ; 2
    mov bx, [FREE_SECTOR+14]     ; BPB_RsvdSecCnt ; 1
    add ax, bx  ; 3
    mov bx, [spare_mem]         ; root directory sectors ; 1
    add ax, bx  ; 4
    mov bx, [partition_start_sector] ; 6
    add ax, bx  ; 10
    
    mov [fat_first_data_sector], ax
    mov [fat_first_data_sector+2], dx ; for any reasonable purposes, probably 0.
                                      ; unless somehow we're not the first partition.
                                      ; this code is brittle, but this is assembly...
                                      ; it's fine.S
  
    ; number of data sectors
    mov bx, [fat_first_data_sector]     ; A
    sub bx, [partition_start_sector]    ; A-6=4
    mov ax, [fat_size_sectors]          ; 14
    sub ax, bx ; -3??                   ; 10
    mov [spare_mem], ax


    ; print this out.
    mov si,  msg_fat_clusterCount
    call r_printstr
    mov si, spare_mem
    call r_printword
    mov si, newline
    call r_printstr

   
    mov ax, [spare_mem]
    cmp ax, 4085
    jb getFAT_fatConfirmed

getFAT_notFat:
    push msg_fat_fs_error
    mov ah, 0
    jmp r_error


getFAT_fatConfirmed:

    ; print a message confirming that we like the partition
    mov si, msg_fat_confirm
    call r_printstr

    ret



; ----- readFile --------------------------------------------------------------
; 

msg_fat_searching db "Scanning root directory for '", 0
msg_fat_searching2 db "'.", 13, 10, 0
msg_fat_clusterCount db "Number of data clusters: ", 0
str_boot_file db "file2", 0 ; name only. cannot be greater than 8 characters
str_boot_ext db "txt", 0   ; extensSion only. cannot be greater than 3 characters

r_readFile:

    ; print a message saying we're looking for the file.
    mov si, msg_fat_searching
    call r_printstr
    mov si, str_boot_file
    call r_printstr
    mov al, '.'
    call r_printchar
    mov si, str_boot_ext
    call r_printstr
    mov si, msg_fat_searching2
    call r_printstr

    ret