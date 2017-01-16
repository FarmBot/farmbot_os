#!/bin/bash
SYSTEM=$1
export MIX_ENV=prod
export NERVES_TARGET=$SYSTEM
echo "building system on $SYSTEM"
cd apps/farmbot
mix deps.get
mix firmware
