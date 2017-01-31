#!/bin/bash
SYSTEM=$1
echo "building system for $SYSTEM"
cd apps/NERVES_SYSTEM_$SYSTEM
make
make system
