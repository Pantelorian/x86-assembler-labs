.code16
.global _start

.section .text

_start:
    xorw %ax, %ax
    movw %ax, %ds
    movw %ax, %es

    movw $0x8000, %bx       # Буфер для данных (ES:BX = 0x0000:0x8000)
    movb $0x00, %dl         # Первый жёсткий диск (DL = 0)
    movb $2, %cl            # Начинаем с сектора 2 (CL хранит номер сектора)

load_sectors:
    movb $0x02, %ah         # Функция чтения
    movb $1, %al            # Читаем 1 сектор за раз
    movb $0, %ch            # Цилиндр 0
    movb $0, %dh            # Головка 0
    int $0x13               # Чтение сектора
    jc disk_error           # Если ошибка, переходим к обработке

    # Вывод сообщения об успешном чтении
    movw $success_msg, %si  # Загружаем адрес сообщения в SI
    call print_string

    addw $512, %bx          # Сдвигаем буфер на 512 байт
    incb %cl                # Увеличиваем номер сектора
    cmpb $9, %cl            # Проверяем, загрузили ли мы 4 сектора (2-5)
    jl load_sectors

    ljmp $0x0000, $0x8000   # Переход к загруженному коду

disk_error:
    # Вывод сообщения об ошибке
    movw $error_msg, %si    # Загружаем адрес сообщения об ошибке в SI
    call print_string
    hlt                     # Остановка процессора
    jmp disk_error

# Функция для вывода строки на экран
print_string:
    movb $0x0E, %ah         # Функция BIOS для вывода символа
print_char:
    lodsb                   # Загружаем следующий символ из строки в AL
    cmpb $0, %al            # Проверяем, достигнут ли конец строки
    je print_done           # Если да, завершаем вывод
    int $0x10               # Выводим символ на экран
    jmp print_char          # Переходим к следующему символу
print_done:
    ret

# Сообщения
success_msg: .asciz "Sector read successfully!\r\n"
error_msg: .asciz "Disk read error!\r\n"
