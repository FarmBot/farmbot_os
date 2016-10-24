use Mix.Config
config :nerves, :firmware,
  rootfs_additions: "config/rootfs-additions-#{Mix.Project.config[:target]}",
  hardware: "config/rootfs-additions-#{Mix.Project.config[:target]}"

config :uart,
  baud: 115200

config :fb,
  ro_path: "/root",
  bot_state_save_file: "/root/botstatus.txt",
  factory_reset_pin: 21

config :json_rpc,
    transport: MqttHandler

config :logger, :console,
  # format: "$metadata[$level] $levelpad$message\r\n",
  colors: [enabled: true ]
config :Logger,
  handle_sasl_reports: true,
  handle_otp_reports: true

config :iex, :colors,
  enabled: true

config :iex,
  # alive_prompt: "\n %prefix(%node)%counter>"
  alive_prompt: [
    "\e[G",    # ANSI CHA, move cursor to column 1
    :magenta,
    "%node",
    ">",
    :reset ] |> IO.ANSI.format |> IO.chardata_to_string

config :blinky, led_list: [ :green ]
config :nerves_leds, names: [ green: "led0" ]
