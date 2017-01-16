#!/bin/bash
cd apps/farmbot
export MIX_ENV=test
mix deps.get
mix test
