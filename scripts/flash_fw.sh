if [ -z $1 ]; then
  echo "usage: scripts/flash_fw.sh [arduino|farmduino] /dev/ttyACM0"
  exit 1
fi

if [ -z $2 ]; then
  echo "usage: scripts/flash_fw.sh [arduino|farmduino] /dev/ttyACM0"
  exit 1
fi

avrdude -v -patmega2560 -cwiring -P$2 -b115200 -D -V -Uflash:w:./priv/$1-firmware.hex:i
