
FlashBootstrapRom::;it should still be Vblank when this gets called
    call ClearLowerScreen
    call InitProgressBar
    ld de, ProgramString
    call StrcpyAboveProgressBar

    call SectorErase

    call WaitAndHandleVblank
    ld a, $3E ;tile number for filled in proress bar
    ld [$99C3],a;fill in the first bit of the bar to show that the erase has completed

    ;ASSERT STARTOF("RAM") == $C000
    ld de, $C000;STARTOF("RAM") ;copy the entire 2KB program that is currently in RAM to the Flash
    ld h,e ;ld hl, $0000 ;area to be flashed
    ld l,e
.flashBootstrapRomByte
    ld a, [de]
    inc de
    call FlashByteProgram

    ld b, 3;give it a little time to fully program
.checkprogramloop
    cp [hl]
    jr z,.doneByte
    dec b
    jr nz, .checkprogramloop
    ;fall through if b runs out
    
    call WaitAndHandleVblank
    
    ld de, ProgramFailedString
    call StrcpyAboveProgressBar
    jp ResetTilemapAfterButtonPress

.doneByte
    inc hl
    bit 3, h; this will be set after 2KB has been copied
    jr z,.flashBootstrapRomByte
    ;if we make it here then we're done programming, but first let's update the progress bar.
    call WaitAndHandleVblank
    ld a, $3E ;tile index of the filled bar
    ld hl, $99C3; start of the bar
    ld c, $99D1 - $99C3 ;length of the bar
    MemsetSmall
    ld de, ProgramDoneString
    call StrcpyAboveProgressBar
    
    jp ResetTilemapAfterButtonPress
    ;that function rets for us, so we don't have to.


