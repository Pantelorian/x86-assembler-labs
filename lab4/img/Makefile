all: boot.o
	ld -m elf_i386 -T linker.ld -o boot.elf boot.o
	objcopy -S -O binary boot.elf boot.img
boot.o: boot.S
	as --32 -o boot.o boot.S

clean:
	rm *.o *.elf  *.img
