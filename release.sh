#!/bin/bash
source .env
rm -rf artifacts deps _build RELEASE_NOTES
grep -Pazo "(?s)(?<=# $(cat VERSION))[^#]+" CHANGELOG.md > RELEASE_NOTES
mkdir artifacts
export MIX_ENV=prod
export MIX_TARGET=rpi3
mix deps.get
mix firmware
mix firmware.image artifacts/farmbot-${MIX_TARGET}-$(cat VERSION).img
fwup -S -s $NERVES_FW_PRIV_KEY -i _build/${MIX_TARGET}/${MIX_ENV}/nerves/images/farmbot.fw -o artifacts/farmbot-${MIX_TARGET}-$(cat VERSION).fw
ghr -t $GITHUB_TOKEN -u farmbot -r farmbot_os -recreate -prerelease -b "$(cat RELEASE_NOTES)" -c $(git rev-parse --verify HEAD) "v$(cat VERSION)" $PWD/artifacts
