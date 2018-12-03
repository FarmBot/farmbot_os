#!/bin/bash
if [ -z $1 ]; then
  echo "usage: scripts/flash_fw.sh [arduino-firmware|farmduino-firmware|farmduino_k14-firmware] /dev/ttyACM0"
  exit 1
fi

if [ -z $2 ]; then
  echo "usage: scripts/flash_fw.sh [arduino-firmware|farmduino-firmware|farmduino_k14-firmware|blink|clear_eeprom] /dev/ttyACM0"
  exit 1
fi

avrdude -v -p atmega2560 -c wiring -P$2 -b 115200 -D -V -Uflash:w:./farmbot_core/priv/$1.hex:i
