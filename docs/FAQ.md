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

## Why can't i update my Arduino Firmware?

as of version 3.8.0 we decided to bundle the arduino firmware into farmbot os. There was a couple reasons for this.
* There is no more version conflicts between the firmware and operating system.
* Applying updates during farmbot os runtime can be dangerous and was leaving peoples bot's unusable because of broken firmwares.

Some more things to note, If you want to use a custom version of the firmware during configuration, make sure to do the following:
* open advanced settings by tap/clicking the "Configure your Farmbot" text 10 times.
* tick the "USE CUSTOM ARDUINO FIRMWARE" box.
This doesn't do anything special, it just makes sure not to overwrite the existing firmware.

## Can I SSH into the Farmbot?

as of `3.0.0` SSH has changed.
* Still disabled by default.
* Can not be enabled in Prod environments. (so if you downloaded a .img file from our "Releases" page.)


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
There are now buttons for factory reset on both the web application, and configurator.
