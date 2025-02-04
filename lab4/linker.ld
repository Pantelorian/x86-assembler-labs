ENTRY(_start)

SECTIONS {
    . = 0x8000;

    .text : {
        *(.text)
    }

    .data : {
        *(.data)
    }

    .bss : {
        *(.bss)
    }
    /DISCARD/ : {
        *(.note*)
        *(.comment)
        *(.gnu*)
    }


    /* Добавляем сигнатуру загрузочного сектора */
}
