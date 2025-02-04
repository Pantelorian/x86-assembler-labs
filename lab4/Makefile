all: lab4.bin img/boot.img
	dd if=img/boot.img of=boot.img conv=notrunc
	dd if=lab4.bin of=boot.img seek=1 bs=512 conv=notrunc
lab4.o: lab4.S
	cpp -o lab4.s lab4.S
	as --32 -o lab4.o lab4.s
lab4.bin: lab4.o
	ld --gc-sections -m elf_i386 -T linker.ld -o lab4.elf lab4.o
	objcopy -S -O binary lab4.elf lab4.bin
img/boot.img: 
	$(MAKE) -C img/
clean:
	rm *.o *.elf *.bin *.s *.img
