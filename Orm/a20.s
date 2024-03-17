; nasm asm file 
; Orm legacy BIOS bootloader | A20 enable
; ----------------------------------------------------------
; this file contains functions and data used by the second stage of the bootloader
; to enable the A20 line, enabling the processor to use a larger area of memory once protected mode is entered.

; ------ A20enable ------------------------------------------------------------
msg_a20_already db "The A20 line is enabled. No action needed.",13, 10,0
msg_a20_disabled db "The A20 line is disabled.",13, 10, 0
msg_a20_enabling db "Attempting to enable... ",0
msg_a20_fail db "Failed to enable A20.", 0


r_A20enable:

	call r_A20check
	cmp al, 0
	jz A20enable_disabled	;  check to see if it's enabled.

A20enable_enabled:
	mov si, msg_a20_already
	call r_printstr
	ret

A20enable_disabled:
	mov si, msg_a20_disabled
	call r_printstr

    ; Now, actually try and enable the line.
    ; we're just going to be using a bios call to do so.
	mov si, msg_a20_enabling
	call r_printstr

    mov ax, 0x2401 
    int 0x15

    ; check again.
    call r_A20check
	cmp al, 0
	jz A20enable_fail	;  check to see if it's enabled.

A20enable_success:
    mov si, msg_succeed
	call r_printstr
	mov si, newline
	call r_printstr
	ret


A20enable_fail:
	mov si, msg_fail
	call r_printstr
	mov si, newline
	call r_printstr

	push msg_a20_fail
	mov ah, 0
	jmp r_error

	



; ------ A20check ------------------------------------------------
; al - 00 if not enabled, 01 if enabled
A20check_mbrAddr equ 0x7dfe
A20check_mbrWrap equ 0x7e0e

r_A20check:
	mov ax, 0xFFFF
	mov ds, ax
 
	mov si, [ds:A20check_mbrWrap]
	mov ax, 0x0000
	mov ds, ax
	mov di, [ds:A20check_mbrAddr]
	cmp si, di
	jne A20check_enabled				; if the address in high memory and low are the same, 
								; then this could be because A20 is disabled, but it's not certain.
	
	inc di
	mov [ds:A20check_mbrAddr], di
	mov ax, 0xFFFF
	mov ds, ax
	mov si, [ds:A20check_mbrWrap]	
	mov ax, 0x0000
	mov ds, ax

	cmp si, di
	jne A20check_enabled		; we changed low mem, and high mem changed. A20 is enabled
								; if it did not, then we know it's disabled.
A20check_disabled:	
	dec di						
	mov [ds:A20check_mbrAddr], di
	mov al, 0
	ret

A20check_enabled:
	dec di						
	mov [ds:A20check_mbrAddr], di
	mov al, 1
	ret



