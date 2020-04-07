# FarmBot OS Documentation

This document will act as an index to available documentation.

## Glossary

* [FarmBot Source Code common terms](/docs/glossary.md)

## Cheat Sheet

**Create a *.fw file from local repo (RPi Zero):**

```sh
NERVES_SYSTEM=farmbot_system_rpi MIX_TARGET=rpi mix deps.get
NERVES_SYSTEM=farmbot_system_rpi MIX_TARGET=rpi mix firmware
sudo fwup farmbot_os/_build/rpi/rpi_dev/nerves/images/farmbot.fw
```

**Create a *.fw file from local repo (RPi v3):**

```sh
NERVES_SYSTEM=farmbot_system_rpi3 MIX_TARGET=rpi3 mix deps.get
NERVES_SYSTEM=farmbot_system_rpi3 MIX_TARGET=rpi3 mix firmware
sudo fwup farmbot_os/_build/rpi3/rpi3_dev/nerves/images/farmbot.fw
```

**Create or Update the Nerves System:**

Please see the official [Nerves documentation on "Nerves Systems"](https://hexdocs.pm/nerves/0.4.0/systems.html).

HINT: You may want to [develop the system locally](https://stackoverflow.com/a/28189056/1064917)

## Hardware specifics

Most FarmBot development/testing is done on a standard desktop PC.

* [Developing on your local PC](/docs/host_development/host_development.md)
* [Deploying on Raspberry Pi](/docs/target_development/building_target_firmware.md)
  * [Provisioning OTA system](/docs/target_development/provisioning_ota_system.md)
  * [Publishing Firmware (OTAs)](/docs/target_development/releasing_target_firmware.md)
  * [Why doesn't my device boot after building firmware](docs/target_development/target_faq.md)
  * [Inspecting a running devicve](/docs/target_development/consoles/target_console.md)

## CeleryScript

CeleryScript is FarmBot's native scripting language. See the below
documentation for information about it as it relates to FarmBot OS.

* [CeleryScript intro](/docs/celery_script/celery_script.md)
* [A list of all supported commands](/docs/celery_script/all_nodes.md)
* [Lua (embedded scripting inside CeleryScript)](/docs/celery_script/assert_expressions.md)

## Project structure

The FarmBot OS application is broken into several sub applications.

* [Project structure overview](/docs/project/structure.md)
  * [farmbot_celery_script](/docs/project/farmbot_celery_script.md)
  * [farmbot_core](/docs/project/farmbot_core.md)
  * [farmbot_ext](/docs/project/farmbot_ext.md)
  * [farmbot_firmware](/docs/project/farmbot_firmware.md)
  * [farmbot_os](/docs/project/farmbot_os.md)
  * [farmbot_telemetry](/docs/project/farmbot_telemetry.md)
