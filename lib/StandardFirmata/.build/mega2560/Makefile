























.build/mega2560/Servo/Servo.o : /usr/share/arduino/libraries/Servo/Servo.cpp
	@echo [93mServo/Servo.cpp[0m
	@mkdir -p .build/mega2560/Servo
	@/usr/bin/avr-g++ -mmcu=atmega2560 -DF_CPU=16000000L -DARDUINO=101 -I/usr/share/arduino/hardware/arduino/cores/arduino -ffunction-sections -fdata-sections -g -Os -w -I/usr/share/arduino/hardware/arduino/variants/mega -I/usr/share/arduino/libraries/Servo -I/usr/share/arduino/libraries/Firmata -I/usr/share/arduino/libraries/Wire -I/usr/share/arduino/libraries/Wire/utility -I/usr/share/arduino/hardware/arduino/cores/arduino -fno-exceptions  -o $@ -c /usr/share/arduino/libraries/Servo/Servo.cpp
include .build/mega2560/Servo/Servo.d



.build/mega2560/Servo/libServo.a : .build/mega2560/Servo/Servo.o
	@echo [92mLinking libServo.a[0m
	@/usr/bin/avr-ar rcs $@ $^












.build/mega2560/Firmata/Firmata.o : /usr/share/arduino/libraries/Firmata/Firmata.cpp
	@echo [93mFirmata/Firmata.cpp[0m
	@mkdir -p .build/mega2560/Firmata
	@/usr/bin/avr-g++ -mmcu=atmega2560 -DF_CPU=16000000L -DARDUINO=101 -I/usr/share/arduino/hardware/arduino/cores/arduino -ffunction-sections -fdata-sections -g -Os -w -I/usr/share/arduino/hardware/arduino/variants/mega -I/usr/share/arduino/libraries/Servo -I/usr/share/arduino/libraries/Firmata -I/usr/share/arduino/libraries/Wire -I/usr/share/arduino/libraries/Wire/utility -I/usr/share/arduino/hardware/arduino/cores/arduino -fno-exceptions  -o $@ -c /usr/share/arduino/libraries/Firmata/Firmata.cpp
include .build/mega2560/Firmata/Firmata.d



.build/mega2560/Firmata/libFirmata.a : .build/mega2560/Firmata/Firmata.o
	@echo [92mLinking libFirmata.a[0m
	@/usr/bin/avr-ar rcs $@ $^







.build/mega2560/Wire/utility/twi.o : /usr/share/arduino/libraries/Wire/utility/twi.c
	@echo [93mWire/utility/twi.c[0m
	@mkdir -p .build/mega2560/Wire/utility
	@/usr/bin/avr-gcc -mmcu=atmega2560 -DF_CPU=16000000L -DARDUINO=101 -I/usr/share/arduino/hardware/arduino/cores/arduino -ffunction-sections -fdata-sections -g -Os -w -I/usr/share/arduino/hardware/arduino/variants/mega -I/usr/share/arduino/libraries/Servo -I/usr/share/arduino/libraries/Firmata -I/usr/share/arduino/libraries/Wire -I/usr/share/arduino/libraries/Wire/utility -I/usr/share/arduino/hardware/arduino/cores/arduino   -o $@ -c /usr/share/arduino/libraries/Wire/utility/twi.c
include .build/mega2560/Wire/utility/twi.d






.build/mega2560/Wire/Wire.o : /usr/share/arduino/libraries/Wire/Wire.cpp
	@echo [93mWire/Wire.cpp[0m
	@mkdir -p .build/mega2560/Wire
	@/usr/bin/avr-g++ -mmcu=atmega2560 -DF_CPU=16000000L -DARDUINO=101 -I/usr/share/arduino/hardware/arduino/cores/arduino -ffunction-sections -fdata-sections -g -Os -w -I/usr/share/arduino/hardware/arduino/variants/mega -I/usr/share/arduino/libraries/Servo -I/usr/share/arduino/libraries/Firmata -I/usr/share/arduino/libraries/Wire -I/usr/share/arduino/libraries/Wire/utility -I/usr/share/arduino/hardware/arduino/cores/arduino -fno-exceptions  -o $@ -c /usr/share/arduino/libraries/Wire/Wire.cpp
include .build/mega2560/Wire/Wire.d



.build/mega2560/Wire/libWire.a : .build/mega2560/Wire/utility/twi.o .build/mega2560/Wire/Wire.o
	@echo [92mLinking libWire.a[0m
	@/usr/bin/avr-ar rcs $@ $^







.build/mega2560/arduino/wiring_analog.o : /usr/share/arduino/hardware/arduino/cores/arduino/wiring_analog.c
	@echo [93marduino/wiring_analog.c[0m
	@mkdir -p .build/mega2560/arduino
	@/usr/bin/avr-gcc -mmcu=atmega2560 -DF_CPU=16000000L -DARDUINO=101 -I/usr/share/arduino/hardware/arduino/cores/arduino -ffunction-sections -fdata-sections -g -Os -w -I/usr/share/arduino/hardware/arduino/variants/mega -I/usr/share/arduino/libraries/Servo -I/usr/share/arduino/libraries/Firmata -I/usr/share/arduino/libraries/Wire -I/usr/share/arduino/libraries/Wire/utility -I/usr/share/arduino/hardware/arduino/cores/arduino   -o $@ -c /usr/share/arduino/hardware/arduino/cores/arduino/wiring_analog.c
include .build/mega2560/arduino/wiring_analog.d

.build/mega2560/arduino/wiring_digital.o : /usr/share/arduino/hardware/arduino/cores/arduino/wiring_digital.c
	@echo [93marduino/wiring_digital.c[0m
	@mkdir -p .build/mega2560/arduino
	@/usr/bin/avr-gcc -mmcu=atmega2560 -DF_CPU=16000000L -DARDUINO=101 -I/usr/share/arduino/hardware/arduino/cores/arduino -ffunction-sections -fdata-sections -g -Os -w -I/usr/share/arduino/hardware/arduino/variants/mega -I/usr/share/arduino/libraries/Servo -I/usr/share/arduino/libraries/Firmata -I/usr/share/arduino/libraries/Wire -I/usr/share/arduino/libraries/Wire/utility -I/usr/share/arduino/hardware/arduino/cores/arduino   -o $@ -c /usr/share/arduino/hardware/arduino/cores/arduino/wiring_digital.c
include .build/mega2560/arduino/wiring_digital.d

.build/mega2560/arduino/wiring_shift.o : /usr/share/arduino/hardware/arduino/cores/arduino/wiring_shift.c
	@echo [93marduino/wiring_shift.c[0m
	@mkdir -p .build/mega2560/arduino
	@/usr/bin/avr-gcc -mmcu=atmega2560 -DF_CPU=16000000L -DARDUINO=101 -I/usr/share/arduino/hardware/arduino/cores/arduino -ffunction-sections -fdata-sections -g -Os -w -I/usr/share/arduino/hardware/arduino/variants/mega -I/usr/share/arduino/libraries/Servo -I/usr/share/arduino/libraries/Firmata -I/usr/share/arduino/libraries/Wire -I/usr/share/arduino/libraries/Wire/utility -I/usr/share/arduino/hardware/arduino/cores/arduino   -o $@ -c /usr/share/arduino/hardware/arduino/cores/arduino/wiring_shift.c
include .build/mega2560/arduino/wiring_shift.d

.build/mega2560/arduino/wiring.o : /usr/share/arduino/hardware/arduino/cores/arduino/wiring.c
	@echo [93marduino/wiring.c[0m
	@mkdir -p .build/mega2560/arduino
	@/usr/bin/avr-gcc -mmcu=atmega2560 -DF_CPU=16000000L -DARDUINO=101 -I/usr/share/arduino/hardware/arduino/cores/arduino -ffunction-sections -fdata-sections -g -Os -w -I/usr/share/arduino/hardware/arduino/variants/mega -I/usr/share/arduino/libraries/Servo -I/usr/share/arduino/libraries/Firmata -I/usr/share/arduino/libraries/Wire -I/usr/share/arduino/libraries/Wire/utility -I/usr/share/arduino/hardware/arduino/cores/arduino   -o $@ -c /usr/share/arduino/hardware/arduino/cores/arduino/wiring.c
include .build/mega2560/arduino/wiring.d

.build/mega2560/arduino/WInterrupts.o : /usr/share/arduino/hardware/arduino/cores/arduino/WInterrupts.c
	@echo [93marduino/WInterrupts.c[0m
	@mkdir -p .build/mega2560/arduino
	@/usr/bin/avr-gcc -mmcu=atmega2560 -DF_CPU=16000000L -DARDUINO=101 -I/usr/share/arduino/hardware/arduino/cores/arduino -ffunction-sections -fdata-sections -g -Os -w -I/usr/share/arduino/hardware/arduino/variants/mega -I/usr/share/arduino/libraries/Servo -I/usr/share/arduino/libraries/Firmata -I/usr/share/arduino/libraries/Wire -I/usr/share/arduino/libraries/Wire/utility -I/usr/share/arduino/hardware/arduino/cores/arduino   -o $@ -c /usr/share/arduino/hardware/arduino/cores/arduino/WInterrupts.c
include .build/mega2560/arduino/WInterrupts.d

.build/mega2560/arduino/wiring_pulse.o : /usr/share/arduino/hardware/arduino/cores/arduino/wiring_pulse.c
	@echo [93marduino/wiring_pulse.c[0m
	@mkdir -p .build/mega2560/arduino
	@/usr/bin/avr-gcc -mmcu=atmega2560 -DF_CPU=16000000L -DARDUINO=101 -I/usr/share/arduino/hardware/arduino/cores/arduino -ffunction-sections -fdata-sections -g -Os -w -I/usr/share/arduino/hardware/arduino/variants/mega -I/usr/share/arduino/libraries/Servo -I/usr/share/arduino/libraries/Firmata -I/usr/share/arduino/libraries/Wire -I/usr/share/arduino/libraries/Wire/utility -I/usr/share/arduino/hardware/arduino/cores/arduino   -o $@ -c /usr/share/arduino/hardware/arduino/cores/arduino/wiring_pulse.c
include .build/mega2560/arduino/wiring_pulse.d






.build/mega2560/arduino/WMath.o : /usr/share/arduino/hardware/arduino/cores/arduino/WMath.cpp
	@echo [93marduino/WMath.cpp[0m
	@mkdir -p .build/mega2560/arduino
	@/usr/bin/avr-g++ -mmcu=atmega2560 -DF_CPU=16000000L -DARDUINO=101 -I/usr/share/arduino/hardware/arduino/cores/arduino -ffunction-sections -fdata-sections -g -Os -w -I/usr/share/arduino/hardware/arduino/variants/mega -I/usr/share/arduino/libraries/Servo -I/usr/share/arduino/libraries/Firmata -I/usr/share/arduino/libraries/Wire -I/usr/share/arduino/libraries/Wire/utility -I/usr/share/arduino/hardware/arduino/cores/arduino -fno-exceptions  -o $@ -c /usr/share/arduino/hardware/arduino/cores/arduino/WMath.cpp
include .build/mega2560/arduino/WMath.d

.build/mega2560/arduino/HardwareSerial.o : /usr/share/arduino/hardware/arduino/cores/arduino/HardwareSerial.cpp
	@echo [93marduino/HardwareSerial.cpp[0m
	@mkdir -p .build/mega2560/arduino
	@/usr/bin/avr-g++ -mmcu=atmega2560 -DF_CPU=16000000L -DARDUINO=101 -I/usr/share/arduino/hardware/arduino/cores/arduino -ffunction-sections -fdata-sections -g -Os -w -I/usr/share/arduino/hardware/arduino/variants/mega -I/usr/share/arduino/libraries/Servo -I/usr/share/arduino/libraries/Firmata -I/usr/share/arduino/libraries/Wire -I/usr/share/arduino/libraries/Wire/utility -I/usr/share/arduino/hardware/arduino/cores/arduino -fno-exceptions  -o $@ -c /usr/share/arduino/hardware/arduino/cores/arduino/HardwareSerial.cpp
include .build/mega2560/arduino/HardwareSerial.d

.build/mega2560/arduino/main.o : /usr/share/arduino/hardware/arduino/cores/arduino/main.cpp
	@echo [93marduino/main.cpp[0m
	@mkdir -p .build/mega2560/arduino
	@/usr/bin/avr-g++ -mmcu=atmega2560 -DF_CPU=16000000L -DARDUINO=101 -I/usr/share/arduino/hardware/arduino/cores/arduino -ffunction-sections -fdata-sections -g -Os -w -I/usr/share/arduino/hardware/arduino/variants/mega -I/usr/share/arduino/libraries/Servo -I/usr/share/arduino/libraries/Firmata -I/usr/share/arduino/libraries/Wire -I/usr/share/arduino/libraries/Wire/utility -I/usr/share/arduino/hardware/arduino/cores/arduino -fno-exceptions  -o $@ -c /usr/share/arduino/hardware/arduino/cores/arduino/main.cpp
include .build/mega2560/arduino/main.d

.build/mega2560/arduino/CDC.o : /usr/share/arduino/hardware/arduino/cores/arduino/CDC.cpp
	@echo [93marduino/CDC.cpp[0m
	@mkdir -p .build/mega2560/arduino
	@/usr/bin/avr-g++ -mmcu=atmega2560 -DF_CPU=16000000L -DARDUINO=101 -I/usr/share/arduino/hardware/arduino/cores/arduino -ffunction-sections -fdata-sections -g -Os -w -I/usr/share/arduino/hardware/arduino/variants/mega -I/usr/share/arduino/libraries/Servo -I/usr/share/arduino/libraries/Firmata -I/usr/share/arduino/libraries/Wire -I/usr/share/arduino/libraries/Wire/utility -I/usr/share/arduino/hardware/arduino/cores/arduino -fno-exceptions  -o $@ -c /usr/share/arduino/hardware/arduino/cores/arduino/CDC.cpp
include .build/mega2560/arduino/CDC.d

.build/mega2560/arduino/Tone.o : /usr/share/arduino/hardware/arduino/cores/arduino/Tone.cpp
	@echo [93marduino/Tone.cpp[0m
	@mkdir -p .build/mega2560/arduino
	@/usr/bin/avr-g++ -mmcu=atmega2560 -DF_CPU=16000000L -DARDUINO=101 -I/usr/share/arduino/hardware/arduino/cores/arduino -ffunction-sections -fdata-sections -g -Os -w -I/usr/share/arduino/hardware/arduino/variants/mega -I/usr/share/arduino/libraries/Servo -I/usr/share/arduino/libraries/Firmata -I/usr/share/arduino/libraries/Wire -I/usr/share/arduino/libraries/Wire/utility -I/usr/share/arduino/hardware/arduino/cores/arduino -fno-exceptions  -o $@ -c /usr/share/arduino/hardware/arduino/cores/arduino/Tone.cpp
include .build/mega2560/arduino/Tone.d

.build/mega2560/arduino/HID.o : /usr/share/arduino/hardware/arduino/cores/arduino/HID.cpp
	@echo [93marduino/HID.cpp[0m
	@mkdir -p .build/mega2560/arduino
	@/usr/bin/avr-g++ -mmcu=atmega2560 -DF_CPU=16000000L -DARDUINO=101 -I/usr/share/arduino/hardware/arduino/cores/arduino -ffunction-sections -fdata-sections -g -Os -w -I/usr/share/arduino/hardware/arduino/variants/mega -I/usr/share/arduino/libraries/Servo -I/usr/share/arduino/libraries/Firmata -I/usr/share/arduino/libraries/Wire -I/usr/share/arduino/libraries/Wire/utility -I/usr/share/arduino/hardware/arduino/cores/arduino -fno-exceptions  -o $@ -c /usr/share/arduino/hardware/arduino/cores/arduino/HID.cpp
include .build/mega2560/arduino/HID.d

.build/mega2560/arduino/USBCore.o : /usr/share/arduino/hardware/arduino/cores/arduino/USBCore.cpp
	@echo [93marduino/USBCore.cpp[0m
	@mkdir -p .build/mega2560/arduino
	@/usr/bin/avr-g++ -mmcu=atmega2560 -DF_CPU=16000000L -DARDUINO=101 -I/usr/share/arduino/hardware/arduino/cores/arduino -ffunction-sections -fdata-sections -g -Os -w -I/usr/share/arduino/hardware/arduino/variants/mega -I/usr/share/arduino/libraries/Servo -I/usr/share/arduino/libraries/Firmata -I/usr/share/arduino/libraries/Wire -I/usr/share/arduino/libraries/Wire/utility -I/usr/share/arduino/hardware/arduino/cores/arduino -fno-exceptions  -o $@ -c /usr/share/arduino/hardware/arduino/cores/arduino/USBCore.cpp
include .build/mega2560/arduino/USBCore.d

.build/mega2560/arduino/WString.o : /usr/share/arduino/hardware/arduino/cores/arduino/WString.cpp
	@echo [93marduino/WString.cpp[0m
	@mkdir -p .build/mega2560/arduino
	@/usr/bin/avr-g++ -mmcu=atmega2560 -DF_CPU=16000000L -DARDUINO=101 -I/usr/share/arduino/hardware/arduino/cores/arduino -ffunction-sections -fdata-sections -g -Os -w -I/usr/share/arduino/hardware/arduino/variants/mega -I/usr/share/arduino/libraries/Servo -I/usr/share/arduino/libraries/Firmata -I/usr/share/arduino/libraries/Wire -I/usr/share/arduino/libraries/Wire/utility -I/usr/share/arduino/hardware/arduino/cores/arduino -fno-exceptions  -o $@ -c /usr/share/arduino/hardware/arduino/cores/arduino/WString.cpp
include .build/mega2560/arduino/WString.d

.build/mega2560/arduino/Print.o : /usr/share/arduino/hardware/arduino/cores/arduino/Print.cpp
	@echo [93marduino/Print.cpp[0m
	@mkdir -p .build/mega2560/arduino
	@/usr/bin/avr-g++ -mmcu=atmega2560 -DF_CPU=16000000L -DARDUINO=101 -I/usr/share/arduino/hardware/arduino/cores/arduino -ffunction-sections -fdata-sections -g -Os -w -I/usr/share/arduino/hardware/arduino/variants/mega -I/usr/share/arduino/libraries/Servo -I/usr/share/arduino/libraries/Firmata -I/usr/share/arduino/libraries/Wire -I/usr/share/arduino/libraries/Wire/utility -I/usr/share/arduino/hardware/arduino/cores/arduino -fno-exceptions  -o $@ -c /usr/share/arduino/hardware/arduino/cores/arduino/Print.cpp
include .build/mega2560/arduino/Print.d

.build/mega2560/arduino/IPAddress.o : /usr/share/arduino/hardware/arduino/cores/arduino/IPAddress.cpp
	@echo [93marduino/IPAddress.cpp[0m
	@mkdir -p .build/mega2560/arduino
	@/usr/bin/avr-g++ -mmcu=atmega2560 -DF_CPU=16000000L -DARDUINO=101 -I/usr/share/arduino/hardware/arduino/cores/arduino -ffunction-sections -fdata-sections -g -Os -w -I/usr/share/arduino/hardware/arduino/variants/mega -I/usr/share/arduino/libraries/Servo -I/usr/share/arduino/libraries/Firmata -I/usr/share/arduino/libraries/Wire -I/usr/share/arduino/libraries/Wire/utility -I/usr/share/arduino/hardware/arduino/cores/arduino -fno-exceptions  -o $@ -c /usr/share/arduino/hardware/arduino/cores/arduino/IPAddress.cpp
include .build/mega2560/arduino/IPAddress.d

.build/mega2560/arduino/Stream.o : /usr/share/arduino/hardware/arduino/cores/arduino/Stream.cpp
	@echo [93marduino/Stream.cpp[0m
	@mkdir -p .build/mega2560/arduino
	@/usr/bin/avr-g++ -mmcu=atmega2560 -DF_CPU=16000000L -DARDUINO=101 -I/usr/share/arduino/hardware/arduino/cores/arduino -ffunction-sections -fdata-sections -g -Os -w -I/usr/share/arduino/hardware/arduino/variants/mega -I/usr/share/arduino/libraries/Servo -I/usr/share/arduino/libraries/Firmata -I/usr/share/arduino/libraries/Wire -I/usr/share/arduino/libraries/Wire/utility -I/usr/share/arduino/hardware/arduino/cores/arduino -fno-exceptions  -o $@ -c /usr/share/arduino/hardware/arduino/cores/arduino/Stream.cpp
include .build/mega2560/arduino/Stream.d

.build/mega2560/arduino/new.o : /usr/share/arduino/hardware/arduino/cores/arduino/new.cpp
	@echo [93marduino/new.cpp[0m
	@mkdir -p .build/mega2560/arduino
	@/usr/bin/avr-g++ -mmcu=atmega2560 -DF_CPU=16000000L -DARDUINO=101 -I/usr/share/arduino/hardware/arduino/cores/arduino -ffunction-sections -fdata-sections -g -Os -w -I/usr/share/arduino/hardware/arduino/variants/mega -I/usr/share/arduino/libraries/Servo -I/usr/share/arduino/libraries/Firmata -I/usr/share/arduino/libraries/Wire -I/usr/share/arduino/libraries/Wire/utility -I/usr/share/arduino/hardware/arduino/cores/arduino -fno-exceptions  -o $@ -c /usr/share/arduino/hardware/arduino/cores/arduino/new.cpp
include .build/mega2560/arduino/new.d



.build/mega2560/arduino/libarduino.a : .build/mega2560/arduino/wiring_analog.o .build/mega2560/arduino/wiring_digital.o .build/mega2560/arduino/wiring_shift.o .build/mega2560/arduino/wiring.o .build/mega2560/arduino/WInterrupts.o .build/mega2560/arduino/wiring_pulse.o .build/mega2560/arduino/WMath.o .build/mega2560/arduino/HardwareSerial.o .build/mega2560/arduino/main.o .build/mega2560/arduino/CDC.o .build/mega2560/arduino/Tone.o .build/mega2560/arduino/HID.o .build/mega2560/arduino/USBCore.o .build/mega2560/arduino/WString.o .build/mega2560/arduino/Print.o .build/mega2560/arduino/IPAddress.o .build/mega2560/arduino/Stream.o .build/mega2560/arduino/new.o
	@echo [92mLinking libarduino.a[0m
	@/usr/bin/avr-ar rcs $@ $^















.build/mega2560/src/src.o : .build/mega2560/src/src.cpp
	@echo [93msrc/src.cpp[0m
	@mkdir -p .build/mega2560/src
	@/usr/bin/avr-g++ -mmcu=atmega2560 -DF_CPU=16000000L -DARDUINO=101 -I/usr/share/arduino/hardware/arduino/cores/arduino -ffunction-sections -fdata-sections -g -Os -w -I/usr/share/arduino/hardware/arduino/variants/mega -I/usr/share/arduino/libraries/Servo -I/usr/share/arduino/libraries/Firmata -I/usr/share/arduino/libraries/Wire -I/usr/share/arduino/libraries/Wire/utility -I/usr/share/arduino/hardware/arduino/cores/arduino -fno-exceptions -iquote src  -o $@ -c .build/mega2560/src/src.cpp
include .build/mega2560/src/src.d







.build/mega2560/firmware.elf : .build/mega2560/src/src.o .build/mega2560/Servo/libServo.a .build/mega2560/Firmata/libFirmata.a .build/mega2560/Wire/libWire.a .build/mega2560/arduino/libarduino.a
	@echo [92mLinking firmware.elf[0m
	@/usr/bin/avr-gcc -mmcu=atmega2560 -Wl,-Os -Wl,--gc-sections -o $@ $^ -lm


.build/mega2560/firmware.hex : .build/mega2560/firmware.elf
	@echo [92mConverting to firmware.hex[0m
	@/usr/bin/avr-objcopy -O ihex -R .eeprom $^ $@

include .build/mega2560/src/dependencies.d .build/mega2560/arduino/dependencies.d .build/mega2560/Servo/dependencies.d .build/mega2560/Firmata/dependencies.d .build/mega2560/Wire/dependencies.d

all : .build/mega2560/firmware.hex
	@true

