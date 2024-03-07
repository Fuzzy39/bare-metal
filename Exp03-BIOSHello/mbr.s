; nasm assembly [EXP 03]
; Make a MBR that uses BIOS functions to print a message.

BITS 16

org 0x7c00

entry:
	; Note: assume every register is filled with garbage initially.
	
	; first, we want to ensure the segment
	; registers are set up in a way that makes sense.
	
	xor ax, ax 				; zero ax
	mov es, ax				; and the extra segment (I don't think that's 
						; it's name, but eh.)
	
	; Now, perhaps, we'll do something interesting.
	mov ah, 0x13				; code for 'print string' for the bios
	mov al, 0b1				; update cursor
	
	mov bh, 0 				; page number (?)
	mov bl, 0b00001111			; background color black, foreground white
	mov dh, 0				; row
	mov dl, 0				; column
	
	mov cx, 11				; number of characters
	
						; pointer to string is in es:bp
	mov bp, string				; bp is the base stack pointer...
						; pretty sure the stack isn't set up, so
						; meh...	
	
	int 0x10
	
	; okay, we've got nothing left to do, let's wrap up.	
	;cli					; interrupts disabled
hang:
	jmp hang				; do nothing. BIOS still does stuff
						; due to interrupts being enabled

string db "It's alive!" , 0

; fill remainder of MBR with zeroes
TIMES 510-($-$$) db 0

; MBR magic number
db 0x55
db 0xAA

