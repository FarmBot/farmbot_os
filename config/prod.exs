use Mix.Config
config :nerves, :firmware,
  rootfs_additions: "config/rootfs-additions-#{Mix.Project.config[:target]}",
  hardware: "config/rootfs-additions-#{Mix.Project.config[:target]}"

config :uart,
  baud: 115200

config :fb,
  ro_path: "/root",
  update_server: "https://api.github.com/repos/farmbot/farmbot-raspberry-pi-controller/releases/latest"

config :json_rpc,
    transport: MqttHandler
