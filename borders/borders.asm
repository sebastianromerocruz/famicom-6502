;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 1. Housecleaning `.ines` directives
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .inesprg 1
    .ineschr 1
    .inesmap 0
    .inesmir 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 2. Helper and macros files
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .include "assets/helper/addresses.h"
    .include "assets/helper/constants.h"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 3. Variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .rsset VARLOC
pointerBackgroundLowByte    .rs 1
pointerBackgroundHighByte   .rs 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 4. Constants
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 5. Reset
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .bank 0
    .org CPUADR

RESET:
    ;; Houseclearning
    SEI
    CLD

    ;; Disable PPU
    LDX APU_RESET
    STX CNTRLRTWO

    ;; Initialise stack
    LDX STACK_INIT
    TXS                     ; transfer X to stack pointer

    ;; Disable NMI, PPU Mask, and DMC IRQ
    INX                     ; x = 0
    STX PPUCTRL
    STX PPUMASK
    STX DELMODADDR

    ;; Subroutines
    JSR LoadBackground
    JSR LoadAttributes
    JSR LoadPalettes
    JSR LoadSprites

    ;; Enable NMI
    LDA #NMI_ENABLE
    STA PPUCTRL

    ;; Enable PPU Mask
    LDA #SPRT_ENBLE
    STA PPUMASK

    ;; Disable scrolling
    LDA #$00
    STA PPUADDR
    STA PPUADDR
    STA PPUSCROLL
    STA PPUSCROLL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 6. Vertical blanks and memory clear
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
VBlankOne:
    BIT PPUSTATUS
    BPL VBlankOne

ClearMem:
    LDA #$00
    STA $0100,X
    STA $0200,X
    STA $0400,X
    STA $0500,X
    STA $0600,X
    STA $0700,X
    LDA #$FE
    STA $0300,X
    
    INX
    BNE ClearMem

VBlankTwo:
    BIT PPUSTATUS
    BPL VBlankTwo

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7. Subroutines (load background, palettes, etc.)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
InfiniteLoop:
    JMP InfiniteLoop

LoadBackground:
    ;; Reset PPU
    LDA PPUSTATUS

    ;; Tell the PPU where to load data (do it twice for necessary 2 bytes)
    LDA #BG_PORT
    STA PPUADDR
    LDA #$00
    STA PPUADDR

    ;; Load the low and high bytes of the background into our variables
    LDA #LOW(background)
    STA pointerBackgroundLowByte
    LDA #HIGH(background)
    STA pointerBackgroundHighByte

    ;; Loop through the background memory banks
    LDX #$00
    LDY #$00
.Loop:
    ;; Store that current byte into the PPU
    LDA [pointerBackgroundLowByte],Y
    STA PPUDATA

    ;; Keep y++ until overflow
    INY
    CPY #$00
    BNE .Loop

    ;; Keep x++ until .Loop iterates four times to cover the necessary bytes (1024)
    INC pointerBackgroundHighByte
    INX
    CPX #$04
    BNE .Loop

    ;; Once done, return
    RTS

LoadAttributes:
    ;; Reset the PPU
    LDA PPUSTATUS

    ;; Tell the PPU where the attribute ports ($23C0) are
    LDA #ATTR_APORT
    STA PPUADDR
    LDA #ATTR_BPORT
    STA PPUADDR

    ;; And load the data with a loop
    LDX #$00
.Loop:
    ;; Load that current byte
    LDA attributes,X
    STA PPUDATA

    ;; And continue x++ until we cover the entire bank
    INX
    CPX #ATTRB_SIZE
    BNE .Loop

    ;; And return
    RTS

LoadPalettes:
    ;; Reset the PPU
    LDA PPUSTATUS

    ;; Tell PPU where to load palette data too; remember to do twice since it's a 16-bit address
    LDA #PLTTE_PORT
    STA PPUADDR
    LDA #$00
    STA PPUADDR

    ;; And load the data with a loop
    LDX #$00
.Loop:
    ;; Loop the current byte
    LDA palettes,X
    STA PPUDATA

    ;; Until we cover the entire palette bank (32 bytes)
    INX
    CPX #PLTTE_SIZE
    BNE .Loop

    ;; Return
    RTS

LoadSprites:
    ;; We don't need to reset the PPU, since we don't load the sprites directly to it
    LDX #$00
.Loop:
    LDA sprites,X
    STA SPRITE_RAM,X

    INX
    CPX #SPRITE_SIZE
    BNE .Loop

    RTS

ReadPlayerOneControls:
    ;; Activate player one controls—twice for 16-bit instruction
    LDA #CTRL_1_PORT
    STA CNTRLRONE
    LDA #$00
    STA CNTRLRONE

    ;; Load A, B, Select, and Start buttons
    LDA CNTRLRONE
    LDA CNTRLRONE
    LDA CNTRLRONE
    LDA CNTRLRONE

ReadUp:
    LDA CNTRLRONE
    AND #BINARY_ONE
    BEQ EndReadUp

    ;; First row
    LDA BBLE_TL_Y_1
    SEC
    SBC #$01

    ;; Check for border collision
    CMP #BRDR_UP_LFT
    BCC EndReadUp

    STA BBLE_TL_Y_1
    STA BBLE_TL_Y_2
    STA BBLE_TL_Y_3

    ;; Second row
    LDA BBLE_TL_Y_4
    SEC
    SBC #$01
    STA BBLE_TL_Y_4
    STA BBLE_TL_Y_5
    STA BBLE_TL_Y_6
EndReadUp:

ReadDown:
    LDA CNTRLRONE
    AND #BINARY_ONE
    BEQ EndReadDown

    LDA BBLE_TL_Y_4
    CLC
    ADC #$01

    ;; Check for border collision
    CMP #BORDER_DOWN
    BEQ EndReadDown
    
    STA BBLE_TL_Y_4
    STA BBLE_TL_Y_5
    STA BBLE_TL_Y_6

    LDA BBLE_TL_Y_1
    CLC
    ADC #$01
    STA BBLE_TL_Y_1
    STA BBLE_TL_Y_2
    STA BBLE_TL_Y_3
EndReadDown:

ReadLeft:
    LDA CNTRLRONE
    AND #BINARY_ONE
    BEQ EndReadLeft
    
    LDA BBLE_TL_X_1
    SEC
    SBC #$01

    ;; Check for border collision
    CMP #BRDR_UP_LFT
    BCC EndReadLeft

    STA BBLE_TL_X_1
    STA BBLE_TL_X_4

    LDA BBLE_TL_X_2
    SEC
    SBC #$01
    STA BBLE_TL_X_2
    STA BBLE_TL_X_5

    LDA BBLE_TL_X_3
    SEC
    SBC #$01
    STA BBLE_TL_X_3
    STA BBLE_TL_X_6 
EndReadLeft:

ReadRight:
    LDA CNTRLRONE
    AND #BINARY_ONE
    BEQ EndReadRight

    LDA BBLE_TL_X_3
    CLC
    ADC #$01

    ;; Check for border collision
    CMP #BORDER_RGHT
    BEQ EndReadRight

    STA BBLE_TL_X_3
    STA BBLE_TL_X_6

    LDA BBLE_TL_X_1
    CLC
    ADC #$01
    STA BBLE_TL_X_1
    STA BBLE_TL_X_4

    LDA BBLE_TL_X_2
    CLC
    ADC #$01
    STA BBLE_TL_X_2
    STA BBLE_TL_X_5
EndReadRight:

    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 8. NMI
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
NMI:
    ;; Load the low and high sprite bytes to their respective addresses
    LDA #SPRITE_LOW
    STA NMI_LO_ADDR

    LDA #SPRITE_HI
    STA NMI_HI_ADDR

    JSR ReadPlayerOneControls

    RTI

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 9. Sprite bank files
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .bank 1
    .org IRQRD

background:
    .include "assets/banks/background.asm"

attributes:
    .include "assets/banks/attributes.asm"

palettes:
    .include "assets/banks/palettes.asm"

sprites:
    .include "assets/banks/bubble.asm"

    .org IRQRE
    .dw NMI
    .dw RESET
    .dw 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 10. Sprite bank data (chr file)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .bank 2
    .org $0000
    .incbin "assets/sprites/graphics.chr"