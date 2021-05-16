
FlashBootstrapRom::;it should still be Vblank when this gets called
    call ClearLowerScreen
    call InitProgressBar
    ld de,.programString
    call StrcpyAboveProgressBar

    call ChipErase

    call WaitAndHandleVblank
    ld a, $3E ;tile number for filled in proress bar
    ld [$99C3],a;fill in the first bit of the bar to show that the erase has completed

    ld de, BootstrapRom
    ld hl, $100 ;area to be flashed
    ld c, BootstrapRomEnd-BootstrapRom
.flashBootstrapRomByte
    ld a, [de]
    inc de
    call FlashByteProgram

    ld b, 3;give it a little time to fully program
.checkprogramloop
    cp [hl]
    jp z,.doneByte
    dec b
    jr nz, .checkprogramloop
    ;fall through if b runs out
    
    call WaitAndHandleVblank
    
    ld de,.programFailedString
    call StrcpyAboveProgressBar
    jp ResetTilemapAfterButtonPress

.doneByte
    inc hl
    dec c
    jr nz,.flashBootstrapRomByte
    ;if we make it here then we're done programming, but first let's update the progress bar.
    call WaitAndHandleVblank
    ld a, $3E ;tile index of the filled bar
    ld hl, $99C3; start of the bar
    ld c, $99D1 - $99C3 ;length of the bar
    MemsetSmall
    ld de, .programDoneString
    call StrcpyAboveProgressBar
    
    jp ResetTilemapAfterButtonPress
    ;that function rets for us, so we don't have to.

.programDoneString
    db " PROGRAM DONE",$FF
.programString
    db " PROGRAMMING  ",$FF;include spaces to cover the whole area

.programFailedString
    db "PROGRAM FAILED",$FF
BootstrapRom:
INCBIN "res/bootstrapRom.gb",$100;a little bootstrap rom. Start with the header
BootstrapRomEnd:
