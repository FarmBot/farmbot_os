#!/bin/bash
SYSTEM=$1
echo "building system on $SYSTEM"
cd apps/NERVES_SYSTEM_$SYSTEM
make
make system
