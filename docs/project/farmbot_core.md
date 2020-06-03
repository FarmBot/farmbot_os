# FarmBot Core OTP App

`farmbot_core` is responsible for the core funcionality of the FarmBot application.
This contains things such as resource (asset) management, plugin (farmware) management,
central state, and schedule management. FarmBot specific network requests are not
made from the `farmbot_core` app. Below describes the important subsystems

## Asset storage subsystem

Sqlite database responsible for storing data needed for FarmBot to operate.
Most device specific REST resources are mirrored here.

* Device
* FarmEvent
* Regimen
* Sequence
* Peripheral

## Asset Worker subsystem

All assets that need to have a process associated with it will be found
in this subsystem. Examples of this include:

* FarmEvent scheduling
* Regimen scheduling
* PinBinding monitoring
* FbosConfig/FirmwareConfig

## Farmware subsystem

Farmbot's external plugin system. See the Farmware documentation for more details.

## BotState subsystem

Central in-memory state process/tracker. This process keeps a cache of
all the moving parts of FarmBot. Some examples of what is stored
in this cache:

* Firmware reporting
  current axis position
  encoder data
  arduino pin data
  currently configured firmware paramaters
* Current configuration
  mirror of `fbos_config` asset
* System info
  version info
  (nerves) firmware info
  memory usage
  disk usage
* Network info
  WiFi signal quality
  private ip address

## Logging subsystem

This is where the `Messages` panel gets it's data from. Calls to this subsystem
push data into an sqlite database. This data is collected on a timer and dispatched
over AMQP/MQTT when/if that subsystem is available. See [farmbot_ext](/docs/project/farmbot_ext.md)
for information on how that works.
