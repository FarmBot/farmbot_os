#!/bin/bash
SYSTEM=$1
export MIX_ENV=prod
export MIX_TARGET=$SYSTEM
echo "building firmware for $SYSTEM"
cd apps/farmbot
npm install
mix deps.get
mix firmware
