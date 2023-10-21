
all:
	cl65 -t cx16 -o 5BF.PRG -l code.list main.asm

run:
	cl65 -t cx16 -o 5BF.PRG -l code.list main.asm
	..\..\x16emu -prg 5BF.PRG -debug
