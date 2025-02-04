ENTRY(_start)

SECTIONS {
    . = 0x7C00;

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
. = 0x7DFE;

    /* Добавляем сигнатуру загрузочного сектора */
    .sig : AT(0x7DFE)
    {
        SHORT(0xAA55) /* Последние два байта должны быть 0x55AA */
    }
       /* Добавляем сигнатуру загрузочного сектора */
}
