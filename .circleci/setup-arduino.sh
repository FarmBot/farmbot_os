#!/bin/bash
ARDUINO_VERSION=1.8.5
[ "$(ls -A $HOME/arduino-$ARDUINO_VERSION)" ]; then
  wget https://downloads.arduino.cc/arduino-$ARDUINO_VERSION-linux64.tar.xz
  tar xf arduino-$ARDUINO_VERSION-linux64.tar.xz
  mv arduino-$ARDUINO_VERSION $HOME
else
  echo "arduino $ARDUINO_VERSION already installed"
fi
