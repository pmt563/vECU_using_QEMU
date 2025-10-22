/* STM32G474-like: 512K FLASH, 128K RAM */
ENTRY(Reset_Handler)

MEMORY {
  FLASH (rx) : ORIGIN = 0x00000000, LENGTH = 512K
  RAM   (rwx): ORIGIN = 0x20000000, LENGTH = 128K
}

_Min_Heap_Size  = 0x02000;  /* 512B */
_Min_Stack_Size = 0x04000;  /* 1KB  */

_estack = ORIGIN(RAM) + LENGTH(RAM);

SECTIONS
{
  .isr_vector :
  {
    . = ALIGN(4);
    KEEP(*(.isr_vector))
    . = ALIGN(4);
  } > FLASH

  .text :
  {
    . = ALIGN(4);
    *(.text) *(.text*)
    *(.rodata) *(.rodata*)
    *(.glue_7) *(.glue_7t)
    KEEP(*(.init)) KEEP(*(.fini))
    __exidx_start = .;
    *(.ARM.exidx* .gnu.linkonce.armexidx.*)
    __exidx_end   = .;

    . = ALIGN(4);
    _etext = .;     
  } > FLASH

  _sidata = LOADADDR(.data);

  .data : AT ( _etext )
  {
    . = ALIGN(4);
    _sdata = .;
    *(.data) *(.data*)
    . = ALIGN(4);
    _edata = .;
  } > RAM


  ._user_heap_stack (NOLOAD) :
  {
    . = ALIGN(8);
    __heap_start__ = .;
    . = . + _Min_Heap_Size;
    __heap_end__ = .;

    . = . + _Min_Stack_Size;
    . = ALIGN(8);
  } > RAM

  .bss (NOLOAD) :
  {
    . = ALIGN(4);
    _sbss = .;
    *(.bss) *(.bss*)
    *(COMMON)
    . = ALIGN(4);
    _ebss = .;
  } > RAM

  /DISCARD/ : { *(.note*) *(.comment*) }
}

PROVIDE(__data_start__ = _sdata);
PROVIDE(__data_end__   = _edata);
PROVIDE(__bss_start__  = _sbss);
PROVIDE(__bss_end__    = _ebss);

PROVIDE(end     = __heap_end__);
PROVIDE(_end    = __heap_end__);
PROVIDE(__end__ = __heap_end__);
