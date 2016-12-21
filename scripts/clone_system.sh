#!/bin/bash
# sets up the environment for building the linux part of Farmbot.

CWD=$PWD # this should be from the root of the project
APPS_DIR=$CWD/apps
TARGET_DIR=$APPS_DIR/nerves_system_$NERVES_TARGET
BR_DIR=$CWD/deps/nerves_system_br

$BR_DIR/create-build.sh $TARGET_DIR/nerves_defconfig  $APPS_DIR/NERVES_SYSTEM_$NERVES_TARGET
exit 0
