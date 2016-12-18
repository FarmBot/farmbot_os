# Raspberry Pi 3 Model B
This is the base Nerves System configuration for the Raspberry Pi 3 Model B.

![Fritzing Raspberry Pi 3 image](assets/images/raspberry-pi-3-model-b.png)
<br><sup>[Image credit](#fritzing)</sup>

| Feature              | Description                     |
| -------------------- | ------------------------------- |
| CPU                  | 1.2 GHz quad-core ARMv8         |
| Memory               | 1 GB DRAM                       |
| Storage              | MicroSD                         |
| Linux kernel         | 4.1 w/ Raspberry Pi patches     |
| IEx terminal         | HDMI and USB keyboard (can be changed to UART)   |
| GPIO, I2C, SPI       | Yes - Elixir ALE                |
| ADC                  | No                              |
| PWM                  | Yes, but no Elixir support      |
| UART                 | 1 available - ttyS0             |
| Camera               | Yes - via rpi-userland          |
| Ethernet             | Yes                             |
| WiFi                 | Yes - Nerves.InterimWiFi        |
| Bluetooth            | Not yet                         |

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add nerves_system_rpi3 to your list of dependencies in `mix.exs`:

        def deps do
          [{:nerves_system_rpi3, github: "ConnorRigby/nerves_system_rpi3"}]
        end

  2. Ensure nerves_system_rpi3 is started before your application:

        def application do
          [applications: [:nerves_system_rpi3]]
        end

## Built-in WiFi Firmware

WiFi modules almost always require proprietary firmware to be loaded for them to work. The
Linux kernel handles this and firmware blobs are maintained in the
`linux-firmware` project. The firmware for the built-in WiFi module on the RPi3
hasn't made it to the `linux-firmware` project nor Buildroot, so it is included
here in a `rootfs-additions` overlay directory. The original firmware files came from
https://github.com/RPi-Distro/firmware-nonfree/blob/master/brcm80211/brcm.

[Image credit](#fritzing): This image is from the [Fritzing](http://fritzing.org/home/) parts library.
