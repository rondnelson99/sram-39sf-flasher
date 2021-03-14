INCLUDE "defines.asm"
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

CopyTileData:
    ld hl,$9010;bg tile area, skipping the first tile because it should be blank
    ld de, BorderTiles
    ld c, BorderTilesEnd - BorderTiles
.copyBorderTileByte
    ld a, [de]
    inc de
    ld [hl+], a
    ld [hl+], a
    dec c
    jr nz,.copyBorderTileByte
    
    dec de
    ld c,2*8;2 tiles times 8 source bytes per tile
.copyInvertedBorderTile
    ld a, [de]
    dec de
    ld [hl+], a
    ld [hl+], a
    dec c
    jr nz,.copyInvertedBorderTile



ASSERT HIGH(BorderTilesEnd-9) == HIGH(SSTTiles)
    ld e,LOW(SSTTiles)
    ;hl still points where it needs to
    ;copy 256 bytes, but c is already 0, so we're good here too
ASSERT SSTTIlesEnd-SSTTiles == 256
.copyLogoTileByte ;this is just memcpysmall
    ld a,[de]
    inc de
    ld [hl+], a
    dec c
    jr nz,.copyLogoTileByte

GenerateTileMap:
    ld hl,$9800 + 32 ;start of second row
    ld a,3;upper-left curve
    ld [hl+], a
    ld a, 1; horizontal line
    ld c, (160/8)-2 ;tiles on screen minus corners
.generateTileMapRow
    ld [hl+], a
    dec c
    jr nz,.generateTileMapRow
    ld a,4;upper-right curve
    ld [hl],a

    lb bc,2,(144/8)-3;vertical line, repeat for the screen minus the top margin and horizontal lines
.generateTileMapColumn
    ld de,32 - (160/8) + 1  ;difference fot hl to get to the start of the next line
    add hl,de
    ld [hl],b
    ld e,(160/8)-1 ;diffetence for hl to get to the end of the current line
    add hl,de
    ld [hl],b
    dec c
    jr nz, .generateTileMapColumn

    ld e,32 - (160/8) + 1
    add hl, de

    ld a,6;lower-left curve
    ld [hl+], a
    ld a, 1; horizontal line
    ld c, (160/8)-2 ;tiles on screen minus corners
.generateTileMapRowBottom
    ld [hl+], a
    dec c
    jr nz,.generateTileMapRowBottom
    ld a,5;upper-right curve
    ld [hl+],a

GenerateSSTTileMap:
    ld hl, $9802;put the logo near the upper-left corner
    ld a, 7;the first tile of the logo
    ld b, 4;three rows
    ld e, 32-4 ;difference between end of one row and start of the next
.writeSSTMapRow
    ld c, 4;four tiles per row
.writeSSTMapByte
    ld [hl+], a
    inc a
    dec c
    jr nz,.writeSSTMapByte
    add hl, de
    dec b
    jr nz,.writeSSTMapRow
    ld b,b

    

 



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



BorderTiles:
INCBIN "res/bordertiles.1bpp"
BorderTilesEnd:

SSTTiles:
INCBIN "res/sstlogo.2bpp"
SSTTIlesEnd: