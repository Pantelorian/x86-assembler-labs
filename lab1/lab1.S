.code16                    
.global _start              
.section .text             

_start:
    xorw %ax, %ax          
    movw %ax, %ds          
    movw %ax, %es          

    movw $hello_msg, %si    
    call print              

    /* ============================= */
    /* Чтение 2 первых секторов с диска 0x00 */
    /* ============================= */
    movw $0x8000, %bx       # Буфер для данных (ES:BX = 0x0000:0x8000)
    movb $0x80, %dl         # Номер диска: первый диск hda 
    movb $0x02, %ah         # AH = 0x02: Функция чтения секторов BIOS
    movb $2, %al            # AL = 2: Читаем 2 сектора
    movb $0, %ch            # CH = 0: Цилиндр 0
    movb $1, %cl            # CL = 1: Начальный сектор (считается с 1)
    movb $0, %dh            # DH = 0: Головка 0
    int $0x13               # Вызов BIOS функции 0x13 для чтения секторов
    jc error                # Если произошла ошибка (CF = 1), переходим к обработке ошибки

    movw $read_ok_msg, %si  
    call print     

    /* ============================== */
    /* Вывод текста, считанного с диска */
    /* ============================== */

    movw $read_data_msg, %si 
    call print               

    /* Вывод первого сектора */
    movw $0x8000, %si        # Загружаем адрес считанного первого сектора (буфер 0x8000) в SI
    call print               

    movw $newline_msg, %si   
    call print               

    /* Вывод второго сектора */
    movw $0x8200, %si        # Загружаем адрес считанного второго сектора (буфер 0x8200) в SI
    call print   

    movw $newline_msg, %si   
    call print                             

    /* ============================== */
    /* Запись текста на диск */
    /* ============================== */

    /* Подготовка текста в буфере */
    movw $text_data, %si    # Источник данных ds:si
    movw $0x9000, %di       # Адрес назначения es:di
    movw $(text_end - text_data), %cx # Количество байт для копирования
    rep movsb               # Копируем данные из источника в буфер

    /* Запись на диск */
    movw $0x9000, %bx       # Буфер данных (ES:BX = 0x0000:0x9000)
    movb $0x80, %dl         # Номер диска: первый диск hda
    movb $0x03, %ah         # AH = 0x03: Функция записи секторов BIOS
    movb $1, %al            # AL = 1: Записываем 1 сектор
    movb $0, %ch            # CH = 0: Цилиндр 0
    movb $3, %cl            # CL = 3: Сектор 3 (считается с 1)
    movb $0, %dh            # DH = 0: Головка 0
    int $0x13               # Вызов BIOS прерывания 0x13 для записи секторов
    jc error                # Если произошла ошибка (CF = 1), переходим к обработке ошибки

    movw $write_ok_msg, %si 
    call print              

    hlt                     
loop: jmp loop             

error:
    movw $error_msg, %si     
    call print               
    hlt                      

/* Функция вывода строки */
print:
    lodsb                    # Загружаем байт из [SI] в AL и увеличиваем SI
    orb %al, %al             # Проверяем, является ли AL нулевым (конец строки)
    jz 1f                    # Если да, завершаем вывод
    movb $0x0E, %ah          # AH = 0x0E: Функция вывода символа BIOS
    int $0x10                # Вызов BIOS прерывания 0x10 для вывода символа
    jmp print                # Повторяем для следующего символа
1:  ret                      # Возвращаемся к вызывающему коду

.section .data              # Секция данных

/* Текстовые сообщения */
read_ok_msg:    .asciz "Read 2 sectors: OK\r\n"      # Сообщение об успешном чтении
write_ok_msg:   .asciz "Write 1 sector: OK\r\n"      # Сообщение об успешной записи
read_data_msg:  .asciz "\r\nData read from disk:\r\n" # Сообщение перед данными с диска
error_msg:      .asciz "Error!\r\n"                  # Сообщение об ошибке
newline_msg:    .asciz "\r\n"                       # Перенос строки
hello_msg:      .asciz "Starting reading data from hda\r\n" # Приветственное сообщение

/* Данные для записи на диск */
text_data:      .asciz "ORGEVM K3 4 kurs\r\n"          # Текст для записи на диск
text_end:                               # Конец данных
