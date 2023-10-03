defmodule FarmbotOS.MQTT.Supervisor do
  @moduledoc """
  Supervises the MQTT handler.
  """
  use Supervisor
  alias FarmbotOS.Config
  alias FarmbotOS.Project
  alias FarmbotOS.JWT
  @wss "wss:"

  def start_link(_, opts \\ [name: __MODULE__]) do
    Supervisor.start_link(__MODULE__, [], opts)
  end

  def init([]) do
    Supervisor.init(children(), strategy: :one_for_all)
  end

  def children do
    token = Config.get_config_value(:string, "authorization", "token")
    config = Application.get_env(:farmbot, __MODULE__) || []

    Keyword.get(config, :children, [mqtt_child(token)])
  end

  def mqtt_child(raw_token) do
    token = JWT.decode!(raw_token)
    host = token.mqtt
    username = token.bot
    # EXPERIMENT: Can't isolate cause of MQTT blinking.
    # I am suspicious that it is caused by non-deterministic
    # mqtt client_id. Temporarily making client_id generation
    # deterministic. RC 1 DEC 21.
    # jitter = String.slice(UUID.uuid4(:hex), 0..7)
    # _#{jitter}"
    client_id = "#{token.bot}_#{Project.version()}"

    server =
      if String.starts_with?(token.mqtt_ws || "", @wss) do
        {Tortoise311.Transport.SSL,
         server_name_indication: :disable,
         cacertfile: :certifi.cacertfile(),
         host: host,
         port: 8883}
      else
        {Tortoise311.Transport.Tcp, host: host, port: 1883}
      end

    opts = [
      client_id: client_id,
      user_name: username,
      password: raw_token,
      server: server,
      handler: {FarmbotOS.MQTT, [client_id: client_id, username: username]},
      # Tortoise will double the min_interval on every attempt.
      backoff: [min_interval: 7_500, max_interval: 120_000],
      subscriptions: [
        {"bot/#{username}/from_clients", 0},
        {"bot/#{username}/ping/#", 0},
        {"bot/#{username}/sync/#", 0},
        {"bot/#{username}/terminal_input", 0}
      ]
    ]

    {Tortoise311.Connection, opts}
  end
end
