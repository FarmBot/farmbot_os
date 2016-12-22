#!/bin/bash
# yes. This is in fact a bash script that gets called
# from a mix task, that then in a wild chain of events, executes more mix tasks.
# don'nt you worry about a thing.
CWD=$PWD # this should be from the root of the project
OS_DIR=$CWD/apps/farmbot
CONFIGURATOR_DIR=$CWD/apps/farmbot_configurator

cd $CONFIGURATOR_DIR
if [ ! -d "node_modules" ]; then
  echo "need to get configurator deps!"
  npm install
  if [ $? != 0 ]; then
    echo "error building bundle"
    exit $?
  fi
fi

npm run build

if [ $? != 0 ]; then
  echo "error building bundle"
  exit $?
fi

cd $OS_DIR

if [ ! -d "deps" ]; then
  echo "need to get os deps!"
  mix deps.get
fi
mix firmware
exit $?
