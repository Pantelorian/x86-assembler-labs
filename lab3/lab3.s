# 1 "lab3.S"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 390 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "lab3.S" 2
# 1 "./gdt.h" 1
# 2 "lab3.S" 2
# 1 "./idt.h" 1
# 3 "lab3.S" 2
# 26 "lab3.S"
.code16
.text

.global _start
_start:
    movw $0x3, %ax
    int $0x10
    movw $.data, %ax
    movw $seg_data, %bx
    movw %ax, 2(%bx)
    movw $.stack, %ax
    movw $seg_stack, %bx
    movw %ax, 2(%bx)

    cli
    movb $0x80, %al
    outb %al, $0x70
    inb $0x92, %al
    orb $0x2, %al
    outb %al, $0x92

    lgdt gdtdesc
    lidt idtdesc

    movl %cr0, %eax
    orl $1, %eax
    movl %eax, %cr0

    ljmp $0x8, $(goto_prot - _start)


.code32
goto_prot:
    movw $0x10, %ax
    movw %ax, %ds
    movw $0x18, %ax
    movw %ax, %ss
    movl $0x100, %esp
    movw $0x20, %ax
    movw %ax, %es





    xorl %ebx, %ebx
    divl %ebx
# 105 "lab3.S"
hang:
    jmp hang
# 115 "lab3.S"
divide_error_handler:
    pushl %ebp
    movl %esp, %ebp
    pushl %eax
    pushl %esi
    movl $(mesg_DE - .data), %esi
    movl %esp, %eax
    addl $12, %eax
    call print_str
    call print_hex
    call print_endl
    addw $2, 4(%ebp)
    popl %esi
    popl %eax
    popl %ebp
    iret


debug_exception_handler:
    pushl %ebp
    movl %esp, %ebp
    pushl %eax
    pushl %esi
    movl $(mesg_DB - .data), %esi
    movl %esp, %eax
    addl $12, %eax
    call print_str
    call print_hex

    movl $(mesg_DB2 - .data), %esi
    addl 12(%ebp), %eax
    call print_str
    call print_hex

    call print_endl
    popl %esi
    popl %eax
    popl %ebp
    iret


breakpoint_handler:
    pushl %eax
    pushl %esi
    movl $(mesg_BP - .data), %esi
    movl %esp, %eax
    addl $8, %eax
    call print_str
    call print_hex
    call print_endl
    popl %esi
    popl %eax
    iret


overflow_handler:
    pushl %eax
    pushl %esi
    movl $(mesg_OF - .data), %esi
    movl %esp, %eax
    addl $8, %eax
    call print_str
    call print_hex
    call print_endl
    popl %esi
    popl %eax
    iret


inval_opcode_handler:
    pushl %eax
    pushl %esi
    movl $(mesg_UD - .data), %esi
    movl %esp, %eax
    addl $8, %eax
    call print_str
    call print_hex
    call print_endl
    popl %esi
    popl %eax
0:
    jmp 0b


inval_tss_handler:
    jmp inval_tss_handler


seg_not_present_handler:
    pushl %ebp
    movl %esp, %ebp
    pushl %eax
    pushl %esi
    movl $(mesg_NP - .data), %esi
    movl %esp, %eax
    addl $12, %eax
    call print_str
    call print_hex
    call print_endl

    movl 4(%ebp), %eax
    movl $(GDT - .data), %esi
    addl %eax, %esi
    movb 5(%esi), %al
    orb $0x80, %al
    movb %al, 5(%esi)

    popl %esi
    popl %eax
    popl %ebp
    addl $4, %esp
    iret

stack_seg_fault_handler:
    pushl %eax
    pushl %esi
    movl $(mesg_SS - .data), %esi
    movl %esp, %eax
    addl $8, %eax
    call print_str
    call print_hex
    call print_endl
    popl %esi
    popl %eax
0:
    jmp 0b


gen_prot_fault_handler:
    pushl %eax
    pushl %esi
    movl $(mesg_GP - .data), %esi
    movl %esp, %eax
    addl $8, %eax
    call print_str
    call print_hex
    call print_endl
    popl %esi
    popl %eax
0:
    jmp 0b


page_fault_handler:
    jmp page_fault_handler


dummy_handler:
    pushl %esi
    movl $(mesg_NH - .data), %esi
    call print_str
    popl %esi
0:
    jmp 0b
# 281 "lab3.S"
putchar:
    pushw %bx
    pushw %si
    pushw %di

    movw %ds:(cur_row - .data), %si
    movw %ds:(cur_col - .data), %di

    cmpb $'\n', %al
    je line_feed

    movw %si, %bx
    imulw $80, %bx
    addw %di, %bx
    imulw $2, %bx

    movw %ax, %es:(%bx)
    incw %di
    cmpw $60, %di
    jne skip_lf

line_feed:
    xorw %di, %di
    incw %si
    cmpw $25, %si
    jne skip_lf
    call scroll_screen

skip_lf:
    movw %si, %ds:(cur_row - .data)
    movw %di, %ds:(cur_col - .data)

    popw %di
    popw %si
    popw %bx

    ret

scroll_screen:
    nop
    ret





print_str:
    pushl %eax
    pushl %esi
    xorl %eax, %eax
    movb $0x7, %ah
0:
    movb (%esi), %al
    cmpb $0, %al
    je 1f
    incl %esi
    call putchar
    jmp 0b
1:
    popl %esi
    popl %eax
    ret


print_endl:
    pushw %ax
    movb $'\n', %al
    call putchar
    popw %ax
    ret

print_hex:
    pushl %eax
    pushl %ebx
    pushl %ecx

    xorl %ecx, %ecx
0:
    movl %eax, %ebx
    andl $0xF, %ebx
    pushw %bx
    incl %ecx
    shrl $4, %eax
    cmpl $0, %eax
    jne 0b
1:
    cmpl $0, %ecx
    je 4f
    popw %ax
    cmpw $10, %ax
    jl 2f
    subw $10, %ax
    addw $'A', %ax
    jmp 3f
2:
    addw $'0', %ax
3:
    movb $0x7, %ah
    call putchar
    decl %ecx
    jmp 1b
4:
    popl %ecx
    popl %ebx
    popl %eax

    ret

text_size = . - _start


    .data



.align 16
GDT:
seg_null: .quad 0
seg_text: .word ((text_size - 1) & 0xFFFF); .word (0x8000 & 0xFFFF); .byte ((0x8000 >> 16) & 0xFF); .byte (0x90 | (0xA)); .byte (0x0 | 0x40 | (((text_size - 1) >> 16) & 0xF)); .byte ((0x8000 >> 24) & 0xFF)
seg_data: .word ((data_size - 1) & 0xFFFF); .word (0 & 0xFFFF); .byte ((0 >> 16) & 0xFF); .byte (0x90 | (0x2)); .byte (0x0 | 0x40 | (((data_size - 1) >> 16) & 0xF)); .byte ((0 >> 24) & 0xFF)
seg_stack: .word ((stack_size - 1) & 0xFFFF); .word (0 & 0xFFFF); .byte ((0 >> 16) & 0xFF); .byte (0x90 | (0x2)); .byte (0x0 | 0x40 | (((stack_size - 1) >> 16) & 0xF)); .byte ((0 >> 24) & 0xFF)
seg_videomem: .word (0xFFF & 0xFFFF); .word (0xB8000 & 0xFFFF); .byte ((0xB8000 >> 16) & 0xFF); .byte (0x90 | (0x2)); .byte (0x0 | 0x40 | ((0xFFF >> 16) & 0xF)); .byte ((0xB8000 >> 24) & 0xFF)
seg_edata: .word (0x3FFFF & 0xFFFF); .word (0xC0000000 & 0xFFFF); .byte ((0xC0000000 >> 16) & 0xFF); .byte (0x90 | (0x2)); .byte (0x80 | 0x40 | ((0x3FFFF >> 16) & 0xF)); .byte ((0xC0000000 >> 24) & 0xFF)
GDT_size = . - GDT

gdtdesc: .word GDT_size - 1
            .long GDT



    .align 8
IDT:

    .word ((divide_error_handler - _start) & 0xFFFF); .word (0x8 & 0xFFFF); .word 0x8F00; .word (((divide_error_handler - _start) >> 16) & 0xFFFF)
    .word ((debug_exception_handler - _start) & 0xFFFF); .word (0x8 & 0xFFFF); .word 0x8F00; .word (((debug_exception_handler - _start) >> 16) & 0xFFFF)
    .quad 0
    .word ((breakpoint_handler - _start) & 0xFFFF); .word (0x8 & 0xFFFF); .word 0x8F00; .word (((breakpoint_handler - _start) >> 16) & 0xFFFF)
    .word ((overflow_handler - _start) & 0xFFFF); .word (0x8 & 0xFFFF); .word 0x8F00; .word (((overflow_handler - _start) >> 16) & 0xFFFF)
    .word ((dummy_handler - _start) & 0xFFFF); .word (0x8 & 0xFFFF); .word 0x8F00; .word (((dummy_handler - _start) >> 16) & 0xFFFF)
    .word ((inval_opcode_handler - _start) & 0xFFFF); .word (0x8 & 0xFFFF); .word 0x8F00; .word (((inval_opcode_handler - _start) >> 16) & 0xFFFF)
    .word ((dummy_handler - _start) & 0xFFFF); .word (0x8 & 0xFFFF); .word 0x8F00; .word (((dummy_handler - _start) >> 16) & 0xFFFF)
    .word ((dummy_handler - _start) & 0xFFFF); .word (0x8 & 0xFFFF); .word 0x8F00; .word (((dummy_handler - _start) >> 16) & 0xFFFF)
    .word ((dummy_handler - _start) & 0xFFFF); .word (0x8 & 0xFFFF); .word 0x8F00; .word (((dummy_handler - _start) >> 16) & 0xFFFF)
    .word ((inval_tss_handler - _start) & 0xFFFF); .word (0x8 & 0xFFFF); .word 0x8F00; .word (((inval_tss_handler - _start) >> 16) & 0xFFFF)
    .word ((seg_not_present_handler - _start) & 0xFFFF); .word (0x8 & 0xFFFF); .word 0x8F00; .word (((seg_not_present_handler - _start) >> 16) & 0xFFFF)
    .word ((stack_seg_fault_handler - _start) & 0xFFFF); .word (0x8 & 0xFFFF); .word 0x8F00; .word (((stack_seg_fault_handler - _start) >> 16) & 0xFFFF)
    .word ((gen_prot_fault_handler - _start) & 0xFFFF); .word (0x8 & 0xFFFF); .word 0x8F00; .word (((gen_prot_fault_handler - _start) >> 16) & 0xFFFF)
    .word ((page_fault_handler - _start) & 0xFFFF); .word (0x8 & 0xFFFF); .word 0x8F00; .word (((page_fault_handler - _start) >> 16) & 0xFFFF)
    .quad 0
    .word ((dummy_handler - _start) & 0xFFFF); .word (0x8 & 0xFFFF); .word 0x8F00; .word (((dummy_handler - _start) >> 16) & 0xFFFF)
    .word ((dummy_handler - _start) & 0xFFFF); .word (0x8 & 0xFFFF); .word 0x8F00; .word (((dummy_handler - _start) >> 16) & 0xFFFF)
    .word ((dummy_handler - _start) & 0xFFFF); .word (0x8 & 0xFFFF); .word 0x8F00; .word (((dummy_handler - _start) >> 16) & 0xFFFF)
    .word ((dummy_handler - _start) & 0xFFFF); .word (0x8 & 0xFFFF); .word 0x8F00; .word (((dummy_handler - _start) >> 16) & 0xFFFF)

    .rept 12
    .quad 0
    .endr
IDT_size = . - IDT

idtdesc: .word IDT_size - 1
            .long IDT



mesg_DE: .asciz "Divide Error! SP = "
mesg_DB: .asciz "Debug Exception! SP = "
mesg_DB2: .asciz " EFLAGS = "
mesg_BP: .asciz "Breakpoint! SP = "
mesg_OF: .asciz "Overflow! SP = "
mesg_UD: .asciz "Invalid Opcode! SP = "
mesg_TS: .asciz "Invalid TSS! SP = "
mesg_NP: .asciz "Segment Not Present! SP = "
mesg_SS: .asciz "Stack-Segment Fault! SP = "
mesg_GP: .asciz "General Protection Fault! SP = "
mesg_PF: .asciz "Page Fault! SP = "
mesg_NH: .asciz "Exception is not handled!!! SP = "


cur_row: .word 0
cur_col: .word 0

data_size = . - .data



    .section .stack, "wa"
    .align 16

    .space 0x100, '^'

stack_size = . - .stack
