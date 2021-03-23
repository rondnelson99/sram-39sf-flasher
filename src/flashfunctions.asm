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
    ld a, [hl]; this is in rom, so we can use it for Data Polling
    ;if the erase has finished, this should be $FF.
    inc a ;so this would set the z flag
    ret z
    dec de;decrement the timer
    ld a, e
    or d
    jr nz, .checkEraseCompletion
    ; if the timeout has triggered, fall through
    halt ;wait for vBlank
    ld b,b
ENDL