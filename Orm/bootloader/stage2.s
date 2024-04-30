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






; code beyond the boot sector
; goal here is just to print some text not using the bios.
; if we can do this, we're ready to make the real bootloader, start learning 
; about protected mode, etc.



msg_stage2Welcome db "BIOS MBR boot: stage 2 started", 13, 10, 0
msg_testNoBios db "The bootloader has successfully reached protected mode. Hello, 32-bit!",0
msg_succeed db "Success!", 0
msg_fail db "Failed.", 0
msg_enterProtected db "Attempting to enter protected mode...", 13, 10, 0




;----- STAGE 2 ----------------------------------------------------------------

stage2_entry:
	mov si, msg_stage2Welcome		; print a message to show that 
	call r_printstr                         ; we're executing from stage 2.


; ------ Enable the A20 line --------------------------------------------------

	call r_A20enable


; ------ Global Descriptor Table Setup ----------------------------------------
        
;	 that's it! if it fails it errors out, so no need to do anything.
	call r_setupGDT


; ----- Read the kernel or whatever off the disk ------------------------------

	call r_getFATbpb
	mov si, FREE_SECTOR
	call r_miniDump


; ----- Switch to protected mode ----------------------------------------------

	mov si, msg_enterProtected
	call r_printstr						; you did us a grand service, printstr, but where we're going, you won't be enough. 

	cli
	mov eax, cr0						; note: eax is available in real mode, we aren't protected yet
	or eax, 1
	mov cr0, eax

	; a precarious moment... 
	jmp  dword code_segment:protected_entry

protected_entry:
BITS 32
	mov eax, data_segment
	mov ds, eax
	mov ss, eax
	mov es, eax
	
; ------ Printing without BIOS ------------------------------------------------
	; given the age of computers we care about this working on,
	; we will assume VGA is a thing and working.
	; also I don't quite understand how to check for it so meh.


	; we're going to mess around with video memory now.
	; we'll do a very basic printing of a string

	; commented out is the real mode version.
; 	mov ax, text_video_memory
; 	mov es, ax
; 	mov di, 160*23	; should be on 4th line if no additonal messages were 
;                         ; printed (crude, I know)

; 	mov si, msg_testNoBios


; noBios_loop:
; 	cmp byte [ds:si], 0
; 	je post

; 	movsb
	
; 	; color atrr
; 	mov byte [es:di], color_attr
; 	inc di


; 	jmp noBios_loop



	mov edi, text_video_memory
	add edi, 160*15

	mov esi, msg_testNoBios

noBios_loop:
	cmp byte [esi], 0
	je post

	movsb

	mov byte [edi], color_attr
	inc edi

	jmp noBios_loop


post:
	hlt
	jmp post

; ------ FUNCIONS ------------------------------------------------










