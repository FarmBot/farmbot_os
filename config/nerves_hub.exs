use Mix.Config

config :nerves_hub,
  client: Farmbot.System.NervesHubClient,
  public_keys: [File.read!("priv/staging.pub"), File.read!("priv/prod.pub")]

config :nerves_hub, NervesHub.Socket, [
  reconnect_interval: 5_000,
]
