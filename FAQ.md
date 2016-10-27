# My bot doesn't boot on a fresh SD card!
This could be one of a few things. These things are in order of probability.
* Your farmbot doesn't have enough power. You NEED a good power supply at least 5 volts and  2.5 Amps for farmbot to boot reliably.
  * Is the power LED flashing? If yes you need more amps.
  * Is the Green LED flashing? If no you need more amps.
* Your Arduino wasn't detected.
* You have more than one UART device.
* You have a bad flash.
  * If you used `dd` to write the image, try setting `BS` to a lower value.
  * if you used win32 disk imager try safely removing the SD card
* You have a bad SD Card.
* You aren't using a Raspberry Pi 3 (Porting Farmbot is relatively simple).

# Can i ssh into the Farmbot?
Yes you can starting with 2.1.1 of the OS we added SSH. The user is root and there is no password.
This is subject to change so look back if you update and your ssh no longer workds.

# Why are my ssh keys invalid?
Long story short this is because Farmbot's rootfs is read only so keys have to be stored elsewhere. They occasionally get lost if you pull the power to your Farmbot. Just do what the shell tells you to fix it.

# Can the shell be on HDMI rather than only SSH?
No. HDMI should display an IEX (elixir shell) session.You can interact with the system in this way if you want. If you want you can `ctrl+c` out of IEX, but this will kill Farmbot's main software. It will give you a linux shell though.   

# When I ssh there is no Linux Utilities.
Farmbot is built using Buildroot. Which uses a very very small linux environment to minimize boot time and overhead. This gives us a Linux shell of `sh` and most utilities are provided by `busybox`.

# Why aren't [X] or [Y] packages included?
See the above answer. If you believe we need a package please open an issue and we can discuss adding it. There is talk of adding a plugin system, where the user could supply their own packages. it is not implemented yet.

# Does Farmbot support Ethernet rather than WIFI?
Yes. When you log into the Farmbot Configurator wifi ssid, you can select `Use Ethernet`. [NOTE]: This can not be changed without a factory reset.

# How do i factory reset my bot?
This is not as trivial as you would think right now. (We are working on it.)
You can use SSH:
```bash
ssh root@<MY FARMBOT IP ADDRESS>
rm /data/* -rf
/usr/sbin/reboot
```
Or if you have a hdmi monitor plugged into your RPI you can use IEX
```elixir
Fw.factory_reset()
```
Or (probably the easiest) you can just flash a new SD Card.
