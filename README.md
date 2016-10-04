# FarmBot Software for the Raspberry Pi 3
The "brains" of Farmbot. Responsible for receiving the commands from users or the farmbot-web-app. It executes them and reports back the results to any subscribed user(s).

## Technical Stuff
* Written in Elixir with the Nerves Framework
* Operation scheduling is not working yet
* Device status infor, such as X,Y,Z and calibration data is stored on the Data partition Nerves allows.
* Backups to the cloud provided by ["Farmbot Web API"]("https://github.com/farmbot/farmbot-web-api")
* Messaging happens vie ["MQTT"]("https://github.com/farmbot/mqtt-gateway")

# Running in production
You can download the latest release from ["Here"]("https://github.com/FarmBot/farmbot-raspberry-pi-controller/releases")
Make sure you download the `.img` file.
## Windows users
* You can use ["Win32 Disk Imager"]("https://sourceforge.net/projects/win32diskimager/")
* Select the `.img` file you downloaded
* Select your sdcard's drive letter
* Click `write`

## Linux / OSX / UNIX
* `dd if=img_file of=/dev/sdX`
* where img_file is the path to you `.img` file, and X is your device's drive letter.

## Running
* Plug your SD Card into your RPi3
* Plug your Arduino into your RPi3
* Plug your power into your RPi3
* From a WiFi enabled device, search for the SSID `FarmbotConfigurator`
* Connect to that and open a web browser to ["http://192.168.24.1/"]("http://192.168.24.1")
* Follow the on screen instruction
* Profit???

# Building
Ok its actually really easy once your environment is set up. Let me prefix this with this simple phrase. ["YOU NEED LINUX"]("http://www.whylinuxisbetter.net/") I am sorry. It is just the bottom line. A VM works fine, a dual boot environment works. even OpenSuse works. But `bash for windows` does not work. `Cygwin` does not work. and for the love of all things development ready, `osx` does not work. You need Linux to build Linux. So with that rant out of the way, and ready for revision here are the steps to build:
* Install Elixir and Erlang.  (Shameless plug for ASDF) ([HEY TRY ME?]("https://gist.github.com/ConnorRigby/8a8bffff935d1a43cd74c4b8cf28a845"))
* install [`Nerves`]("https://hexdocs.pm/nerves/installation.html") (and all the things it tells you to install there)
* clone and cd into this directory.
* plug an sdcard into your machine.
``` bash
MIX_ENV=prod mix deps.get
MIX_ENV=prod mix firmware
MIX_ENV=prod mix firmware.burn
```

You can also run locally (not on an RPI3) (This works on windows)
``` bash
export MIX_ENV=dev
rm -rf _deps build _images
mix deps.get
iex -S mix
```
You should only need to do the first two commands once.

## Debugging on hardware
The Rpi will boot up with an Iex console on the hardware UART. If you need to debug something this is the easiest to get too.
If you do not happen to have a 3.3v FTDI cable, you can build the firmware with the console on HDMI. In the `erlinit.config` file you can change `-c ttyS0` to `-c ttyS1`. This requires you to plug a usb mouse, keyboard and monitor into your pi.

## Other stuff
You can connect IEx to the running pi by doing
`iex -name console@localhost --remsh farmbot@<FARMBOT IP ADDRESS> --cookie democookie`
Debug message still only will print to UART or HDMI (whichever you have configured)

If you are frequently building firmware, removing the sdcard and writing the build every time gets pretty old. You can upload firmware to an already running farmbot one of two ways after you run a successful `mix firmware`
0. You can upload the image to the pi using CURL or similar. `curl -T _images/rpi3/fw.fw "http://$RPI_IP_ADDRESS:8988/firmware" -H "Content-Type: application/x-firmware" -H "X-Reboot: true"`
0. Or you can host the .fw file on your pc using a webserver ie `npm install serve` and download it from the pi.This should be ran ON THE PI ITSELF `Downloader.download_and_install_update("http://<DEV_PC_IP_ADDRESS>/WHEREVER YOUR FILE IS")`

# Tests
Test coverage is not very good right now but you should be able to run `mix test --no-start` and see tests run. 
