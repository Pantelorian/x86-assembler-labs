all: lab1.bin
	dd if=lab1.bin of=boot.img # Записываем программу в disk.img
lab1.o: lab1.S
	as --32 -o lab1.o lab1.S # Компилируем программу для архитектуры x86
lab1.bin: lab1.o
	ld -m elf_i386 -T linker.ld --gc-sections -o lab1.elf lab1.o # Связываем объектный файл lab1.o с использованием скрипта линкера linker.ld, создавая ELF-файл lab1.elf. Флаг --gc-sections удаляет неиспользуемые секции для оптимизации.
	objcopy -S -O binary lab1.elf lab1.bin # Конвертируем ELF-файл lab1.elf в чистый бинарный файл lab1.bin. Флаг -S исключает символы и отладочную информацию, а -O binary указывает формат вывода.
clean:
	rm *.o *.elf *.bin *.img # Удаляем всё лишнее 
