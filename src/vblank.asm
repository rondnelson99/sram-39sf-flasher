INCLUDE "defines.asm"
SECTION FRAGMENT "ROM CODE",ROM0
LOAD FRAGMENT "RAM CODE",SRAM
Handle_Vblank::
	ld c, LOW(rP1)
	ld a, $20 ; Select D-pad
	ldh [c], a
REPT 6;apparently you have to read several times to get a consistent reading.
	ldh a, [c]
ENDR
	or $F0 ; Set 4 upper bits (give them consistency)
	ld b, a

	; Filter impossible D-pad combinations
	and $0C ; Filter only Down and Up
	ld a, b
	jp nz, .notUpAndDown
	or $0C ; If both are pressed, "unpress" them
	ld b, a
.notUpAndDown
	and $03 ; Filter only Left and Right
	jp nz, .notLeftAndRight
	; If both are pressed, "unpress" them
	inc b;this will set the bottom 2 bits of B if they were 0.
	inc b
	inc b
.notLeftAndRight
	swap b ; Put D-pad buttons in upper nibble

	ld a, $10 ; Select buttons
	ldh [c], a
REPT 6
	ldh a, [c]
ENDR

	or $F0 ; Set 4 upper bits
	xor b ; Mix with D-pad bits, and invert all bits (such that pressed=1) thanks to both nibbles' "or $F0"
	ld b, a

	; Release joypad
	ld a, $30
	ldh [c], a

	ldh a, [hHeldKeys]
	cpl
	and b
	ldh [hPressedKeys], a
	ld a, b
	ldh [hHeldKeys], a

	xor a
    ldh [rIF],a ;IF needs to be manually cleared after a 'di halt'

    ret
ENDL
SECTION "VBlank HRAM", HRAM
    ; Keys that are currently being held, and that became held just this frame, respectively.
    ; Each bit represents a button, with that bit set == button pressed
    ; Button order: Down, Up, Left, Right, Start, select, B, A
    ; U+D and L+R are filtered out by software, so they will never happen
hHeldKeys:: db
hPressedKeys:: db
    