defmodule FarmbotExt.AMQP.TerminalChannel do
  use GenServer
  require FarmbotCore.Logger

  # 5 minutes
  @iex_timeout 300 * 1000

  defstruct [:chan, :jwt, :iex_pid]

  alias __MODULE__, as: State
  alias FarmbotExt.AMQP.TerminalChannelSupport, as: Support

  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(args) do
    send(self(), :connect_amqp)
    {:ok, default_state(args)}
  end

  def handle_amqp_connection(state, {:ok, chan}) do
    FarmbotCore.Logger.debug(3, "Connected to terminal channel")
    %{state | chan: chan}
  end

  def handle_amqp_connection(state, nil) do
    Process.send_after(self(), :connect_amqp, 5000)
    %{state | chan: nil}
  end

  def handle_amqp_connection(state, err) do
    msg = "Terminal connection failed: #{inspect(err)}"
    FarmbotCore.Logger.error(1, msg)
    Process.send_after(self(), :connect_amqp, 3000)
    %{state | chan: nil}
  end

  def handle_info(:connect_amqp, state) do
    result = Support.get_channel(state.jwt.bot)
    {:noreply, handle_amqp_connection(state, result)}
  end

  # Confirmation sent by the broker after registering this
  # process as a consumer
  def handle_info({:basic_consume_ok, _}, state) do
    {:noreply, state}
  end

  # Sent by the broker when the consumer is
  # unexpectedly cancelled (such as after a queue deletion)
  def handle_info({:basic_cancel, _}, state) do
    {:stop, :normal, state}
  end

  # Confirmation sent by the broker to the consumer process
  # after a Basic.cancel
  def handle_info({:basic_cancel_ok, _}, state) do
    {:noreply, state}
  end

  # INCOMING MESSAGE: We must lazily instantiate an IEX
  # session
  def handle_info({:basic_deliver, _, %{routing_key: _}}, %{iex_pid: nil} = state) do
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
    tty_send(state, "UNKNOWN TERMINAL MSG - #{inspect(req)}")
    {:noreply, state}
  end

  def start_iex(state) do
    opts = [type: :elixir, shell_opts: Support.shell_opts(), handler: self()]
    {:ok, iex_pid} = ExTTY.start_link(opts)
    %{state | iex_pid: iex_pid}
  end

  def stop_iex(%{iex_pid: nil} = state), do: state

  def stop_iex(%{iex_pid: iex} = state) do
    _ = Process.unlink(iex)
    :ok = GenServer.stop(iex, 10_000)
    %{state | iex_pid: nil}
  end

  def tty_send(state, data) do
    chan = "bot.#{state.jwt.bot}.terminal_output"
    :ok = AMQP.Basic.publish(state.chan, "amq.topic", chan, data)
  end

  def default_state(args) do
    %State{chan: nil, iex_pid: nil, jwt: Keyword.fetch!(args, :jwt)}
  end
end
