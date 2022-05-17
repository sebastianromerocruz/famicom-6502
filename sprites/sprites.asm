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
;; CONSTANTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
APUDISABLE = #$40
APUDISADDR = $4017
DMCCHANDIS = $4010 ; disable APU DMC channel

STACKINIT  = #$FF

NMIENABLER = #%10000000               ; Binary 128. Enable NMI, sprites and background on table 0...
SPRENABLER = #%00011110               ; Enables sprites, enable backgrounds—binary 30

BGLOOPCNTR = #$04

PALETTELOC = #$3F
PALETTEBYT = #$20

ATTRIBLOC1 = #$23
ATTRIBLOC2 = #$C0
ATTRIBUBYT = #$40

BUBBLELOC  = $0300
BUBBLEBYTE = #$18

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; RESET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RESET:
	SEI                               ; disable IRQs
	CLD                               ; disable decimal mode

    ; Disable APU frame IRQ
	LDX APUDISABLE	
	STX APUDISADDR

    ; Set up stack
	LDX STACKINIT
	TXS                               ; X = #$FF

	INX                               ; now X = 0
	STX PPUCTRL                       ; disable NMI
	STX PPUMASK                       ; disable rendering
	STX DMCCHANDIS                    ; disable DMC IRQs

    ; Graphics and Sprites
	JSR LoadBackground				  ; JSR operation will jump to that label, then return here once it is done
	JSR LoadPalettes				  ; Same operation, but for the palettes
	JSR LoadAttributes
    JSR LoadBubble

	LDA NMIENABLER
	STA PPUCTRL						  ; ...which will use that address $2000 (PPUCTRL) we sent the PPU earlier

	LDA SPRENABLER					  ; 
	STA PPUMASK						  ; $2001; Controls the rendering of sprites and backgrounds, as well as colour effects.

	LDA #$00						  ; Disable background scrolling
	STA PPUADDR						  ; Writes twice
	STA PPUADDR
	STA PPUSCROLL					  ; Writes twice
	STA PPUSCROLL

	BIT PPUSTATUS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Vertical Blanks and Memory Clear
;; 
;; We now have about 30,000 cycles to burn before the PPU stabilizes.
;; One thing we can do with this time is put RAM in a known state.
;; Here we fill it with $00, which matches what (say) a C compiler
;; expects for BSS.  Conveniently, X is still 0.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
@VBlankWait1:                          ; First wait for vblank to make sure PPU is ready
	BIT PPUSTATUS					   ; Clear the VBL flag if it was set at reset time
	BPL VBlankWait1					   ; At this point, about 27384 cycles have passed

@ClrMem:
	LDA #$00
	STA $0000,x
	STA $0100,x
	STA $0200,x
	STA $0400,x
	STA $0500,x
	STA $0600,x
	STA $0700,x
	LDA #$FE				 		   ; $0300 - $07FF is RAM
	STA $0300,x
	INX
	BNE ClrMem
   
@VBlankWait2:                          ; Second wait for vblank, PPU is ready after this
	BIT PPUSTATUS
	BPL VBlankWait2					   ; At this point, about 57165 cycles have passed

InfiniteLoop:
	JMP InfiniteLoop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Subroutines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LoadBackground:
    ; Loading background; {} bytes of data
	LDA PPUSTATUS					  ; Resets the PPU

	LDA PPUCTRL						
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

    ; Secondary loop. We do have to repeat 4 times (BGLOOPCNTR) because we have too much data to send with a single register

	INC pointerBackgroundHighByte
	INX
	CPX BGLOOPCNTR
	BNE .BackgroundLoop
	RTS								  ; RTS operation will mark the end of a method and return

LoadPalettes:
    ; Loading palette; 32 bytes of data
	LDA PPUSTATUS					  ; Resets the PPU

	LDA PALETTELOC					  ; This is where the palette data is located on the PPU.
	STA PPUADDR

	LDA #$00						  ; And we perform this operation to fill out the 2 bytes required
	STA PPUADDR

	LDX #$00
.PaletteLoop:
	LDA palettes,x					  ; Load one palette byte into the PPU one at a time (X-offset)
	STA PPUDATA

	INX
	CPX PALETTEBYT				      ; Keep doing this until #$20, or 32 decimal
	BNE .PaletteLoop

	RTS								  ; No need for inner loop because we are not in danger of overflowing.

LoadAttributes:
    ; Loading attributes; 64 bytes of data
	LDA PPUSTATUS

	LDA ATTRIBLOC1					  ; Where attribute data is store in the PPU
	STA PPUADDR
	
	LDA ATTRIBLOC2					  ; PPU stores its attribute data at memory address $23C0
	STA PPUADDR

	LDX #$00
.AttributeLoop:
	LDA attributes,x
	STA PPUDATA

	INX
	CPX ATTRIBUBYT			   		  ; Keep doing this until #$40, or 64 decimal
	BNE .AttributeLoop
	
	RTS

LoadBubble:
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; The difference with sprite data is that we are not putting it in the PPU, but rather in RAM starting
    ;; at address $0300 (24 bytes of data)
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    LDX #$00
.BubbleLoop:
    LDA bubbleSprite,X
    STA BUBBLELOC,X
    INX
    CPX BUBBLEBYTE
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
    LDA BUBBLELOC                     ; We load the high byte of the CPU
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
    