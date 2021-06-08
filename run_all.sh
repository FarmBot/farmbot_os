#!/bin/bash

set -e
set -o pipefail

export MIX_ENV=test

cd farmbot_telemetry

clear
echo "######### farmbot_telemetry"
cd ../farmbot_telemetry
mix format
mix deps.get --all
MIX_ENV=test mix compile --warnings-as-errors --force
mix coveralls.html
rm -f *.coverdata

clear
echo "######### farmbot_celery_script"
cd ../farmbot_celery_script
mix format
mix deps.get --all
MIX_ENV=test mix compile --warnings-as-errors --force
mix coveralls.html
rm -f *.coverdata

clear
echo "######### farmbot_core"
cd ../farmbot_core
mix format
mix deps.get --all
MIX_ENV=test mix compile --warnings-as-errors --force
mix coveralls.html
rm -f *.coverdata

clear
echo "######### farmbot_ext"
cd ../farmbot_ext
mix format
mix deps.get --all
MIX_ENV=test mix compile --warnings-as-errors --force
mix coveralls.html
rm -f *.coverdata

clear
echo "######### farmbot_os"
cd ../farmbot_os
mix format
mix deps.get --all
MIX_ENV=test mix compile --warnings-as-errors --force
mix coveralls.html
rm -f *.coverdata

cd ..
cd farmbot_os

clear
echo "######### Build RPI3 FW"

MIX_TARGET=rpi3 MIX_ENV=prod mix deps.get
MIX_TARGET=rpi3 MIX_ENV=prod mix compile --warnings-as-errors --force
MIX_TARGET=rpi3 MIX_ENV=prod mix firmware

clear
echo "######### Build RPI0 FW"
MIX_TARGET=rpi MIX_ENV=prod mix deps.get
MIX_TARGET=rpi MIX_ENV=prod mix compile --warnings-as-errors --force
MIX_TARGET=rpi MIX_ENV=prod mix firmware
