#!/bin/bash
AVAILABLE=$(ls ./farmbot_core/priv/*.hex | grep -v "eeprom_clear" | tr '\n' ' ')
if [ -z $1 ]; then
  echo "usage: scripts/reset_fw.sh [$AVAILABLE] /dev/ttyACM0"
  exit 1
fi

if [ -z $2 ]; then
  echo "usage: scripts/reset_fw.sh [$AVAILABLE] /dev/ttyACM0"
  exit 1
fi

FW_TYPE=$1
TTY=$2
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if $DIR/flash_fw.sh eeprom_clear.ino $TTY; then
    $DIR/flash_fw.sh $FW_TYPE $TTY
else
  echo "Failed to clear eeprom!"
  exit 1
fi
