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

  def handle_info({:basic_deliver, payload, %{routing_key: routing_key}}, state) do
    IO.inspect(payload, label: "== TTY: ")
    routing_key = String.replace(routing_key, "_input", "_output")
    :ok = Basic.publish(state.chan, @exchange, routing_key, "OK")
    {:noreply, state}
  end

  def handle_info({:tty_data, data}, state) do
    tty_send(state.conn, data)
    {:noreply, state, @iex_timeout}
  end

  # Lazily start IEX when commands come in.
  def handle_info({:incoming_cmd, _} = msg, %{iex_pid: nil} = state) do
    handle_info(msg, start_iex(state))
  end

  def handle_info({:incoming_cmd, data}, state) do
    ExTTY.send_text(state.iex_pid, data)
    {:noreply, state, @iex_timeout}
  end

  def handle_info(:timeout, state) do
    tty_send(state.conn, "=== Session timeout due to inactivity ===")

    {:noreply, stop_iex(state)}
  end

  def handle_info(req, state) do
    tty_send(state.conn, "Can't hande this info - #{inspect(req)}")
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
    :ok = AMQP.Basic.publish(state.conn, "amq.topic", "bot.device_123.from_device_stream", data)
  end
end
