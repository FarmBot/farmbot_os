#!/bin/bash
if [ -z $1 ]; then
  echo "usage: scripts/reset_fw.sh [arduino-firmware|farmduino-firmware|farmduino_k14-firmware] /dev/ttyACM0"
  exit 1
fi

if [ -z $2 ]; then
  echo "usage: scripts/reset_fw.sh [arduino-firmware|farmduino-firmware|farmduino_k14-firmware] /dev/ttyACM0"
  exit 1
fi

FW_TYPE=$1
TTY=$2
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if $DIR/flash_fw.sh clear_eeprom $TTY; then
  if $DIR/flash_fw.sh blink $TTY; then
    $DIR/flash_fw.sh $FW_TYPE $TTY
  else
    echo "Failed to flash blink!"
    exit 1
  fi
else
  echo "Failed to clear eeprom!"
  exit 1
fi
