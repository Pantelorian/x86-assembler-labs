#define EXEC_ONLY 0x8
#define EXEC_READ 0xA
#define READ_ONLY 0x0
#define READ_WRITE 0x2
#define G_BYTE 0x0
#define G_PAGE 0x80
#define SEG_16 0x0
#define SEG_32 0x40
#define STACK_SIZE 0x10

#define descr(base, limit, type, attr) \
  .word (limit & 0xFFFF); \
  .word (base & 0xFFFF); \
  .byte ((base >> 16) & 0xFF); \
  .byte (0x90 | (type)); \
  .byte (attr | ((limit >> 16) & 0xF)); \
  .byte ((base >> 24) & 0xFF)

#define CS_OFF(label) (label - _start)
#define DS_OFF(label) (label - .data)

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
  ljmp $0x8, $CS_OFF(goto_prot)

.code32
goto_prot:
  movw $0x10, %ax
  movw %ax, %ds
  movw $0x18, %ax
  movw %ax, %ss
  movl $STACK_SIZE, %esp
  movw $0x20, %ax
  movw %ax, %es
  
  movl $320, %ebx
  movl $110, %ecx
  movw %ds:DS_OFF(symbol), %ax
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

  movw $0xFFFF, %ds:DS_OFF(seg_text)
  movb $0, %ds:DS_OFF(seg_text) + 6
  orb $EXEC_READ, %ds:DS_OFF(seg_text) + 5
  movw $0xFFFF, %ds:DS_OFF(seg_data)
  movb $0, %ds:DS_OFF(seg_data) + 6
  orb $READ_WRITE, %ds:DS_OFF(seg_data) + 5
  movw $0xFFFF, %ds:DS_OFF(seg_stack)
  movb $0, %ds:DS_OFF(seg_stack) + 6
  orb $READ_WRITE, %ds:DS_OFF(seg_stack) + 5
  movw $0xFFFF, %ds:DS_OFF(seg_videomem)
  movb $0, %ds:DS_OFF(seg_videomem) + 6
  orb $READ_WRITE, %ds:DS_OFF(seg_videomem) + 5
  movw $0x10, %ax
  movw %ax, %ds
  movw $0x18, %ax
  movw %ax, %ss
  movw $0x20, %ax
  movw %ax, %es
  ljmp $0x8, $CS_OFF(goto_64k_segment)

goto_64k_segment:
  .code16
  movl %cr0, %eax
  andl $0xFFFFFFFE, %eax
  movl %eax, %cr0
  ljmp $0x7C0, $CS_OFF(goto_real)

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
  movw $DS_OFF(mesg), %si
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
seg_text: descr (0x7c00, (text_size - 1), EXEC_READ, G_BYTE | SEG_32)
seg_data: descr (0, (data_size - 1), READ_WRITE, G_BYTE | SEG_32)
seg_stack: descr (0, (stack_size - 1), READ_WRITE, G_BYTE | SEG_32)
seg_videomem: descr (0xB8000, 0xFFF, READ_WRITE, G_BYTE | SEG_32)
GDT_size = . - GDT

gdtdesc:  .word GDT_size - 1
         .long GDT
symbol:   .byte 1
sym_attr: .byte 0x1e
mesg:     .asciz "Back to real mode!!!!"

data_size = . - .data

.section .stack, "wa"
.align 16
.space STACK_SIZE, '^'
stack_size = . - .stack

