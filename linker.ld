/* STM32G474-like: 512K FLASH, 128K RAM */
ENTRY(Reset_Handler)

MEMORY {
  FLASH (rx) : ORIGIN = 0x00000000, LENGTH = 512K
  RAM   (rwx): ORIGIN = 0x20000000, LENGTH = 128K
}

/* Tùy chỉnh heap/stack tối thiểu */
_Min_Heap_Size  = 0x0200;  /* 512B */
_Min_Stack_Size = 0x0400;  /* 1KB  */

/* Đỉnh stack */
_estack = ORIGIN(RAM) + LENGTH(RAM);

SECTIONS
{
  /* Vector table ở đầu FLASH */
  .isr_vector :
  {
    . = ALIGN(4);
    KEEP(*(.isr_vector))
    . = ALIGN(4);
  } > FLASH

  /* Code & hằng số */
  .text :
  {
    . = ALIGN(4);
    *(.text) *(.text*)
    *(.rodata) *(.rodata*)
    *(.glue_7) *(.glue_7t)
    KEEP(*(.init)) KEEP(*(.fini))
    /* Đặt exidx NGAY TRONG VÙNG FLASH TRƯỚC _etext */
    __exidx_start = .;
    *(.ARM.exidx* .gnu.linkonce.armexidx.*)
    __exidx_end   = .;

    . = ALIGN(4);
    _etext = .;      /* LMA cho .data sẽ lấy ở đây */
  } > FLASH

  /* LMA cho .data: */
  _sidata = LOADADDR(.data);

  .data : AT ( _etext )
  {
    . = ALIGN(4);
    _sdata = .;
    *(.data) *(.data*)
    . = ALIGN(4);
    _edata = .;
  } > RAM


  /* Heap & Stack (NOLOAD) để tạo mốc end/__end__ */
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

  /* (tuỳ chọn) bỏ bớt note/comment */
  /DISCARD/ : { *(.note*) *(.comment*) }
}

/* --------- Alias hữu ích cho rdimon/newlib & tương thích code ---------- */

/* newlib/libgloss đôi khi cần các tên này: */
PROVIDE(__data_start__ = _sdata);
PROVIDE(__data_end__   = _edata);
PROVIDE(__bss_start__  = _sbss);
PROVIDE(__bss_end__    = _ebss);

/* Ràng buộc “end” làm cuối heap (phù hợp syscalls _sbrk của rdimon) */
PROVIDE(end     = __heap_end__);
PROVIDE(_end    = __heap_end__);
PROVIDE(__end__ = __heap_end__);
