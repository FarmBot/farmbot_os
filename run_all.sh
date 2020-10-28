#!/bin/bash

set -e
set -o pipefail
cd farmbot_telemetry

echo "######### farmbot_telemetry"
cd ../farmbot_telemetry
mix format
mix deps.get --all
mix test

echo "######### farmbot_celery_script"
cd ../farmbot_celery_script
mix format
mix deps.get --all
mix test

echo "######### farmbot_firmware"
cd ../farmbot_firmware
mix format
mix deps.get --all
mix test

echo "######### farmbot_core"
cd ../farmbot_core
mix format
mix deps.get --all
mix test

echo "######### farmbot_ext"
cd ../farmbot_ext
mix format
mix deps.get --all
mix test

echo "######### farmbot_os"
cd ../farmbot_os
mix format
mix deps.get --all
mix test

cd ..
cd farmbot_os

echo "######### Build RPI3 FW"
MIX_ENV=prod MIX_TARGET=rpi3 mix deps.get
MIX_ENV=prod MIX_TARGET=rpi3 mix compile --force
MIX_ENV=prod MIX_TARGET=rpi3 mix firmware

echo "######### Build RPI0 FW"
MIX_ENV=prod MIX_TARGET=rpi mix deps.get
MIX_ENV=prod MIX_TARGET=rpi mix compile --force
MIX_ENV=prod MIX_TARGET=rpi mix firmware
