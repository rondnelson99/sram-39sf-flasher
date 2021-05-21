
SectorErase::;send the sector-erase command sequence
    ld hl,$5555 ;sector-erase command sequence
    ld de,$2AAA
    ld [hl],e;[$5555]<-$AA
    ld a,l
    ld [de],a;[$2AAA]<-$55
    ld [hl], $80;[$5555]<-$80
    ld [hl],e;[$5555]<-$AA
    ld [de],a;[$2AAA]<-$55
    ld a, $30;[$5555]<-$30
    ld [$0000],a ;erase the first sector
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
    
    call WaitAndHandleVblank

    ld de,EraseFailedString
    call StrcpyAboveProgressBar
    pop de;pop off whatever program operation called the erase
    jr ResetTilemapAfterButtonPress


FlashByteProgram::;write a to the flash, but don't do anything fancy like checking if it worked.
    ld b,a;we need a to send the command sequence so back it up at the expense of destroying b.
    
    ld a,$AA;18 cycles, 15 bytes
    ld [$5555],a
    cpl ;ld a,$55
    ld [$2AAA],a
    ld a, $A0
    ld [$5555],a;send the command seuence

    ld [hl], b ;and do the write
    ld a, b
    ret

EraseFailedString:
    db " ERASE FAILED ",$ff ;using ff-terminated strings so that null can be space.
ProgramDoneString:
    db " PROGRAM DONE ",$FF
ProgramString:
    db " PROGRAMMING  ",$FF;include spaces to cover the whole area

ProgramFailedString:
    db "PROGRAM FAILED",$FF