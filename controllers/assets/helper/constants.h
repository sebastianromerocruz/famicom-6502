;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Author: Sebastián Romero Cruz ;;
;; Spring 2022                   ;;
;; Constants                     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; APU RESET AND STACK   ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;
APU_RESET   = $40
STACK_INIT  = $FF
NMI_ENABLE  = %10000000
SPRT_ENBLE  = %00011110

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SUBROUTINES           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Background
BG_PORT     = $20

; Palette
PLTTE_PORT  = $3F
PLTTE_SIZE  = $20

; Attributes
ATTR_APORT  = $23
ATTR_BPORT  = $C0
ATTRB_SIZE  = $40

; Sprites
SPRITE_RAM  = $0300
SPRITE_SIZE = $18
SPRITE_LOW  = $00
SPRITE_HI   = $03
NMI_LO_ADDR = OAMADDR
NMI_HI_ADDR = SPRITEDMA

; Controller Input
CTRL_1_PORT = $01
BINARY_ONE  = %00000001
BBLE_TL_Y_1 = $0300
BBLE_TL_Y_2 = $0304
BBLE_TL_Y_3 = $0308
BBLE_TL_Y_4 = $030C
BBLE_TL_Y_5 = $0310
BBLE_TL_Y_6 = $0314
BBLE_TL_X_1 = $0303
BBLE_TL_X_2 = $0307
BBLE_TL_X_3 = $030B
BBLE_TL_X_4 = $030F
BBLE_TL_X_5 = $0313
BBLE_TL_X_6 = $0317