# FarmBot Software for the Raspberry Pi 3
The "brains" of Farmbot. Responsible for receiving the commands from [the browser](https://github.com/FarmBot/farmbot-web-frontend) or the [FarmBot API](https://github.com/FarmBot/Farmbot-Web-API). It executes them and reports back the results to any subscribed user(s).

# First Time Installation

If you are setting up your FarmBot for the first time, download the latest FarmBot OS `.img` file [here](https://github.com/FarmBot/farmbot-raspberry-pi-controller/releases).

## Windows users

* Download [Win32 Disk Imager](https://sourceforge.net/projects/win32diskimager/)
* Select the `.img` file you downloaded
* Select your sdcard's drive letter
* Click `write`

## Linux / OSX / UNIX
* `dd if=img_file of=/dev/sdX`
* where img_file is the path to you `.img` file, and X is your device's drive letter.

## Running
 0. Plug your SD Card into your RPi3
 0. Plug your Arduino into your RPi3
 0. Plug your power into your RPi3
 0. From a WiFi enabled device*, search for the SSID `FarmbotConfigurator`
 0. Connect to that and open a web browser to [http://192.168.24.1/](http://192.168.24.1)
 0. Follow the on screen instructions to configure your FarmBot. Once you save your configuration FarmBot will connect to your home WiFi network and to the FarmBot web application.
 
Asterisk: If you are using a smartphone you may need to disable cellular data to allow your phone's browser to connect to the configurator.

## Updating the firmware
To update the firmware on the Raspberry Pi and the Arduino, simply use the "update" buttons on the web application. There is no need to reinstall the entire OS.
 
 

# Building / Development (for developers only)

## Technical Stuff
* Written in [Elixir](http://elixir-lang.org/) using [Nerves Project](http://nerves-project.org/).
* Device status info such as X,Y,Z and calibration data is stored on the Data partition Nerves allows.
* Backups to the cloud provided by [Farmbot API](https://github.com/farmbot/farmbot-web-api)
* Messaging happens via [MQTT](https://github.com/farmbot/mqtt-gateway)

## Building
[You need Linux to build Linux.](http://www.whylinuxisbetter.net/). Windows is not supported. Bash for Windows and Cygwin will not work. A VM or dual boot environment will work. So with that rant out of the way, and ready for revision here are the steps to build:
* Install Elixir and Erlang. ([installer script]("https://gist.github.com/ConnorRigby/8a8bffff935d1a43cd74c4b8cf28a845"))
* Install [`Nerves`](https://hexdocs.pm/nerves/installation.html) and all related dependencies.
* clone this repo. `git clone https://github.com/FarmBot/farmbot-raspberry-pi-controller.git`
* `cd farmbot-raspberry-pi-controller`.
* Insert an sdcard into your development machine and run:

```bash
MIX_ENV=prod mix deps.get
MIX_ENV=prod mix firmware
MIX_ENV=prod mix firmware.burn
```

You can also run locally (not on an RPI3- Windows is supported for this):

```bash
export MIX_ENV=dev
rm -rf _deps build _images
mix deps.get
iex -S mix
```

You should only need to do the first two commands once.

## Debugging on hardware

The Raspberry Pi will boot up with an Iex console on the hardware UART. If you need to debug something this is the easiest to get too.

If you do not have a 3.3v FTDI cable, you can build the firmware with the console on HDMI.
In the `erlinit.config` file change `-c ttyS0` to `-c ttyS1`. This requires a usb mouse, keyboard and monitor into your pi.

## Development Tips

You can connect IEx to the running pi by running
`iex -name console@localhost --remsh farmbot@<FARMBOT IP ADDRESS> --cookie democookie`.

Debug message still only will print to UART or HDMI (whichever you have configured)

If you frequently build the firmware, removing the sdcard and writing the build every time gets pretty old. You can upload firmware to an already running farmbot one of two ways after you run a successful `mix firmware`
0. You can upload the image to the pi using CURL or similar. `curl -T _images/rpi3/fw.fw "http://$RPI_IP_ADDRESS:8988/firmware" -H "Content-Type: application/x-firmware" -H "X-Reboot: true"`
0. Or you can host the .fw file on your pc using a webserver ie `npm install serve` and download it from the pi.This should be ran ON THE PI ITSELF `Downloader.download_and_install_update("http://<DEV_PC_IP_ADDRESS>/WHEREVER YOUR FILE IS")`

# Tests

Run `mix test --no-start`.


# Building for production

## Major version change
you will have to do one of two things:
0. Do a fresh clone of this repo. (prefered)
0. Clean everything out with something along the lines of `rm -rf _build deps _images rel/fw`

Then follow these steps then follow the steps for a minor version.
```bash
export MIX_ENV=prod
mix deps.get
```
this will generate a .fw file in the images dir. this will be an update file. A raw image file is then generated from this file

## Minor Version
```bash
export MIX_ENV=prod
mix firmware
cd _images/rpi3/
fwup -a -d firmware.img -i fw.fw -t complete
```

These two files should be put into the github release.
If someone would like to write a Mix Task for this it'd be much appreciated.
