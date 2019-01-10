# Changelog

# 6.4.14
* Initial support for WPA-EAP networks. 

# 6.4.13
* Add SensorReadings when `read_pin` is executed.

# 6.4.12
* Fix race condition after getting time which broke self hosting users.
* Add retry mechanism for fetching a token.
    * Farmbot will now try 5 times to fetch a token.
* Fix bug causing static ip settings not to work.
* Enable `multi_time_warp` which should hopefully compensate for time skew.
* Migrate OTA system to NervesHub

# 6.4.11
* Add SSH back.
* Fix bug during configuration causing bots to maybe not connect.
* FarmBot will now try to emergency lock the firmware on powerdown and reset.
* Fix bug causing FarmBot not to reconnect to WiFi.
* Add fields to `informational_settings`:
    * `uptime` seconds
    * `memory_usage` megabytes
    * `disk_usage` percent

# 6.4.10
* Skipped due to release failure.

# 6.4.9
* Add feature to save logs to sdcard for debugging.
* Fix bug causing long running Farmwares to fail.
* Make sure to clear eeprom before flashing Arduino firmware.
* Update Linux system layer.

# 6.4.8
* Make sure not to crash if a wifi network is malformed.

# 6.4.7
* Fix DNS server config for self hosters.
* Add new field to `informational_settings`: `currently_on_beta`.
* Reindex farmware on bot_state crash.

# 6.4.6
* Add new RPC to reinitialize Firmware
* Tweak PinBinding debounce timeout.
* Update Linux system layer to fix sound.

# 6.4.5
* Fix Firmware syncing applying _every_ setting.

# 6.4.4
* Optimize AMQP connection.
* Sync PinBindings with the API.
* Add new field on `informational_settings`: `soc_temp`.
* Add new field on `informational_settings`: `wifi_level`.
* Add new RPC `dump_info` that collects some info helpful for bug reports.
* Add `BoxLed3` and `BoxLed4` to `write_pin`.
* Implement new LED subsystem.
* Declare language and charset in Configurator to avoid localization issues.
* Add new Configurator fields for dns and ntp.
* Another attempt at catching broken sqlite3 lib.
* Update Linux system layer.

# 6.4.3
* Fix Ramps firmware build.

# 6.4.2
* Remove `hostapd`
* Remove a lot of custom Logger code.
* Try to write the last 100 logs to a flash drive if one exists.
* Fix bugs in `send_message` block templating.
* Add new farmware_tools package for plugins.

# 6.4.1
* Beta updates should _always_ try to flash firmware.
* Bump Nerves and friends to 1.0.0.
* Add new firmware params: `movement_invert_2_endpoints_<x|y|z>`.
* Add new rpc: `set_pin_io_mode`.
* Clean up positions in logs.
* Update Configurator to support more control over network setup.
* Add mdns to development setups.
* Remove use of `iw`.
* Add checks for uart auto detector.
* Syncing a sequence reindexes running regimens that require it.

# 6.4.0
* Update logs to no longer use the `meta` field.
* Update Timed Estop messages to use the `fatal_email` channel.
* Regimens will now persist reboots.

# 6.3.2
* Add support for Raspberry Pi 3 B+.
* Add new package `pyserial`.

# 6.3.1
* Fix bug causing FarmEvents not to work.

# 6.3.0
* Update system update system.
* Rename and refactor external resources internally so they are more readable in the codebase.
* Write tests for new system.
* Implement the new "Flat" CeleryScript representation.
* Add ability to log into a new account without rebooting into Configurator.
* Firmware settings are now synced with Farmbot API.
* Add third Firmware board.
* Fix bug causing false positives on sync failure.
* Fix bug causing a captive portal staying up if the user chooses a wired network connection.
* Fix bug that prevented a user from configuring network credentials.
* Fix bug that would halt bootup if a PinBinding is high during boot.
* Add new syncable `Sensor`.
* Add new celeryscript node `NamedPin`.
* Add new args:
   * `pin_id`
   * `pin_type`
* allow `pin_number` to be new `NamedPin` node.
* allow to use `NamedPin` in:
   * `ReadPin`
   * `WritePin`
   * `If`

# 6.2.1
* Fix Bug breaking diy builders with Arduinos showing up other than `/dev/ttyACM0`.

# 6.2.0
* Farmbot Settings are now synced with Farmbot API.
* Refactor Syncing to not make unnecessary HTTP requests.
* Estop status is now much faster.
* Add dns checkup for users with factory resetting disabled to make tokens refresh faster.
* Opting into beta updates will refresh farmbot's token.

# 6.1.2
* Fix fw hardware being reset on os upgrade.
* Bump arduino-firmware version to 6.0.1

# 6.1.1
* Fix bug that caused the "update" button on the frontend to give an error log.
* Fix flashing `beta` channel updates.
* Add feature to send user an email if the bot has been e-stopped for 10 minutes.
* Add feature to `espeak` logs.
* Set `busy` a little earlier making the bot seem snappier.
* Fix `tzdata` bug for real this time.
* Update Arduino Firmware.

# 6.1.0
* Remove all the migration code to safely get from 5.0.x to 6.0.1.
* Clean up and upgrade dependencies.
* Fix bug that could cause Image uploads to silently fail.
* Fix bug in `tzdata` that could cause the sdcard to fill up.

# 6.0.1
* Add feature auto sync.
* Add feature RPI GPIO.
* Refactor Configurator to not need Javascript/Webpack
* Add timer before network not found factory resets bot.
* Remove steps/mm conversion.
* Bundle new arduino-firmware.
* Replace MQTT with AMQP.
* Get rid of Log batching.
* Add verbosity level to _every_ log message.
* Show position for log messages.
* Add many helpful log messages.
* Add feature to disable many log message.
* Add feature to log all arduino-firmware I/O.
* Migrated CI to CircleCI from TravisCI.
* Refactored FarmEvent Calendar generator.
* Fix a ton of little bugs.

# 5.0.9
* Add missing redis-py package for Farmware.

# 5.0.8
* Update underlying Linux System deps.
* Preperation for 6.x releases.

# 5.0.6
* Fix images double uploading.
* Allow reinstallation of first party farmware.

# 5.0.5
* Fix token refreshing.

# 5.0.4
* Fix lag when communicating over MQTT
* Don't retain last will log message.
* Update node packages.

# 5.0.3
* Add selector for firmware hardware to Configurator.
* Fix an OS update bug.
* Fix an image upload bug.
* Fix a farmware download bug.

# 5.0.2
* Fix a bug causing `busy` to be set erroneously.
* add note to configurator for osx users.

# 5.0.1
* Fix not being able to move to a point in some cases.
* Fix a sub sequence never returning.
* add `busy` flag to the bot's state.

# 5.0.0
* add a progress bar to http client for downloads.
* Bundle new Arduino Firmware.
* Rewrite Farmware Handler again, to use HTTP/REST this time instead of STDIN/STDOUT.
* Add location_data to bot state. This includes encoder position.
* Add `jobs` field to bot state.

# 4.0.1
* fix bug in E-Stop

# 4.0.0
* bundle new Arduino Firmware
* overhaul HTTP adapter
* start fixing cross cutting concerns within the application

# 3.1.6
* Bundle new FW (01.13)
* Increase WiFi Stability
* Refresh auth token more frequently
* Clean up noisy log messages

# 3.1.5
* Clean up a ton of log messages causing RollBar problems.
* Finally rewrite the firmware uploader.
* Bump Firmware Version.
* Misc bug fixes.

# 3.1.4
* Bundle new FW
* Add Rollbar client

# 3.1.3
* Fix peripheral bug.

# 3.1.2
* Fix bug caused by Github changing their release api.

# 3.1.1
* Bundle a new FW fixing z axis and gravity.

# 3.1.0
* Fix a bug with unwanted Logs going to the frontend/backend.

# 3.0.8
* Rewrite Serial handler and bundle FW into the OS.

# 3.0.6
* Syncing is now a multiple request action and is now much faster and safer.
* change folder structure
* begin adding redis support.

# 3.0.5
* Configurator got a facelift + a few extra features.

# 3.0.4
* Logger bug fixes

# 3.0.3
* Farmware fixes

# 3.0.2
* Farmware initial concepts.

# 3.0.1
* implement bot state migrations
* logger fixes.

# 3.0.0
* Makefile

# 2.1.10
* a few minor bug fixes to the previous release.

# 2.1.9
* changed folder structure around
* moved farmbot_auth and farmbot_configurator back into an umbrella application
* begin migration to CeleryScript for all the things
* Multi Platform support
* `Configurator` looks great. thanks @MrChristofferson && @RickCarlino
* Code base was converted to CeleryScript, so it is much more stable
* bot configuration is now based on a single (json) that is shared across platforms/targets
