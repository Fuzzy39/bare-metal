; nasm assembly [EXP 03]
; Make a MBR that uses BIOS functions to print a message.
; this is the third program, where we are a bit more involved in the printing.

BITS 16

org 0x7c00

entry:
	; Note: assume every register is filled with garbage initially.
	
	; first, we want to ensure the segment
	; registers are set up in a way that makes sense.
	
	xor ax, ax 				; zero ax
	mov es, ax				; and the extra segment (I don't think that's 
						; it's name, but eh.)
	mov ds, ax				; zero data segment
	
						
	; setup the stack
	mov ss, ax				; zero the stack segment
	
	mov sp, 0x7bff				; put the stack below our code.
	
	
	; Now, let's print a string.

	mov si, message1			
	call printstr				; call our glorious routine.
	
	mov si, message2
	call printstr	
	
	; wrap up.
	
	;cli					; interrupts disabled
hang:
	jmp hang				; do nothing.
	
	

printstr:
; -------------
; Prints a string. si should contain the address of the string	
	cld					; clear the direction flag
						; this makes sure we will read the string 
						; in the correct direction (a good idea)
	
	
			
print_loop:
	mov al, [ds:si]				
	cmp al, 0				; check to make sure we're not reached
	je print_ret 				; the end of the string
	
	
	mov ah, 0x0E				; tell bios we're printing a char
	
	LODSB					; load the byte in si to al, inc si
	
	mov bh, 0				; page, which by default should be 0.
	
	
	int 0x10				; actually make bios do the thing.
	
	jmp print_loop

print_ret:
	ret					


message1 db "I'm here!" , 10, 0
message2 db "Am I late?", 10, 0

; fill remainder of MBR with zeroes
TIMES 510-($-$$) db 0

; MBR magic number
db 0x55
db 0xAA

