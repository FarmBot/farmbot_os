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
