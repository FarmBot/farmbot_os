use Mix.Config
config :nerves, :firmware,
  rootfs_additions: "config/rootfs-additions-#{Mix.Project.config[:target]}",
  hardware: "config/rootfs-additions-#{Mix.Project.config[:target]}"

config :farmbot,
  state_path: "/state"

config :farmbot_networking,
  dnsmasq_path: "/root/dnsmasq.lease"

config :logger, :console,
  # format: "$metadata[$level] $levelpad$message\r\n",
  colors: [enabled: true ]

config :logger,
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
