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
    ld hl, $9942 ;start of first row
    ld de, 16 ;offset between the rows
.rowLoop
    ld c, 16/4;write 4 at once
.memsetLoop
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    dec c
    jr nz, .memsetLoop

    add hl, de
    dec b
    jr nz,.rowLoop
    ret

ResetTilemapAfterButtonPress::
    call WaitAndHandleVblank
    ld b,b
    ldh a, [hPressedKeys]
    or a;is it 0? have any keys been pressed?
    jr z, ResetTilemapAfterButtonPress;if not, wait for next time
    call ClearLowerScreen;we need to wait a frame now because otherwise Vblank runs out.
    call WaitVblank
    ld de, LowerStrings
    ld c, 4;4strings
    call Multiple_Strcpy
    ret

LowerStrings::
    dw $9943
    db "A:DOWNLOAD ROM",$FF
    dw $9983
    db "SELECT:BURN",$FF
    dw $99A4
    db "BOOTLOADER",$FF
    dw $99E3
    db "B:EXIT TO ROM",$FF

ENDL

