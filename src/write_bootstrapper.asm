SECTION  "Write the Bootstrapper ROM",ROM0
LOAD "Write the Bootstrapper",SRAM
FlashBootstrapRom::
    call ChipErase
    ret

BootstapRom:
INCBIN "res/bootstrapRom.gb",$100;a little bootstrap rom. Start with the header
ENDL