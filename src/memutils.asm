SECTION FRAGMENT "ROM CODE",ROM0
LOAD FRAGMENT "RAM CODE",SRAM
Strcpy:: ;copy an FF-terminated string from de to hl
    ld a, [de]
    inc de

    inc a;if a is $ff, ret. Otherwise, restore it to its old value.
    ret z
    dec a

    ld [hl+], a
    jr Strcpy

ENDL