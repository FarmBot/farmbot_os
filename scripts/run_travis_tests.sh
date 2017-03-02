#!/bin/bash
export MIX_ENV=test
mix deps.get
mix travis_test
