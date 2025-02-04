ENTRY(_start)

SECTIONS {
    . = 0x8000;

    .text : {
        *(.text)
    }

    .data : {
        *(.data)
    }

    .stack : {
        *(.stack)
    }
    /DISCARD/ : {
        *(.note*)
        *(.comment)
        *(.gnu*)
    }
}
