all: lab4.bin img/boot.img
	dd if=img/boot.img of=boot.img # Копируем загрузочный образ
	dd if=lab4.bin of=boot.img seek=1 bs=512 conv=notrunc # Записываем программу после загрузчика
lab4.o: lab4.S
	cpp -o lab4.s lab4.S # Разворачиваем макрорасширения
	as --32 -o lab4.o lab4.s # Компилируем программу для архитектуры x86
lab4.bin: lab4.o
	ld --gc-sections -m elf_i386 -T linker.ld -o lab4.elf lab4.o # Связываем объектный файл lab4.o с использованием скрипта линкера linker.ld, создавая ELF-файл lab4.elf. Флаг --gc-sections удаляет неиспользуемые секции для оптимизации.
	objcopy -S -O binary lab4.elf lab4.bin # Конвертируем ELF-файл lab4.elf в чистый бинарный файл lab4.bin. Флаг -S исключает символы и отладочную информацию, а -O binary указывает формат вывода.
img/boot.img: 
	$(MAKE) -C img/ # Собираем загрузчик
clean:
	rm *.o *.elf *.bin *.s *.img # Удаляем всё лишнее
