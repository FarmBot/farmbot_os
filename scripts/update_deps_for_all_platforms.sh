#!/bin/bash
PROJECTS="farmbot_celery_script \
farmbot_core \
farmbot_ext \
farmbot_firmware \
farmbot_os
"

for project in $PROJECTS; do
  cd $project && mix deps.get && cd ..
done