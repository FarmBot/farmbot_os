use Mix.Config

config :farmbot, Farmbot.TTYDetector, expected_names: ["ttyUSB0", "ttyACM0", "ttyS0"]
