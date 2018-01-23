use Mix.Config

config :nerves_leds, names: [ status: "led0" ]
config :farmbot, :gpio, status_led_on: false
config :farmbot, :gpio, status_led_off: true

config :farmbot, :captive_portal_address, "192.168.24.1"

config :bootloader,
  init: [:nerves_runtime, :nerves_firmware_ssh],
  app: :farmbot

  config :farmbot, kernel_modules: ["snd-bcm2835"]
