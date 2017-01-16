# Advanced Things that you shouldn't need to worry about.

## Building an image
Building a `*.img` file is rather simple, its one step farther than the regular build.

```bash
cd ~/farmbot/os/apps/farmbot
export MIX_ENV=prod
export NERVES_TARGET=<MY_BOARD_CHOICE_REPLACEME>
# THIS COULD TAKE A WHILE DEPENDING ON YOUR MACHINE
mix firmware
# this is the actual .img generation, it should go pretty quick.
fwup -a -d _images/farmbot/<MY_BOARD_CHOICE_REPLACEME>/farmbot.img -i \
 _images/farmbot/<MY_BOARD_CHOICE_REPLACEME>/farmbot.fw -t complete
```

## Documentation

Documentation isn't stored in source control, because it is large and changes frequently. [Raise an issue](https://github.com/FarmBot/farmbot_os/issues/new) if you would like them published on HEX.

To view documentation:

```bash
cd ~/farmbot/os
MIX_ENV=dev mix deps.get
MIX_ENV=dev mix docs
```

## Tests

Tests coverage is a work in progress and all help is appreciated!

```bash
export MIX_ENV=test
mix deps.get
mix test
```

## Code Styling and Consistency

Credo doesn't work very well on umbrella projects, so I only enforce credo on
the main application.

Note: this will show all #TODOS in the application.

```bash
cd ~/farmbot/os/apps/farmbot
export MIX_ENV=dev
mix deps.get
mix credo --strict
```



## Building the Linux RootFS

```bash
cd ~/farmbot/os
# this should set up the environment needed to build the system
export NERVES_TARGET=<MY_BOARD_CHOICE>
make create-build-${NERVES_TARGET}

# Now that the environment is set up you should change into the new dir it told you too.
cd apps/NERVES_SYSTEM_${NERVES_TARGET}
# from this dir we have a few different things we can configure in buildroot.

# To add/remove linux packages.
make menuconfig

# To add/remove busybox packages.
make busybox-menuconfig

# To add/enable/disable features in the kernel.
make linux-menuconfig

# Save those configs

# For buildroot packages
make savedefconfig

# For busybox config
cp build/busybox*/.config ../nerves_system_*/busybox_defconfig

# for linux config
cp build/linux*/.config ../nerves_system_*/linux-*.defconfig

# To make your configuration
make

# that will take a while depending on your machine. You will see the build output in your terminal.
# on a core i7, 32 gigs or ram, nvme ssd machine, it takes about 15-20 minutes depending on if ccache is enabled.

# when the rootfs build finishes to use said rootfs in building firmware:
cd ../farmbot

mix firmware
# to burn to an sdcard. (this requires sudo)
mix firmware.burn

```

## Porting to a New System

There are several options for porting FarmBot to non-Raspberry Pi systems. One option is to use the RPI3 system as a template:

```bash
cd ~/os/farmbot/os/apps
mix new nerves_system_newboard
```

At bare minimum you will need the following files files, using the RPI3 system as a template:

```
nerves_system_newboard
├── rootfs-additions
├── busybox_defconfig
├── fwup.conf
├── linux-VERSION.defconfig
├── mix.exs
├── nerves.exs
└── nerves_defconfig
```

Lets go thru those files and folders and explain what each one is.

* `rootfs-additions`
    thechnically this is optional but that will never happen. there is usually some prop files needed like wireless firmware, erlinit config etc.
* `busybox_defconfig`
    This file has extra configs for Farmbot System. We require a few extra packages in busybox to be enabled.
    * mkfs.ext
* `fwup.conf`
    [FwUp](https://github.com/fhunleth/fwup) is how farmbot updates and builds its firmware. This can be configured how ever your platfrom requires, but we require a few basic things
    * one squashfs system partition which will ALWAYS read only.
    * one data partition. This can be any filesystem as long as it supports symbolic links. It will be mounted read only MOST of the time
* `linux.defconfig`
    The configuration for the Linux Kernel on this board.
* `mix.exs`
    a description of this project. requires a bit of configuration. see rpi3 system for example.
* `nerves.exs`
    configures a nerves target. See RPI3 System for examples.
* `nerves_defconfig`
    The buildroot configuration. Needs a bit of specifics.
    ```
    buildroot
    ├── packages
    |    ├── networking
    |    |   ├── hostapd
    |    |   ├── dnsmasq
    |    |   ├── dropbear
    |    |   └── iw
    |    |
    |    └── hardware handling
    |        └── avrdude
    |
    └── filesystem
        └── squashfs
    ```
