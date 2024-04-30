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

partition_size_kb equ 7     ;size, in kibibytes, of the fat partition where the os is. 
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


%include "bootloader/stage1.s"

; the following files contain functions/routines used by the stage 2 bootloader
%include "bootloader/debug.s"
%include "bootloader/gdt.s"
%include "bootloader/a20.s"

%include "bootloader/stage2.s"

TIMES (512*(1+sectors))-($-$$) db 0



; Fat 12 parition starts here

db 0xeb, 0x00, 0x90           ; relative jump. execution really shouldn't ever go here
db "Orm OS!!"               ; this shouldn't matter
dw 512                      ; bytes per sector
db 1                        ; sectors per cluster
dw 1                        ; reserved sectors (just this one, please!)
db 2                        ; number of fat structures. should always be 2, basically
dw 32                       ; number of 32 byte directory entries in the root directory.
dw partition_size_kb*2      ; sectors on volume
db 0xf8                     ; typically f0 for removable media. f8 for non-removable. typically unused.
dw 1                        ; sectors occupied by one fat
dw 64                       ; sectors for track. shouldn't matter.
dw 0x10                     ; number of heads. check this! this is wrong! but maybe it's fine?
dd sectors+1                ; number of hidden sectors on disk.
dd 0 				        ; number of sectors in partition if greater than 2^16
; fat 12/16 exclusive
db 0						; drive number
db 0						; reserved. 0.
db 0x29						; signature.
dd 1						; serial number.. doesn't matter?
db "Orm OS     "            ; 11 byte volume label
db "FAT12   "               ; 8 bytes


TIMES (512*(1+sectors+1))-($-$$)-2 db 0

dw 0xAA55                   ; apparently has to be true

; FAT Table!

; first two special entires
db 0xf8
db 0xff
db 0xff

; FAT table size
TIMES (512*(1+sectors+1+1))-($-$$) db 0

; FAT table 2 is a copy of the first, as far as I know.


; first two special entires
db 0xf8
db 0xff
db 0xff

; FAT2 table size
TIMES (512*(1+sectors+1+2))-($-$$) db 0

; root directory

; we will just name the partition here.
db "Orm OS  "       ; name
db "   "            ; ext.
db 0x08             ; volume label attribute (not real file)
db 0x0              ; reserved, legacy
db 0x0              ; timestamp of some sort
dw 0x0              ; timestamp
dw 0x0              ; date
dw 0x0              ; date
dw 0x0              ; high cluster
dw 0x0              ; write time
dw 0x0              ; write date
dw 0x0              ; low cluster
dd 0x0              ; file size

; root directory size
TIMES (512*(1+sectors+1+2+3))-($-$$) db 0



TIMES (512*(1+sectors+(partition_size_kb*2)))-($-$$) db 0


