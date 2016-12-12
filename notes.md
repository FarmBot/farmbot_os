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
