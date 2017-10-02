/usr/share/arduino/hardware/tools/avrdude -C/usr/share/arduino/hardware/tools/avrdude.conf -v -patmega2560 -cwiring -P/dev/ttyACM0 -b115200 -D -V -Uflash:w:./priv/arduino-firmware.hex:i
