
---

# 🧩 Linker Script (`linker.ld`) and Memory Mapping

The **linker script** defines how program sections are placed in memory (Flash and RAM).  
It provides critical symbol addresses used by `startup.s` for initialization.

---

## 🏁 ENTRY(_start)
Declares `_start` as the **entry point** of the program — the first symbol executed after reset.  
This usually maps to `Reset_Handler` in `startup.s`.

---

## 💾 MEMORY Regions

Defines the **Flash** and **SRAM** memory map according to the device datasheet.

### Example — STM32F4 Memory Layout
```ld
MEMORY
{
  FLASH (rx) : ORIGIN = 0x08000000, LENGTH = 512K
  RAM   (rwx): ORIGIN = 0x20000000, LENGTH = 128K
}
```

| Region | Permissions | Start Address | Size  | Purpose |
|---------|--------------|----------------|--------|----------|
| FLASH | `rx` | `0x08000000` | 512 KB | Stores code (.text) and initialized data (.data LMA) |
| RAM   | `rwx` | `0x20000000` | 128 KB | Stores variables, stack, and heap |

---

## 📦 SECTIONS Layout

Sections specify which memory regions hold each program segment.

### `.text` (Code Section)
Contains program instructions and constants, stored in **Flash**.

### `.data` (Initialized Data Section)
Holds global/static variables **with** initial values.

```ld
.data : 
{
    *(.data*)
} > RAM AT > FLASH
```

- **VMA (Virtual Memory Address)** → location in RAM (runtime address).  
- **LMA (Load Memory Address)** → location in Flash (where initialized data is stored before being copied).  

During startup, the `.data` section is copied from **Flash → RAM** by the `Reset_Handler`.

### `.bss` (Uninitialized Data Section)
Holds global/static variables **without initialization**.  
These variables are cleared (set to zero) in RAM during startup.

---

## 🧭 Key Linker Symbols

| Symbol | Defined In | Used In | Purpose |
|---------|-------------|----------|----------|
| `_estack` | `linker.ld` | `startup.s` | Marks top of stack (initial SP value). |
| `__etext` | `linker.ld` | `startup.s` | End of `.text` section in Flash; serves as LMA for `.data`. |
| `__data_start__` | `linker.ld` | `startup.s` | Start of `.data` section in RAM (VMA). |
| `__data_end__` | `linker.ld` | `startup.s` | End of `.data` section in RAM (VMA). |
| `__bss_start__` | `linker.ld` | `startup.s` | Start of `.bss` section in RAM. |
| `__bss_end__` | `linker.ld` | `startup.s` | End of `.bss` section in RAM. |

---

## 🧮 RAM Layout Visualization

```
0x20000000: [ .data     ]  ← Initialized globals (copied from Flash)
            [ .bss      ]  ← Zero-initialized globals
_ebss →     [ Heap      ]  ← Dynamic memory (malloc/new)
            [ ...       ]  ← Free RAM space
            [ Stack     ]  ← Grows downward
_estack →    -------------  ← Top of RAM (Stack Pointer)
```

### ❓ Clarifications

- **Is `_estack` the Stack Pointer?**  
  → `_estack` is a **symbol** pointing to the **top of RAM**. The **Reset_Handler** loads its address into the **MSP (Main Stack Pointer)** register.

- **Is the end of `.bss` also the top of RAM?**  
  → Not exactly. `.bss` ends **before** the heap and stack areas begin. `_estack` marks the *very top* of RAM, not the end of `.bss`.

---

## 🧩 Relationship Between Linker and Startup File

| Symbol | Defined In | Used In | Purpose |
|---------|-------------|----------|----------|
| `_estack` | `linker.ld` | `startup.s` | Stack top address loaded into MSP. |
| `__etext` | `linker.ld` | `startup.s` | End of `.text` in Flash (source for `.data`). |
| `__data_start__` | `linker.ld` | `startup.s` | Start of `.data` in RAM. |
| `__data_end__` | `linker.ld` | `startup.s` | End of `.data` in RAM. |
| `__bss_start__` | `linker.ld` | `startup.s` | Start of `.bss` in RAM. |
| `__bss_end__` | `linker.ld` | `startup.s` | End of `.bss` in RAM. |

---

## 🧠 Summary

- The **linker script** maps program sections into memory.
- The **startup.s** file uses these symbols to initialize RAM and set up the stack.
- Together, they create the minimal runtime environment required before `main()` executes.

---

## 📚 References

- ARM® Cortex-M Linker and Memory Model Guide  
- STMicroelectronics Application Notes (AN4065, AN4365)  
- GNU Linker (ld) documentation