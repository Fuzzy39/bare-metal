; nasm asm file 
; Orm legacy BIOS bootloader stage 2
; ----------------------------------------------------------
; this is the second stage bootloader for use by Orm, an OS that plays a 
; game of snake.
; When complete, this code will:
; set up protected mode for the kernel
; find the kernel of orm, load it into memroy, and jump to it.
; the kernel is expected to be on a fat filesystem, in the active partition 
; indicated by the MBR. Ideally, the code that this bootloader loads and 
; jumps into will be the same code
; that the uefi loader jumps to. I am currently unsure of how that prospect 
; will be achived, though.


; some random memory locations where we'll store stuff
spare_mem equ 0x0500                    ; drive info in stage one. we have 0x50 bytes here.
errorCodeTemp equ 0x550				
driveBooted:equ 0x551
; some space is here
GDT_descriptor equ 0x55A                ; 0x46 bytes in size header + 8 entries
GDT equ 0x560
TSS equ 0x600                           ; 0x100 bytes, to make it easy



%include "stage1.s"
%include "debug.s"



; code beyond the boot sector
; goal here is just to print some text not using the bios.
; if we can do this, we're ready to make the real bootloader, start learning 
; about protected mode, etc.

text_video_memory equ 0xb800

msg_stage2Welcome db "BIOS MBR boot: stage 2 started", 13, 10, 0
msg_gdt_begin db "Setting up GDT...",13,10,0
msg_gdt_setup_success db "GDT set up. Contents:", 13, 10, 0
msg_testNoBios db "The bootloader has reached the end of its code!",0
color_attr equ 0x0A ; green!

; GDT Descriptors (in a sane format)

GDT_NULL:
        db  0, 0, 0, 0                          ; base
        db  0, 0, 0                             ; limit (20 bits)
        db  0b00000000                          ; access byte
        db  0b00000000                          ; flags

GDT_CODE:
        db  0, 0, 0, 0                          ; base
        db  0x0f, 0xff, 0xff                    ; limit (20 bits)
        db  0b10011011                          ; access byte
        db  0b00001100                              ; flags

GDT_DATA:
        db  0,0,0,0                             ; base
        db  0x0f, 0xff, 0xff                    ; limit (20 bits)
        db  0b10010011                          ; access byte
        db  0b00001100                              ; flags

GDT_TASK_STATE:
        dd  TSS                                 ; base
        db  0, 0x01, 0x0                        ; limit (20 bits)
        db  0b10001001                          ; access byte
        db  0b00001100                              ; flags


code_segment equ 0b00001000
data_segment equ 0b00010000
tss_segment equ  0b00011000

; task state segment is 0x72 bytes in size, stores registers for a task switch
; (as in during interrupt) A special instruction should be called to save registers (IRET?)
; LTR should be called to configure task register


;----- STAGE 2 ----------------------------------------------------------------

stage2_entry:
	mov si, msg_stage2Welcome		; print a message to show that 
	call r_printstr                         ; we're executing from stage 2.



; ------ Global Descriptor Table Setup ----------------------------------------
        
	mov si, msg_gdt_begin
	call r_printstr
    
	; This is going to be complicated...
	cli
	; set up the GDT descriptor. This has to be loaded in with the LDTR instruction.
	; we're not just putting this in the code because
	; it needs to remain if the boot loader cdoe gets overwritten.
	mov word [GDT_descriptor+2], GDT		; pointer to GDT
	mov word [GDT_descriptor+4], 0
	mov word [GDT_descriptor], 0x3F 	; size in bytes minus 1.

	; clear mem first
	mov di, GDT
	mov al, 0
	mov ecx, 0x46
	rep stosb 
	

	; push gdt entry, then data
	mov ax, GDT
	push ax

	;db "LOOK HERE"
	mov bx,GDT_NULL
	call r_EncodeGDT

	pop ax
	add ax, 8	
	push ax


	mov bx,  GDT_CODE
	call r_EncodeGDT

	pop ax
	add ax, 8
	push ax
	
	mov bx, GDT_DATA
	call r_EncodeGDT

	pop ax
	add ax, 8
	push ax

	mov bx, GDT_TASK_STATE
	call r_EncodeGDT
	

	


	; next step, actually load everything in.
	LGDT [GDT_descriptor]
	sti

	mov si, msg_gdt_setup_success
	call r_printstr
	
	mov si, GDT
	call r_miniDump
	mov si, GDT+16
	call r_miniDump
	mov si, GDT+32
	call r_miniDump
	mov si, GDT+48
	call r_miniDump


	; NOTE: we need to do a number of things with the tss in order for interrupts to work.

	; not entirely sure it worked, but we can only know once we're in protected mode, so.


	
; ------ Printing without BIOS ------------------------------------------------
	; given the age of computers we care about this working on,
	; we will assume VGA is a thing and working.
	; also I don't quite understand how to check for it so meh.


	; we're going to mess around with video memory now.
	; we'll do a very basic printing of a string
	mov ax, text_video_memory
	mov es, ax
	mov di, 160*23	; should be on 4th line if no additonal messages were 
                        ; printed (crude, I know)

	mov si, msg_testNoBios


noBios_loop:
	cmp byte [ds:si], 0
	je post

	movsb
	
	; color atrr
	mov byte [es:di], color_attr
	inc di


	jmp noBios_loop

post:
	jmp hang

; ------ FUNCIONS ------------------------------------------------



; ------ EncodeGDT ------------------------------------------------
; Push on stack: addr of GDT entry, addr of data

; ax  - addr of GDT entry
; bx - addr of data
msg_error_gdtEncode db "Could not encode Global Descriptor Table entry. Limit > 2^20.", 13, 10, "High byte ->", 0
msg_colonSpace db ": ", 0
msg_space db " ", 0
gdt_loop_count db 0

r_EncodeGDT:
	push ax
	push bx


	mov al, 0
	mov [gdt_loop_count], al

	
	; pop si
	; push si

	; mov si, bx
	; call r_miniDump


	pop si
	
	; first we check that the limit does not exceed 20 bits
	add si, 4
	cmp byte [si], 0x10
	jb limit_good

	mov ah, [si]
	push msg_error_gdtEncode
	jmp r_error

limit_good:
	pop di
	sub si, 4
	
	; next, we encode the base.
	add di, 2
	mov al, [si]
	mov [di], al
	inc si
	inc di
	mov al, [si]
	mov [di], al
	inc si
	inc di


    mov al, [si]
	mov [di], al
	add si, 1
	add di, 3
	mov al, [si]
	mov [di], al	


	add si, 1
	sub di, 1



	; next we encode the limit.
	mov al, [si]
	shl al, 4
	mov [di], al
	inc si
	sub di, 6

	mov ax, [si]
	mov [di], ax
	add si, 2
	add di, 6

	; now the special byte of specialness
	dec di
	mov al, [si]
	mov [di], al

	; now the even more special nybble
	inc si
	inc di
	mov ah, [si]
	mov al, [di]
	or ah, al
	mov [di], ah

	ret




TIMES (512*(1+sectors))-($-$$) db 0


