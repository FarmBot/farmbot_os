#!/bin/bash
if [ -z $1 ]; then
  echo "usage: scripts/flash_fw.sh [arduino-firmware|farmduino-firmware] /dev/ttyACM0"
  exit 1
fi

if [ -z $2 ]; then
  echo "usage: scripts/flash_fw.sh [arduino-firmware|farmduino-firmware|blink|clear_eeprom] /dev/ttyACM0"
  exit 1
fi

avrdude -v -patmega2560 -cwiring -P$2 -b115200 -D -V -Uflash:w:./priv/$1.hex:i
