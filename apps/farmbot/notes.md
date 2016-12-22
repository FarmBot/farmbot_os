# STATE PERSISTENCE
## Modules that need to persist configuration across reboots.
These are all key values. IE not actually state, but just configuration.
* Farmbot.BotState.Authorization
  * server
  * secret
* Farmbot.BotState.Configuration
  * os_auto_update
  * fw_auto_update
  * timezone
  * steps_per_mm
* Farmbot.BotState.Network
  * connection (ethernet or wifi creds)
* Farmbot.BotState.Hardware
  * all mcu_params

## Modules that require actual state to persist reboots
These modules actually have more than just configuration.
* Farmbot.Scheduler
* Farmbot.Sync.Database

## Problems
* Storing configuration is easy. it can be stored as a json file on the data partition but actually saving that file along with states is hard.
  * Without serializing everything to one file, different modules will be fighting for time to save to disk.
* Storing small State is easy, it can be stored from :erlang.term_to_binary |> File.write!
  * same as above problem.
* Storing large state (like the scheduler, and the database) is more difficult.
  * Turning the entire state to a binary takes an exponential amount of time.
  * it updates frequently and having to "stringify" it every update would slaughter performance.

## Solutions
The previous solution was to have EVERY thing that needed state to persist reboots be entered into a server "SafeStorage"
This works for small states and configurations. but its over kill for simple key value storage that can be represented as json data.
and is "underkill" for large amounts of state that arent as easily "stringified"

* Configuration can be stored as a json file, all represented by one module Farmbot.ConfigStorage
  * This file can have a routine to save to the filesystem or enter into a module that saves to disk.
  * could also save to the /tmp partition, then another module copies that file to the main persistent ext4 fs.
* The Database uses amnesia, and could probably use built in :mnesia commands to copy it to persistent storage
  * or :mnesia could copy to /tmp similarly to configuration, and the yet to be created module could copy that /tmp to persisteent fs.
* scheduler stil tbd


# Network
## Problem
* network information needs to persist reboots.
* networking needs to support quite a few differente modes
  * ethernet
    * static
    * dhcp
  * wifi
    * static
    * dhcp
  * host mode
  * already connected (no managemnt from farmbot.)

but it also can't be too tightly coupled to authorization.
for example: i cant just have network get an ip address, and then tell authorization to do its thing.
network should be taken care of before the farmbot application starts, but be configurable at runtime.

configurator needs to have some knowledge of networking because it gets configured there, but it really only needs to know what
different interfaces are available and how to configure them. Configurator should have no knowledge of linux. it should just pass information along to something else.
