
.SUFFIXES:

################################################
#                                              #
#             CONSTANT DEFINITIONS             #
#                                              #
################################################

# Directory constants
SRCDIR := src
BINDIR := bin
OBJDIR := obj
DEPDIR := dep
RESDIR := res

# Program constants
ifneq ($(shell which rm),)
    # POSIX OSes
    RM_RF := rm -rf
    MKDIR_P := mkdir -p
    PY :=
    filesize = echo 'NB_PB$2_BLOCKS equ (' `wc -c $1 | cut -d ' ' -f 1` ' + $2 - 1) / $2'
else
    # Windows outside of a POSIX env (Cygwin, MSYS2, etc.)
    # We need Powershell to get any sort of decent functionality
    $(warning Powershell is required to get basic functionality)
    RM_RF := -del /q
    MKDIR_P := -mkdir
    PY := python
    filesize = powershell Write-Output $$('NB_PB$2_BLOCKS equ ' + [string] [int] (([IO.File]::ReadAllBytes('$1').Length + $2 - 1) / $2))
endif
# Shortcut if you want to use a local copy of RGBDS
RGBDS   :=
RGBASM  := $(RGBDS)rgbasm
RGBLINK := $(RGBDS)rgblink
RGBFIX  := $(RGBDS)rgbfix
RGBGFX  := $(RGBDS)rgbgfx

ROM = $(BINDIR)/$(ROMNAME).$(ROMEXT)

# Argument constants
INCDIRS  = $(SRCDIR)/ $(SRCDIR)/include/
WARNINGS = all extra
ASFLAGS  = -p $(PADVALUE) $(addprefix -i,$(INCDIRS)) $(addprefix -W,$(WARNINGS))
LDFLAGS  = -p $(PADVALUE)
FIXFLAGS = -v -i "$(GAMEID)" -k "$(LICENSEE)" -l $(OLDLIC) -m $(MBC) -n $(VERSION) -r $(SRAMSIZE) -t $(TITLE)

# The list of "root" ASM files that RGBASM will be invoked on
SRCS = $(wildcard $(SRCDIR)/*.asm)

## Project-specific configuration
# Use this to override the above
include project.mk

################################################
#                                              #
#                RESOURCE FILES                #
#                                              #
################################################

# By default, asset recipes convert files in `res/` into other files in `res/`
# This line causes assets not found in `res/` to be also looked for in `src/res/`
# "Source" assets can thus be safely stored there without `make clean` removing them
VPATH := $(SRCDIR)

$(RESDIR)/%.1bpp: $(RESDIR)/%.png
	@$(MKDIR_P) $(@D)
	$(RGBGFX) -d 1 -o $@ $<

$(RESDIR)/%.2bpp: $(RESDIR)/%.png
	@$(MKDIR_P) $(@D)
	$(RGBGFX) -o $@ $<

# Define how to compress files using the PackBits16 codec
# Compressor script requires Python 3
$(RESDIR)/%.pb16: $(RESDIR)/% $(SRCDIR)/tools/pb16.py
	@$(MKDIR_P) $(@D)
	$(PY) $(SRCDIR)/tools/pb16.py $< $(RESDIR)/$*.pb16

$(RESDIR)/%.pb16.size: $(RESDIR)/%
	@$(MKDIR_P) $(@D)
	$(call filesize,$<,16) > $(RESDIR)/$*.pb16.size

# Define how to compress files using the PackBits8 codec
# Compressor script requires Python 3
$(RESDIR)/%.pb8: $(RESDIR)/% $(SRCDIR)/tools/pb8.py
	@$(MKDIR_P) $(@D)
	$(PY) $(SRCDIR)/tools/pb8.py $< $(RESDIR)/$*.pb8

$(RESDIR)/%.pb8.size: $(RESDIR)/%
	@$(MKDIR_P) $(@D)
	$(call filesize,$<,8) > $(RESDIR)/$*.pb8.size

#this is for using rgbds to make little roms which will be incbin'd into another rom
$(RESDIR)/%.gb: $(RESDIR)/%.asm
	@$(MKDIR_P) $(@D)
	$(RGBASM)  -o $(RESDIR)/$*.o $<
	$(RGBLINK)  -x -o $@ $(RESDIR)/$*.o
	$(RGBFIX)	-C -f lhg -j -k "RN" -m 0x09 -r 0x02 -t "FLASH BOOTSTRAP" $@
###############################################
#                                             #
#                 COMPILATION                 #
#                                             #
###############################################

# `all` (Default target): build the ROM
all: $(ROM)
.PHONY: all

# `clean`: Clean temp and bin files
clean:
#$(RM_RF) $(BINDIR)
	$(RM_RF) $(OBJDIR)
	$(RM_RF) $(DEPDIR)
	$(RM_RF) $(RESDIR)
.PHONY: clean

# `rebuild`: Build everything from scratch
# It's important to do these two in order if we're using more than one job
rebuild:
	$(MAKE) clean
	$(MAKE) all
.PHONY: rebuild

upload:
	$(MAKE) all
	stty -F /dev/ttyS4 500000 cs8 -cstopb -parenb -opost -ixoff
	sx bin/$(ROM) < /dev/ttyS4 > /dev/ttyS4
.PHONY: upload

# How to build a ROM
$(BINDIR)/%.$(ROMEXT) $(BINDIR)/%.sym $(BINDIR)/%.map: $(patsubst $(SRCDIR)/%.asm,$(OBJDIR)/%.o,$(SRCS))
	@$(MKDIR_P) $(@D)
	$(RGBLINK) $(LDFLAGS) -m $(BINDIR)/$*.map -n $(BINDIR)/$*.sym -o $(BINDIR)/$*.$(ROMEXT) $^  \
	&& $(RGBFIX) -v $(FIXFLAGS) $(BINDIR)/$*.$(ROMEXT)
# `.mk` files are auto-generated dependency lists of the "root" ASM files, to save a lot of hassle.
# Also add all obj dependencies to the dep file too, so Make knows to remake it
# Caution: some of these flags were added in RGBDS 0.4.0, using an earlier version WILL NOT WORK
# (and produce weird errors)
$(OBJDIR)/%.o $(DEPDIR)/%.mk: $(SRCDIR)/%.asm
	@$(MKDIR_P) $(patsubst %/,%,$(dir $(OBJDIR)/$* $(DEPDIR)/$*))
	$(RGBASM) $(ASFLAGS) -M $(DEPDIR)/$*.mk -MG -MP -MQ $(OBJDIR)/$*.o -MQ $(DEPDIR)/$*.mk -o $(OBJDIR)/$*.o $<

ifneq ($(MAKECMDGOALS),clean)
-include $(patsubst $(SRCDIR)/%.asm,$(DEPDIR)/%.mk,$(SRCS))
endif


# Catch non-existent files
# KEEP THIS LAST!!
%:
	@false