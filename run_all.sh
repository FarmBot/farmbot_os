#!/bin/bash

set -e
set -o pipefail

MIX_ENV=prod

cd farmbot_telemetry

echo "######### farmbot_telemetry"
cd ../farmbot_telemetry
mix deps.get --all
mix coveralls.html
rm -f *.coverdata
mix compile
mix format
mix test

echo "######### farmbot_celery_script"
cd ../farmbot_celery_script
mix deps.get --all
mix coveralls.html
rm -f *.coverdata
mix compile
mix format
mix test

echo "######### farmbot_firmware"
cd ../farmbot_firmware
mix deps.get --all
mix coveralls.html
rm -f *.coverdata
mix compile
mix format
mix test

echo "######### farmbot_core"
cd ../farmbot_core
mix deps.get --all
mix coveralls.html
rm -f *.coverdata
mix compile
mix format
mix test

echo "######### farmbot_ext"
cd ../farmbot_ext
mix deps.get --all
mix coveralls.html
rm -f *.coverdata
mix compile
mix format
mix test

echo "######### farmbot_os"
cd ../farmbot_os
mix deps.get --all
mix coveralls.html
rm -f *.coverdata
mix compile
mix format
mix test

cd ..
cd farmbot_os

echo "######### Build RPI3 FW"
MIX_TARGET=rpi3
mix deps.get
mix compile --force
mix firmware

echo "######### Build RPI0 FW"
MIX_TARGET=rpi
mix deps.get
mix compile --force
mix firmware
