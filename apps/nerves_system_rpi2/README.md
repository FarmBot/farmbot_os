# Raspberry Pi 2 Model B
[![Build Status](https://travis-ci.org/nerves-project/nerves_system_rpi2.png?branch=master)](https://travis-ci.org/nerves-project/nerves_system_rpi2)

This is the base Nerves System configuration for the Raspberry Pi 2 Model B.

![Fritzing Raspberry Pi 2 image](assets/images/raspberry-pi-2-model-b.png)
<br><sup>[Image credit](#fritzing)</sup>

| Feature              | Description                     |
| -------------------- | ------------------------------- |
| CPU                  | 900 MHz quad-core ARM Cortex-A7 |
| Memory               | 1 GB DRAM                       |
| Storage              | MicroSD                         |
| Linux kernel         | 4.4.3 w/ Raspberry Pi patches     |
| IEx terminal         | HDMI and USB keyboard (can be changed to UART)   |
| GPIO, I2C, SPI       | Yes - Elixir ALE                |
| ADC                  | No                              |
| PWM                  | Yes, but no Elixir support      |
| UART                 | 1 available - ttyAMA0           |
| Camera               | Yes - via rpi-userland          |
| Ethernet             | Yes                             |
| WiFi                 | Requires USB WiFi dongle        |
| Bluetooth            | Not supported                   |

## Supported USB WiFi devices

The base image includes drivers and firmware for Ralink RT53xx
(`rt2800usb` driver) and RealTek RTL8712U (`r8712u` driver) devices.

We are still working out which subset of all possible WiFi dongles to
support in our images. At some point, we may have the option to support
all dongles and selectively install modules at packaging time, but until
then, these drivers and their associated firmware blobs add significantly
to Nerves release images.

If you are unsure what driver your WiFi dongle requires, run Raspbian and configure WiFi
for your device. At a shell prompt, run `lsmod` to see which drivers are loaded.
Running `dmesg` may also give a clue. When using `dmesg`, reinsert the USB
dongle to generate new log messages if you don't see them.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add nerves_system_rpi2 to your list of dependencies in `mix.exs`:

        def deps do
          [{:nerves_system_rpi2, "~> 0.10.0"}]
        end

  2. Ensure nerves_system_rpi2 is started before your application:

        def application do
          [applications: [:nerves_system_rpi2]]
        end

[Image credit](#fritzing): This image is from the [Fritzing](http://fritzing.org/home/) parts library.
