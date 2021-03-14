INCLUDE "include/hardware.inc/hardware.inc"
SECTION "Header", ROM0[$100]

	; This is your ROM's entry point
	; You have 4 bytes of code to do... something
	di
	jp Start

	; Make sure to allocate some space for the header, so no important
	; code gets put there and later overwritten by RGBFIX.
	; RGBFIX is designed to operate over a zero-filled header, so make
	; sure to put zeros regardless of the padding value. (This feature
	; was introduced in RGBDS 0.4.0, but the -MG etc flags were also
	; introduced in that version.)
	ds $150 - @, 0

SECTION "Entry point", ROM0


Start:
.waitVBlank
    ld a, [rLY]
    cp a, 144
    jr c, .waitVBlank

    xor a; ld a, 0
    ld [rLCDC], a ;turn display off

    ld hl, $9000

.genTiles
    ld e, a
    ld d, a;ld de,$0000
    call TileGen
    dec e;ld de, $00FF
    call TileGen
    inc e
    dec d;ld de, $FF00
    call TileGen
    dec e;ld de, $FFFF
    call TileGen


    ld hl, $9800; print sentence on top screen


    xor a
.generateTileMap
    ld b,128;copy 128 tiles for 4 visible rows
.generateTileMapRow
    ld [hl+], a;store a in the tilemap, atarting with index 0
    dec b
    jr nz, .generateTileMapRow
    inc a
    cp 4+1 ;check if we've finished the fourth colour
    jr c, .generateTileMap



    ld a, %11100100
    ld [rBGP], a

    xor a; ld a, 0
    ld [rSCY], a
    ld [rSCX], a
    ld [rNR52], a
    ld a, %10000001
    ld [rLCDC], a

.lockup
    jr .lockup

TileGen:
    ld c, 8
.copyTileRow
    ld a, e
    ld [hl+], a
    ld a, d
    ld [hl+], a
    dec c
    jr nz,.copyTileRow
    ret

