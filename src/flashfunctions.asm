INCLUDE "defines.asm"
SECTION "Flash Functions ROM",ROM0
LOAD "Flash Functions",SRAM
ChipErase::;send the chip-erase command sequence
    ld hl,$5555 ;chip-erase command sequence
    ld de,$2AAA
    ld [hl],e;[$5555]<-$AA
    ld a,l
    ld [de],a;[$2AAA]<-$55
    ld [hl], $80;[$5555]<-$80
    ld [hl],e;[$5555]<-$AA
    ld [de],a;[$2AAA]<-$55
    ld [hl], $10;[$5555]<-$10
    ;very efficient, but clobbers everything except BC

    ld de,10000; timeout for the erase. I think this is above the max chip-erase time.
.checkEraseCompletion
    ld a, [$100]; this is in rom, so we can use it for Data Polling
    ;if the erase has finished, this should be $FF.
    inc a ;so this would set the z flag
    ret z
    dec de;decrement the timer
    ld a, e
    or d
    jr nz, .checkEraseCompletion
    ; if the timeout has triggered, fall through
    xor a
    ldh [rIF],a ;zero interrupt requests before halt to wait for the next Vblank
    halt ;wait for vBlank
    call Handle_Vblank
    ld hl,$9984 ;above the progress bar, one char to the right to make it centered
    ld de,.eraseFailedString
    call Strcpy
    pop de;pop off whatever program operation called the erase
    ret;return to the main loop
.eraseFailedString
    db "ERASE FAILED",$ff ;using ff-terminated strings so that null can be space.
ENDL