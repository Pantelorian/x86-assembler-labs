all: lab2.bin
	dd if=lab2.bin of=boot.img   
lab2.o: lab2.S
	cpp -o lab2.s lab2.S
	as --32 -o lab2.o lab2.s
lab2.bin: lab2.o
	ld -m elf_i386 -T linker.ld --gc-sections -o lab2.elf lab2.o
	objcopy -S -O binary lab2.elf lab2.bin
clean:
	rm *.o *.elf *.bin *.s *.img
