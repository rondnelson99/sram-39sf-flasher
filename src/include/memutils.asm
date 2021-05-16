Multiple_Strcpy::;copy C destination prefixed strings from de
    ld a, [de]
    inc de
    ld l, a
    ld a, [de]
    inc de
    ld h, a
    call Strcpy
    dec c
    jr nz, Multiple_Strcpy
    ret

StrcpyAboveProgressBar::
    ld hl,$9983 ;above the progress bar
Strcpy:: ;copy an FF-terminated string from de to hl
    ld a, [de]
    inc de

    inc a;if a is $ff, ret. Otherwise, restore it to its old value.
    ret z
    dec a

    ld [hl+], a
    jr Strcpy
