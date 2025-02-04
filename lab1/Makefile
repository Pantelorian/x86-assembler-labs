all: lab1.bin
	dd if=lab1.bin of=boot.img bs=512 conv=notrunc
lab1.o: lab1.S
	as --32 -o lab1.o lab1.S
lab1.bin: lab1.o
	ld -m elf_i386 -T linker.ld --gc-sections -o lab1.elf lab1.o
	objcopy -S -O binary lab1.elf lab1.bin
clean:
	rm *.o *.elf *.bin *.img
