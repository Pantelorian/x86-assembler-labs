all: lab2.bin
	dd if=lab2.bin of=boot.img # Записываем программу в disk.img
lab2.o: lab2.S
	cpp -o lab2.s lab2.S # Разворачиваем макрорасширения
	as --32 -o lab2.o lab2.s # Компилируем программу для архитектуры x86
lab2.bin: lab2.o
	ld -m elf_i386 -T linker.ld --gc-sections -o lab2.elf lab2.o # Связываем объектный файл lab2.o с использованием скрипта линкера linker.ld, создавая ELF-файл lab2.elf. Флаг --gc-sections удаляет неиспользуемые секции для оптимизации.
	objcopy -S -O binary lab2.elf lab2.bin # Конвертируем ELF-файл lab2.elf в чистый бинарный файл lab2.bin. Флаг -S исключает символы и отладочную информацию, а -O binary указывает формат вывода.
clean:
	rm *.o *.elf *.bin *.s *.img #Удаляем всё лишнее
