START_TOKEN = 42;sent by the GB
RECIEVED_TOKEN = 43;recieved by the gb 2nd
INIT_TOKEN = 44;sent by the GB 2nd



CopyRom:: ; this needs to be called during Vblank
    call ClearLowerScreen
    call SectorErase
   

    ld a, START_TOKEN; Special token to start a transfer with computer
    ldh [rSB], a
    ld a, $83 ;we're the master, and we're initiating a fast transfer
    ldh [rSC], a

    lb bc, HIGH(wFlashBuffer1), 0
    ld d, c
    ld e, c ; ld de, 0
    ld hl, wFlashBuffer2

    call WaitTransferCompletion    

CheckReply:
    ld a, INIT_TOKEN
    
    call TransferAndWait
    
    ldh a, [rSB]
    cp RECIEVED_TOKEN 
    jr nz, ConnectFail

    
LoadFirstPage:;since the main copy routine flashes and downloads at the same time, we need to fetch the first 256 bytes ahead of time.
    /*
    Registers:
    D - The sum of the incoming bytes from Serial. This will be used to verify the block's integrity
    HL - The destination buffer of this copy
    */
    ld a, d ; d should be 0 when this starts
    
    call TransferAndWait

    ldh a, [rSB]
    ld [hl], a

    add d
    ld d, a

    inc l
    jr nz, LoadFirstPage

PrepareFirstTransferOfBlock:
    ld a, d ; d should be 0 when this starts
    
    call TransferAndWait

    ld d, 0
FlashROM0:
    push de ;pushed de holds the block number
    call LoadBlock
    pop de

    
    inc e ; advance to the next block
    ld a, e
    cp $08 ; are we at the end of ROM0?
    jr nz, FlashROM0
    ret




LoadBlock:
    ld d, 0 ;start a fresh checksum
LoadByte:; simultaneously read a byte from serial into the loading buffer, and write a byte to the flash from the flashing buffer
    /*
    Registers:
    B - The high byte of the downloading buffer's location. Xor it with 1 to get the flashing buffer's location instead
    C - The byte previously written to the flash. This is checked to see that the byte was written properly before writing the next one
    D - The sum of the incoming bytes from Serial. This will be used to verify the block's integrity
    E - The high byte of the pointer to the ROM(flash) location being currently written to
    L - The low byte of all pointers. Also functions as the counter for the block.
    */
    
    ;Flash a Byte

    ld a, b ; get the pointer to the downloading buffer
    xor $01 ;now it points to the other buffer (which is now the flashing buffer)
    ld h, a ;so now hl has the index in that buffer, which should be prorammed.
    
    ld a , $AA ;send the byte-program command sequence
    ld [$5555], a
    cpl ;ld a, $55
    ld [$2AAA], a
    ld a, $A0
    ld [$5555], a

    ld a, [hl] ;fetch the byte to program
    ld h, e ;this will be the high byte of the destination address
    
    ld [hl], a  ;actually write the byte

    ld c,a ;store it to check later

    ;Fetch a Byte
    ldh a, [rSB] ;get the byte previously sent by the arduino
    ld h, b ; hl now points to the fetch buffer
    ld [hl],a ; write to the buffer

    add d
    ld d, a

    ;Request a Byte
    ;ld a, d ;send out the checksum so far
    ldh [rSB], a
    ld a, $83 ;we're the master, and we're initiating a fast transfer
    ldh [rSC], a


    
    ld h, e ;point hl to the flash location
    ld a, c ;get the previously written byte
    cp [hl] ; check if the write has gone through yet

    ;that already took 20 cycles, so in single-speed mode, the byte should be done writing.

    jr nz, FlashFail

    inc l ; move to the next byte of the 256 byte block
    jr nz, LoadByte

    ;Finishing The Block
    ld a, b
    xor $01
    ld b, a; switch the buffers around
    
    ret
    
FlashFail:
    ld de, ProgramFailedString
    
    add sp, 4 ;pop off the stacked block number as well as 1 return address
    call WaitVblank
    call StrcpyAboveProgressBar
    jp ResetTilemapAfterButtonPress
    ;this will return to the caller of CopyRom

ConnectFail:
    ld de, NoConnectionString
    call WaitVblank
    call StrcpyAboveProgressBar
    jp ResetTilemapAfterButtonPress

NoConnectionString:
    db "NO CONNECTION ", $FF
PUSHS

    
SECTION "Flash Wram Buffers", WRAM0, ALIGN[9]
wFlashBuffer1: ; these will alternate between storing validated data to be flashed and downloaded data to be verified
    ds 256
wFlashBuffer2:
    ds 256

POPS