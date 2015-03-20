#==========================
# makefile for attiny2313
# Samuel Munz
#==========================
MCU=attiny2313
avrdude_name=t2313
# Processor frequency
F_CPU =  8000000UL
#         F_CPU =  1000000UL
#         F_CPU =  8000000UL
#         F_CPU = 12000000UL
#         F_CPU = 16000000UL
#         F_CPU = 20000000UL

CC=avr-gcc
OBJCOPY=avr-objcopy
#==========================
#Programmer
#usbasp von http://www.fischl.de/usbasp/
PROGRAMMER = -c usbasp
#==========================
# not optimize :
CFLAGS  = -g -mmcu=$(MCU) -Wall -Wstrict-prototypes -Os -mcall-prologues -DF_CPU=$(F_CPU) 
#==========================
all: main.hex
#==========================
help: 
	clear
	@echo
	@echo "Moegliche Befehle:"
	@echo "		make - compiliert main.c und erzeugt die .hex-Datei"
	@echo "		make all - wie make"
	@echo "		make load - Compilieren und Flashen"
	@echo "		make clean - loescht die beim Compilieren erzeugten Dateien"
	@echo
	@echo "		make help - zeigt die Hilfe"
	@echo
	@echo "		make rdfuses - read Fusebits"
	@echo "		make wrfusedefaults - werkseintellung 1MHz"
	@echo "		make wrfuse8mhz - internen Oszillator 8 MHz"
	@echo "		make wrfuse8mhz_clkout- internen Oszillator 8 MHz + clk out PD2"
	@echo
	
#==========================
main.hex : main.out 
	$(OBJCOPY) -R .eeprom -O ihex main.out main.hex 
main.out : main.o 
	$(CC) $(CFLAGS) -o main.out -Wl,-Map,main.map main.o 
main.o : main.c 
	$(CC) $(CFLAGS) -Os -c main.c
#==========================
load: main.hex
	avrdude -p $(avrdude_name) $(PROGRAMMER) -e -U flash:w:"main.hex"
#==========================
# fuse byte settings attiny2313:
rdfuses:
	avrdude -p t2313 $(PROGRAMMER) -v -q	
	
# Fusebit Werkseinstellung
wrfusedefaults:
	avrdude -p $(avrdude_name) $(PROGRAMMER) -u -v -U lfuse:w:0x64:m
	avrdude -p $(avrdude_name) $(PROGRAMMER) -u -v -U hfuse:w:0xdf:m
	avrdude -p $(avrdude_name) $(PROGRAMMER) -u -v -U efuse:w:0xff:m
	
# Frequenz des internen Oszillators auf 8 MHz setzen
wrfuse8mhz:
	avrdude -p $(avrdude_name) $(PROGRAMMER) -u -v -U lfuse:w:0xE4:m
	
# Frequenz des internen Oszillators auf 8 MHz setzen zusätzlich Clock out auf PD2
wrfuse8mhz_clkout:
	avrdude -p $(avrdude_name) $(PROGRAMMER) -u -v -U lfuse:w:0xA4:m

#==========================
clean:
	rm -f *.o *.map *.out *.hex
#==========================