defmodule FarmbotExt.AMQP.TerminalChannel do
  use GenServer
  use AMQP
  require Logger
  require FarmbotTelemetry
  require FarmbotCore.Logger
  alias FarmbotExt.AMQP.ConnectionWorker
  @exchange "amq.topic"
  # 5 minutes
  @iex_timeout 300 * 1000

  defstruct [:conn, :chan, :jwt, :iex_pid]
  alias __MODULE__, as: State

  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(args) do
    send(self(), :connect_amqp)

    state = %State{
      chan: nil,
      conn: nil,
      iex_pid: nil,
      jwt: Keyword.fetch!(args, :jwt)
    }

    {:ok, state}
  end

  def handle_info(:connect_amqp, state) do
    bot = state.jwt.bot
    name = bot <> "_terminal"

    with %{} = conn <- ConnectionWorker.connection(),
         {:ok, %{pid: channel_pid} = chan} <- Channel.open(conn),
         Process.link(channel_pid),
         :ok <- Basic.qos(chan, global: true),
         {:ok, _} <- Queue.declare(chan, name, auto_delete: true),
         {:ok, _} <- Queue.purge(chan, name),
         :ok <-
           Queue.bind(chan, name, @exchange, routing_key: "bot.#{bot}.terminal_input"),
         {:ok, _tag} <- Basic.consume(chan, name, self(), no_ack: true) do
      FarmbotCore.Logger.debug(3, "connected to Terminal channel")
      {:noreply, %{state | conn: conn, chan: chan}}
    else
      nil ->
        Process.send_after(self(), :connect_amqp, 5000)
        {:noreply, %{state | conn: nil, chan: nil}}

      err ->
        FarmbotCore.Logger.error(1, "Failed to connect to Terminal channel: #{inspect(err)}")
        Process.send_after(self(), :connect_amqp, 3000)
        {:noreply, %{state | conn: nil, chan: nil}}
    end
  end

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:basic_consume_ok, _}, state) do
    {:noreply, state}
  end

  # Sent by the broker when the consumer is
  # unexpectedly cancelled (such as after a queue deletion)
  def handle_info({:basic_cancel, _}, state) do
    {:stop, :normal, state}
  end

  # Confirmation sent by the broker to the consumer process after a Basic.cancel
  def handle_info({:basic_cancel_ok, _}, state) do
    {:noreply, state}
  end

  # INCOMING MESSAGE: We must lazily instantiate an IEX session
  def handle_info({:basic_deliver, _payl, %{routing_key: _}}, %{iex_pid: nil} = state) do
    tty_send(state, "Starting IEx...")
    {:noreply, start_iex(state)}
  end

  # INCOMING MESSAGE: IEx already running.
  def handle_info({:basic_deliver, payload, %{routing_key: _}}, state) do
    IO.puts("Sending " <> inspect(payload))
    ExTTY.send_text(state.iex_pid, payload)
    {:noreply, state, @iex_timeout}
  end

  def handle_info({:tty_data, data}, state) do
    tty_send(state, data)
    {:noreply, state, @iex_timeout}
  end

  def handle_info(:timeout, state) do
    tty_send(state, "=== Session timeout due to inactivity ===")

    {:noreply, stop_iex(state)}
  end

  def handle_info(req, state) do
    tty_send(state, "Can't hande this info - #{inspect(req)}")
    {:noreply, state}
  end

  defp start_iex(state) do
    shell_opts = [
      [
        dot_iex_path:
          [".iex.exs", "~/.iex.exs", "/etc/iex.exs"]
          |> Enum.map(&Path.expand/1)
          |> Enum.find("", &File.regular?/1)
      ]
    ]

    {:ok, iex_pid} = ExTTY.start_link(handler: self(), type: :elixir, shell_opts: shell_opts)

    %{state | iex_pid: iex_pid}
  end

  defp stop_iex(%{iex_pid: nil} = state), do: state

  defp stop_iex(%{iex_pid: iex} = state) do
    _ = Process.unlink(iex)
    :ok = GenServer.stop(iex, 10_000)
    %{state | iex_pid: nil}
  end

  defp tty_send(state, data) do
    chan = "bot.#{state.jwt.bot}.terminal_output"
    :ok = AMQP.Basic.publish(state.chan, "amq.topic", chan, data)
  end
end
