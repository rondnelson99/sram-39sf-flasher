INCLUDE "defines.asm"

CODE_LOCATION equ $C000
SECTION "ROM copy routine", ROM0[0]

    ;This starting bit is stupidly jank. It's meant to be run from ROM, but needs to still get loaded into RAM so that it can be flashed later. 
    ;It only works like this because the copy routine contains no jp or call and doesn't use any labels, so it doesn't matter what @ is.

    ds $100 ;get to the header

	; This is your ROM's entry point
	; You have 4 bytes of code to do... something
	di
    nop
	jr EntryPoint

	; Make sure to allocate some space for the header, so no important
	; code gets put there and later overwritten by RGBFIX.
	; RGBFIX is designed to operate over a zero-filled header, so make
	; sure to put zeros regardless of the padding value. (This feature
	; was introduced in RGBDS 0.4.0, but the -MG etc flags were also
	; introduced in that version.)
	ds $150 - @, 0




EntryPoint:
	; Here is where the fun begins, happy coding :)
CopyToRam:
    ld hl, CODE_LOCATION
    ASSERT LOW(CODE_LOCATION) == 0
    ;ASSERT STARTOF("ROM") == $0000
    ld d, l
    ld e, l;ld de, STARTOF("ROM")
    ld bc, 2048 ; copy the 2KB program
.loop
    ld a, [de]
    inc de
    ld [hl+], a
    dec bc
    ld a, b
    or c
    jr nz, .loop
    jp Start

SECTION "RAM copy routine", WRAM0[CODE_LOCATION]
    ;reserve space for the previous rom copy routine
    ds SIZEOF("ROM copy routine")

SECTION "ROM Main Code", ROM0 ;since it's the only other section, this will be placed immediately after the ROM copy routine
LOAD "RAM", WRAM0[CODE_LOCATION + SIZEOF("ROM copy routine")]
  
; now this code will actually be run from RAM

Start::
    di

    ;SERIAL DEBUG
    xor a
    ldh [rSC],a

.waitVBlank
    ld a, [rLY]
    cp a, 144
    jr c, .waitVBlank

    xor a; ld a, 0
    ld [rLCDC], a ;turn display off
    ;init stack
STACK_SIZE = 128
    ld sp,wStackBottom

ClearVRAM:
    ld hl,$8000;start of vram
    ld bc,$2000;length of vram
.clearVramByte
    xor a
    ld [hl+],a
    dec bc
    ld a,b
    or c
    jr nz,.clearVramByte

    ldh [hHeldKeys],a

    ; Register map for PB8 decompression
	; HL: source address in boot ROM
	; DE: destination address in VRAM
	; A: Current literal value
	; B: Repeat bits, terminated by 1000...
	; C: Number of 8-byte blocks left in this block
	; Source address in HL lets the repeat bits go straight to B,
	; bypassing A and avoiding spilling registers to the stack.

CopyTileDataPB8:
    ld de,$9010;bg tile area, skipping the first tile because it should be blank
    ld hl, FontTiles
INCLUDE "res/font.1bpp.pb8.size"
NB_PB8_BLOCKS_PART1 = NB_PB8_BLOCKS
    PURGE NB_PB8_BLOCKS
INCLUDE "res/bordertiles.1bpp.pb8.size"
NB_PB8_BLOCKS_TOTAL = NB_PB8_BLOCKS + NB_PB8_BLOCKS_PART1
    ld c, NB_PB8_BLOCKS_PART1 + NB_PB8_BLOCKS
    PURGE NB_PB8_BLOCKS
    .pb8BlockLoop
	ld b, [hl]
	inc hl

	; Shift a 1 into lower bit of shift value.  Once this bit
	; reaches the carry, B becomes 0 and the byte is over
	scf
	rl b

.pb8BitLoop
	; If not a repeat, load a literal byte
	jr c,.pb8Repeat
	ld a, [hli]
.pb8Repeat
	; Decompressed data uses colors 0 and 3, so write twice
	ld [de], a
	inc e ; inc de
	ld [de], a
	inc de
	sla b
	jr nz, .pb8BitLoop

	dec c
	jr nz, .pb8BlockLoop

    ; Register map for PB16 decompression
	; HL: source address in boot ROM
	; DE: destination address in VRAM
	; C: previous plane 1
    ; HRAM: previous plane 2
	; B: Repeat bits, terminated by 1000...
	; B,stacked: Number of 8-byte blocks left in this block
	; Source address in HL lets the repeat bits go straight to B,
	; bypassing A and avoiding spilling registers to the stack.
CopyTileDataPB16: ;This is just the logo for now.
INCLUDE "res/sstlogo.2bpp.pb16.size"
    ld b, NB_PB16_BLOCKS * 2; the script was made for copying 2 bytes at a time, but I only do 1.
    PURGE NB_PB16_BLOCKS
    ;hl and de still point where they need to
    ; Prefill temp storage with zeroes
    xor a
    ldh [hBackupA],a
    ld c,a
.packetloop:
    push bc
    
.pb16_unpack_packet:
    ; Read first bit of control byte.  Treat B as a ring counter with
    ; a 1 bit as the sentinel.  Once the 1 bit reaches carry, B will
    ; become 0, meaning the 8-byte packet is complete.
    ld a,[hl+]
    scf
    rla
    ld b,a
.byteloop:
    ; If the bit from the control byte is clear, plane 0 is is literal
    jr nc,.p0_is_literal
    ldh a,[hBackupA]
    jr .have_p0
.p0_is_literal:
    ld a,[hl+]
    ldh [hBackupA],a
.have_p0:
    ld [de],a
    inc e;this'll be aligned if we're copying to VRAM
  
    ; Read next bit.  If it's clear, plane 1 is is literal.
    ld a,c
    sla b
    jr c,.have_p1
.p1_is_copy:
    ld a,[hl+]
    ld c,a
.have_p1:
    ld [de],a
    inc de
  
    ; Read next bit of control byte
    sla b
    jr nz,.byteloop

    ld a,c
    pop bc
    ld c,a
    dec b
    jr nz,.packetloop
    
DecompressTilemap::
    ;hl is still where it needs to be
    ld de, $9800
INCLUDE "res/main.tilemap.pb8.size"
    ld c, NB_PB8_BLOCKS 
    PURGE NB_PB8_BLOCKS
    call UnPB8
    ld a, %00000001;vblank interrupt only
    ldh [rIE],a


    ld a, BCPSF_AUTOINC + 0
    ldh [rBCPS], a
    lb bc, 8, LOW(rBCPD) ;get ready to set BGP0
    ld hl, BgPaletteData
.paletteloop
    ld a, [hl+]
    ld [$ff00+c], a
    dec b
    jr nz, .paletteloop

    ;old DMG palette code
    /*ld a, %11100100
    ldh [rBGP], a
    ldh [rOBP1],a*/

    xor a; ld a, 0
    ld [rSCY], a
    ld [rSCX], a
    ld [rNR52], a
    ld a, %10000001
    ld [rLCDC], a

Wait:
    call WaitAndHandleVblank

    ldh a,[hPressedKeys]
    bit 2,a;select button
    call nz,FlashBootstrapRom
    
    /*ldh a,[hPressedKeys]
    rrca ;shift bit 0 (a button) into carry
    call c, CopyRom ; copy a rom if it's being sent*/
    call CopyRom

    jr Wait


BgPaletteData:
    rgb $1F,$1F,$1F, $0F,$1F,$06, $00,$0C,$18, $00,$00,$00 ;equivalent to the default white, green, blue, black in back-compat mode

FontTiles:
INCBIN "res/font.1bpp.pb8"
FontTilesEnd:
BorderTiles:
INCBIN "res/bordertiles.1bpp.pb8"
BorderTilesEnd:

SSTTiles:
INCBIN "res/sstlogo.2bpp.pb16"
SSTTIlesEnd:
MainTilemap::
INCBIN "res/main.tilemap.pb8"
TilemapEnd:

PUSHS

SECTION "HRAM misc vars", HRAM

hBackupA: db

SECTION "Stack", WRAM0[$E000 - STACK_SIZE]

	ds STACK_SIZE
wStackBottom:

POPS

INCLUDE "vblank.asm"
INCLUDE "memutils.asm"
INCLUDE "gfxfunctions.asm"
INCLUDE "flashfunctions.asm"
INCLUDE "transfer_from_computer.asm"
INCLUDE "unPB8.asm"
INCLUDE "write_bootstrapper.asm"

ENDL