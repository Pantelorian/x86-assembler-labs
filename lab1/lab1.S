.code16
.global _start

.section .text

_start:
    xorw %ax, %ax
    movw %ax, %ds
    movw %ax, %es

    /* Вывод успешного чтения */
    movw $hello_msg, %si
    call print

    /* ============================= */
    /* Чтение 2 первых секторов с диска 0x00 */
    /* ============================= */
    movw $0x8000, %bx       # Буфер для данных (ES:BX = 0x0000:0x8000)
    movb $0x00, %dl         # Первый жёсткий диск (DL = 0)
    movb $0x02, %ah         # Функция чтения
    movb $2, %al            # 2 сектора
    movb $0, %ch            # Цилиндр 0
    movb $1, %cl            # Сектор 1 (начальный)
    movb $0, %dh            # Головка 0
    int $0x13
    jc error                # Обработка ошибки

    /* Вывод успешного чтения */
    movw $read_ok_msg, %si
    call print

    /* ============================== */
    /* Запись текста на диск */
    /* ============================== */
    /* Подготовка текста в буфере */
    movw $text_data, %si
    movw $0xc000, %di
    movw $(text_end - text_data), %cx
    rep movsb

    /* Запись на диск */
    movw $0xc000, %bx       # Источник данных
    movb $0x00, %dl         # Первый диск (DL = 0)
    movb $0x03, %ah         # Функция записи
    movb $1, %al            # 1 сектор
    movb $0, %ch            # Цилиндр 0
    movb $3, %cl            # Сектор 1
    movb $0, %dh            # Головка 0
    int $0x13
    jc error                # Обработка ошибки

    /* Вывод успешной записи */
    movw $write_ok_msg, %si
    call print

    /* ============================== */
    /* Вывод текста, считанного с диска */
    /* ============================== */
    movw $read_data_msg, %si
    call print

    /* Вывод первого сектора */
    movw $0x8000, %si
    call print

    /* Перенос строки между секторами */
    movw $newline_msg, %si
    call print

    /* Вывод второго сектора */
    movw $0x8200, %si
    call print

    hlt
loop: jmp loop
error:
    movw $error_msg, %si
    call print
    hlt

/* Функция вывода строки */
print:
    lodsb
    orb %al, %al
    jz 1f
    movb $0x0E, %ah
    int $0x10
    jmp print
1:  ret

.data
/* Текстовые сообщения */
read_ok_msg:    .asciz "Read 2 sectors: OK\r\n"
write_ok_msg:   .asciz "Write 1 sector: OK\r\n"
read_data_msg:  .asciz "\r\nData read from disk:\r\n"
error_msg:      .asciz "Error!\r\n"
newline_msg:    .asciz "\r\n"  # Перенос строки
hello_msg:      .asciz "Starting reading data from fda\r\n"
/* Данные для записи на диск */
text_data:      .asciz "Hello from X86\r\n"
text_end:
