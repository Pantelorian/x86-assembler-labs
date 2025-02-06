#include "gdt.h"
#include "idt.h"
#include "irq.h"

#define CS  0x8                 // селектор сегмента кода
#define DS  0x10                // селектор сегмента данных
#define SS  0x18                // селектор сегмента стека
#define ES  0x20                // селектор сегмента видеобуфера
#define ED  0x28                // селектор дополнительного сегмента данных
#define STACK_SIZE  0x100       // размер стека

#define SCREEN_ROWS 25
#define SCREEN_COLS 80
#define MAX_COLS    60

#define TIMER_ROW   1
#define TIMER_COL   65

/*------------------------------------------------------
    Загрузчик первой стадии (GRUB) загружает образ программы начиная со 2 селектора
    по адресу 0x0000:0x8000 и передает на него управление: ip = 0x8000
    Процессор находится в реальном режиме

    Значения сегментных регистров:
    cs = 0x0    ds = 0x0    es = 0x0
    ss = 0x0    fs = 0x0    gs = 0x0
-------------------------------------------------------*/
/*---------------------------------------- Начало секции кода ----------------------------------------*/

.code16
.text
#.org 0x8000

.global _start
_start:
    movw    $0x3, %ax           // очистка экрана: задаем режим видеоадаптера (80x25, 16-цветный)
    int     $0x10               // используем 0x10 прерывание BIOS (ah = 0, al = 3)
    movw    $.data, %ax
    movw    $seg_data, %bx      // записываем базовый адрес семента данных в соответствующий дескриптор
    movw    %ax, 2(%bx)
    movw    $.stack, %ax        // записываем базовый адрес сегмента стека в соответствующий дескриптор
    movw    $seg_stack, %bx
    movw    %ax, 2(%bx)         // (для кода и видеобуфера базовые адреса известны)

    cli                         // запрещаем аппаратные прерывания
    movb    $0x80, %al
    outb    %al, $0x70          // запрещаем NMI (немаскируемые прерывания)
    inb     $0x92, %al          // включаем А20 адресную линию
    orb     $0x2, %al
    outb    %al, $0x92

    lgdt    gdtdesc             // загружаем значение GDTR
    lidt    idtdesc             // загружаем значение IDTR

    movl    %cr0, %eax
    orl     $1, %eax
    movl    %eax, %cr0                  // устанавливаем бит PE в регистре CR0

    ljmp    $CS, $CS_OFF(goto_prot)     // переходим в новый сегмент кода (cs, ip)
/*---------------------------------------- Теперь процессор работает в защищенном режиме ----------------------------------------*/

.code32                                 // указание процессору генерировать 32-разрядный код
goto_prot:
    movw    $DS, %ax
    movw    %ax, %ds                    // загружаем новый селектор сегмента данных
    movw    $SS, %ax
    movw    %ax, %ss				    // загружаем новый селектор сегмента стека
    movl    $STACK_SIZE, %esp           // устанавливаем указатель стека на значение на значение "дна" стека
    movw    $ES, %ax
    movw    %ax, %es                    // загружаем селектор сегмента видеобуфера

    call    init_pic                    // инициализация контроллеров прерываний

    movb    $0, %al                     // разрешаем немаскируемые прерывания
    outb    %al, $0x70
    sti                                 // разрешаем прерывания

    movw    $320, %bx                   // начальное смещение на экране
    movw    $110, %cx                   // число выводимых символов
    movw    $0x1e01, %ax                // загружаем начальный символ с атрибутом

screen:
    movw    %ax, %es:(%bx)          // записываем очередной символ в видеопамять
    addw    $2, %bx                 // смещаемся в видеобуфере
    incw    %ax                     // код следующего символа
    pushw   %cx                     // сохраняем cx
    movl    $0x0FFFFF, %ecx         // добавим паузу для наглядности

pause:
    nop
    loop    pause       // цикл паузы
    popw    %cx         // возвращаем cx
    loop    screen      // цикл вывода на экран

    int $0x80

hang:
    nop
    jmp     hang        // зацикливание

init_pic:
    pushw   %ax

    movb    $(ICW1_INIT | ICW1_ICW4_NEEDED), %al    // запись 1-ого слова инициализации в регистр команд
    outb    %al, $MASTER_PIC_COMMAND
    nop
    outb    %al, $SLAVE_PIC_COMMAND
    nop

    movb    $ICW2_MASTER_BASE_VECTOR, %al       // запись базового вектора прерываний для обоих контрллеров
    outb    %al, $MASTER_PIC_DATA
    nop
    movb    $ICW2_SLAVE_BASE_VECTOR, %al
    outb    %al, $SLAVE_PIC_DATA
    nop

    movb    $ICW3_MASTER, %al           // указание линии IRQ, к которой подключен SLAVE-контроллер
    outb    %al, $MASTER_PIC_DATA
    nop
    movb    $ICW3_SLAVE, %al            // указываем номер SLAVE-контроллера в каскаде
    outb    %al, $SLAVE_PIC_DATA
    nop

    movb    $ICW4_8086_MODE, %al        // запись последнего слова инициализации
    outb    %al, $MASTER_PIC_COMMAND
    nop
    outb    %al, $SLAVE_PIC_COMMAND
    nop

    movb    $(IRQ2|IRQ3|IRQ4|IRQ5|IRQ6|IRQ7), %al   // инициализация регистров маски обоих контроллеров
    outb    %al, $MASTER_PIC_DATA

    movb    $(IRQ0|IRQ1|IRQ2|IRQ3|IRQ4|IRQ5|IRQ6|IRQ7), %al
    outb    %al, $SLAVE_PIC_DATA

    popw    %ax
    ret

/*------------------------------------------------------
    Процедуры обработки исключений. Для каждого исключения выводится символическая
    строка с его названием и значение регистра SP. Для некоторых исключений
    предпринимаются попытки восстановления. Исключения без собственного обработчика
    перенаправляются на псевдообработчик (dummy_handler)
-------------------------------------------------------*/

/*  Обработка исключения 0: Ошибка деления (DE) */
divide_error_handler:
    pushl   %ebp
    movl    %esp, %ebp                  // инициализация указателя кадра стека
    pushl   %eax                        // сохраняем затрагиваемые регистры в стеке
    pushl   %esi
    movl    $DS_OFF(mesg_DE), %esi      // адрес строки с названием исключения в ESI
    movl    %esp, %eax                  // значение ESP при выходе в обработчик в EAX
    addl    $12, %eax
    call    print_str                   // вывод строки
    call    print_hex                   // вывод указателя стека
    call    print_endl                  // переход на следующую строку
    addw    $2, 4(%ebp)
    popl    %esi
    popl    %eax                        // возврат регистров из стека
    popl    %ebp
    iret                                // возврат из прерывания

/*  Обработка исключения 1: Исключение отладки (DB) */
debug_exception_handler:
    pushl   %ebp
    movl    %esp, %ebp                  // инициализация указателя кадра стека
    pushl   %eax                        // сохраняем затрагиваемые регистры в стеке
    pushl   %esi
    movl    $DS_OFF(mesg_DB), %esi      // адрес строки с названием исключения в ESI
    movl    %esp, %eax                  // значение ESP при выходе в обработчик в EAX
    addl    $12, %eax
    call    print_str                   // вывод строки
    call    print_hex                   // вывод указателя стека

    movl    $DS_OFF(mesg_DB2), %esi
    addl    12(%ebp), %eax              // считываем значение регистра флагов
    call    print_str
    call    print_hex                   // выводим регистр флагов

    call    print_endl                  // переход на следующую строку
    popl    %esi
    popl    %eax                        // возврат регистров из стека
    popl    %ebp
    iret                                // возврат из прерывания

/*  Обработка исключения 3: Контрольная точка (BP) */
breakpoint_handler:
    pushl   %eax
    pushl   %esi                        // сохраняем затрагиваемые регистры в стеке
    movl    $DS_OFF(mesg_BP), %esi      // адрес строки с названием исключения в ESI
    movl    %esp, %eax
    addl    $8, %eax                    // значение ESP при выходе в обработчик в EAX
    call    print_str
    call    print_hex                   // вывод на экран
    call    print_endl
    popl    %esi                        // возрат регистров из стека
    popl    %eax
    iret                                // возврат из прерывания

/*  Обработка исключения 4: Переполнение (OF) */
overflow_handler:
    pushl   %eax
    pushl   %esi                        // сохраняем затрагиваемые регистры в стеке
    movl    $DS_OFF(mesg_OF), %esi      // адрес строки с названием исключения в ESI
    movl    %esp, %eax
    addl    $8, %eax                    // значение ESP при выходе в обработчик в EAX
    call    print_str
    call    print_hex                   // вывод на экран
    call    print_endl
    popl    %esi                        // возрат регистров из стека
    popl    %eax
    iret                                // возврат из прерывания

/*  Обработка исключения 6: Недопустимая команда (UD) */
inval_opcode_handler:
    pushl   %eax
    pushl   %esi                        // сохраняем затрагиваемые регистры в стеке
    movl    $DS_OFF(mesg_UD), %esi      // адрес строки с названием исключения в ESI
    movl    %esp, %eax
    addl    $8, %eax                    // значение ESP при выходе в обработчик в EAX
    call    print_str
    call    print_hex                   // вывод на экран
    call    print_endl
    popl    %esi                        // возрат регистров из стека
    popl    %eax
0:
    jmp     0b

/*  Обработка исключения 10: Недопустимый TSS (TS) */
inval_tss_handler:
    jmp     inval_tss_handler

/*  Обработка исключения 11: Сегмент отсутствует в памяти (NP) */
seg_not_present_handler:
    pushl   %ebp
    movl    %esp, %ebp                  // инициализация указателя кадра стека
    pushl   %eax
    pushl   %esi
    movl    $DS_OFF(mesg_NP), %esi      // адрес строки с названием исключения в ESI
    movl    %esp, %eax
    addl    $12, %eax                   // значение ESP при входе в обработчик в EAX
    call    print_str
    call    print_hex
    call    print_endl

    movl    4(%ebp), %eax               // считываем код ошибки - селектор отсутствующего сегмента
    movl    $DS_OFF(GDT), %esi
    addl    %eax, %esi                  // получаем адре дескриптора в GDT
    movb    5(%esi), %al
    orb     $0x80, %al                  // устанавливаем бит присутствия "P" в дескрипторе сегмента
    movb    %al, 5(%esi)

    popl    %esi
    popl    %eax                        // возврат регистров из стека
    popl    %ebp
    addl    $4, %esp                    // удаляем код ошибки (4б) из стека
    iret                                // чтобы корректно выйти из прерывания
/*  Обработка исключения 12: Ошибка сегмента стека (SS) */
stack_seg_fault_handler:
    pushl   %eax
    pushl   %esi                        // сохраняем затрагиваемые регистры в стеке
    movl    $DS_OFF(mesg_SS), %esi      // адрес строки с названием исключения в ESI
    movl    %esp, %eax
    addl    $8, %eax                    // значение ESP при выходе в обработчик в EAX
    call    print_str
    call    print_hex                   // вывод на экран
    call    print_endl
    popl    %esi                        // возрат регистров из стека
    popl    %eax
0:
    jmp     0b

/*  Обработка исключения 13: Общее исключение защиты (GP) */
gen_prot_fault_handler:
    pushl   %eax
    pushl   %esi                        // сохраняем затрагиваемые регистры в стеке
    movl    $DS_OFF(mesg_GP), %esi      // адрес строки с названием исключения в ESI
    movl    %esp, %eax
    addl    $8, %eax                    // значение ESP при выходе в обработчик в EAX
    call    print_str
    call    print_hex                   // вывод на экран
    call    print_endl
    popl    %esi                        // возрат регистров из стека
    popl    %eax
0:
    jmp     0b

/*  Обработка исключения 14: Страничное нарушение (PF) */
page_fault_handler:
    jmp     page_fault_handler

/*  Обработка всех остальных исключений */
dummy_handler:
    pushl   %esi
    movl    $DS_OFF(mesg_NH), %esi
    call    print_str
    popl    %esi
0:
    jmp     0b

trap_handler:
    movw    $640, %bx
    movw    $110, %cx
    movw    $0x2f01, %ax
0:
    movw    %ax, %es:(%bx)
    addw    $2, %bx
    incw    %ax
    pushw   %cx
    movl    $0x0FFFF, %ecx
1:
    nop
    loop    1b
    popw    %cx
    loop    0b

    iret
/*------------------------------------------------------
    Процедуры вывода на экран строк и чисел. Реализовано простейшее управление терминалом с
    экраном 80x25 символов. Можно задать правую границу области вывода. При заполнении
    экрана терминала осуществляется его прокрутка вниз
-------------------------------------------------------*/
/*------------------------------------------------------
    Вывод символа на экран в текущую позицию. Осуществляет управление терминалом.
    Параметры: %al - код символа, %ah - атрибут. При значении символа '\n' = 0xA
    осуществляет перевод на новую строку. При заполнении экрана - прокрутка вниз.
-------------------------------------------------------*/

putchar:
    pushw   %bx
    pushw   %si                             // сохраняем затрагиваемые регистры в стеке
    pushw   %di

    movw    %ds:DS_OFF(cur_row), %si        // считываем значение текущей строки из памяти
    movw    %ds:DS_OFF(cur_col), %di        // считываем значение текущего столбца из памяти

    cmpb    $'\n', %al                      // если символ '\n' = 0xA, то перейти на следующую строку
    je      line_feed

    movw    %si, %bx                        // вычисляем адрес видеопамяти, соответствующий текущему положению на экране
    imulw   $SCREEN_COLS, %bx               // количество столбцаов, задаваемое разрешением экрана
    addw    %di, %bx
    imulw   $2, %bx

    movw    %ax, %es:(%bx)                  // выводим переданный символ в текущую позицию
    incw    %di                             // увеличиваем значение столбца
    cmpw    $MAX_COLS, %di                  // правая граница вывода в количестве символов. Может быть <=80
    jne     skip_lf                         // если превышена, то переход на следующую строку

line_feed:                                  // переход на следующую строку
    xorw    %di, %di                        // обнуляем значением столбца
    incw    %si                             // увеличиваем значение столбца
    cmpw    $SCREEN_ROWS,   %si
    jne     skip_lf                         // если строки заполнены, то прокрутка вниз
    call    scroll_screen

skip_lf:
    movw    %si, %ds:DS_OFF(cur_row)        // сохранение значений текущих строки и столбца в память
    movw    %di, %ds:DS_OFF(cur_col)

    popw    %di
    popw    %si                             // возврат регистров из стека
    popw    %bx

    ret

scroll_screen:
    nop
    ret

/*------------------------------------------------------
    Процедуры обработки аппаратных прерываний
-------------------------------------------------------*/

timer_ISR:
    pushl   %eax
    pushl   %esi

    xorl    %eax, %eax

    cmpw    $18, %ds:DS_OFF(timer_ticks)    // если количество тиков превысило 18 (секунда)
    jle     skip
    movw    $0, %ds:DS_OFF(timer_ticks)     // обнуляем счетчик тиков
    incw    %ds:DS_OFF(timer_sec)           // увеличиваем счетчик секунд
    movw    %ds:DS_OFF(timer_sec), %ax
    call    print_time                      // выводим количество секунд на экран
skip:
    incw    %ds:DS_OFF(timer_ticks)         // увеличиваем счетчик тиков
    movb    $EOI, %al
    outb    %al, $MASTER_PIC_COMMAND        // выдаем команду окончания обработки прерывания
    popl    %eax
    popl    %esi
    iret

keyboard_ISR:
    pushl   %eax
    pushl   %esi

    sti

    pushl   %ecx
    movl    $0x7FFFFFF, %ecx

0:
    nop
    loop    0b
    popl    %ecx

    xorl    %eax, %eax
    xorl    %esi, %esi

    inb     $0x60, %al                      // считываем полученный скан-код

    movl    $DS_OFF(keymap), %esi           // получаем соответствующий ему код символа
    movb    (%esi, %eax), %al               // по таблице скан-кодов
    movb    $0x7, %ah
    call    putchar                         // выводим его на экран

    inb     $0x61, %al                      // установкой старшего бита и последующим его сбросом
    orb     $0x80, %al
    outb    %al, $0x61                      // сообщим контроллеру клавиатуры о приеме кода символа
    andb    $0x7f, %al
    outb    %al, $0x61

    movb    $EOI, %al
    outb    %al, $MASTER_PIC_COMMAND        // выдаем команду окончания обработки прерывания

    popl    %esi
    popl    %eax

    iret

/*  Функция вывода символьной строки на экран.
    Параметры: esi - адрес строки. Строка должна заканчиваться нулем '\0'
    '\n' - переход на следующую строку
*/
print_str:
    pushl   %eax
    pushl   %esi
    xorl    %eax, %eax
    movb    $0x7, %ah       // белые символы на черном фоне
0:
    movb    (%esi), %al     // текущий символ строки в al
    cmpb    $0, %al         // пока не достигли конца строки '\0'
    je      1f
    incl    %esi            // переход к следующему символу
    call    putchar         // вывод символа на экран
    jmp     0b
1:
    popl    %esi
    popl    %eax
    ret

/*  Функция перехода на следующую строку */
print_endl:
    pushw   %ax
    movb    $'\n', %al
    call    putchar
    popw    %ax
    ret

print_hex:
    pushl   %eax
    pushl   %ebx
    pushl   %ecx

    xorl    %ecx, %ecx
0:
    movl    %eax, %ebx
    andl    $0xF, %ebx
    pushw   %bx
    incl    %ecx
    shrl    $4, %eax
    cmpl    $0, %eax
    jne     0b
1:
    cmpl    $0, %ecx
    je      4f
    popw    %ax
    cmpw    $10, %ax
    jl      2f
    subw    $10, %ax
    addw    $'A', %ax
    jmp     3f
2:
    addw    $'0', %ax
3:
    movb    $0x7, %ah
    call    putchar
    decl    %ecx
    jmp     1b
4:
    popl    %ecx
    popl    %ebx
    popl    %eax

    ret

print_time:
    pushl   %eax
    pushl   %ebx
    pushl   %ecx
    pushl   %edi

    movl    $TIMER_COL, %edi
    xorl    %ecx, %ecx
0:
    movl    %eax, %ebx
    andl    $0xF, %ebx
    pushw   %bx
    incl    %ecx
    shrl    $4, %eax
    cmpl    $0, %eax
    jne     0b
1:
    cmpl    $0, %ecx
    je      4f
    popw    %ax
    cmpw    $10, %ax
    jl      2f
    subw    $10, %ax
    addw    $'A', %ax
    jmp     3f
2:
    addw    $'0', %ax
3:
    movb    $0x7, %ah
    call    put_time
    decl    %ecx
    jmp     1b
4:
    popl    %edi
    popl    %ecx
    popl    %ebx
    popl    %eax

    ret
put_time:
    pushl   %eax
    pushl   %ebx

    movw    $TIMER_ROW, %bx
    imulw   $SCREEN_COLS, %bx
    addw    %di, %bx
    imulw   $2, %bx
    movw    %ax, %es:(%bx)
    incw    %di

    popl    %ebx
    popl    %eax
    ret

text_size = . - _start

/*---------------------------------------- Начало секции данных ----------------------------------------*/
    .data

/*---------------------------------------- Глобальная таблица дескрипторов ----------------------------------------*/

.align 16								                                    // процессор быстрее обращается с выровненной таблицей
GDT:
seg_null:       .quad   0							                                // нулевой дескриптор
seg_text:       descr   (0x8000, (text_size - 1), EXEC_READ, G_BYTE | SEG_32)       // дескриптор сегмента кода 	(селектор 0x0)
seg_data:       descr   (0, (data_size - 1), READ_WRITE, G_BYTE | SEG_32)           // дескриптор сегмента данных	(селектор 0x10)
seg_stack:      descr   (0, (stack_size - 1), READ_WRITE, G_BYTE | SEG_32)          // дескриптор сегмента стека	(селектор 0x18)
seg_videomem:   descr   (0xB8000, 0xFFF, READ_WRITE, G_BYTE | SEG_32)               // дескриптор видеобуфера	    (селектор 0x20)
seg_edata:      descr   (0xC0000000, 0x3FFFF, READ_WRITE, G_PAGE | SEG_32)
GDT_size = . - GDT

gdtdesc:    .word   GDT_size - 1    // предел GDT
            .long   GDT             // базовый адрес GDT

/*---------------------------------------- Таблица прерываний ----------------------------------------*/

    .align  8
IDT:
/*                                                      Вектор      Мнемоника   Описание                            Тип         Код ошибка */
    trap_gate   (CS, CS_OFF(divide_error_handler) )      // 0        #DE         Ошибка деления                      Fault       Нет
    trap_gate   (CS, CS_OFF(debug_exception_handler))   // 1        #DB         Исключение отлпдки                  Fault/Trap  Нет
    null_descr                                          // 2        -           Прерывания NMI                      Interrupt   Нет
    trap_gate   (CS, CS_OFF(breakpoint_handler))        // 3        #BP         Контрольная точка                   Trap        Нет
    trap_gate   (CS, CS_OFF(overflow_handler))          // 4        #OF         Переполнение                        Trap        Нет
    trap_gate   (CS, CS_OFF(dummy_handler))             // 5        #BR         Превышение предела                  Fault       Нет
    trap_gate   (CS, CS_OFF(inval_opcode_handler))      // 6        #UD         Недопустимая команда                Fault       Нет
    trap_gate   (CS, CS_OFF(dummy_handler))             // 7        #NM         Устройство недостпуно               Fault       Нет
    trap_gate   (CS, CS_OFF(dummy_handler))             // 8        #DF         Двойная ошибка                      Abort       Да(ноль)
    trap_gate   (CS, CS_OFF(dummy_handler))             // 9        -           Превышение сегмента сопроцессора    Fault       Нет
    trap_gate   (CS, CS_OFF(inval_tss_handler))         // 10       #TS         Недопустимый TSS                    Fault       Да
    trap_gate   (CS, CS_OFF(seg_not_present_handler))   // 11       #NP         Сегмент отсутствует в памяти        Fault       Да
    trap_gate   (CS, CS_OFF(stack_seg_fault_handler))   // 12       #SS         Ошибка сегмента стека               Fault       Да
    trap_gate   (CS, CS_OFF(gen_prot_fault_handler))    // 13       #GP         Общее исключение защиты             Fault       Да
    trap_gate   (CS, CS_OFF(page_fault_handler))        // 14       #PF         Страничное нарушение                Fault       Да
    null_descr                                          // 15       -           Зарезервировано (не использовать)               Нет
    trap_gate   (CS, CS_OFF(dummy_handler))             // 16       #MF         Ошибка плавающей точки в x87 FPU    Fault       Нет
    trap_gate   (CS, CS_OFF(dummy_handler))             // 17       #AC         Проверка выравнивания               Fault       Да(ноль)
    trap_gate   (CS, CS_OFF(dummy_handler))             // 18       #MC         Проверка оборудования               Abort       Нет
    trap_gate   (CS, CS_OFF(dummy_handler))             // 19       #XM         Исключение плавающей точки в SIMD   Fault       Нет

    .rept   44                                          // 20-31    -           Зарезервировано (не использовать )
    null_descr
    .endr
/*---------------------------------------- Аппаратные прерывания ----------------------------------------*/

    interrupt_gate  (CS, CS_OFF(timer_ISR))
    interrupt_gate  (CS, CS_OFF(keyboard_ISR))
    .rept   62
    null_descr
    .endr
/*---------------------------------------- Аппаратные прерывания ----------------------------------------*/
    interrupt_gate  (CS, CS_OFF(trap_handler))
IDT_size = . - IDT

idtdesc:    .word   IDT_size - 1    // предел IDT
            .long   IDT             // базовый адрес IDT

/*---------------------------------------- Строки сообщений о исключениях ----------------------------------------*/

mesg_DE:    .asciz  "Divide Error! SP = "
mesg_DB:    .asciz  "Debug Exception! SP = "
mesg_DB2:   .asciz  " EFLAGS = "
mesg_BP:    .asciz  "Breakpoint! SP = "
mesg_OF:    .asciz  "Overflow! SP = "
mesg_UD:    .asciz  "Invalid Opcode! SP = "
mesg_TS:    .asciz  "Invalid TSS! SP = "
mesg_NP:    .asciz  "Segment Not Present! SP = "
mesg_SS:    .asciz  "Stack-Segment Fault! SP = "
mesg_GP:    .asciz  "General Protection Fault! SP = "
mesg_PF:    .asciz  "Page Fault! SP = "
mesg_NH:    .asciz  "Exception is not handled!!! SP = "
mesg_time:  .asciz  "TIMER"
keymap:     .asciz  "\000\0001234567890-=\b\tqwertyuiop[]\n\000asdfghjkl;\'`\000\\zxcvbnm,./\000*\000 `"

/*  Текущая позиция на экране */
cur_row:    .word   0               // текущая строка
cur_col:    .word   0               // текущий столбец

timer_ticks: .word   0
timer_sec:  .word   0

data_size = . - .data               // размер секции данных

/*---------------------------------------- Секция стека ----------------------------------------*/

    .section    .stack, "wa"
    .align 16

    .space  STACK_SIZE, '^'         // выделим место под стек и заполним его символом '^'

stack_size = . - .stack             // размер секции стека
