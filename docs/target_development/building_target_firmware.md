# Building FarmBot OS from source

This project is written in the programming language Elixir and built using the
Nerves Project framework.

## Cloning

Farmbot OS now bundles and builds the [Arduino Firmware](https://github.com/farmbot/farmbot-arduino-firmware).
This is bundled as a `git` submodule. You can choose to do one of:

```bash
git clone https://github.com/FarmBot/farmbot_os.git --recursive
```

or

```bash
git clone https://github.com/FarmBot/farmbot_os.git
git submodule update --init --recursive
cd farmbot_os
```

To initialize the repository.

## Before you begin

You will need a number of things before we start:

* A x64 bit non windows machine
  * We suggest the latest OSX or Ubuntu LTS.

## Install dependencies

If you have the above set up you will need some software dependencies:

* Erlang
* Elixir
  * Nerves Bootstrapper found [here](https://hexdocs.pm/nerves/installation.html#Linux)
* GNU Make + GCC
* git

## Optional dependencies

* python
* opencv-python

Following [this](http://embedded-elixir.com/post/2017-05-23-using-asdf-vm/) guide
will get you mostly setup.

## Development

Most development will be done in "host" environment. This means that rather than
making a change on your computer, then pushing it to the device, we can rapidly
develop things from the luxury of our own machine.
See [The Nerves getting started guide](https://hexdocs.pm/nerves/getting-started.html)
for more information about this. But as a side effect, we will need to be able
to configure (at least) two different environment/target combos. where:

* `environment` - is one of:
  * `prod` - The production environment.
    * No developer features enabled (such as logs, local fw updates etc).
    * No remote shell
    * No remote firmware updates.
    * Must be digitally signed.
  * `dev` - The development environment.
    * Logs most things to the console.
    * Remote shell
    * Remote firmwre updates.
  * `test` - The test environment
    * Only exists for running tests on the `host` target currently.
* `target` - the target this `environment` will run on. Usually one of:
  * `host` - For development.
  * `rpi3` - Run on Farmbot's intended hardware.

## Feature development

If you plan on developing features, you will probably want to develop them with
the `dev` and `host` combo. These are both the default values,
so you can simply do:

```bash
export FARMBOT_EMAIL="email@server.com"
export FARMBOT_PASSWORD="supersecret"
export FARMBOT_SERVER="https://my.farm.bot"
export CONFIGURATOR_PORT=4000 # you should only need to do this once
mix deps.get # You should only need to do this once.
iex -S mix # This will start an interactive shell.
```

## Development on device

Sometimes features will need to be developed and tested on the device itself.
This is accomplished with the `dev` and `rpi3` combo.
It is *highly* recommended that you have an FTDI cable for this such as
[this](https://www.digikey.com/product-detail/en/ftdi/TTL-232R-RPI/768-1204-ND) one

Get deps for the rpi3 target. You should only need to do this once:

```bash
MIX_TARGET=rpi3 mix deps.get
```

Produce a firmware image:

```bash
MIX_TARGET=rpi3 mix firmware
```

Make sure you SDCard is plugged in before the following command:

```bash
MIX_TARGET=rpi3 mix firmware.burn
```

### Local firmware updates

If your bot is connected to your local network, you should be able to
push updates over the network to your device.

```bash
MIX_TARGET=rpi3 mix firmware # Build a new fw.
MIX_TARGET=rpi3 mix firmware.gen.script # this should onlye be ran once
MIX_TARGET=rpi3 ./upload.sh <your device ip address> # Push the new fw to the device.
```

Your device should now reboot into that new code. As long as you don't cause
a factory reset somehow, (bad init code, typo, etc) you should be able
continuously push updates to your device.
