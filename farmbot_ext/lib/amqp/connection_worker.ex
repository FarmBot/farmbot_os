defmodule Farmbot.AMQP.ConnectionWorker do
  use GenServer
  alias Farmbot.JWT
  require Farmbot.Logger
  require Logger

  defstruct [:opts, :conn]

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def connection do
    GenServer.call(__MODULE__, :connection)
  end

  def init(opts) do
    Process.flag(:sensitive, true)
    Process.flag(:trap_exit, true)
    {:ok, %__MODULE__{conn: nil, opts: opts}, 0}
  end

  def terminate(reason, %{conn: nil}) do
    Logger.info("AMQP connection not open: #{inspect(reason)}")
  end

  def terminate(reason, %{conn: conn}) do
    if Process.alive?(conn.pid) do
      try do
        Logger.info("Closing AMQP connection: #{inspect(reason)}")
        :ok = AMQP.Connection.close(conn)
      rescue
        ex ->
          message = Exception.message(ex)
          Logger.error("Could not close AMQP connection: #{message}")
      end
    end
  end

  def handle_info(:timeout, state) do
    token = Keyword.fetch!(state.opts, :token)
    email = Keyword.fetch!(state.opts, :email)
    jwt = JWT.decode!(token)

    case open_connection(token, email, jwt.bot, jwt.mqtt, jwt.vhost) do
      {:ok, conn} ->
        Process.link(conn.pid)
        Process.monitor(conn.pid)
        {:noreply, %{state | conn: conn}}

      err ->
        Logger.error("Error connecting to AMPQ: #{inspect(err)}")
        {:noreply, %{state | conn: nil}, 5000}
    end
  end

  def handle_info({:DOWN, _, :process, _pid, reason}, conn) do
    Logger.error("Connection crash: #{inspect(reason)}")
    {:stop, reason, conn}
  end

  def handle_call(:connection, _, %{conn: conn} = state), do: {:reply, conn, state}

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

    AMQP.Connection.open(opts)
  end
end
