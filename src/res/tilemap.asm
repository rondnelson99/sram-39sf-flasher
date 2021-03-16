
	newcharmap crash_handler
CHARS equs "0123456789ABCDEF-GHIJKLMNOPQR:SUVWXYZabcdefghijklmnopqrTstuvwxyz! "
CHAR = 0
REPT STRLEN("{CHARS}")
	charmap STRSUB("{CHARS}", CHAR + 1, 1), CHAR
CHAR = CHAR + 1
ENDR
SECTION "chars", ROM0[0]
    REPT 2
    db 0
    ENDR
    db 5,6,7,8
    REPT 32-6
    db 0
    ENDR
    db 9,10,11,12,13,14
    REPT (160/8)-6-1
    db 10
    ENDR
    db 15
    REPT (144/8)-3
    REPT 32-(160/8)
    db 0
    ENDR
    db 16
    

