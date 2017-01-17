#!/bin/bash
SYSTEM=$1
NERVES_SYSTEM_BR_GIT="https://github.com/nerves-project/nerves_system_br"

if [ -d "apps/NERVES_SYSTEM_$SYSTEM" ]; then
  # Control will enter here if $DIRECTORY exists.
  echo "NERVES_SYSTEM_$SYSTEM dir found."
else
  echo "NERVES_SYSTEM_$SYSTEM dir not found."
  git clone $NERVES_SYSTEM_BR_GIT apps/nerves_system_br
fi

apps/nerves_system_br/create-build.sh apps/nerves_system_$SYSTEM/nerves_defconfig apps/NERVES_SYSTEM_$SYSTEM
