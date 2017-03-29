# Raspberry Pi Model Zero

This is the base Nerves System configuration for the Raspberry Pi Zero and
Raspberry Pi Zero W.

![Fritzing Raspberry Pi Zero image](assets/images/raspberry-pi-model-zero.png)
<br><sup>[Image credit](#fritzing)</sup>

| Feature              | Description                     |
| -------------------- | ------------------------------- |
| CPU                  | 1 GHz ARM1176JZF-S              |
| Memory               | 512 MB                          |
| Storage              | MicroSD                         |
| Linux kernel         | 4.4 w/ Raspberry Pi patches     |
| IEx terminal         | HDMI and USB keyboard (can be changed to UART or OTG USB serial via `ttyGS0`) |
| GPIO, I2C, SPI       | Yes - Elixir ALE                |
| ADC                  | No                              |
| PWM                  | Yes, but no Elixir support      |
| UART                 | 1 available - `ttyAMA0`         |
| Camera               | Yes - via rpi-userland          |
| Ethernet             | Yes - via OTG USB port          |
| WiFi                 | Pi Zero W, IoT pHAT or USB WiFi dongle |
| Bluetooth            | Not supported yet               |

## Supported OTG USB modes

The base image activates the `dwc2` overlay, which allows the Pi Zero to appear as a
device (aka gadget mode). When plugged into a host computer via the OTG port, the Pi
Zero will appear as a composite ethernet and serial device.

When a peripheral is plugged into the OTG port, the Pi Zero will act as USB host, with
somewhat reduced performace vs the `dwc_otg` driver used in other base systems like
the official `nerves_system_rpi`.

## Supported HAT WiFi devices

The base image includes drivers for the Red Bear IoT pHAT.

## Supported USB WiFi devices

The base image includes drivers and firmware for onboard Raspberry Pi
Zero W wifi driver (`brcmfmac` driver), Ralink RT53xx
(`rt2800usb` driver) and RealTek RTL8712U (`r8712u` driver) devices.

If you are unsure what driver your WiFi dongle requires, run Raspbian and configure WiFi
for your device. At a shell prompt, run `lsmod` to see which drivers are loaded.
Running `dmesg` may also give a clue. When using `dmesg`, reinsert the USB
dongle to generate new log messages if you don't see them.

## Installation

Coming soon. For now, a custom system build is required until a system image file is created.

[Image credit](#fritzing): This image is from the [Fritzing](http://fritzing.org/home/) parts library.
