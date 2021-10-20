use Mix.Config
local_file = Path.join(System.user_home!(), ".ssh/id_rsa.pub")
local_key = if File.exists?(local_file), do: [File.read!(local_file)], else: []
data_path = Path.join("/", "root")

config :nerves_firmware_ssh,
  authorized_keys: local_key

config :vintage_net,
  regulatory_domain: "00",
  persistence: VintageNet.Persistence.Null,
  config: [{"wlan0", %{type: VintageNet.Technology.Null}}]

config :mdns_lite,
  mdns_config: %{
    host: :hostname,
    ttl: 120
  },
  services: [
    # service type: _http._tcp.local - used in match
    %{
      name: "Web Server",
      protocol: "http",
      transport: "tcp",
      port: 80
    },
    # service_type: _ssh._tcp.local - used in match
    %{
      name: "Secure Socket",
      protocol: "ssh",
      transport: "tcp",
      port: 22
    }
  ]

config :shoehorn,
  init: [
    :nerves_runtime,
    :vintage_net,
    :nerves_firmware_ssh
  ],
  handler: FarmbotOS.Platform.Target.ShoehornHandler,
  app: :farmbot

config :tzdata, :autoupdate, :disabled

config :farmbot, FarmbotCore.AssetWorker.FarmbotCore.Asset.PublicKey,
  ssh_handler: FarmbotOS.Platform.Target.SSHConsole

config :farmbot, FarmbotCore.AssetWorker.FarmbotCore.Asset.PinBinding,
  gpio_handler: FarmbotOS.Platform.Target.PinBindingWorker.CircuitsGPIOHandler

config :farmbot, FarmbotCore.Leds,
  gpio_handler: FarmbotOS.Platform.Target.Leds.CircuitsHandler

config :farmbot, FarmbotOS.FileSystem, data_path: data_path

config :farmbot, FarmbotOS.Platform.Supervisor,
  platform_children: [
    FarmbotOS.Platform.Target.Network.Supervisor,
    FarmbotOS.Platform.Target.SSHConsole,
    FarmbotOS.Platform.Target.InfoWorker.Supervisor
  ]

config :farmbot, FarmbotOS.Configurator,
  network_layer: FarmbotOS.Platform.Target.Configurator.VintageNetworkLayer

config :farmbot, FarmbotOS.System,
  system_tasks: FarmbotOS.Platform.Target.SystemTasks

config :logger, backends: [RingLogger]
config :logger, RingLogger, max_size: 1024, color: [enabled: true]
