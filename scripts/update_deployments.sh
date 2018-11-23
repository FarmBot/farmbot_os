#!/bin/bash

mix nerves_hub.deployment update $1-prod-stable firmware $2
mix nerves_hub.deployment update $1-prod-beta firmware $2
mix nerves_hub.deployment update $1-prod-staging firmware $2
mix nerves_hub.deployment update $1-prod-next firmware $2
