bubbleSprite:
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; Our bubble player consists of 6 tiles (24 bytes). Below, each tile consists of 4 bytes of data:
	;;	1. Vertical screen position (top left corner)
	;;	2. Graphical tile (hex value of the tile in the sprite sheet)
	;;	3. Attributes (%76543210):
	;;		- Bits 0 and 1 are for the colour palette
	;;		- Bits 2, 3, and 4 are not used
	;;		- Bit 5 is priority (0 shows the sprite in front of the background, and 1 displays it
	;;		  behind it)
	;;		- Bit 6 flips the sprite horizontally (0 is normal, 1 is flipped)
	;;		- Bit 7 flips the sprite vertically (0 is normal, 1 is flipped)
	;;	4. Horizontal screen position (top left corner)
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.db $80, $0A, %00000000, $80
	.db $80, $0B, %00000000, $88
	.db $80, $0C, %00000000, $90
	.db $88, $0A, %10000000, $80
	.db $88, $0B, %10000000, $88
	.db $88, $0C, %10000000, $90

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; The last three bytes would be as follows if we weren't taking advantage of the bubble's 
	;; symmetry.
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; .db $88, $0D, %00000000, $80
	; .db $88, $0E, %00000000, $88
	; .db $88, $0F, %00000000, $90