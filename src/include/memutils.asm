Multiple_Strcpy::;copy C destination prefixed strings from de
    ld a, [de]
    inc de
    ld l, a
    ld a, [de]
    inc de
    ld h, a
    call Strcpy
    dec c
    jr nz, Multiple_Strcpy
UnconditionalRet:: ;this can be called in order to efficiently delay
    ret

StrcpyAboveProgressBar::
    ld hl,$9983 ;above the progress bar
Strcpy:: ;copy an FF-terminated string from de to hl
    ld a, [de]
    inc de

    inc a;if a is $ff, ret. Otherwise, restore it to its old value.
    ret z
    dec a

    ld [hl+], a
    jr Strcpy

TransferAndWait:: ;transfer a to/from Serial, then wait for the exchange to finish
    ldh [rSB], a
    ld a, $83;we're the master, initiate a fast transfer
    ldh [rSC], a

WaitTransferCompletion:: ;wait for the current Serial transfer to finish
    ldh a, [rSC]
    rlca ;shift bit 7 (transfer in progress flag) into carry
    ret nc
    jr WaitTransferCompletion 
    