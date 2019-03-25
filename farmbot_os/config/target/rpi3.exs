use Mix.Config
config :farmbot, :captive_portal_address, "192.168.24.1"

config :farmbot, FarmbotOS.FirmwareTTYDetector, expected_names: ["ttyUSB0", "ttyACM0"]
