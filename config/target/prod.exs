use Mix.Config
import_config("dev.exs")

config :nerves_firmware_ssh,
  authorized_keys: []

config :bootloader,
  init: [:nerves_runtime],
  app: :farmbot
