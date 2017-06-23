#!/bin/bash
SYSTEM=$1
echo "building system for $SYSTEM"
cd nerves/NERVES_SYSTEM_$SYSTEM
time make
make system
