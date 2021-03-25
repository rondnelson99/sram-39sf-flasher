INCLUDE "hardware.inc/hardware.inc"
; `ld b, X` followed by `ld c, Y` is wasteful (same with other reg pairs).
; This writes to both halves of the pair at once, without sacrificing readability
; Example usage: `lb bc, X, Y`
CHARS equs " 1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ"
CHAR = 0
REPT STRLEN("{CHARS}")
	charmap STRSUB("{CHARS}", CHAR + 1, 1), CHAR
CHAR = CHAR + 1
ENDR

lb: MACRO
	assert -128 <= (\2) && (\2) <= 255, "Second argument to `lb` must be 8-bit!"
	assert -128 <= (\3) && (\3) <= 255, "Third argument to `lb` must be 8-bit!"
	ld \1, ((\2) << 8) | (\3)
ENDM

MemsetSmall: MACRO
.loop\@
	ld [hl+], a
	dec c
	jr nz, .loop\@
ENDM