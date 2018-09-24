use Mix.Config

config :nerves_hub,
  client: Farmbot.System.NervesHubClient,
  ca_certs: "/etc/ssl_dev",
  public_keys: [File.read!("priv/staging.pub"), File.read!("priv/prod.pub")]

config :nerves_hub, NervesHub.Socket,
  url: "wss://device.nerves-hub.org:4001/socket/websocket"

config :nerves_hub, NervesHub.Socket, [
  reconnect_interval: 5_000,
]

config :nerves_hub, NervesHub.HTTPClient, [
  host: "device.nerves-hub.org",
  port: 4001
]

config :nerves_hub_cli, NervesHubCLI.API,
  host: "api.nerves-hub.org",
  port: 4002

config :nerves_hub_cli,
  home: Path.expand(".nerves-hub/test-setup"),
  ca_certs: Path.expand("test/fixtures/ca_certs")
