# ===== EDIT THIS LINE if your mount path differs =====
MICROBIT_PATH = /media/$(USER)/MICROBIT

AS      = arm-none-eabi-as
LD      = arm-none-eabi-ld
OBJCOPY = arm-none-eabi-objcopy

CPU_FLAGS = -mcpu=cortex-m4 -mthumb

all: blink.hex

startup.o: startup.s
	$(AS) $(CPU_FLAGS) -o $@ $<

main.o: main.s
	$(AS) $(CPU_FLAGS) -o $@ $<

blink.elf: startup.o main.o linker.ld
	$(LD) -T linker.ld -o $@ startup.o main.o

blink.hex: blink.elf
	$(OBJCOPY) -O ihex $< $@

flash: blink.hex
	pyocd flash -t nrf52833 blink.hex
	@echo "Flashed."

clean:
	rm -f *.o *.elf *.hex

.PHONY: all flash clean