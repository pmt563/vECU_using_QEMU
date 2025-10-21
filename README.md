# 🚗 Virtual ECU (vECU) — STM32 QEMU Simulation

This project builds a **virtual ECU (Electronic Control Unit)** environment that simulates STM32 behavior on **QEMU (mps2-an385 platform)**.  
It executes a minimal firmware pipeline — from **bootloader startup** to **C runtime initialization** — and runs **crash detection logic** using sensor data read from a `.txt` file.

---

## 🧠 Overview

The goal is to simulate how a real STM32 microcontroller boots and runs embedded logic by:
1. **Emulating the MCU** architecture (`Cortex-M4` / `STM32G474` / `STM32F4` class).
2. **Building startup flow** with assembly (`startup.s`) and **linker mapping** (`linker.ld`).
3. **Implementing application logic** such as crash detection.
4. **Integrating with QEMU** for sensor-driven runtime testing.

---

## 📁 Project Structure

```
vECU/
├── build/                    # Compiled object files and map output
│   ├── crash_detector.o
│   ├── main.o
│   ├── startup.o
│   └── virtual_ecu.map
├── data/
│   └── Shopping-cart-impact_10kmph_Side-curves.txt  # Sensor input data
├── linker.ld                 # Memory layout and section mapping
├── main.elf                  # Final linked firmware binary
├── Makefile                  # Build instructions (gcc, linker, etc.)
├── mps2-an385.ld             # QEMU-compatible linker for Cortex-M4
├── src/
│   ├── main.c                # Main application logic
│   ├── crash_detector.c/.h   # Crash detection algorithm
│   ├── data_loader.c         # Read sensor data (from text file)
│   └── startup.s             # Startup assembly (Reset_Handler, vector table)
├── README.md                 # Main documentation (this file)
├── README_startup.md         # Deep dive into startup.s
├── README_linker.md          # Deep dive into linker.ld
├── README_memory_map.md      # Flash/RAM organization and section layout
└── README_uart.md            # UART communication guide
```

---

## 🧩 Boot Process Summary

The system boot flow is modeled after **real MCU startup** behavior:

```mermaid
graph TD
    A[Power On / Reset] --> B[Load MSP from 0x00000000]
    B --> C[Load PC from 0x00000004 (Reset_Handler)]
    C --> D[Copy .data from Flash → RAM]
    D --> E[Zero .bss section]
    E --> F[Call SystemInit()]
    F --> G[Call main()]
    G --> H[Run crash detection logic using sensor data]
```

### Key Steps
- **`.isr_vector`** defines interrupt vectors and the Reset_Handler entry.
- **`Reset_Handler`** prepares RAM (copies `.data`, zeros `.bss`).
- **`SystemInit()`** configures system clocks, vector table, and FPU.
- **`main()`** runs the crash detection algorithm.

---

## 🧱 Memory Layout (STM32F4 Example)

```ld
MEMORY
{
  FLASH (rx) : ORIGIN = 0x08000000, LENGTH = 512K
  RAM   (rwx): ORIGIN = 0x20000000, LENGTH = 128K
}
```

| Region | Permissions | Start | Size | Description |
|---------|--------------|--------|------|-------------|
| FLASH | `rx` | 0x08000000 | 512 KB | Stores code (.text), constants, and initialized data |
| RAM | `rwx` | 0x20000000 | 128 KB | Stores variables (.data, .bss), heap, and stack |

**RAM Layout Visualization**

```
0x20000000: [ .data     ]  ← Initialized globals (copied from Flash)
            [ .bss      ]  ← Zero-initialized globals
_ebss →     [ Heap      ]  ← Dynamic memory (malloc)
            [ ...       ]  ← Free space
            [ Stack     ]  ← Grows downward
_estack →    -------------  ← Top of RAM (Stack Pointer)
```

---

## ⚙️ Key Linker Symbols

| Symbol | Defined In | Used In | Description |
|---------|-------------|----------|-------------|
| `_estack` | linker.ld | startup.s | Stack top address (MSP init value) |
| `__etext` | linker.ld | startup.s | End of `.text` in Flash; LMA for `.data` |
| `__data_start__` | linker.ld | startup.s | Start of `.data` in RAM |
| `__data_end__` | linker.ld | startup.s | End of `.data` in RAM |
| `__bss_start__` | linker.ld | startup.s | Start of `.bss` in RAM |
| `__bss_end__` | linker.ld | startup.s | End of `.bss` in RAM |

---

## 🪄 Build and Run

### 🧰 Build Commands
```bash
cd ~/Documents/emtek/sdv/vECU
make
```

This will:
- Compile all `.c` and `.s` files into object files under `build/`.
- Link them with `linker.ld` to create `main.elf` and `main.map`.

### ▶️ Run in QEMU
```bash
qemu-system-arm -M mps2-an385 -kernel main.elf -nographic
```
> The simulated vECU will start executing `Reset_Handler`, then `main()`, reading data from `data/Shopping-cart-impact_10kmph_Side-curves.txt`.

---

## 🧪 Crash Detection Logic

Implemented in `crash_detector.c`, the logic:
1. Reads acceleration/velocity data from `.txt`.
2. Determines collision type and severity.
3. Logs result via UART or console.
4. Optionally publishes CAN/virtual signals in a full SDV setup.

---

## 🧰 Developer Notes

- `startup.s` and `linker.ld` must stay synchronized (symbol consistency).
- For **STM32F4**, `_estack` typically equals `ORIGIN(RAM) + LENGTH(RAM)`.
- All peripheral ISRs (Timer, UART, ADC, etc.) can be added to `.isr_vector`.
- `SystemInit()` is hardware-specific and may reconfigure vector mapping.

---

## 📘 References

- **ARM® Cortex-M Technical Reference Manual**
- **CMSIS (Cortex Microcontroller Software Interface Standard)**
- **STM32 Reference Manual & HAL documentation**
- **GNU Linker (ld) documentation**
- **QEMU mps2-an385 platform specification**

---

## 🧩 Related Documentation

| File | Description |
|------|--------------|
| `README_startup.md` | Full breakdown of vector table & Reset_Handler |
| `README_linker.md` | Detailed linker script explanation |
| `README_memory_map.md` | Visual memory organization |
| `README_uart.md` | UART initialization and TX/RX routine |

---

**Author:** *Tuan Pham*  
**Project:** *EMTEK – SDV / Virtual ECU Simulation*  
**Environment:** *QEMU Cortex-M4, STM32G474/STM32F4 compatible*