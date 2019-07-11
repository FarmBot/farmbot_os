defmodule FarmbotExt.AMQP.ConnectionWorker do
  @moduledoc """
  Manages the AMQP socket lifecycle.
  """

  use GenServer
  require Logger
  require FarmbotCore.Logger
  alias AMQP.{Basic, Channel, Queue}

  alias FarmbotExt.{JWT, AMQP.ConnectionWorker}
  alias FarmbotCore.{Project, JSON}

  @exchange "amq.topic"

  @type connection :: map()
  @type channel :: map()

  defstruct [:opts, :conn]

  @doc "Get the current active connection"
  @callback connection(GenServer.server()) :: connection()
  def connection(connection_worker \\ __MODULE__) do
    GenServer.call(connection_worker, :connection)
  end

  def close(connection_worker \\ __MODULE__) do
    GenServer.call(connection_worker, :close)
  end

  @doc "Cleanly close an AMQP channel"
  @callback close_channel(channel) :: nil
  def close_channel(chan) do
    Channel.close(chan)
  end

  @doc "Uses JWT 'bot' claim and connects to the AMQP broker / autosync channel"
  @callback maybe_connect_autosync(String.t()) :: map()
  def maybe_connect_autosync(jwt_dot_bot) do
    auto_delete = false
    chan_name = jwt_dot_bot <> "_auto_sync"
    purge? = false
    route = "bot.#{jwt_dot_bot}.sync.#"

    maybe_connect(chan_name, route, auto_delete, purge?)
  end

  @doc "Takes the 'bot' claim seen in the JWT and connects to the RPC server."
  @callback maybe_connect_celeryscript(String.t()) :: map()
  def maybe_connect_celeryscript(jwt_dot_bot) do
    auto_delete = true
    chan_name = jwt_dot_bot <> "_from_clients"
    purge? = true
    route = "bot.#{jwt_dot_bot}.from_clients"

    maybe_connect(chan_name, route, auto_delete, purge?)
  end

  defp maybe_connect(chan_name, route, auto_delete, purge?) do
    with %{} = conn <- FarmbotExt.AMQP.ConnectionWorker.connection(),
         {:ok, chan} <- Channel.open(conn),
         :ok <- Basic.qos(chan, global: true),
         {:ok, _} <- Queue.declare(chan, chan_name, auto_delete: auto_delete),
         {:ok, _} <- maybe_purge(chan, chan_name, purge?),
         :ok <- Queue.bind(chan, chan_name, @exchange, routing_key: route),
         {:ok, _} <- Basic.consume(chan, chan_name, self(), no_ack: true) do
      %{conn: conn, chan: chan}
    else
      nil -> %{conn: nil, chan: nil}
      error -> error
    end
  end

  defp maybe_purge(chan, chan_name, purge?) do
    if purge? do
      Queue.purge(chan, chan_name)
    else
      {:ok, :skipped}
    end
  end

  @doc "Respond with an OK message to a CeleryScript(TM) RPC message."
  @callback rpc_reply(map(), String.t(), String.t()) :: :ok
  def rpc_reply(chan, jwt_dot_bot, label) do
    json = JSON.encode!(%{args: %{label: label}, kind: "rpc_ok"})
    Basic.publish(chan, @exchange, "bot.#{jwt_dot_bot}.from_device", json)
  end

  @doc false
  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  @impl GenServer
  def init(opts) do
    Process.flag(:sensitive, true)
    Process.flag(:trap_exit, true)
    {:ok, %ConnectionWorker{conn: nil, opts: opts}, 0}
  end

  @impl GenServer
  def terminate(reason, %{conn: nil}) do
    Logger.info("AMQP connection not open: #{inspect(reason)}")
  end

  @impl GenServer
  def terminate(_reason, %{conn: conn}) do
    close_connection(conn)
  end

  @impl GenServer
  def handle_info(:timeout, state) do
    token = Keyword.fetch!(state.opts, :token)
    email = Keyword.fetch!(state.opts, :email)
    jwt = JWT.decode!(token)

    case open_connection(token, email, jwt.bot, jwt.mqtt, jwt.vhost) do
      {:ok, conn} ->
        Process.monitor(conn.pid)
        {:noreply, %{state | conn: conn}}

      err ->
        Logger.error("Error connecting to AMPQ: #{inspect(err)}")
        Process.send_after(self(), :timeout, 5000)
        {:noreply, %{state | conn: nil}}
    end
  end

  def handle_info({:DOWN, _ref, :process, _pid, reason}, state) do
    FarmbotCore.Logger.error(2, "AMQP Connection exit")
    _ = close_connection(state.conn)
    {:stop, reason, state}
  end

  @impl GenServer
  def handle_call(:connection, _, %{conn: conn} = state) do
    {:reply, conn, state}
  end

  def handle_call(:close, _from, %{conn: _conn} = state) do
    FarmbotCore.Logger.error(2, "AMQP Connection closing")
    reply = close_connection(state.conn)
    {:stop, :close, reply, %{state | conn: nil}}
  end

  # Public function because the NervesHub channel requires it.
  # TODO(Connor) - Fix that
  @doc false
  def open_connection(token, email, bot, mqtt_server, vhost) do
    Logger.info("Opening new AMQP connection.")

    # Make sure the types of these fields are correct. If they are not
    # you timeouts will happen.
    # Specifically if anything is `nil` or _any_ other atom, encoded as
    # a `:longstr` or `:shortstr` they will _NOT_ be `to_string/1`ified.
    opts = [
      client_properties: [
        {"version", :longstr, Project.version()},
        {"commit", :longstr, Project.commit()},
        {"target", :longstr, to_string(Project.target())},
        {"opened", :longstr, to_string(DateTime.utc_now())},
        {"product", :longstr, "farmbot_os"},
        {"bot", :longstr, bot},
        {"email", :longstr, email},
        {"node", :longstr, to_string(node())}
      ],
      host: mqtt_server,
      username: bot,
      password: token,
      virtual_host: vhost,
      connection_timeout: 10_000
    ]

    AMQP.Connection.open(opts)
  end

  defp close_connection(nil), do: :ok

  defp close_connection(%{pid: pid}) do
    if Process.alive?(pid) do
      try do
        Process.exit(pid, :close)
        :ok
        # :ok = AMQP.Connection.close(conn)
      rescue
        ex ->
          message = Exception.message(ex)
          Logger.error("Could not close AMQP connection: #{message}")
          :ok
      end
    end
  end
end
