use Mix.Config
config :nerves, :firmware,
  rootfs_additions: "config/rootfs-additions-#{Mix.Project.config[:target]}",
  hardware: "config/rootfs-additions-#{Mix.Project.config[:target]}"

config :uart,
  baud: 115200

config :fb,
  ro_path: "/root",
  factory_reset_pin: 21,
  os_update_server: System.get_env("OS_UPDATE_SERVER") || "https://api.github.com/repos/farmbot/farmbot_os/releases/latest",
  fw_update_server: System.get_env("FW_UPDATE_SERVER") || "https://api.github.com/repos/FarmBot/farmbot-arduino-firmware/releases/latest"

config :json_rpc,
    transport: MqttHandler

config :logger, :console,
  format: "$metadata[$level] $levelpad$message\n",
  colors: [enabled: true ]
config :Logger,
  handle_sasl_reports: true,
  handle_otp_reports: true

config :iex, :colors,
  enabled: true

config :iex,
  # alive_prompt: "%prefix(%node)%counter>"
  alive_prompt: [
    "\e[G",    # ANSI CHA, move cursor to column 1
    :magenta,
    "%node",
    ">",
    :reset ] |> IO.ANSI.format |> IO.chardata_to_string
