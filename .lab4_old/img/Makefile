all: boot.o
	ld -m elf_i386 -T linker.ld -o boot.elf boot.o # Связываем объектный файл boot.o с использованием скрипта линкера linker.ld, создавая ELF-файл boot.elf. Флаг --gc-sections удаляет неиспользуемые секции для оптимизации.
	objcopy -S -O binary boot.elf boot.img # Конвертируем ELF-файл boot.elf в чистый бинарный файл boot.bin. Флаг -S исключает символы и отладочную информацию, а -O binary указывает формат вывода.
boot.o: boot.S
	as --32 -o boot.o boot.S # Компилируем программу для архитектуры x86

clean:
	rm *.o *.elf  *.img # Удаляем всё лишнее 
