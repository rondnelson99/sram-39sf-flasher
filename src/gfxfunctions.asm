INCLUDE "defines.asm"
SECTION FRAGMENT "ROM CODE",ROM0
LOAD FRAGMENT "RAM CODE",SRAM

InitProgressBar::
    ld de, $99C2 ;left edge of progress bar
    ld hl, .progressBarMap
INCLUDE "res/progressbar.tilemap.pb8.size"
    ld c, NB_PB8_BLOCKS 
PURGE NB_PB8_BLOCKS
    call UnPB8
    ret
.progressBarMap
INCBIN "res/progressbar.tilemap.pb8"

ClearLowerScreen::
    xor a
    ld b,6;six rows to clear
    ld hl, $9943 ;start of first row
    ld de, 18 ;offset between the rows
.rowLoop
    ld c, 14
    MemsetSmall
    add hl, de
    dec b
    jr nz,.rowLoop
    ret

