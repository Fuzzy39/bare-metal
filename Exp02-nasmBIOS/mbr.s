; nasm assembly [EXP 02]
; Make a MBR that hangs

BITS 16

org 0x7c00

entry:
	;mov ax, 0			; make sure our registers are handled right
	;mov cs, ax
					
	cli				; disable maskable interrupts by clearing a flag
hang:
	jmp hang
	
						

; fill remainder of MBR with zeroes
TIMES 510-($-$$) db 0

; MBR magic number
db 0x55
db 0xAA

