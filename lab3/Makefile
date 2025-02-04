all: lab3.bin img/boot.img
	dd if=img/boot.img of=boot.img
	dd if=lab3.bin of=boot.img seek=1 bs=512 conv=notrunc
lab3.o: lab3.S
	cpp -o lab3.s lab3.S
	as --32 -o lab3.o lab3.s
lab3.bin: lab3.o
	ld --gc-sections -m elf_i386 -T linker.ld -o lab3.elf lab3.o
	objcopy -S -O binary lab3.elf lab3.bin
img/boot.img: 
	$(MAKE) -C img/
clean:
	rm *.o *.elf *.bin *.s *.img
