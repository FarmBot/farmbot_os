defmodule FarmbotExt.MQTT.Supervisor do
  @moduledoc """
  Supervises the MQTT handler.
  """
  # use Supervisor
  use GenServer
  alias FarmbotCore.Config
  alias FarmbotCore.Project
  alias FarmbotExt.JWT
  @wss "wss:"

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_) do
    Process.send_after(self(), :experiment, 1000 * 60 * 3)
    {:ok, %{not_ready: true}}
  end

  def handle_info(:experiment, _state) do
    args = [strategy: :one_for_one]
    {:ok, pid} = Supervisor.start_link(children(), args)
    {:noreply, %{child: pid}}
  end

  def children do
    token = Config.get_config_value(:string, "authorization", "token")
    config = Application.get_env(:farmbot_ext, __MODULE__) || []

    Keyword.get(config, :children, [mqtt_child(token)])
  end

  def mqtt_child(raw_token) do
    token = JWT.decode!(raw_token)
    host = token.mqtt
    username = token.bot
    jitter = String.slice(UUID.uuid4(:hex), 0..7)
    client_id = "#{token.bot}_#{Project.version()}_#{jitter}"

    server =
      if String.starts_with?(token.mqtt_ws || "", @wss) do
        {Tortoise.Transport.SSL,
         server_name_indication: :disable,
         cacertfile: :certifi.cacertfile(),
         host: host,
         port: 8883}
      else
        {Tortoise.Transport.Tcp, host: host, port: 1883}
      end

    opts = [
      client_id: client_id,
      user_name: username,
      password: raw_token,
      server: server,
      handler: {FarmbotExt.MQTT, [client_id: client_id, username: username]},
      # Tortoise will double the min_interval on every attempt.
      backoff: [min_interval: 7_500, max_interval: 120_000],
      subscriptions: [
        {"bot/#{username}/from_clients", 0},
        {"bot/#{username}/ping/#", 0},
        {"bot/#{username}/sync/#", 0},
        {"bot/#{username}/terminal_input", 0}
      ]
    ]

    {Tortoise.Connection, opts}
  end
end
