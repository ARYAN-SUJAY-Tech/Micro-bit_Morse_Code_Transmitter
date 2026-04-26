.syntax unified
.cpu cortex-m4
.thumb

/* ============================================================
   Register addresses
   ============================================================ */
.equ P0_OUT,         0x50000504
.equ P0_IN,          0x50000510
.equ P0_PIN_CNF,     0x50000700
.equ P1_OUT,         0x50000804
.equ P1_IN,          0x50000810
.equ P1_PIN_CNF,     0x50000A00

/* LED matrix pins — Port 0 */
.equ ROW_1,  21
.equ ROW_2,  22
.equ ROW_3,  15
.equ ROW_4,  24
.equ ROW_5,  19
.equ COL_1,  28
.equ COL_2,  11
.equ COL_3,  31
.equ COL_5,  30

/* COL_4 is on Port 1 */
.equ COL_4,   5

/* Inputs */
.equ BTN_A,    14
.equ BTN_B,    23
.equ TOUCH,     4

/* PIN_CNF values */
.equ CNF_OUTPUT,        0x00000001
.equ CNF_INPUT_PULLUP,  0x0000000C
.equ CNF_INPUT_NOPULL,  0x00000000

/* Symbol values */
.equ SYM_DOT,   0
.equ SYM_DASH,  1

/* Sentinel */
.equ INVALID,  0xFF


/* ============================================================
   Morse table for A-Z (packed encoding)
   ============================================================ */
.section .rodata
.align 2
morse_table:
    .byte 0x42   /* A: .-   */
    .byte 0x84   /* B: -... */
    .byte 0xA4   /* C: -.-. */
    .byte 0x83   /* D: -..  */
    .byte 0x01   /* E: .    */
    .byte 0x24   /* F: ..-. */
    .byte 0xC3   /* G: --.  */
    .byte 0x04   /* H: .... */
    .byte 0x02   /* I: ..   */
    .byte 0x74   /* J: .--- */
    .byte 0xA3   /* K: -.-  */
    .byte 0x44   /* L: .-.. */
    .byte 0xC2   /* M: --   */
    .byte 0x82   /* N: -.   */
    .byte 0xE3   /* O: ---  */
    .byte 0x64   /* P: .--. */
    .byte 0xD4   /* Q: --.- */
    .byte 0x43   /* R: .-.  */
    .byte 0x03   /* S: ...  */
    .byte 0x81   /* T: -    */
    .byte 0x23   /* U: ..-  */
    .byte 0x14   /* V: ...- */
    .byte 0x63   /* W: .--  */
    .byte 0x94   /* X: -..- */
    .byte 0xB4   /* Y: -.-- */
    .byte 0xC4   /* Z: --.. */
morse_table_end:


/* ============================================================
   5x5 bitmap font for A-Z
   5 bytes per letter, one byte per row.
   In each byte: bit 4 = leftmost column (COL_1), bit 0 = rightmost (COL_5).
   ============================================================ */
.align 2
font_table:
    /* A */
    .byte 0x0E, 0x11, 0x1F, 0x11, 0x11
    /* B */
    .byte 0x1E, 0x11, 0x1E, 0x11, 0x1E
    /* C */
    .byte 0x0F, 0x10, 0x10, 0x10, 0x0F
    /* D */
    .byte 0x1E, 0x11, 0x11, 0x11, 0x1E
    /* E */
    .byte 0x1F, 0x10, 0x1E, 0x10, 0x1F
    /* F */
    .byte 0x1F, 0x10, 0x1E, 0x10, 0x10
    /* G */
    .byte 0x0F, 0x10, 0x13, 0x11, 0x0F
    /* H */
    .byte 0x11, 0x11, 0x1F, 0x11, 0x11
    /* I */
    .byte 0x1F, 0x04, 0x04, 0x04, 0x1F
    /* J */
    .byte 0x07, 0x02, 0x02, 0x12, 0x0C
    /* K */
    .byte 0x11, 0x12, 0x1C, 0x12, 0x11
    /* L */
    .byte 0x10, 0x10, 0x10, 0x10, 0x1F
    /* M */
    .byte 0x11, 0x1B, 0x15, 0x11, 0x11
    /* N */
    .byte 0x11, 0x19, 0x15, 0x13, 0x11
    /* O */
    .byte 0x0E, 0x11, 0x11, 0x11, 0x0E
    /* P */
    .byte 0x1E, 0x11, 0x1E, 0x10, 0x10
    /* Q */
    .byte 0x0E, 0x11, 0x11, 0x12, 0x0D
    /* R */
    .byte 0x1E, 0x11, 0x1E, 0x12, 0x11
    /* S */
    .byte 0x0F, 0x10, 0x0E, 0x01, 0x1E
    /* T */
    .byte 0x1F, 0x04, 0x04, 0x04, 0x04
    /* U */
    .byte 0x11, 0x11, 0x11, 0x11, 0x0E
    /* V */
    .byte 0x11, 0x11, 0x11, 0x0A, 0x04
    /* W */
    .byte 0x11, 0x11, 0x15, 0x1B, 0x11
    /* X */
    .byte 0x11, 0x0A, 0x04, 0x0A, 0x11
    /* Y */
    .byte 0x11, 0x0A, 0x04, 0x04, 0x04
    /* Z */
    .byte 0x1F, 0x02, 0x04, 0x08, 0x1F

/* "Invalid" pattern: an X */
invalid_pattern:
    .byte 0x11, 0x0A, 0x04, 0x0A, 0x11


/* ============================================================
   .bss
   ============================================================ */
.section .bss
.align 2
morse_buffer:    .space 8
morse_length:    .space 1
prev_a:          .space 1
prev_b:          .space 1
prev_touch:      .space 1
last_letter:     .space 1     /* 0=none, 1-26=letter, 0xFF=invalid */
scan_row:        .space 1     /* current scan row 0-4 */


/* ============================================================
   Main
   ============================================================ */
.section .text
.global main
.thumb_func
main:
    bl configure_pins
    bl init_state

main_loop:
    bl read_inputs
    bl scan_display
    b main_loop


/* ============================================================
   read_inputs: edge-detect the three inputs and update the state
   ============================================================ */
.thumb_func
read_inputs:
    push {r4, r5, r6, r7, lr}

    ldr r0, =P0_IN
    ldr r4, [r0]
    ldr r0, =P1_IN
    ldr r5, [r0]

    /* Button A → DASH */
    movs r6, #1
    lsls r6, r6, #BTN_A
    tst r4, r6
    ite eq
    moveq r6, #0
    movne r6, #1
    ldr r0, =prev_a
    ldrb r7, [r0]
    strb r6, [r0]
    cmp r7, #1
    bne .ri_check_b
    cmp r6, #0
    bne .ri_check_b
    movs r0, #SYM_DASH
    bl append_symbol

.ri_check_b:
    /* Button B → DOT */
    movs r6, #1
    lsls r6, r6, #BTN_B
    tst r4, r6
    ite eq
    moveq r6, #0
    movne r6, #1
    ldr r0, =prev_b
    ldrb r7, [r0]
    strb r6, [r0]
    cmp r7, #1
    bne .ri_check_t
    cmp r6, #0
    bne .ri_check_t
    movs r0, #SYM_DOT
    bl append_symbol

.ri_check_t:
    /* Touch → decode */
    movs r6, #1
    lsls r6, r6, #TOUCH
    tst r5, r6
    ite eq
    moveq r6, #0
    movne r6, #1
    ldr r0, =prev_touch
    ldrb r7, [r0]
    strb r6, [r0]
    cmp r7, #1
    bne .ri_done
    cmp r6, #0
    bne .ri_done
    bl decode_buffer

.ri_done:
    pop {r4, r5, r6, r7, pc}


/* ============================================================
   append_symbol(r0)
   ============================================================ */
.thumb_func
append_symbol:
    push {r4, r5, lr}
    ldr r4, =morse_length
    ldrb r5, [r4]
    cmp r5, #8
    bge .as_done
    ldr r1, =morse_buffer
    strb r0, [r1, r5]
    adds r5, r5, #1
    strb r5, [r4]
.as_done:
    pop {r4, r5, pc}


/* ============================================================
   encode_buffer → r0
   ============================================================ */
.thumb_func
encode_buffer:
    push {r4, r5, r6, lr}
    ldr r4, =morse_length
    ldrb r4, [r4]
    cmp r4, #4
    bgt .eb_invalid
    cmp r4, #0
    beq .eb_invalid
    movs r5, #0
    movs r6, #0
    ldr r1, =morse_buffer
.eb_loop:
    cmp r6, r4
    bge .eb_done
    ldrb r2, [r1, r6]
    lsls r5, r5, #1
    orrs r5, r5, r2
    adds r6, r6, #1
    b .eb_loop
.eb_done:
    movs r2, #8
    subs r2, r2, r4
    lsls r5, r5, r2
    orrs r5, r5, r4
    movs r0, r5
    pop {r4, r5, r6, pc}
.eb_invalid:
    movs r0, #INVALID
    pop {r4, r5, r6, pc}


/* ============================================================
   decode_buffer
   ============================================================ */
.thumb_func
decode_buffer:
    push {r4, r5, r6, lr}
    bl encode_buffer
    movs r4, r0
    cmp r4, #INVALID
    beq .db_invalid
    ldr r5, =morse_table
    ldr r6, =morse_table_end
    movs r3, #0
.db_search:
    cmp r5, r6
    bge .db_invalid
    ldrb r2, [r5]
    cmp r2, r4
    beq .db_found
    adds r5, r5, #1
    adds r3, r3, #1
    b .db_search
.db_found:
    adds r3, r3, #1
    ldr r0, =last_letter
    strb r3, [r0]
    b .db_clear
.db_invalid:
    movs r3, #INVALID
    ldr r0, =last_letter
    strb r3, [r0]
.db_clear:
    ldr r0, =morse_length
    movs r1, #0
    strb r1, [r0]
    pop {r4, r5, r6, pc}


/* ============================================================
   scan_display: light one row of the current letter bitmap.
   On each call, advances scan_row to next row.
   With ~5 calls per millisecond we get well above flicker fusion.
   ============================================================ */
.thumb_func
scan_display:
    push {r4, r5, r6, r7, lr}

    /* Get current scan row */
    ldr r0, =scan_row
    ldrb r4, [r0]            /* r4 = row 0..4 */

    /* Get last_letter to determine which bitmap to use */
    ldr r0, =last_letter
    ldrb r5, [r0]            /* r5 = letter index */

    cmp r5, #0
    beq .sd_blank            /* no letter → all off */
    cmp r5, #INVALID
    beq .sd_invalid

    /* Valid letter: pointer = font_table + (letter-1)*5 + row */
    subs r5, r5, #1          /* zero-based letter index */
    movs r2, #5
    muls r5, r2, r5          /* r5 = (letter-1) * 5 */
    ldr r6, =font_table
    adds r6, r6, r5
    adds r6, r6, r4          /* r6 = pointer to this row's byte */
    ldrb r7, [r6]            /* r7 = bitmap byte for this row */
    b .sd_have_bitmap

.sd_invalid:
    ldr r6, =invalid_pattern
    adds r6, r6, r4
    ldrb r7, [r6]
    b .sd_have_bitmap

.sd_blank:
    movs r7, #0

.sd_have_bitmap:
    /* r7 holds 5-bit bitmap for current row.
       bit 4 = COL_1 (leftmost), bit 3 = COL_2, bit 2 = COL_3,
       bit 1 = COL_4, bit 0 = COL_5.

       Build P0 OUT value:
         - The current row pin: HIGH (active)
         - All other row pins: LOW (we'll just leave them at 0)
         - Each COL pin (port 0): LOW if its bit in r7 is set (lit),
           HIGH if cleared (unlit / disabled).
         - Why HIGH for unlit? With ROW HIGH, COL must be LOW for
           current to flow. If COL is HIGH, both ends are HIGH, no
           current → LED off.
    */

    /* First decide which row pin to activate */
    cmp r4, #0
    beq .sd_r1
    cmp r4, #1
    beq .sd_r2
    cmp r4, #2
    beq .sd_r3
    cmp r4, #3
    beq .sd_r4
    /* else row 4 (last) */
    ldr r0, =(1 << ROW_5)
    b .sd_row_done
.sd_r1:
    ldr r0, =(1 << ROW_1)
    b .sd_row_done
.sd_r2:
    ldr r0, =(1 << ROW_2)
    b .sd_row_done
.sd_r3:
    ldr r0, =(1 << ROW_3)
    b .sd_row_done
.sd_r4:
    ldr r0, =(1 << ROW_4)
.sd_row_done:
    /* r0 = row bit (will be HIGH) */
    movs r1, r0              /* r1 = P0 OUT value being built */

    /* For each column on Port 0, set its bit HIGH if NOT lit */
    /* COL_1 = bit 4 of bitmap */
    movs r2, #1
    lsls r2, r2, #4          /* mask for bit 4 */
    tst r7, r2
    beq .sd_col1_off
    b .sd_col1_done          /* lit → leave bit 0 (LOW) */
.sd_col1_off:
    ldr r2, =(1 << COL_1)
    orrs r1, r1, r2
.sd_col1_done:

    /* COL_2 = bit 3 */
    movs r2, #1
    lsls r2, r2, #3
    tst r7, r2
    beq .sd_col2_off
    b .sd_col2_done
.sd_col2_off:
    ldr r2, =(1 << COL_2)
    orrs r1, r1, r2
.sd_col2_done:

    /* COL_3 = bit 2 */
    movs r2, #1
    lsls r2, r2, #2
    tst r7, r2
    beq .sd_col3_off
    b .sd_col3_done
.sd_col3_off:
    ldr r2, =(1 << COL_3)
    orrs r1, r1, r2
.sd_col3_done:

    /* COL_5 = bit 0 */
    movs r2, #1
    tst r7, r2
    beq .sd_col5_off
    b .sd_col5_done
.sd_col5_off:
    ldr r2, =(1 << COL_5)
    orrs r1, r1, r2
.sd_col5_done:

    /* Write Port 0 OUT */
    ldr r0, =P0_OUT
    str r1, [r0]

    /* Now Port 1: only COL_4 (bit 1 of bitmap) */
    movs r2, #1
    lsls r2, r2, #1
    tst r7, r2
    beq .sd_col4_off
    /* lit: bit 0 of P1 OUT */
    movs r1, #0
    b .sd_col4_done
.sd_col4_off:
    ldr r1, =(1 << COL_4)
.sd_col4_done:
    ldr r0, =P1_OUT
    str r1, [r0]

    /* Tiny delay so this row is visible */
    ldr r2, =1500
.sd_delay:
    subs r2, r2, #1
    bne .sd_delay

    /* Advance scan_row: (row + 1) mod 5 */
    adds r4, r4, #1
    cmp r4, #5
    blt .sd_save
    movs r4, #0
.sd_save:
    ldr r0, =scan_row
    strb r4, [r0]

    pop {r4, r5, r6, r7, pc}


/* ============================================================
   init_state
   ============================================================ */
.thumb_func
init_state:
    movs r1, #1
    ldr r0, =prev_a
    strb r1, [r0]
    ldr r0, =prev_b
    strb r1, [r0]
    ldr r0, =prev_touch
    strb r1, [r0]
    movs r1, #0
    ldr r0, =last_letter
    strb r1, [r0]
    ldr r0, =scan_row
    strb r1, [r0]
    bx lr


/* ============================================================
   configure_pins
   ============================================================ */
.thumb_func
configure_pins:
    /* Port 0 outputs */
    ldr r0, =P0_PIN_CNF
    ldr r1, =CNF_OUTPUT
    str r1, [r0, #(4*ROW_1)]
    str r1, [r0, #(4*ROW_2)]
    str r1, [r0, #(4*ROW_3)]
    str r1, [r0, #(4*ROW_4)]
    str r1, [r0, #(4*ROW_5)]
    str r1, [r0, #(4*COL_1)]
    str r1, [r0, #(4*COL_2)]
    str r1, [r0, #(4*COL_3)]
    str r1, [r0, #(4*COL_5)]

    /* Port 0 inputs */
    ldr r1, =CNF_INPUT_PULLUP
    str r1, [r0, #(4*BTN_A)]
    str r1, [r0, #(4*BTN_B)]

    /* Port 1: COL_4 output, TOUCH input */
    ldr r0, =P1_PIN_CNF
    ldr r1, =CNF_OUTPUT
    str r1, [r0, #(4*COL_4)]
    ldr r1, =CNF_INPUT_NOPULL
    str r1, [r0, #(4*TOUCH)]

    bx lr
