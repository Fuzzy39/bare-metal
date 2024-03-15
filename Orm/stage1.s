; nasm asm file	
; Orm legacy BIOS bootloader stage 1.
; ----------------------------------------------------------
; this is the master boot record for use by Orm, an OS that plays a game of snake.
; the program here prints a welcome message and  attempts to load the 
; stage 2 bootloader. It is not robust, and wastes a lot of space
; on various messages that it can print in error situations.


BITS 16

org 0x7c00


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
	

; ----- Prepare to get more secctors ------------------------------------------------------

	; let's try to figure out disk io now I guess.
	
	; step one: are int 13h extensions enabled? If not we give up and croak
	
	mov ah, 0x41				; check if enabled
	mov bx, 0x55aa				; magic number
	mov dl, [driveBooted]			; drive
	
	int 0x13				; carry should be cleared
	
	jnc drive_ext_installed
	

	push msg_error_13ext			; error out and give up.
	mov ah, 0
	jmp r_error


drive_ext_installed:
	
	
	; print a message, because I want to.
	mov si, messageDrive
	call r_printstr

	mov si, driveBooted
	call r_printbyte
	
	mov si, newline
	call r_printstr
	



	; Next we get info about the disk.
	mov ah, 0x48				; GET DRIVE PARAMETERS
	mov dl, [driveBooted]		
	mov si, spare_mem

	mov word [si], 0x0042				; size of buffer

	int 0x13

	jnc got_drive_params

	; error!
	push msg_error_driveParams
	jmp r_error

got_drive_params:

	; check that sector size is equal to 512

	


	mov ax, [spare_mem+0x18]
	cmp ax, 512
	je get_sectors

	; the sector size is wrong, so we'll print it out.
	; barely enough space for this, so hopefully if somebody encounters this 
	; they would be able to guess what it's for
	mov si, spare_mem+0x19
	call r_printbyte
	dec si
	call r_printbyte
	mov si, newline
	call r_printstr

	mov ah, 0
	push msg_error_sectorLen
	jmp r_error

; ----- Get more sectors ------------------------------------------------------


get_sectors:

	; now we can try to read things from disk. supposedly.
	mov ah, 0x42
	mov si, disk_access_packet
	
	int 0x13
	
	; check if worked
	jnc stage2_entry			; If We succeded, we can now bail to stage 2.
	
	; print an error message.
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


sectors equ 2

; disk address packet for reading additional sectors from the disk
disk_access_packet:
db 0x10						; packet size
db 0						; reserved
dw sectors					; sectors to absorb in my scalp
dd 0x7e00					; pointer to place to load it
dq 1						; starting absolute block number




messageWelcome db "Orm BIOS MBR boot" 		; we do a trick to save some space here. newline is next.
newline db 13,10,0
messageDrive db "On disk with ID: 0x", 0

msg_error db "Err: ",0
msg_error_code db ". Code: 0x",0
msg_error_13ext db "Interrupt 13h ext. are not supported.", 0
msg_error_drive db "Failed reading drive", 0
msg_error_driveParams db "Failed getting drive info",0
msg_error_sectorLen db "Sector not 512 bytes.", 0
msg_abort db "Boot Abort", 0

; fill remainder of MBR with zeroes
bytes_free equ 446-($-$$)
TIMES  bytes_free db 0

; partition table which we currently don't care about
TIMES 64 db 0


; MBR magic number
mbr_magic:
db 0x55
db 0xAA



