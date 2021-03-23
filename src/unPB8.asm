SECTION "UnPB8rom",ROM0
LOAD  "UnPB8",SRAM
UnPB8::
.pb8BlockLoop
    ;unpack c blocks from hl to de. 8 byte blocks
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
    inc de ; inc de
    sla b
    jr nz, .pb8BitLoop

    dec c
    jr nz, .pb8BlockLoop
    ret
ENDL
