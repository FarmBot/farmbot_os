#!/bin/bash
SYSTEM=$1
NERVES_SYSTEM_BR_GIT="https://github.com/nerves-project/nerves_system_br"

if [ -d "nerves/NERVES_SYSTEM_$SYSTEM" ]; then
  # Control will enter here if $DIRECTORY exists.
  echo "NERVES_SYSTEM_$SYSTEM dir found."
else
  echo "NERVES_SYSTEM_$SYSTEM dir not found."
  git clone $NERVES_SYSTEM_BR_GIT nerves/nerves_system_br
fi

cp buildroot_patches/*.patch nerves/nerves_system_br/patches
nerves/nerves_system_br/create-build.sh nerves/nerves_system_$SYSTEM/nerves_defconfig nerves/NERVES_SYSTEM_$SYSTEM
