#!/bin/sh

cd farmbot_telemetry
cd ../farmbot_celery_script
mix format
mix deps.get --all
mix test

cd ../farmbot_core
mix format
mix deps.get --all
mix test

cd ../farmbot_ext
mix format
mix deps.get --all
mix test

cd ../farmbot_firmware
mix format
mix deps.get --all
mix test

cd ../farmbot_os
mix format
mix deps.get --all
mix test

cd ../farmbot_telemetry
mix format
mix deps.get --all
mix test
