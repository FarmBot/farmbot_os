# Frequently Asked Questions

## What ports oputbound does Farmbot OS use?
* AMQP: 5673
* HTTP(S): 80 + 443 (this is configurable)
* NTP: UDP 123

## My bot doesn't boot on a fresh SD card!
This could be one of a few things. These things are in order of probability.

* Your farmbot doesn't have enough power. You NEED a good power supply at
least 5 volts and  2.5 Amps for farmbot to boot reliably.
  * Is the power LED flashing? If yes you need more amps.
  * Is the Green LED flashing? If no you need more amps.
* Your Arduino wasn't detected.
* You have more than one UART device.
* You have a bad flash.
  * If you used `dd` to write the image, try setting `BS` to a lower value.
  * if you used win32 disk imager try safely removing the SD card
* You have a bad SD Card.
* You aren't using a Raspberry Pi 3.

## Why can't I update my Arduino Firmware?
As of version 3.8.0 we decided to bundle the arduino firmware into farmbot os.
There was a couple reasons for this.
* There is no more version conflicts between the firmware and operating system.
* Applying updates during farmbot os runtime can be dangerous and was leaving
peoples bot's unusable because of broken firmwares.

## Can the shell run on HDMI
No. Farmbot is designed to operate without the use of a monitor.

## Can I SSH into the Farmbot?
No. Farmbot does not run `raspbain` as many users are used too. There are no
normal `linux` utilities (such as `apt`, `sudo`, `bash` etc).

## Why aren't [X] or [Y] packages included?
See the above answer. [Raise an issue](https://github.com/FarmBot/farmbot_os/issues/new)
to request a package. Future versions of FarmBotOS may provide a plugin system.
It is not implemented yet.
