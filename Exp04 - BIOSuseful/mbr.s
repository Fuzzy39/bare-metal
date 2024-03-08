; nasm asm [EXP 04]
; make an MBR that is able to load additonal sectors into memory.
; 

BITS 16

org 0x7c00

entry:
	; Note: assume every register is filled with garbage initially.
	
	; first, we want to ensure the segment
	; registers are set up in a way that makes sense.
	
	mov [driveBooted], dl
	
	xor ax, ax 				; zero ax
	mov es, ax				; and the extra segment (I don't think that's 
						; it's name, but eh.)
	mov ds, ax				; zero data segment
	
						
	; setup the stack
	mov ss, ax				; zero the stack segment
	 	
	mov sp, 0x7bff				; put the stack below our code.
	
	
	
	; try clearing the screen by setting the graphics mode?
	mov ah, 0x0				; set mode
	
	mov al, 3				; mode 3 is text, I think.
	
	int 0x10
	
	
	; Let's print a couple messages to show we're alive and kicking.

	mov si, message1			
	call r_printstr				
	
	mov si, message2
	call r_printstr
	
	
	; let's try to figure out disk io now I guess.
	
	; step one: are int 13h extensions enabled? If not we give up and croak
	
	mov ah, 0x41				; check if enabled
	mov bx, 0x55aa				; magic number
	mov dl, [driveBooted]			; drive
	
	int 0x13				; carry should be cleared
	
	jnc drive_ext_installed
	
	mov si, error13ext			; if not, throw an error and give up.
	call r_printstr
	jmp hang

drive_ext_installed:
	
	
	
	
	; print a message, because I want to.
	mov si, messageDrive
	call r_printstr

	mov si, driveBooted
	call r_printbyte
	
	mov si, newline
	call r_printstr
	
	
	; now we can try to read things from disk. supposedly.
	mov ah, 0x42
	mov dl, [driveBooted]
	mov si, disk_access_packet
	
	int 0x13
	
	; check if worked
	jnc sectors_read
	
	mov si, errorDrive
	call r_printstr
	
	mov si, tempByte
	call r_printbyte
	
	mov si, newline
	call r_printstr
	
	jmp hang
	
	
	
sectors_read:
	
	mov si, teststr
	call r_printstr
	
	
	; wrap up.
	
hang:
	hlt
	jmp hang				; do nothing.
	
	

r_printstr:
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
	

r_printbyte:
; ---------------
; prints a byte. si is the address of the byte to print.	

	mov al, [si]
	and al, 0xF0 				; get the high nybble
	shr al, 4
	call r_printnybble
	
	mov al, [si]				; low nybble
	and al, 0x0f
	call r_printnybble
	ret
	
	

r_printnybble:
; ---------------
; prints a nybble as a hex character. al is the nybble. it is expected that the high nybble is zero.
; this is for r_printbyte - don't use it.

	cmp al, 10
	jnb high_letter

high_number:
	mov ah, al
	mov al, '0'
	add al, ah				; al should contain the character we want to print now
	jmp high_print

high_letter:
	sub al, 10
	mov ah, al				; same idea here.
	mov al, 'A'
	add al, ah

high_print:
	
	mov ah, 0x0E				; print the nybble
	mov bh, 0
	int 0x10
	ret



sectors equ 1

; disk address packet for reading additional sectors from the disk
disk_access_packet:
db 0x10						; packet size
db 0						; reserved
dw sectors					; sectors to absorb in my scalp
dd 0x7e00					; pointer to place to load it
dq 1						; starting absolute block number



tempByte: db 0				
driveBooted: db 0
message1 db "Hi! I'm real! (16-bit)" , 13, 10, 0
message2 db "Figuring things out...", 13, 10, 0
messageDrive db "I booted from a disk with BIOS ID: 0x", 0
newline db 13,10,0
error13ext db "Interrupt 0x13 extensions are not supported. I don't know how to read the hard drive.", 13, 10, 0
errorDrive db "Error Reading Drive. Code: 0x", 0

; fill remainder of MBR with zeroes
TIMES 446-($-$$) db 0

db 0xff
TIMES 63 db 0


; MBR magic number
db 0x55
db 0xAA



; STAGE 2 -----------------------------------------------------



; nasm asm. Link with mbr.s
; code beyond the boot sector
; goal here is to understand fat enough to run a file from it, where we'll run more code.


teststr db "This message originates from beyond the boot sector!", 13, 10, 0

TIMES (512*(1+sectors))-($-$$) db 0


