use Mix.Config
data_path = Path.join("/", "root")
local_file = Path.join(System.user_home!(), ".ssh/id_rsa.pub")

local_key = if File.exists?(local_file), do: [File.read!(local_file)], else: []

config :logger, backends: [RingLogger]
config :logger, RingLogger, max_size: 1024, color: [enabled: true]

config :mdns_lite,
  mdns_config: %{host: :hostname, ttl: 120},
  services: [
    %{name: "Configurator", protocol: "http", transport: "tcp", port: 80},
    %{name: "Secure Socket", protocol: "ssh", transport: "tcp", port: 22}
  ]

config :nerves_firmware_ssh, authorized_keys: local_key

config :shoehorn,
  init: [:nerves_runtime, :vintage_net, :nerves_firmware_ssh],
  handler: FarmbotOS.Platform.Target.ShoehornHandler,
  app: :farmbot

config :tzdata, :autoupdate, :disabled

config :vintage_net,
  regulatory_domain: "00",
  persistence: VintageNet.Persistence.Null,
  config: [{"wlan0", %{type: VintageNet.Technology.Null}}]

%{
  FarmbotCore.Asset.Repo => [database: "/root/database.#{Mix.env()}.db"],
  FarmbotCore.AssetWorker.FarmbotCore.Asset.PinBinding => [
    gpio_handler: FarmbotOS.Platform.Target.PinBindingWorker.CircuitsGPIOHandler
  ],
  FarmbotCore.AssetWorker.FarmbotCore.Asset.PublicKey => [
    ssh_handler: FarmbotOS.Platform.Target.SSHConsole
  ],
  FarmbotCore.Leds => [
    gpio_handler: FarmbotOS.Platform.Target.Leds.CircuitsHandler
  ],
  FarmbotOS.Configurator => [
    network_layer: FarmbotOS.Platform.Target.Configurator.VintageNetworkLayer
  ],
  FarmbotOS.FileSystem => [data_path: data_path],
  FarmbotOS.Init.Supervisor => [
    init_children: [FarmbotOS.Platform.Target.RTCWorker]
  ],
  FarmbotOS.Platform.Supervisor => [
    platform_children: [
      FarmbotOS.Platform.Target.Network.Supervisor,
      FarmbotOS.Platform.Target.SSHConsole,
      FarmbotOS.Platform.Target.InfoWorker.Supervisor
    ]
  ],
  FarmbotOS.System => [system_tasks: FarmbotOS.Platform.Target.SystemTasks]
}
|> Enum.map(fn {m, c} -> config :farmbot, m, c end)
