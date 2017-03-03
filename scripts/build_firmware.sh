#!/bin/bash
SYSTEM=$1
export MIX_ENV=prod
export MIX_TARGET=$SYSTEM
echo "building firmware for $SYSTEM"
npm install
npm run build
mix deps.get
mix firmware
