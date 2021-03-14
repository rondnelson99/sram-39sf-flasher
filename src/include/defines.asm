INCLUDE "hardware.inc/hardware.inc"
; `ld b, X` followed by `ld c, Y` is wasteful (same with other reg pairs).
; This writes to both halves of the pair at once, without sacrificing readability
; Example usage: `lb bc, X, Y`
lb: MACRO
	assert -128 <= (\2) && (\2) <= 255, "Second argument to `lb` must be 8-bit!"
	assert -128 <= (\3) && (\3) <= 255, "Third argument to `lb` must be 8-bit!"
	ld \1, ((\2) << 8) | (\3)
ENDM
