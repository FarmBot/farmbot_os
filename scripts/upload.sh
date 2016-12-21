#!/bin/bash
echo "uploading to ${BOT_IP_ADDR}"
/usr/bin/curl -T apps/os/_images/rpi3/farmbot.fw http://${BOT_IP_ADDR}:8988/firmware \
  -H "Content-Type: application/x-firmware" -H "X-Reboot: true" -#
