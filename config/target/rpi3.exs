use Mix.Config

# We need a special fwup conf for the initial v6 release.
# TODO Remove this some day.
config :nerves, :firmware, fwup_conf: "fwup_interim.conf"

config :nerves_leds, names: [ status: "led0" ]
config :farmbot, :gpio, status_led_on: false
config :farmbot, :gpio, status_led_off: true

config :bootloader,
  init: [:nerves_runtime, :nerves_firmware_ssh],
  app: :farmbot
