#!/bin/bash

set -e
set -o pipefail

export MIX_ENV=test

echo "######### Fetch Deps"
mix deps.get --all
mix format
MIX_ENV=test mix compile --force

echo "######### Run Tests"
mix coveralls.html
rm -f *.coverdata

echo "######### Build RPI4 FW"

MIX_TARGET=rpi4 MIX_ENV=prod mix deps.get
MIX_TARGET=rpi4 MIX_ENV=prod mix compile --force
MIX_TARGET=rpi4 MIX_ENV=prod mix firmware

echo "######### Build RPI3 FW"

MIX_TARGET=rpi3 MIX_ENV=prod mix deps.get
MIX_TARGET=rpi3 MIX_ENV=prod mix compile --force
MIX_TARGET=rpi3 MIX_ENV=prod mix firmware

echo "######### Build RPI0 FW"
MIX_TARGET=rpi MIX_ENV=prod mix deps.get
MIX_TARGET=rpi MIX_ENV=prod mix compile --force
MIX_TARGET=rpi MIX_ENV=prod mix firmware
