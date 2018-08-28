#!/usr/bin/env bash
# stollen from https://stackoverflow.com/questions/14208001/save-screen-program-output-to-a-file
mkdir -p log
PORT=$1
CONFIG="logfile log/$PORT.log
logfile flush 1
log on
logtstamp after 1
logtstamp string \"[ %t: %Y-%m-%d %c:%s ]\012\"
logtstamp on"

echo "$CONFIG" > log/$PORT.log.conf
screen -c log/$PORT.log.conf -mSL '$PORT' /dev/$PORT 115200
