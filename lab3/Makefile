all: lab3.bin img/boot.img
	dd if=img/boot.img of=boot.img # Копируем загрузочный образ
	dd if=lab3.bin of=boot.img seek=1 bs=512 conv=notrunc # Записываем программу после загрузчика
lab3.o: lab3.S
	cpp -o lab3.s lab3.S # Разворачиваем макрорасширения
	as --32 -o lab3.o lab3.s # Компилируем программу для архитектуры x86
lab3.bin: lab3.o
	ld --gc-sections -m elf_i386 -T linker.ld -o lab3.elf lab3.o # Связываем объектный файл lab3.o с использованием скрипта линкера linker.ld, создавая ELF-файл lab3.elf. Флаг --gc-sections удаляет неиспользуемые секции для оптимизации.
	objcopy -S -O binary lab3.elf lab3.bin # Конвертируем ELF-файл lab3.elf в чистый бинарный файл lab3.bin. Флаг -S исключает символы и отладочную информацию, а -O binary указывает формат вывода.
img/boot.img: 
	$(MAKE) -C img/ # Собираем загрузчик
clean:
	rm *.o *.elf *.bin *.s *.img # Удаляем всё лишнее
