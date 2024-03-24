; nasm asm file	
; Orm legacy BIOS bootloader stage 1.
; ----------------------------------------------------------
; this is the master boot record for use by Orm, an OS that plays a game of snake.
; the program here prints a welcome message and  attempts to load the 
; stage 2 bootloader. It is not robust, and wastes a lot of space
; on various messages that it can print in error situations.





entry:
	; Note: assume every register is filled with garbage initially.
	
	; first, we want to ensure the segment
	; registers are set up in a way that makes sense.


; ----- Setup ------------------------------------------------------

	jmp 0:start				; clear cs, we're gonna ignore segmentation.
start:
	mov [driveBooted], dl
	
	xor ax, ax 				; zero ax
	mov es, ax				; and the extra segment
	mov ds, ax				; zero data segment
	
						
	; setup the stack
	mov ss, ax				; zero the stack segment
	mov sp, 0x7bff				; put the stack below our code.
	

	cld					; clear the direction flag
						; this makes sure we will read strings and things
						; in the correct direction (a good idea)

; ----- Text Output ------------------------------------------------------

	
	; try clearing the screen by setting the graphics mode?
	mov ah, 0x0				; set mode
	mov al, 3				; mode 3 is text, I think.
	int 0x10
	
	
	; Let's print a couple messages to show we're alive and kicking.

	mov si, messageWelcome			
	call r_printstr	
	

; ----- load data from the drive and start stage 2. ------------------------------------------------------

	; let's try to figure out disk io now I guess.
	

	
	
	; print a message, because I want to.
	mov si, messageDrive
	call r_printstr

	mov si, driveBooted
	call r_printbyte
	
	mov si, newline
	call r_printstr
	

	; access disk
	mov ah, 0x02
	mov al, sectors						; number of sectors to read
	mov ch, 0							; cylinder num
	mov cl, 1							; sector num
	mov dh, 0							; head num
	mov dl, [driveBooted]
	mov bx, 0x7e00						; memory location to load
	
	int 0x13

	jnc stage2_entry
	push msg_error_drive
	jmp r_error




	
; ----- end of MBR main code ---------------------------------------------------	



; ----- functions/routines ------------------------------------------------------

r_printstr:
; -------------
; Prints a string. si should contain the address of the string	
			
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

	mov al, [ds:si]
	and al, 0xF0 				; get the high nybble
	shr al, 4
	call r_printnybble
	
	mov al, [ds:si]				; low nybble
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

r_error:
; ---------------
; errors out with a code. pops an address to an error message string. ah is error code
; if ah is zero, no code is displayed.

	mov [errorCodeTemp], ah

	mov si, msg_error
	call r_printstr

	pop si
	call r_printstr


	mov ah, [errorCodeTemp]			; avoid printing error code if there isn't one.
	cmp ah, 0
	je err_end

	mov si, msg_error_code
	call r_printstr
	
	mov si, errorCodeTemp
	call r_printbyte
	
err_end:
	mov si, newline
	call r_printstr
	
	mov si, msg_abort
	call r_printstr
	
	; we've reached the end of the road.
hang:
	hlt
	jmp hang				; do nothing.




; disk address packet for reading additional sectors from the disk
disk_access_packet:
db 0x10						; packet size
db 0						; reserved
dw sectors					; sectors to absorb in my scalp
dd 0x7e00					; pointer to place to load it
dq 1						; starting absolute block number




messageWelcome db "Orm BIOS boot" 		; we do a trick to save some space here. newline is next.
newline db 13,10,0
messageDrive db "On disk with ID: 0x", 0

msg_error db "Error: ",0
msg_error_code db ". Code: 0x",0
msg_error_drive db "Failed reading drive", 0
msg_abort db "Boot Abort.", 0

; fill remainder of MBR with zeroes
bytes_free equ 446-($-$$)
TIMES  bytes_free db 0

; partition table! oh no
; we intend on having a single fat32 partition
db 0x80									; we intend this to be the 'active' partition
;64 sectors = 1 head. 255 heads = 1 cylinder
db 0x0									; starting head
dw sectors+2							; starting sector+cylinder
db 0x01									; partition type. 01 = fat12 
db 0x0									; ending head
dw sectors+2+(partition_size_kb*2)		; ending sector+cylinder
dd sectors+1							; starting lba
dd partition_size_kb*2					; sectors in partition

TIMES 48 db 0


; MBR magic number
mbr_magic:
db 0x55
db 0xAA



