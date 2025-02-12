.code16
.global _start

.section .text

_start:
    xorw %ax, %ax
    movw %ax, %ds
    movw %ax, %es

    movw $0x8000, %bx       # Буфер для данных (ES:BX = 0x0000:0x8000)
    movb $0x08, %ah         # Функция 08h: Read Drive Parameters
    movb $0x80, %dl         # Первый жёсткий диск (DL = 80)

    int $0x13

    andb $0x3F, %cl
    sub $0x01, %cl
    movw %cx, %ax
    movw $0x8000, %bx       # Буфер для данных (ES:BX = 0x0000:0x8000)

    movb $0x80, %dl         # Первый жёсткий диск (DL = 80)

    movb $2, %cl            # Начинаем с сектора 2 (CL хранит номер сектора)

load_sectors:
    pushw %ax
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
    popw %ax
    cmpb %al, %cl            # Проверяем, загрузили ли мы все секторы
    jl load_sectors

long_jmp:
    ljmp $0x0000, $0x8000   # Переход к загруженному коду

disk_error:
# Смотрим на ah, если ah=12, то дальний переход на 0x8000, иначе ошибка 
    
    cmpb $12, %ah
    je long_jmp

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
