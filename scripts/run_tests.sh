#!/bin/bash
export MIX_ENV=test
mix deps.get
mix all_test
