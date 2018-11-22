#!/bin/bash
TARGETS="rpi0 \
rpi3 \
host
"
for target in $TARGETS; do
  MIX_TARGET=$target mix do deps.get, deps.compile
done
