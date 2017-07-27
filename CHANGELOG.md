# 2.1.9
* changed folder structure around
* moved farmbot_auth and farmbot_configurator back into an umbrella application
* begin migration to CeleryScript for all the things
* Multi Platform support
* `Configurator` looks great. thanks @MrChristofferson && @RickCarlino
* Code base was converted to CeleryScript, so it is much more stable
* bot configuration is now based on a single (json) that is shared across platforms/targets

# 2.1.10
* a few minor bug fixes to the previous release.

# 3.0.0
* Makefile

# 3.0.1
* implement bot state migrations
* logger fixes.

# 3.0.2
* Farmware initial concepts.

# 3.0.3
* Farmware fixes

# 3.0.4
* Logger bug fixes

# 3.0.5
* Configurator got a facelift + a few extra features.

# 3.0.6
* Syncing is now a multiple request action and is now much faster and safer.
* change folder structure
* begin adding redis support.

# 3.0.8
* Rewrite Serial handler and bundle FW into the OS.

# 3.1.0
* Fix a bug with unwanted Logs going to the frontend/backend.

# 3.1.1
* Bundle a new FW fixing z axis and gravity.

# 3.1.2
* Fix bug caused by Github changing their release api.

# 3.1.3
* Fix peripheral bug.

# 3.1.4
* Bundle new FW
* Add Rollbar client

# 3.1.5
* Clean up a ton of log messages causing RollBar problems.
* Finally rewrite the firmware uploader.
* Bump Firmware Version.
* Misc bug fixes.

# 3.1.6
* Bundle new FW (01.13)
* Increase WiFi Stability
* Refresh auth token more frequently
* Clean up noisy log messages

# 4.0.0
* bundle new Arduino Firmware
* overhaul HTTP adapter
* start fixing cross cutting concerns within the application

# 4.0.1
* fix bug in E-Stop

# 4.0.2
* add a progress bar to http client for downloads.
* Bundle new Arduino Firmware.
* Rewrite Farmware Handler again, to use HTTP/REST this time instead of STDIN/STDOUT.
* Add location_data to bot state. This includes encoder position.
* Add `jobs` field to bot state.
