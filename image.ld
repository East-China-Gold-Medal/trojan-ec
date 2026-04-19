/* @file image.ld

    Linker script to place everything into STM32 correctly.
    SPDX-License-Identifier: WTFPL

*/

MEMORY
{
    FLASH (rx)  : ORIGIN = 0x08000000, LENGTH = 0x200000
    /* RAM cannot be executed, protected by NX policy */
    RAM   (rw)  : ORIGIN = 0x20000000, LENGTH = 0xA0000
}

SECTIONS
{
    .isr_vector : {
        KEEP(*(.isr_vector))
    } > FLASH

    .text : {
        *(.text*)
        *(.rodata*)
    } > FLASH

    /* .data section: Copy to RAM at runtime */
    .data : AT(ADDR(.text) + SIZEOF(.text)) {
        data_begin = .;
        *(.data*)
        data_end = .;
    } > RAM

    data_addr_in_flash = LOADADDR(.data);

    .bss : {
        bss_begin = .;
        *(.bss*)
        *(COMMON)
        bss_end = .;
    } > RAM

    _stack_top = ORIGIN(RAM) + LENGTH(RAM);

    /DISCARD/ : {
        *(.ARM.exidx)
    }
}