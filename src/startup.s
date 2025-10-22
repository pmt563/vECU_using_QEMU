    .syntax unified
    .cpu cortex-m4
    .fpu fpv4-sp-d16
    .thumb

    .extern main
    .extern SystemInit
    .extern __libc_init_array

    .extern _estack        
    .extern _sidata       
    .extern _sdata
    .extern _edata
    .extern __bss_start__
    .extern __bss_end__

    .section .isr_vector, "a", %progbits
    .type   g_pfnVectors, %object
    .size   g_pfnVectors, .-g_pfnVectors

g_pfnVectors:
    .word   _estack                
    .word   Reset_Handler          
    .word   NMI_Handler
    .word   HardFault_Handler
    .word   MemManage_Handler
    .word   BusFault_Handler
    .word   UsageFault_Handler
    .word   0                       
    .word   0
    .word   0
    .word   0
    .word   SVC_Handler
    .word   DebugMon_Handler
    .word   0                       
    .word   PendSV_Handler
    .word   SysTick_Handler

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

    .text
    .thumb
    .thumb_func
    .align 2
.global Reset_Handler
Reset_Handler:
    ldr   r0, =0xE000ED88        
    ldr   r1, [r0]
    orr   r1, r1, #(0xF << 20)
    str   r1, [r0]
    dsb
    isb

    ldr   r0, =_sidata
    ldr   r1, =_sdata
    ldr   r2, =_edata
1:
    cmp   r1, r2
    ittt  lt
    ldrlt r3, [r0], #4
    strlt r3, [r1], #4
    blt   1b

    ldr   r0, =__bss_start__
    ldr   r1, =__bss_end__
    movs  r2, #0
2:
    cmp   r0, r1
    itt   lt
    strlt r2, [r0], #4
    blt   2b

    bl    __libc_init_array

    bl    main

3:  b 3b
