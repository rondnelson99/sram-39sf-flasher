INCLUDE "defines.asm"
SECTION FRAGMENT "ROM CODE",ROM0
LOAD FRAGMENT "RAM CODE",SRAM
FlashBootstrapRom::;it should still be Vblank when this gets called
    call InitProgressBar

    call ChipErase
    
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
    jp z,.done
    dec b
    jr nz, .checkprogramloop
    ;fall through if b runs out
    
    xor a
    ldh [rIF],a ;zero interrupt requests before halt to wait for the next Vblank
    halt ;wait for vBlank
    call Handle_Vblank
    
    ld hl,$9983 ;above the progress bar
    ld de,.programFailedString
    call Strcpy
    ret

.done
    dec c
    jr nz,.flashBootstrapRomByte

    ret

.programFailedString
    db "PROGRAM FAILED",$FF
BootstrapRom:
INCBIN "res/bootstrapRom.gb",$100;a little bootstrap rom. Start with the header
BootstrapRomEnd:
ENDL