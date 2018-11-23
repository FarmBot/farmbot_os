#!/bin/bash
PROJECTS="farmbot_celery_script \
farmbot_firmware \
farmbot_core \
farmbot_ext \
farmbot_os
"
TARGETS="rpi \
rpi0 \
rpi3 \
host
"
for project in $PROJECTS; do
  cd $project && mix deps.get && cd ..
done

for target in $TARGETS; do
  cd farmbot_os && MIX_TARGET=$target mix deps.get && cd ..
done
