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
sectors equ 3

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



