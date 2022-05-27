;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Author: Sebastián Romero Cruz                                                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 1. Housecleaning `.ines` directives
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .inesprg 1
    .ineschr 1
    .inesmap 0
    .inesmir 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 2. Helper and macros files
;; 3. Constants
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .include "assets/helper/addresses.h"
    .include "assets/helper/constants.h"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 4. Variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .rsset VARLOC
pointerBackgroundLowByte    .rs 1
pointerBackgroundHighByte   .rs 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 5. Reset
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .bank 0
    .org CPUADR

RESET:
    ;; Housecleaning
    SEI             ; disable interrupts
    CLD             ; clear decimal mode

    ;; Disable PPU
    LDX APU_RESET
    STX CNTRLRTWO

    ;; Initialise stack
    LDX STACK_INIT
    TXS

    ;; Disable other things
    INX             ; x = 0
    STX PPUCTRL     ; disable NMI
    STX PPUMASK     ; disable sprite rendering
    STX DELMODADDR  ; disable DMC IRQs

    ;; Start subroutines
    JSR LoadBackground
    JSR LoadAttributes
    JSR LoadPalettes
    JSR LoadBubble

    ;; Enable NMI
    LDA #NMI_ENABLE
    STA PPUCTRL

    ;; Enable sprite rendering
    LDA #SPRT_ENBLE
    STA PPUMASK

    ;; Disable scrolling for now
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

;; Load background
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

;; Load palettes
LoadPalettes:
    ;; Reset PPU
    LDA PPUSTATUS

    ;; Tell PPU where to load palette data too; remember to do twice
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

    ;; Afterward, return
    RTS

;; Load attribute data
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

;; Load bubble sprite
LoadBubble:
    ;; We don't need to reset PPU, since we don't load sprites directly into it
    LDX #$00
.Loop:
    ;; Load and store the current bubble sprice into its appropriate place in RAM
    LDA bubble,X
    STA SPRITE_RAM,X

    ;; And keep x++ until we cover all of them
    INX
    CPX #SPRITE_SIZE
    BNE .Loop

    ;; And return
    RTS

;; Read controller one input
ReadPlayerOneControls:
    ;; Twice for the instruction
    LDA #CTRL_1_PORT
    STA CNTRLRONE
    LDA #$00
    STA CNTRLRONE

    ;; Buttons are read from the same register, but in a fixed order:
    ;;  1. A
    LDA CNTRLRONE
    ;;  2. B
    LDA CNTRLRONE
    ;;  3. Select
    LDA CNTRLRONE
    ;;  4. Start
    LDA CNTRLRONE

    ;;  5. Up
ReadUp:
    LDA CNTRLRONE
    AND #BINARY_ONE     ; Performing an AND operation with binary 1 will tell us if the button was pressed (1) or not (0)
    BEQ EndReadUp       ; If we don’t use a CMP operation before BEQ, it will branch if the value is equal to zero.

    ;; If the button was pressed:
    ; Load the first tile of the first row of tiles
    LDA BBLE_TL_Y_1
    ; Set carry for possible subtraction
    SEC
    ; Move down by 1
    SBC #$01
    ; And store the result in the first row of tiles
    STA BBLE_TL_Y_1
    STA BBLE_TL_Y_2
    STA BBLE_TL_Y_3

    ; Load the first tile of the second row of tiles
    LDA BBLE_TL_Y_4
    ; And repeat...
    SEC
    SBC #$01
    STA BBLE_TL_Y_4
    STA BBLE_TL_Y_5
    STA BBLE_TL_Y_6
EndReadUp:

    ;;  6. Down
ReadDown:
    LDA CNTRLRONE
    AND #BINARY_ONE
    BEQ EndReadDown

    LDA BBLE_TL_Y_1
    CLC
    ADC #$01
    STA BBLE_TL_Y_1
    STA BBLE_TL_Y_2
    STA BBLE_TL_Y_3

    LDA BBLE_TL_Y_4
    CLC
    ADC #$01
    STA BBLE_TL_Y_4
    STA BBLE_TL_Y_5
    STA BBLE_TL_Y_6
EndReadDown:

    ;;  7. Left
ReadLeft:
    ; Check for button press, otherwise end
    LDA CNTRLRONE
    AND #BINARY_ONE
    BEQ EndReadLeft

    ; If press:
    ;   - First column of tiles
    LDA BBLE_TL_X_1
    SEC
    SBC #$01
    STA BBLE_TL_X_1
    STA BBLE_TL_X_4

    ;   - Second column of tiles
    LDA BBLE_TL_X_2
    SEC
    SBC #$01
    STA BBLE_TL_X_2
    STA BBLE_TL_X_5

    ;   - Third column of tiles
    LDA BBLE_TL_X_3
    SEC
    SBC #$01
    STA BBLE_TL_X_3
    STA BBLE_TL_X_6
EndReadLeft:

    ;;  8. Right
ReadRight:
    ; Check for button right press, otherwise end
    LDA CNTRLRONE
    AND #BINARY_ONE
    BEQ EndReadRight

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

    LDA BBLE_TL_X_3
    CLC
    ADC #$01
    STA BBLE_TL_X_3
    STA BBLE_TL_X_6
EndReadRight:

    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 8. NMI; load our sprites
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
NMI:
    ;; Load and store the low sprite byte
    LDA #SPRITE_LOW
    STA NMI_LO_ADDR

    ;; Load and store the high sprite byte
    LDA #SPRITE_HI
    STA NMI_HI_ADDR

    ;; Read (and use) player input
    JSR ReadPlayerOneControls

    ;; And return from interrupt
    RTI

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 9. Sprite bank files
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; Allocate a bank for our bytes
    .bank 1
    .org IRQRD

background:
    .include "assets/banks/background.asm"

palettes:
    .include "assets/banks/palettes.asm"

attributes:
    .include "assets/banks/attributes.asm"

bubble:
    .include "assets/banks/bubble.asm"

    ;; Housekeeping vectors
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