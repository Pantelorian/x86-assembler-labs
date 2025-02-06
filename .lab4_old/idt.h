/*------------------------------------------------------
    Макроопределение в С-стиле. Создает дескрипторы прерывания, ловушки и
    шлюза с заданными адресами процедур обработки (селектор, смещение)
-------------------------------------------------------*/
#define interrupt_gate(selector, offset)	\
    .word   (offset & 0xFFFF);				\
    .word   (selector & 0xFFFF);			\
    .word   0x8E00;							\
    .word   ((offset >> 16) & 0xFFFF)	

#define trap_gate(selector, offset)		\
    .word   (offset & 0xFFFF);			\
    .word   (selector & 0xFFFF);		\
    .word   0x8F00;						\
    .word   ((offset >> 16) & 0xFFFF)	

#define task_gate(selector, offset)		\
    .word   0;							\
    .word   tss_selector;				\
    .word   0x8500;						\
    .word   0						

#define null_descr  .quad   0
