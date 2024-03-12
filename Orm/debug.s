; nasm asm file 
; Orm legacy BIOS bootloader stage 2
; -----------------------------------------
; real mode debugging 'functions' for Orm's BIOS bootloader.


;----- printword -------------------------------------------------------------------
; prints a word. si is the address of the word to print.

r_printword:
	push si
	inc si
	call r_printbyte
	pop si
	call r_printbyte
	ret




;----- regPrint ----------------------------------------------------------------
; prints contents of registers.  
; example format:

; ax: 0x0000  bx: 0x0000
; cx: 0x0000  dx: 0x0000
; si: 0x0000  di: 0x0000

; sp: 0x0000  bp: 0x0000
; cs: 0x0000  ss: 0x0000
; ds: 0x0000  es: 0x0000

regPrint_msg db "Register Status:", 13, 10, 0
regPrint_msg_regName: db "axbxcxdxsidispbpcsssdses", 0,0
regPrint_msg_fluff: db ": 0x", 0
regPrint_msg_space: db "  ",0
regPrint_i equ (spare_mem+24)


r_regPrint:

    ; We'd like to save 24 bytes of data for all of the registers we care about.
    ; spare mem should be a good place to do that.

    mov [spare_mem], ax
    mov [spare_mem+2], bx
    mov [spare_mem+4], cx
    mov [spare_mem+6], dx
    mov [spare_mem+8], si
    mov [spare_mem+10], di

    mov [spare_mem+12], sp              ; stack pointer is wrong since call got used, 
    mov [spare_mem+14], bp              ; we'll have to add 2 to it to get the correct value.

    mov [spare_mem+16], cs              ; might not be able to do this?           
    mov [spare_mem+18], ss
    mov [spare_mem+20], ds             
    mov [spare_mem+22], es

    ; correct the stack pointer.
    mov ax, [spare_mem+14]
    add ax, 2
    mov [spare_mem+14], ax

    
    ; start the printout!
    mov si, regPrint_msg
    call r_printstr

    mov si, 0
    mov [regPrint_i], si

regPrint_loop:
    ; print the name of a register
    mov bx, regPrint_msg_regName
    mov si, [regPrint_i]

    mov al, [bx+si]                     ; character to print
    
    mov ah, 0x0e                        ; character print code

    mov bh, 0
    int 0x10				; print it

    mov bx, regPrint_msg_regName
    mov si, [regPrint_i]

    mov al, [bx+si+1]                   ; character to print
    
    mov ah, 0x0e                        ; character print code

    mov bh, 0
    int 0x10				; print it

    ; print helpful fluff

    mov si, regPrint_msg_fluff
    call r_printstr

    ; print the contents of the register
    mov si, [regPrint_i]
    add si, spare_mem
    call r_printword

    ; some space
    mov si, regPrint_msg_space
    call r_printstr



    ; increment i
    mov ax, [regPrint_i]
    add ax, 2
    mov [regPrint_i], ax

    add ax, 0x02
    and ax, 0x02
    jz regPrint_loopcheck

    ; newline time
    mov si, newline
    call r_printstr

    ; check if it's time for a blank line. i=12
    mov ax, [regPrint_i]
    cmp ax, 12	
    jne regPrint_loopcheck


    ; newline time
    mov si, newline
    call r_printstr

regPrint_loopcheck:
    mov bx, [regPrint_i]
    mov ax, [bx+regPrint_msg_regName]
    cmp ax, 0
    jnz regPrint_loop

    ; restore registers
    mov ax, [spare_mem]
    mov bx, [spare_mem+2]
    mov cx, [spare_mem+4]
    mov dx, [spare_mem+6]
    mov si, [spare_mem+8]
    mov di, [spare_mem+10]

    mov bp, [spare_mem+14]             

    ; I don't think sectors change.


    ret


;----- printchar ----------------------------------------------------------------
; prints a character. al should contain the character.
r_printchar:
	mov ah, 0x0e
	mov bl, 0
	int 0x10
	ret


;----- miniDump ----------------------------------------------------------------
; prints 16 bytes of memory.
; si should contain a pointer to the location read from.


r_miniDump:

	push si				; start by printing the address.		
	mov si, [si]
	call r_printword

	mov al, ':'
	call r_printchar

	mov al, ' '
	call r_printchar

	push 0
	mov bp, sp

miniDump_loop:
	
	mov si, [bp+2]
	mov bx, [bp]
	add si, bx
	call r_printbyte

	mov si, [bp+2]
	mov bx, [bp]
	add si, bx
	inc si
	call r_printbyte

	mov al, ' '
	call r_printchar

	mov ax, [bp]			; increment counter
	add ax, 2
	mov [bp], ax

	cmp ax, 16
	jne miniDump_loop
	
	mov si, newline			; print a new line before returning
	call r_printstr

	add sp, 4
	ret
