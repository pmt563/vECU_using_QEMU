# =========================
# Virtual ECU (Cortex-M4F)
# =========================

# Output elf name (without extension)
TARGET     := virtual_ecu

# Toolchain
CC         := arm-none-eabi-gcc
OBJCOPY    := arm-none-eabi-objcopy
SIZE       := arm-none-eabi-size

# Dirs
SRCDIR     := src
BUILDDIR   := build
DATADIR    := data

# Sources
SOURCES_C  := $(wildcard $(SRCDIR)/*.c)
SOURCES_S  := $(wildcard $(SRCDIR)/*.s)
OBJECTS    := $(patsubst $(SRCDIR)/%.c,$(BUILDDIR)/%.o,$(SOURCES_C)) \
              $(patsubst $(SRCDIR)/%.s,$(BUILDDIR)/%.o,$(SOURCES_S))

# Linker script
LDSCRIPT   := linker.ld

# CPU/FPU
CPU        := -mcpu=cortex-m4
FPU        := -mfloat-abi=hard -mfpu=fpv4-sp-d16
MCU        := $(CPU) -mthumb $(FPU)

# Enable rdimon (semihosting via newlib/libgloss)
USE_RDIMON ?= 1

# Common flags
CSTD       := -std=c11
OPT        := -O0
WARN       := -Wall -Wextra
CFLAGS     := $(MCU) $(OPT) -g $(WARN) $(CSTD) -ffunction-sections -fdata-sections

# Linker flags (common)
LDFLAGS    := $(MCU) -T$(LDSCRIPT) -Wl,--gc-sections -Wl,-Map=$(BUILDDIR)/$(TARGET).map

# rdimon vs bare-metal
ifeq ($(USE_RDIMON),1)
  # Use rdimon semihosting (printf/scanf etc.)
  LDFLAGS += --specs=rdimon.specs -nostartfiles
  LIBS    := -Wl,--start-group -lc -lrdimon -lgcc -Wl,--end-group
else
  # Bare-metal (no rdimon; e.g., if you use your own BKPT semihosting stubs)
  CFLAGS  += -fno-builtin
  LDFLAGS += -nostdlib -nostartfiles
  LIBS    := -Wl,--start-group -lgcc -Wl,--end-group
endif

ELF       := $(BUILDDIR)/$(TARGET).elf
BIN       := $(BUILDDIR)/$(TARGET).bin

# =========================
# Rules
# =========================
.PHONY: all run debug clean size objdump

all: $(ELF) size

$(ELF): $(OBJECTS) $(LDSCRIPT)
	@mkdir -p $(BUILDDIR)
	@echo "Linking..."
	$(CC) $(OBJECTS) $(LDFLAGS) $(LIBS) -o $@

# C sources
$(BUILDDIR)/%.o: $(SRCDIR)/%.c
	@mkdir -p $(@D)
	@echo "Compiling $<..."
	$(CC) $(CFLAGS) -c $< -o $@

# Assembly sources (.s)
$(BUILDDIR)/%.o: $(SRCDIR)/%.s
	@mkdir -p $(@D)
	@echo "Assembling $<..."
	$(CC) $(CFLAGS) -c $< -o $@

# Optional: raw binary
$(BIN): $(ELF)
	$(OBJCOPY) -O binary $< $@

size: $(ELF)
	$(SIZE) -Ax $(ELF)
	$(SIZE) $(ELF)

# -------------------------
# QEMU run/debug helpers
# -------------------------
# Tip: Ensure your sensor .txt file is in the CWD when launching QEMU
# (or use an absolute path in your code).

run: $(ELF)
	# MPS2 AN386 (Cortex-M4); semihosting to host FS
	qemu-system-arm -M mps2-an386 -cpu cortex-m4 \
	  -kernel build/virtual_ecu.elf \
	  -nographic -semihosting-config enable=on,target=native || true


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
