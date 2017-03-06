#!/bin/bash
export MIX_ENV=test
mix deps.get
mix travis_test || { echo 'Tests failed!' ; exit 1; }
if [[ "$`TRAVIS_BRANCH`" == "staging" ]]; then
  make release
fi
