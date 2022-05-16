;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Some housekeeping
;; We do this for every project
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.inesprg 1    					  ; Defines the number of 16kb PRG banks
	.ineschr 1    					  ; Defines the number of 8kb CHR banks
	.inesmap 0    					  ; Defines the NES mapper
	.inesmir 1    					  ; Defines VRAM mirroring of banks

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Helper Files and macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.include "assets/nes.h"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.rsset VARLOC					  ; defining where in memory our variables will be located
pointerBackgroundLowByte  .rs 1		  ; .rs directive is used to define how many bytes are allocated to that variable
pointerBackgroundHighByte .rs 1

	.bank 0						  	  ; Add a bank of memory
	.org CPUADR					  	  ; Define where in the CPU’s address space it is located

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; RESET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RESET:
    ; Graphics and Sprites
	JSR LoadBackground				  ; JSR operation will jump to that label, then return here once it is done
	JSR LoadPalettes				  ; Same operation, but for the palettes
	JSR LoadAttributes
    JSR LoadBubble

	LDA #%10000000					  ; Binary 128. Enable NMI, sprites and background on table 0...
	STA PPUCTRL						  ; ...which will use that address $2000 (PPUCTRL) we sent the PPU earlier
	LDA #%00011110					  ; Enables sprites, enable backgrounds—binary 30
	STA PPUMASK						  ; $2001
	LDA #$00						  ; Disable background scrolling
	STA PPUADDR						  ; Writes twice
	STA PPUADDR
	STA PPUSCROLL					  ; Writes twice
	STA PPUSCROLL

InfiniteLoop:
	JMP InfiniteLoop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Subroutines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LoadBackground:
    ; Loading background; 32 bytes of data
	LDA PPUSTATUS					  ; Resets the PPU

	LDA #$20						
	STA PPUADDR						  ; Port to the PPU to tell it where to store the background data
    
	LDA #$00						  ; Because the memory addresses are 2 bytes and we can only send 1 byte at a time
	STA PPUADDR						  ; we have to perform this action twice

	LDA #LOW(background)			  ; Load the low byte of our background data
	STA pointerBackgroundLowByte	  ; and store it
	LDA #HIGH(background)			  ; Take the high byte of our background data
	STA pointerBackgroundHighByte	  ; and store it

    ; The loop itself

	LDX #$00						  ; x = 0x0
	LDY #$00						  ; y = 0x0
.BackgroundLoop:					  ; . denotes a local method
	LDA [pointerBackgroundLowByte],y  ; Load the low byte of our background data, offset by y
	STA PPUDATA						  ; Writing a byte to $2007 (PPUDATA) communicates one graphical tile to the PPU
									  ; so we will need to repeatedly send data to this address until we’re done
	INY								  ; y++
	CPY #$00						  ; Compare y to the value #$00 by using the CPY operation
	BNE .BackgroundLoop

    ; Secondary loop. We do this because we have too much data to send with a single register

	INC pointerBackgroundHighByte
	INX
	CPX #$04
	BNE .BackgroundLoop
	RTS								  ; RTS operation will mark the end of a method and return

LoadPalettes:
    ; Loading palette; 32 bytes of data
	LDA PPUSTATUS					  ; Resets the PPU

	LDA #$3F						  ; This is where the palette data is located on the PPU.
	STA PPUADDR

	LDA #$00						  ; And we perform this operation to fill out the 2 bytes required
	STA PPUADDR

	LDX #$00
.PaletteLoop:
	LDA palettes,x					  ; Load one palette byte into the PPU one at a time (X-offset)
	STA PPUDATA

	INX
	CPX #$20						  ; Keep doing this until #$20, or 32 decimal
	BNE .PaletteLoop

	RTS								  ; No need for inner loop because we are not in danger of overflowing.

LoadAttributes:
    ; Loading attributes; 64 bytes of data
	LDA PPUSTATUS

	LDA #$23						   ; Where attribute data is store in the PPU
	STA PPUADDR
	
	LDA #$C0						   ; PPU stores its attribute data at memory address $23C0
	STA PPUADDR

	LDX #$00
.AttributeLoop:
	LDA attributes,x
	STA PPUDATA

	INX
	CPX #$40							; Keep doing this until #$40, or 64 decimal
	BNE .AttributeLoop
	
	RTS

LoadBubble:
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; The difference with sprite data is that we are not putting it in the PPU, but rather in RAM starting
    ;; at address $0300
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    LDX #$00
.BubbleLoop:
    LDA bubbleSprite,X
    STA $0300,X
    INX
    CPX #$18
    BNE .BubbleLoop
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Interrupt
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
NMI:								  ; Game loop interrupt
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; In order to display the sprites, we have to send them to the PPU—not when we load them, but once per
    ;; frame. This is exactly the NMI does.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    LDA #$00                          ; We load the low byte of the CPU...
    STA OAMADDR                       ; ...into the PPU
    LDA #$03                          ; We load the high byte of the CPU
    STA OAMDMA                        ; ...into the OAM DMA high address

	RTI

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Including our sprite bank files
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.bank 1
	.org IRQRD

background:
	.include "assets/background_addresses.asm"

palettes:
	.include "assets/palettes.asm"

attributes:
	.include "assets/attributes.asm"

bubbleSprite:
    .include "assets/bubble-sprite.asm"

	.org IRQRE
	.dw NMI								; non-maskable interrupt
	.dw RESET
	.dw 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Set up an empty bank which we will load our sprite data to
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.bank 2
	.org $0000
    .incbin "graphics.chr"
    