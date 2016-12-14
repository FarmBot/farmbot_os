#!/bin/bash
fwup -a -d _images/qemu/farmbot.img -i _images/qemu/farmbot.fw -t complete
qemu-system-arm -M vexpress-a9 -smp 1 -m 256                         \
    -kernel _build/qemu/prod/nerves/system/images/zImage            \
    -dtb _build/qemu/prod/nerves/system/images/vexpress-v2p-ca9.dtb \
    -drive file=_images/qemu/farmbot.img,if=sd,format=raw     \
    -append "console=ttyAMA0,115200 root=/dev/mmcblk0p2" -serial stdio \
    -net none
