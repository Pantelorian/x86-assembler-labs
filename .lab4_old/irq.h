#define IRQ0    0x1
#define IRQ1    0x2
#define IRQ2    0x4
#define IRQ3    0x8
#define IRQ4    0x10
#define IRQ5    0x20
#define IRQ6    0x40
#define IRQ7    0x80

#define MASTER_PIC_COMMAND      0x20
#define MASTER_PIC_DATA         0x21
#define SLAVE_PIC_COMMAND       0xA0
#define SLAVE_PIC_DATA          0xA1

#define ICW1_ICW4_NEEDED        0x1
#define ICW1_SINGLE_MODE        0x2
#define ICW1_INTERVAL4          0x4
#define ICW1_LEVEL              0x8
#define ICW1_INIT               0x10

#define ICW2_MASTER_BASE_VECTOR     0x40
#define ICW2_SLAVE_BASE_VECTOR      0x48

#define ICW3_MASTER     0x4
#define ICW3_SLAVE      0x2

#define ICW4_8086_MODE     0x01
#define ICW4_AUTO_EOT      0x02
#define ICW4_BUF_SLAVE     0x08
#define ICW4_BUF_MASTER    0x0C
#define ICW4_SFNM          0x10

#define EOI                0x20
