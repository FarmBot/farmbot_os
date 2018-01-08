use Mix.Config

config :nerves_leds, names: [ status: "led0" ]
config :farmbot, :gpio, status_led_on: false
config :farmbot, :gpio, status_led_off: true

config :farmbot, kernel_modules: ["snd-bcm2835"]
