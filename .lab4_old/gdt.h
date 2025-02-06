#define EXEC_ONLY 0x8                     // сегмент кода, только чтение
#define EXEC_READ 0xA                     // сегмент кода, чтение и исполнение
#define READ_ONLY 0x0                     // сегмент данных, только чтение
#define READ_WRITE 0x2                    // сегмент данных, чтение и запись
#define G_BYTE 0x0                        // байтовая гранулярность
#define G_PAGE 0x80                       // страничная гранулярность
#define SEG_16 0x0                        // 16-разрядный сегмент
#define SEG_32 0x40                       // 32-разрядный сегмент

#define descr(base, limit, type, attr) \
	.word (limit & 0xFFFF); \
	.word (base & 0xFFFF); \
	.byte ((base >> 16) & 0xFF); \
	.byte (0x90 | (type)); \
	.byte (attr | ((limit >> 16) & 0xF)); \
	.byte ((base >> 24) & 0xFF)

#define CS_OFF(label) (label - _start)
#define DS_OFF(label) (label - .data)
