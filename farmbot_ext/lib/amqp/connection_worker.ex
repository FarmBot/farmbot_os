defmodule Farmbot.AMQP.ConnectionWorker do
  use GenServer
  alias Farmbot.JWT
  require Farmbot.Logger
  require Logger
  import Farmbot.Config, only: [update_config_value: 4]

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def connection do
    GenServer.call(__MODULE__, :connection)
  end

  def init(opts) do
    token = Keyword.fetch!(opts, :token)
    email = Keyword.fetch!(opts, :email)
    Process.flag(:sensitive, true)
    Process.flag(:trap_exit, true)
    jwt = JWT.decode!(token)
    IO.puts "OPEN"
    {:ok, conn} = open_connection(token, email, jwt.bot, jwt.mqtt, jwt.vhost)
    IO.puts "OPENED"
    Process.link(conn.pid)
    Process.monitor(conn.pid)
    {:ok, conn}
  end

  def terminate(_, conn) do
    if Process.alive?(conn.pid) do
      try do
        Logger.info("Closing AMQP connection.")
        :ok = AMQP.Connection.close(conn)
      rescue
        ex ->
          message = Exception.message(ex)
          Logger.error("Could not close AMQP connection: #{message}")
      end
    end
  end

  def handle_info({:DOWN, _, :process, _pid, reason}, conn) do
    ok_reasons = [:normal, :shutdown, :token_refresh]
    update_config_value(:bool, "settings", "ignore_fbos_config", false)

    if reason not in ok_reasons do
      Farmbot.Logger.error(1, "AMQP Connection closed: #{inspect(reason)}")
      update_config_value(:bool, "settings", "log_amqp_connected", true)
    end

    {:stop, reason, conn}
  end

  def handle_call(:connection, _, conn), do: {:reply, conn, conn}

  defp open_connection(token, email, bot, mqtt_server, vhost) do
    Logger.info("Opening new AMQP connection.")
    opts = [
      client_properties: [
        {"version", :longstr, Farmbot.Project.version()},
        {"commit", :longstr, Farmbot.Project.commit()},
        {"target", :longstr, Farmbot.Project.target()},
        {"opened", :longstr, to_string(DateTime.utc_now())},
        {"product", :longstr, "farmbot_os"},
        {"bot", :longstr, bot},
        {"email", :longstr, email},
        {"node", :longstr, to_string(node())}
      ],
      host: mqtt_server,
      username: bot,
      password: token,
      virtual_host: vhost
    ]

    case AMQP.Connection.open(opts) do
      {:ok, conn} ->
        {:ok, conn}

      {:error, reason} ->
        Logger.error("Error connecting to AMPQ: #{inspect(reason)}")
        Process.sleep(5000)
        open_connection(token, email, bot, mqtt_server, vhost)
    end
  end
end
