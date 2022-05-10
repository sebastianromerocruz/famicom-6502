;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; NES Game Development Tutorial (Based on Jonathan Moody's tutorial @ https://github.com/jonmoody)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Some housekeeping
;; We do this for every project
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.inesprg 1    		; Defines the number of 16kb PRG banks
	.ineschr 1    		; Defines the number of 8kb CHR banks
	.inesmap 0    		; Defines the NES mapper
	.inesmir 1    		; Defines VRAM mirroring of banks

	.bank 0				; Add a bank of memory
	.org $C000			; Define where in the CPU’s address space it is located

RESET:

InfiniteLoop:
	JMP InfiniteLoop

NMI:
	RTI

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; The CPU has a few memory addresses set aside to define three interrupt vectors (NMI, RESET, and IRQ). 
;; These three vectors will each take up 2 bytes of memory and will be located at the range $FFFA-$FFFF. 
;; We won’t deal with the IRQ now, but just know that it is an interrupt for mappers and audio. 
;; We will just set the IRQ to 0 for now.
;;		- .dw: data word—this is used to define a word, meaning 2 bytes of data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.bank 1
	.org $FFFA
	.dw NMI				; non-maskable interrupt
	.dw RESET
	.dw 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Set up an empty bank which we will eventually add our character data to
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.bank 2
	.org $0000
