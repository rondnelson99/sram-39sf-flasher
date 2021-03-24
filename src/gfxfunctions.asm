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