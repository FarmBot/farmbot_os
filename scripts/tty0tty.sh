#!/bin/sh
CWD=`pwd`
mkdir /tmp/tty0tty
cd /tmp/tty0tty
git clone https://github.com/freemed/tty0tty .
cd module
make
sudo cp tty0tty.ko /lib/modules/$(uname -r)/kernel/drivers/misc/
sudo depmod
sudo modprobe tty0tty
cd $CWD
