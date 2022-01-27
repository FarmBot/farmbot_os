# Changelog

# 14.9.0

 * Ability to manage `resource` variables from Lua.
 * Ability to specify `safe_z` from Lua `move_absolute()`.

# 14.8.1

 * Add `api()` helper to simplify API access in Lua.
 * Remove legacy logs relating to device updates.
 * Ability to execute raw CeleryScript from Lua.

# 14.8.0

 * Upgrade Elixir, Erlang and system deps.
 * Nerves System (Linux) upgrade.
 * Add support for RPi4 target.
 * Bugfix: Prevent crashes from stopping a soft reset.
 * Change the way Lua handles e-stops (no operation during e-stop now that soft_stop() exists)
 * E-stop now prevents _all_ sequence operations, not just firmware commands.
 * Add `movement_calibration_retry_total_*` fields to MCU params
 * Lua technical preview for `set_job_progress` / `get_job_progress`

# 14.7.0

 * Add support for text variables.
 * Possible fix for "blinking MQTT" bug where device stops seeing incoming MQTT packets.
 * Increase UART timeout / better handling of UART timeouts.
 * Genesis and Express firmware updates.
 * Fix bug where scheduling > 1 regimen per day would crash the scheduler.
 * Farmware updates.

# 14.6.4

 * Genesis and Express firmware updates.
 * Fix bug where firmware parameters would appear to not be uploaded.
 * Ability to handle `numeric` sequence variables from Lua
 * Silence timeout error messages from user log stream
 * Add `photo_grid()` technical preview to Lua VM.
 * Better handling of timeout errors in lua `http()` function.
 * Bugfix: Prevent firmware handler from crashing when there is an active but unused pin watcher.

# 14.6.3

 * Recovery deploy / hotfix. Fix bug where not all firmware parameters would load.

# 14.6.2

 * Fix bug where Lua scripts would not stop sending GCode during estop
 * Genesis and Express firmware updates.
 * Improved Lua error legibility.
 * Technical preview of load sense API
 * Routine dependency upgrades.

# 14.6.1

 * Remove need to download farmwares over the network (improves offline experience)
 * Remove references to legacy components (FarmbotCore, FarmbotExt, etc..)
 * Add new Lua functions: `detect_weeds`, `garden_size`, `measure_soil_height`

# 14.6.0

 * Upgrade database driver.
 * Convert application to a monolith.

# 14.5.0

 * SSL/HTTPS configuration updates.
 * Upgrade numerouse deps, such as Lua runtime and Certifi.
 * Fix issue where FarmEvents would fail to execute near boot time on Express models.
 * Performance updates to firmware handler.

# 14.4.1

 * Update Erlang version
 * Update error reporting info

# 14.4.0

 * Upgrade Nerves system, Erlang, Elixir, OTP.
 * Minor changes related to deprecations and platform changes.

# 14.3.3

 * Ability to read `lat`, `lng`, and `indoor` from Lua `get_device()` helpers.
 * Fix system halting memory leak when taking > 1,000 photos in a single boot.
 * Increase timeout for `http()` requests in Lua.
 * `alpha` release of Lua helpers: `base64.encode()`, `base64.decode()`, `auth_token()`, `take_photo_raw()`.
 * Fix bug where calling `json.decode()` in Lua on an Array would raise an exception.

# 14.3.2

 * Refactor code that generates calendars for FarmEvent resources.
 * Routine dependency upgrades
 * Bug fix: FBOS crashes when pinbinding is set to SYNC / REBOOT.

# 14.3.1

 * Express firmware bugfix

# 14.3.0

 * Genesis and Express firmware updates.
 * Ability to use more than one variable per sequence.
 * Ability for Lua developers to see current point group via `__GROUP__` sequence variable.
 * Improved CeleryScript / RPC error reporting.
 * Fix bug where stall was reported as timeout.
 * Report axis name when detecting stalls.

# 14.2.2

 * Genesis and Express firmware updates.

# 14.2.1

 * Add new v1.6 firmware with beta support for quiet mode.
 * Fix problem where writing to an analog peripheral did not update device state.
 * Add a `write_pin()` lua helper.
 * Bug fix for some Lua formulas.
 * Full removal of factory reset timers.
 * MOVE block now attempts to guess soil height when more than three soil height readings are available (previous versions relied on `soil_height` setting in device panel)
 * Genesis and Express firmware updates.

# 14.2.0

 * Expose the following point attributes to the Lua `variable()` helper:
    * gantry_mounted
    * id
    * meta
    * openfarm_slug
    * plant_stage
    * pointer_type
    * pullout_direction
    * radius
    * tool_id

# 14.1.3

 * Box LED fixes.
 * Impoved internal diagnostic tools for diagnosing camera problems.
 * Routine dependency updates.

# 14.1.2

 * Remove WatchDog timer.

# 14.1.1

 * Add WatchDog timer to handle unresponsive firmware.

# 14.1.0

 * Routine system upgrades.
 * Fix box LEDs (solid red when firmware online).
 * Fix espeak logs.
 * Remove useless / developer-centric logs

# 14.0.3

 * Fix bug where some FarmEvent and Regimen executions silently fail
 * Add `wait()` helper to Lua
 * Minor changes to firmware restart logic
 * Remove non-actionable disconnect logs.

# 14.0.2

 * Better error output for Lua users
 * Bug fix in Lua `read_pin` helper
 * Bug fix in Lua `uart.*` helpers (ALPHA status - feedback welcome!)
 * Routine dep. updates.

# 14.0.1

 * Bugfix for CODE 30 error under rare circumstances.

# 14.0.0

 * Complete overhaul of firmware handler in FBOS.
 * Genesis and Express firmware updates.
 * Ability to use `custom.hex` firmware file in user data partition instead of default firmware.
 * Ability to detect missing boot loader.
 * Bug fix for devices that became throttled after long disconnects.
 * Alpha support for 3rd paty UART devices in Lua sandbox.

# 13.2.0

 * Expose `set_pin_io_mode` to Lua (feature request from forum use @JoeHou)

# 13.1.0

 * Finalize AMQP removal. MQTT is the only transport now.

# 13.0.1

 * Begin transition back to MQTT from AMQP (ping channel only)

# 13.0.0

 * Nerves system upgrade

# 12.3.4

 * Bug fix for self-hosted image uploads.
 * Support for new LUA block
 * Numerous fixes to Lua VM (formulas, ASSERT block, LUA block)
 * Ability to access sequence variables within LUA block (via `variables.parent`)

# 12.3.3

Bug fixes:

 * SD card errors from log overflow (limit log buffer to 1000 logs max).
 * app crashes if user accidentally installs very old / incompatible Farmwares.
 * prevent firmware handler crashes on unexpected or timed out messages.
 * WiFi-related app crashes on certain networks.

# 12.3.2

 * Improve remote error reporting.
 * Improve captive portal performance on certain platforms.

# 12.3.1

 * Require explicit call to `read_status()` to update farmware state information.

# 12.3.0

 * Fix farmware bug where farmware system reports stale version of bot state.

# 12.2.3

 * Firmware debug log removal

# 12.2.2

 * Performance updates for Express devices
 * Fix firmware bug where `report_position_change` was erroneously reported as an error.
 * Dependency upgrades
 * Firmware debug log removal

# 12.2.1

 * Performance updates for Express devices
 * Fix firmware bug where `report_position_change` was erroneously reported as an error.

# 12.2.0

 * Legacy component removal.
 * Upgrade OS-level dependencies.
 * Add support for USB Ethernet adapters (for Express users with WiFi trouble)

# 12.1.0

 * `safe_height` and `soil_height` support for MOVE block.
 * Bug fix relating to auth errors after > 40 days of uptime.

# 12.0.1

 * See release notes for 12.0.0

# 12.0.0

 * Migrate OTA system to an in-house solution.
 * Express v1.0 firmware updates.
 * Fix bug where sequences would crash when a `coordinate` is passed as a variable (Thanks, @jsimmonds2).

# 11.1.0

 * Interim release to transition devices to new in-house OTA system

# 11.0.1

 * Bug fix related to usage of tools in MOVE block.
 * Interim release to transition devices to new in-house OTA system

# 11.0.0

 * Auto sync is now mandatory.
 * Ability to use Lua expressions for movement
 * Ability to set "variance" to movement commands
 * Ability to use axial overrides
 * Ability to perform axis addition
 * "Safe Z" feature
 * Remove CeleryScript unused variable warnings in terminal
 * Ability to set speed for an individual axis (rather than all axes)
 * Improve accuracy of runtime telemetry (Thanks, @Jsimmonds2)

# 10.1.6

 * Add colors and labels to configurator WiFi signal strengths.

# 10.1.5

 * Remove unused variable warning from SSH logs.
 * Fix bug affecting OTAs of Express devices.

# 10.1.4

 * See changelog for 10.1.5

# 10.1.3

 * Express v1.0 firmware homing updates.
 * Add warning to configurator credentials page.
 * Fix bug where configurator would not restart when bad credentials were entered.
 * Fix missing `firmware_path` bug.

# 10.1.2

 * Express v1.0 firmware updates.
 * Regimen Farm Event scheduler fixes.

# 10.1.1

 * Changes to TTY to allow use of DIY boards
 * Upgrade underlying OS for RPi3 Nerves system (`ERL_CRASH_DUMP_SECONDS=-1`)

# 10.1.0

 * Internal upgrades to underlying OS
 * Bug fix to prevent firmware reset issues when MCU becomes unresponsive

# 10.0.1

 * Fix for Genesis v1.5 firmware bug.

# 10.0.0

 * Deprecate `resource_update` RPC
 * Introduce `update_resource` RPC, which allows users to modify variables from the sequence editor.
 * Genesis v1.5 and Express v1.0 firmware updates.
 * Fix a bug where FBOS would not honor an "AUTO UPDATE" value of "false".

# 9.2.2

 * Fix firmware locking error ("Can't perform X in Y state")
 * Removal of dead code / legacy plus numerous unit test additions.
 * Added coveralls test coverage reporter
 * Unit test additions (+2.7% coverage :tada:)
 * Updates to build instructions for third party developers
 * Bug fix for criteria-based groups that have only one filter criteria.
 * Bug fix for express bots involving timeout during remote firmware flash
 * Remove VCR again (for now)
 * Increase farmware timeout to 20 minutes (use at own risk)

# 9.2.1

 * Improve firmware debug messages.
 * Remove confusing firmware debug messages, such as "Error OK".
 * Improved camera support on FarmBot express.
 * Bug fix to prevents OTA updates occuring when one is already in progress.

# 9.2.0

 * Support for criteria-based groups.
 * Genesis v1.5 and Express v1.0 firmware homing updates.
 * Fix bug where unknown positions would report as -1.

# 9.1.2

 * Genesis v1.5 and Express v1.0 firmware updates.
 * Bug fix for movement error reporting
 * Improved firmware error message reporting
 * Improved support for gantry mounted tools.

# 9.1.1

 * Genesis v1.5 and Express v1.0 firmware updates.

# 9.1.0

 * Improved support for new FarmBot Express models
 * Various firmware bug fixes for Express models.
 * Bug fix for slow Farmware execution (Thanks, @jsimmonds2)
 * Dependency upgrades
 * Upgrade VintageNet (networking library)
 * Removal of `dump_info` RPCs
 * Numerous internal improvements, such as increasing test coverage and changing dependency injection scheme.
 * Fix issue where firmware commands would be tried too many times.

# 9.0.4

 * Bug fix for slow Farmware execution (Thanks, @jsimmonds2)
 * Dependency upgrades
 * Upgrade VintageNet (networking library)
 * Removal of `dump_info` RPCs
 * Numerous internal improvements, such as increasing test coverage and changing dependency injection scheme.

# 9.0.3

 * Dependency updates

# 9.0.2
 * See notes for 9.0.1.

# 9.0.1
 * Routine token updates on Circle CI.
 * Fix bugs that were causing devices to erroneously factory reset under some circumstances.

# 9.0.0
 * Run updates on Nerves systems.
 * Updates to the way `set_servo_angle` is handled.
 * Fixes rip0 firmware flash issues.

# 8.2.4
* Bug fixes
    * fix Farmware causing sequences to exit
    * fix `arduino_debug_messages` fbos_config field being ignored
    * fix `espeak` not working
    * add `name` paramater back to image uploads
* Enhancements
    * `resource_update` command can now update:
        * device.mounted_tool_id
        * GenericPointer.*

# 8.2.3
* Features
    * Farmbot will now check for an hour in which to apply over the air updates
* Bug fixes
    * `take-photo` will now send a log
    * having multiple instances of the app open won't cause sync errors

# 8.2.2
* Bug fixes
    * Fix race condition in executing farmwares

# 8.2.1
* Features
    * Add timer to reset `firmware_input_log` and `firmware_output_log` after 5 minutes
    * Add a back off timer for flashing firmware
* Bug fixes
    * Fix issue where opencv would error. Most notibly in take-photo

# 8.2.0
* Features
    * Add telemetry to app. Telemetry data is now streamed to AMQP
    * Add log messages containing iteration context for looped sequences and events
    * Add support for EAP networks back

# 8.1.1
* Bug fixes
    * Fix bug where farmbot could not execute the following commands
        * home
        * calibrate

# 8.1.0
* Features
    * PointGroups are now supported by farmbot os
    * Sequence, FarmEvent, and Regimens can now enumerate over PointGroups
* Bug fixes
    * Fixed a arduino-firmware bug when sending commands that are bigger than the buffer

# 8.0.4
* Bug fixes
    * Fix the `move_absolute` step to honor speed parameter correctly

# 8.0.3
* Features
    * Add new firmware params to support trinamic motor drivers
* Bug fixes
    * Fix farmware sometimes hanging sequences
    * Fix the `mark_as` step

# 8.0.2
* Updated dependencies
    * `nerves_hub`
    * `nerves_runtime`
* Updated log messages
    * Configuration changes now log human readable names
    * Firmware changes now log human readable names
* Bug fixes
    * Fix farmbot ignoring `movement_invert_2_endpoints` params

# 8.0.1
* Updated log messages
    * AMQP connection log should be less noisy on first boot
    * Farmware installation logs will be more condensed
* Enhancements
    * Syncing LED blink speed increased

# 8.0.0
* Reorganize project structure
* Split original single application into multiple OTP applications:
    * `farmbot_celery_script` - CeleryScript compiler and friends
    * `farmbot_firmware` - Interaction with the motor controler
    * `farmbot_core` - Main database access and other workers
    * `farmbot_ext` - Extra, mostly networked functionality
    * `farmbot_os` - `Nerves` Framework
* Refactor global process initialization
* Refactor networking for increased reliability
* Refactor CeleryScript to support run-time variables
* Preliminary support for raspberry pi 0

# 7.0.3
* Update to AMQP to disable `heartbeat` timeouts

# 7.0.2
* AMQP now reconnects immediately after an unexpected disconnect
* Misc Configurator UI updates

# 7.0.1
* Fix typo causing custom dns servers to be ignored.
* Update Configurator UI
* Update Farmbot-Arduino-Firmware to 6.4.2
* Fix bug in decoding of CeleryScript
* Fix bug causing the stubbed Firmware implemenation to crash

# 7.0.0
* Initial support for WPA-EAP networks.
* Increase NervesHub reconnect timer to not waste CPU time.
* Update Farmware packages
    * Python 3
    * OpenCv 3

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
