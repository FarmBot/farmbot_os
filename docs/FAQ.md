# Frequently Asked Questions
## My bot doesn't boot on a fresh SD card!

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

## Can I SSH into the Farmbot?

Yes, starting with version `2.1.1`. The user is root and there is no password. This may change in future versions.

## Why are my SSH keys invalid?

Farmbot's `rootfs` file system is read only. SSH keys must be stored elsewhere. They may get lost if you pull the power to your Farmbot. Follow the directions in the shell to resolve the issue.

## Can the shell run on HDMI rather than SSH?

Yes and no. HDMI will display an IEX (Elixir shell) session. You may access the shell via `ctrl+c` but this will kill Farmbot's main software.

## SSH Has No Linux Utilities.

Farmbot is built using Buildroot, Which uses a very small Linux environment to minimize boot time and overhead. This gives us a Linux shell of `sh` and most utilities are provided by `busybox`.

## Why aren't [X] or [Y] packages included?

See the above answer. [Raise an issue](https://github.com/FarmBot/farmbot_os/issues/new) to request a package. Future versions of FarmBotOS may provide a plugin system. It is not implemented yet.

## Does Farmbot support Ethernet rather than WIFI?

Yes. When you log into the Farmbot Configurator wifi SSID, select `Use Ethernet`.
**NOTE**: This can not be changed without a factory reset.

## How do I factory reset my bot?

This is not as trivial as you would think right now. (We are working on it.)

** EASY: ** Flash the SD card
** Via HDMI monitor / IEx: ** `Farmbot.factory_reset()`

** Via SSH: **

```bash
ssh root@<MY FARMBOT IP ADDRESS>
rm /data/* -rf
/usr/sbin/reboot
```
