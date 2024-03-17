; nasm asm file 
; Orm legacy BIOS bootloader
; ----------------------------------------------------------
; this is the primarily file of the bootloader for use by Orm, an OS that plays a 
; game of snake.
; this code holds constants and includes the other source code files.
; the bootloader consists of 2/3 stages:
; stage 1: MBR boot sector. This code's goal is to load stage 2.
; stage 2: real mode. this stage sets up the system to run in protected mode, 
;          looks at the active partition to find stage 3, and loads it.
; stage 3: protected mode. this stage is a seperate program, ideally written in C,
;          that does any remaining bios boot specific tasks before starting Orm proper.


BITS 16

; some random memory locations where we'll store stuff
spare_mem equ 0x0500                    ; we have 0x50 bytes here.
errorCodeTemp equ 0x550				
driveBooted:equ 0x551
; some space is here
GDT_descriptor equ 0x55A                ; 0x46 bytes in size header + 8 entries
GDT equ 0x560
TSS equ 0x600                           ; 0x100 bytes, to make it easy

; size, in sectors (512 bytes) of stage 2. stage 1 is one sector.
sectors equ 5 ; 5+1 = 3kb of space for stage 1 and 2 bootloader.

partition_size_kb equ 1     ;size, in kibibytes, of the fat partition where the os is. 
                            ; WARNING: this cannot be larger than (64-sectors+1)/2 (currently 29kb) 
                            ; without adjusting partition table 

; for printing in protected mode
text_video_memory equ 0xb8000
color_attr equ 0x0A ; green!

; for use in protected mode
code_segment equ 0b00001000
data_segment equ 0b00010000
tss_segment equ  0b00011000




org 0x7c00


%include "stage1.s"

; the following files contain functions/routines used by the stage 2 bootloader
%include "debug.s"
%include "gdt.s"
%include "a20.s"

%include "stage2.s"

TIMES (512*(1+sectors))-($-$$) db 0

; Fat 32 parition starts here

db 0xeb, 0x00, 0x90           ; relative jump. execution really shouldn't ever go here
db "Orm OS!!"               ; this shouldn't matter
dw 512                      ; bytes per sector
db 1                        ; sectors per cluster
dw 1                        ; reserved sectors (just this one, please!)
db 2                        ; number of fat structures. should always be 2, basically
dw 0                        ; always 0 for fat32
dw 0                        ; always 0 for fat32
db 0xf0                     ; typically f0 for removable media. f8 for non-removable. typically unused.
dw 0                        ; always 0 for fat32
dw 64                       ; sectors for track. shouldn't matter.
dw 2                        ; number of heads. check this! this is wrong! but maybe it's fine?
dd sectors+1                ; number of hidden sectors on disk.
dd partition_size_kb*2      ; number of sectors in partition
; fat32 exclusive
dd 1;??                       ; number of sectors occupied on one fat
dw 0;0b??                     ; flags... not sure what this means ExtFlags
db 0x00, 0x00               ; Fat version
dw 0;??                       ; cluster number of 1st cluster of root directory
dw 0;??                       ; sector number of FSINFO in reserved section
dw 0                        ; if nonzero, sector number of copy of mbr, I think?

dq 0                        ; 12 bytes reserved
dw 0
db 0                        ; drive num, shouldn't matter
db 0                        ; reserved
db 0x29                     ; indicates the following fields are present
dd 0x0                      ;serial number. shouldn't matter?
db "Orm OS     "            ; 11 byte volume label
db "FAT32   "               ; 8 bytes

TIMES (512*(1+sectors+1))-($-$$)-2 db 0

dw 0xAA55                   ; apparently has to be true

TIMES (512*(1+sectors+(partition_size_kb*2)))-($-$$) db 0


