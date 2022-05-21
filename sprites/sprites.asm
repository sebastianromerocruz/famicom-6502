;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 1. Housecleaning `.ines` directives
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.inesprg 1    					  ; Defines the number of 16kb PRG banks
	.ineschr 1    					  ; Defines the number of 8kb CHR banks
	.inesmap 0    					  ; Defines the NES mapper
	.inesmir 1    					  ; Defines VRAM mirroring of banks

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 2. Helper and macros files
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.include "assets/nes.h"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 3. Variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.rsset VARLOC					  ; defining where in memory our variables will be located
pointerBackgroundLowByte  .rs 1		  ; .rs directive is used to define how many bytes are allocated to that variable
pointerBackgroundHighByte .rs 1

APU_RESET   = $40
STACK_INIT  = $FF
NMI_ENABLE  = %10000000
SPRT_ENBLE  = %00011110
BG_PORT     = $20
PLTTE_PORT  = $3F
PLTTE_SIZE  = $20
ATTR_APORT  = $23
ATTR_BPORT  = $C0
ATTRB_SIZE  = $40
BUBBLE_RAM  = $0300
BUBBLE_SIZE = $18
SPRITE_LOW  = $00
SPRITE_HI   = $03

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 4. Constants
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.bank 0						  	  ; Add a bank of memory
	.org CPUADR					  	  ; Define where in the CPU’s address space it is located

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 5. Reset
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RESET:
	SEI             ; disable IRQs
	CLD             ; disable decimal mode

	LDX #APU_RESET	
	STX CNTRLRTWO   ; disable APU frame IRQ
	LDX #STACK_INIT	
	TXS             ; Set up stack
	INX             ; now X = 0
	STX PPUCTRL     ; disable NMI
	STX PPUMASK     ; disable rendering
	STX DELMODCTRL  ; disable DMC IRQs
	JSR LoadBackground				  ; JSR operation will jump to that label, then return here once it is done
	JSR LoadPalettes				  ; Same operation, but for the palettes
	JSR LoadAttributes
	JSR LoadBubble

	LDA #NMI_ENABLE					  ; Binary 128. Enable NMI, sprites and background on table 0...
	STA PPUCTRL						  ; ...which will use that address $2000 (PPUCTRL) we sent the PPU earlier
	LDA #SPRT_ENBLE					  ; Enables sprites, enable backgrounds—binary 30
	STA PPUMASK						  ; $2001
	LDA #$00						  ; Disable background scrolling
	STA PPUADDR						  ; Writes twice
	STA PPUADDR
	STA PPUSCROLL					  ; Writes twice
	STA PPUSCROLL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 6. Vertical blanks and memory clear
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
VBlankOne:       ; First wait for vblank to make sure PPU is ready
	BIT PPUSTATUS
	BPL VBlankOne

MemClear:
	LDA #$00
	STA $0000, x
	STA $0100, x
	STA $0400, x
	STA $0500, x
	STA $0600, x
	STA $0700, x
	LDA #$FE
	STA $0300, x
	INX
	BNE MemClear
   
VBlankTwo:      ; Second wait for vblank, PPU is ready after this
	BIT PPUSTATUS
	BPL VBlankTwo

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7. Subroutines (load background, palettes, etc.)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
InfiniteLoop:
	JMP InfiniteLoop

LoadBackground:
	LDA PPUSTATUS					  ; Resets the PPU
	LDA #BG_PORT						
	STA PPUADDR						  ; Port to the PPU to tell it where to store the background data
	LDA #$00						  ; Because the memory addresses are 2 bytes and we can only send 1 byte at a time
	STA PPUADDR						  ; we have to perform this action twice

	LDA #LOW(background)			  ; Load the low byte of our background data
	STA pointerBackgroundLowByte	  ; and store it
	LDA #HIGH(background)			  ; Take the high byte of our background data
	STA pointerBackgroundHighByte	  ; and store it

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; The loop itself
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	LDX #$00						  ; x = 0x0
	LDY #$00						  ; y = 0x0
.BackgroundLoop:					  ; . denotes a local method
	LDA [pointerBackgroundLowByte],y  ; Load the low byte of our background data, offset by y
	STA PPUDATA						  ; Writing a byte to $2007 (PPUDATA) communicates one graphical tile to the PPU
									  ; so we will need to repeatedly send data to this address until we’re done
	INY								  ; y++
	CPY #$00						  ; Compare y to the value #$00 by using the CPY operation
	BNE .BackgroundLoop

	INC pointerBackgroundHighByte
	INX
	CPX #$04
	BNE .BackgroundLoop
	RTS								  ; RTS operation will mark the end of a method and return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 8. NMI
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
NMI:								  ; Game loop interrupt
	LDA #SPRITE_LOW
	STA OAMADDR						  ; Sprite low byte
	LDA #SPRITE_HI
	STA SPRITEDMA					  ; Sprite high byte

	RTI

LoadPalettes:
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; Loading palettes; 32 bytes of data
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	LDA PPUSTATUS					  ; Resets the PPU
	LDA #PLTTE_PORT					  ; This is where the palette data is located on the PPU.
	STA PPUADDR

	LDA #$00						  ; And we perform this operation to fill out the 2 bytes required
	STA PPUADDR

	LDX #$00
.PaletteLoop:
	LDA palettes,x					  ; Load one palette byte into the PPU one at a time (X-offset)
	STA PPUDATA
	INX
	CPX #PLTTE_SIZE					  ; Keep doing this until #$20, or 32 decimal
	BNE .PaletteLoop

	RTS								  ; No need for inner loop because we are not in danger of overflowing.

LoadAttributes:
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; Loading attributes; 64 bytes of data
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	LDA PPUSTATUS
	LDA #ATTR_APORT					   ; Where attribute data is store in the PPU
	STA PPUADDR
	
	LDA #ATTR_BPORT					   ; PPU stores its attribute data at memory address $23C0
	STA PPUADDR

	LDX #$00
.AttributeLoop:
	LDA attributes,x
	STA PPUDATA
	INX
	CPX #ATTRB_SIZE						; Keep doing this until #$40, or 64 decimal
	BNE .AttributeLoop
	
	RTS


LoadBubble:
	LDX #$00
.BubbleLoop:
	LDA bubble,x
	STA BUBBLE_RAM,x
	INX
	CPX #BUBBLE_SIZE
	BNE .BubbleLoop
	RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 9. Sprite bank files
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.bank 1
	.org IRQRD

background:
	.include "assets/background_addresses.asm"

palettes:
	.include "assets/palettes.asm"

attributes:
	.include "assets/attributes.asm"

bubble:
	.include "assets/bubble-sprite.asm"

	.org IRQRE
	.dw NMI								; non-maskable interrupt
	.dw RESET
	.dw 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 11. Sprite bank data (chr file)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.bank 2
	.org $0000
    .incbin "graphics.chr"
    