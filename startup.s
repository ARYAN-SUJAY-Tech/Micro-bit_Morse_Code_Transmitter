.syntax unified
.cpu cortex-m4
.thumb

/* ============================================================
   Interrupt Vector Table
   ============================================================ */
.section .vectors, "a"
.word _stack_top
.word Reset_Handler

/* ============================================================
   Reset Handler
   Before calling main, we zero-initialize the .bss section.
   Without this, RAM contents are undefined on power-on, and
   our "uninitialized" variables could hold any value.
   ============================================================ */
.section .text
.global Reset_Handler
.thumb_func
Reset_Handler:
    /* ---- Zero the .bss section ---- */
    ldr r0, =_bss_start    /* r0 = start address */
    ldr r1, =_bss_end      /* r1 = end address */
    movs r2, #0            /* r2 = zero (the value to write) */

bss_loop:
    cmp r0, r1
    bge bss_done           /* If r0 >= r1, we're done */
    str r2, [r0]           /* Write 0 to *r0 */
    adds r0, r0, #4        /* Move to next word */
    b bss_loop

bss_done:
    /* ---- Now jump to main ---- */
    bl main

hang:
    b hang