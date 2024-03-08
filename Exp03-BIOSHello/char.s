; nasm assembly [EXP 03]
; Goal: Make a MBR that uses BIOS functions to print a message.
; this is the first program, which simply prints a character.

BITS 16

org 0x7c00

entry:
	; Note: assume every register is filled with garbage initially.
	
	
	
	
	mov ah, 0xE				; print character
	mov al, '?'				; character
	mov bh, 0				; page
	mov bl, 0x0F				; color?
	int 0x10
	
	; okay, we've got nothing left to do, let's wrap up.	
	;cli					; interrupts disabled
hang:
	jmp hang				; do nothing. BIOS still does stuff
						; due to interrupts being enabled


; fill remainder of MBR with zeroes
TIMES 510-($-$$) db 0

; MBR magic number
db 0x55
db 0xAA

