    .syntax unified
    .cpu cortex-m4
    .fpu fpv4-sp-d16
    .thumb

    .extern main
    .extern SystemInit
    .extern __libc_init_array

/* Symbols từ linker.ld */
    .extern _estack        /* đỉnh stack */
    .extern _sidata        /* src của .data trong FLASH */
    .extern _sdata
    .extern _edata
    .extern __bss_start__
    .extern __bss_end__

/* Vector Table (nằm ở .isr_vector trong FLASH) */
    .section .isr_vector, "a", %progbits
    .type   g_pfnVectors, %object
    .size   g_pfnVectors, .-g_pfnVectors

g_pfnVectors:
    .word   _estack                 /* 0: Initial MSP */
    .word   Reset_Handler           /* 1: Reset */
    .word   NMI_Handler
    .word   HardFault_Handler
    .word   MemManage_Handler
    .word   BusFault_Handler
    .word   UsageFault_Handler
    .word   0                       /* Reserved */
    .word   0
    .word   0
    .word   0
    .word   SVC_Handler
    .word   DebugMon_Handler
    .word   0                       /* Reserved */
    .word   PendSV_Handler
    .word   SysTick_Handler

/* IRQ tối thiểu (weak alias) */
    .weak   NMI_Handler, HardFault_Handler, MemManage_Handler, BusFault_Handler, UsageFault_Handler
    .weak   SVC_Handler, DebugMon_Handler, PendSV_Handler, SysTick_Handler

    .thumb_func
NMI_Handler:          b .
HardFault_Handler:    b .
MemManage_Handler:    b .
BusFault_Handler:     b .
UsageFault_Handler:   b .
SVC_Handler:          bx lr
DebugMon_Handler:     bx lr
PendSV_Handler:       bx lr
SysTick_Handler:      bx lr

/* Reset Handler: copy .data, zero .bss, enable FPU, SystemInit, ctor, main */
    .text
    .thumb
    .thumb_func
    .align 2
.global Reset_Handler
Reset_Handler:
    /* Bật FPU (Cortex-M4F) */
    ldr   r0, =0xE000ED88        /* CPACR */
    ldr   r1, [r0]
    orr   r1, r1, #(0xF << 20)   /* full access CP10/CP11 */
    str   r1, [r0]
    dsb
    isb

    /* Copy .data từ FLASH -> RAM */
    ldr   r0, =_sidata
    ldr   r1, =_sdata
    ldr   r2, =_edata
1:
    cmp   r1, r2
    ittt  lt
    ldrlt r3, [r0], #4
    strlt r3, [r1], #4
    blt   1b

    /* Zero .bss */
    ldr   r0, =__bss_start__
    ldr   r1, =__bss_end__
    movs  r2, #0
2:
    cmp   r0, r1
    itt   lt
    strlt r2, [r0], #4
    blt   2b

    /* Gọi constructors C++ (nếu dùng newlib) */
    bl    __libc_init_array

    /* Vào main */
    bl    main

/* Nếu main trả về -> loop */
3:  b 3b
