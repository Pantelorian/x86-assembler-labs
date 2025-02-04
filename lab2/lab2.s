# 1 "lab2.S"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 390 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "lab2.S" 2
# 41 "lab2.S"
.text
.code16


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
  movl $0x10, %esp
  movw $0x20, %ax
  movw %ax, %es

 # Обращение за пределы GDT
 # movw $0x30, %ax
 # movw %ax, %gs

 # Декриптор кода в сегмент данных
 # movw $0x8, %ax
 # movw %ax, %ds



  movl $320, %ebx
  movl $110, %ecx
  movw %ds:(symbol - .data), %ax
print_pm:
  movw %ax, %es:(%ebx)
  addl $2, %ebx
  incw %ax
  pushl %ecx
  movl $0xFFFFFF, %ecx
idle:
  nop
  loop idle
  popl %ecx
  loop print_pm
# 122 "lab2.S"
  movw $0xFFFF, %ds:(seg_text - .data)
  movb $0, %ds:(seg_text - .data) + 6
  orb $0xA, %ds:(seg_text - .data) + 5


  movw $0xFFFF, %ds:(seg_data - .data)
  movb $0, %ds:(seg_data - .data) + 6
  orb $0x2, %ds:(seg_data - .data) + 5

  movw $0xFFFF, %ds:(seg_stack - .data)
  movb $0, %ds:(seg_stack - .data) + 6
  orb $0x2, %ds:(seg_stack - .data) + 5

  movw $0xFFFF, %ds:(seg_videomem - .data)
  movb $0, %ds:(seg_videomem - .data) + 6
  orb $0x2, %ds:(seg_videomem - .data) + 5

  movw $0x10, %ax
  movw %ax, %ds
  movw $0x18, %ax
  movw %ax, %ss
  movw $0x20, %ax
  movw %ax, %es

  ljmp $0x8, $(goto_64k_segment - _start)


goto_64k_segment:

  .code16
  movl %cr0, %eax
  andl $0xFFFFFFFE, %eax
  movl %eax, %cr0

  ljmp $0x7C0, $(goto_real - _start)





goto_real:
  movw $.data, %ax
  shrw $4, %ax
  movw %ax, %ds
  movw %ax, %es
  movw $.stack, %ax
  shrw $4, %ax
  movw %ax, %ss

  sti
  movb $0, %al
  outb %al, $0x70



  movb $0x0E, %ah
  xorw %bx, %bx

  movw $(mesg - .data), %si

print_rm:
  movb (%si), %al
  cmpb $0, %al
  je hang
  inc %si
  int $0x10
  loop print_rm

hang:
  jmp hang

text_size = . - _start


.data




.align 16
GDT:
seg_null: .quad 0
seg_text: .word ((text_size - 1) & 0xFFFF); .word (0x7C00 & 0xFFFF); .byte ((0x7C00 >> 16) & 0xFF); .byte (0x90 | (0xA)); .byte (0x0 | 0x40 | (((text_size - 1) >> 16) & 0xF)); .byte ((0x7C00 >> 24) & 0xFF)
seg_data: .word ((data_size - 1) & 0xFFFF); .word (0 & 0xFFFF); .byte ((0 >> 16) & 0xFF); .byte (0x90 | (0x2)); .byte (0x0 | 0x40 | (((data_size - 1) >> 16) & 0xF)); .byte ((0 >> 24) & 0xFF)
seg_stack: .word ((stack_size - 1) & 0xFFFF); .word (0 & 0xFFFF); .byte ((0 >> 16) & 0xFF); .byte (0x90 | (0x2)); .byte (0x0 | 0x40 | (((stack_size - 1) >> 16) & 0xF)); .byte ((0 >> 24) & 0xFF)
seg_videomem: .word (0xFFF & 0xFFFF); .word (0xB8000 & 0xFFFF); .byte ((0xB8000 >> 16) & 0xFF); .byte (0x90 | (0x2)); .byte (0x0 | 0x40 | ((0xFFF >> 16) & 0xF)); .byte ((0xB8000 >> 24) & 0xFF)
GDT_size = . - GDT



gdtdesc: .word GDT_size - 1
         .long GDT

symbol: .byte 1
sym_attr: .byte 0x1e

mesg: .asciz "Back to real mode!!!"

data_size = . - .data



.section .stack, "wa"
.align 16

.space 0x10, '^'

stack_size = . - .stack
