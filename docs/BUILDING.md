# Building an Image from source
This project is written in the programming language Elixir and built using the
Nerves Project framework.

## Before you begin
You will need a number of things before we start:
* A Linux machine
* A x64 bit machine
* Probably about 16 gigs of ram
* About ~30 gigs of hard drive space
* A fairly recent cpu

## Install dependencies
If you have the above set up you will need some software dependencies:
* Elixir found [here](http://elixir-lang.org/install.html)
* Nerves Bootstrapper found [here](https://hexdocs.pm/nerves/installation.html#Linux)
* NodeJS found [here](https://nodejs.org/en/download/)

## Set up environment
We are going to set up the environment for building Farmbot OS:
```bash
mkdir farmbot
cd farmbot
git clone https://github.com/FarmBot/farmbot_os.git os
cd farmbot_os
npm install
```

## Compile the application
From here you will have to choose your own adventure. You get to choose if you
want development mode or production mode, and you get to choose the target you
want to build the executables for. See the [ENVIRONMENT](environment.md) for more details.
This will take a while depending on you machine.
```bash
export MIX_ENV=prod
export MIX_TARGET=rpi3
mix deps.get
mix firmware
```
