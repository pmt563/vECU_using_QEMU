# Virtual ECU (Cortex-M4)
TARGET     := virtual_ecu

CC         := arm-none-eabi-gcc
OBJCOPY    := arm-none-eabi-objcopy
SIZE       := arm-none-eabi-size

SRCDIR     := src
BUILDDIR   := build
DATADIR    := data

SOURCES_C  := $(wildcard $(SRCDIR)/*.c)
SOURCES_S  := $(wildcard $(SRCDIR)/*.s)
OBJECTS    := $(patsubst $(SRCDIR)/%.c,$(BUILDDIR)/%.o,$(SOURCES_C)) \
              $(patsubst $(SRCDIR)/%.s,$(BUILDDIR)/%.o,$(SOURCES_S))

LDSCRIPT   := linker.ld

CPU        := -mcpu=cortex-m4
FPU        := -mfloat-abi=soft
MCU := $(CPU) -mthumb $(FPU)
USE_RDIMON ?= 1

CSTD       := -std=c11
OPT        := -O0
WARN       := -Wall -Wextra
CFLAGS     := $(MCU) $(OPT) -g $(WARN) $(CSTD) -ffunction-sections -fdata-sections

LDFLAGS    := $(MCU) -T$(LDSCRIPT) -Wl,--gc-sections -Wl,-Map=$(BUILDDIR)/$(TARGET).map -Wl,--wrap=exit -Wl,--wrap=_exit

ifeq ($(USE_RDIMON),1)
  LDFLAGS += --specs=rdimon.specs -nostartfiles
  LIBS    := -Wl,--start-group -lc -lrdimon -lgcc -Wl,--end-group
else
  CFLAGS  += -fno-builtin
  LDFLAGS += -nostdlib -nostartfiles
  LIBS    := -Wl,--start-group -lgcc -Wl,--end-group
endif

ELF       := $(BUILDDIR)/$(TARGET).elf
BIN       := $(BUILDDIR)/$(TARGET).bin

.PHONY: all run debug clean size objdump

all: $(ELF) size

$(ELF): $(OBJECTS) $(LDSCRIPT)
	@mkdir -p $(BUILDDIR)
	@echo "Linking..."
	$(CC) $(OBJECTS) $(LDFLAGS) $(LIBS) -o $@

$(BUILDDIR)/%.o: $(SRCDIR)/%.c
	@mkdir -p $(@D)
	@echo "Compiling $<..."
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILDDIR)/%.o: $(SRCDIR)/%.s
	@mkdir -p $(@D)
	@echo "Assembling $<..."
	$(CC) $(CFLAGS) -c $< -o $@

$(BIN): $(ELF)
	$(OBJCOPY) -O binary $< $@

size: $(ELF)
	$(SIZE) -Ax $(ELF)
	$(SIZE) $(ELF)

run: $(ELF)
	# MPS2 AN386 (Cortex-M4); semihosting to host FS
	@set -e; \
	qemu-system-arm -M mps2-an386 -cpu cortex-m4 \
	  -kernel $(ELF) \
	  -nographic -semihosting-config enable=on,target=native; \
	rc=$$?; echo "Exit code: $$rc"; exit 0


debug: $(ELF)
	qemu-system-arm -M mps2-an386 -cpu cortex-m4 \
		-kernel $(ELF) \
		-nographic -semihosting-config enable=on,target=native -serial stdio \
		-s -S
	# Then in another terminal:
	# arm-none-eabi-gdb $(ELF)
	# (gdb) target remote :1234

objdump: $(ELF)
	arm-none-eabi-objdump -dC $(ELF) | less

clean:
	@echo "Cleaning..."
	rm -rf $(BUILDDIR)
