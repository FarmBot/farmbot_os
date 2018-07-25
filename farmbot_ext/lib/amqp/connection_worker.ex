defmodule Farmbot.AMQP.ConnectionWorker do
  use GenServer
  require Farmbot.Logger
  import Farmbot.Config, only: [update_config_value: 4]

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [name: __MODULE__])
  end

  def connection do
    GenServer.call(__MODULE__, :connection)
  end

  def init([token]) do
    Process.flag(:sensitive, true)
    jwt = Farmbot.Jwt.decode!(token)
    {:ok, conn} = open_connection(token, jwt.bot, jwt.mqtt, jwt.vhost)
    Process.monitor(conn.pid)
    {:ok, conn}
  end

  def handle_info({:DOWN, _, :process, _pid, reason}, conn) do
    ok_reasons = [:normal, :shutdown, :token_refresh]
    update_config_value(:bool, "settings", "ignore_fbos_config", false)

    if reason not in ok_reasons do
      Farmbot.Logger.error 1, "AMQP Connection closed: #{inspect reason}"
      update_config_value(:bool, "settings", "log_amqp_connected", true)
    end
    {:stop, reason, conn}
  end

  def handle_call(:connection, _, conn), do: {:reply, conn, conn}

  defp open_connection(token, bot, mqtt_server, vhost) do
    opts = [
      host: mqtt_server,
      username: bot,
      password: token,
      virtual_host: vhost]
    AMQP.Connection.open(opts)
  end
end
