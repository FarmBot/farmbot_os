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
    {:ok, default_state(args), {:continue, {:connect_amqp, 0}}}
  end

  def handle_amqp_connection(state, {:ok, chan}) do
    FarmbotCore.Logger.debug(3, "Connected to terminal channel")
    {:noreply, %{state | chan: chan}}
  end

  def handle_amqp_connection(state, nil) do
    {:noreply, %{state | chan: nil}, {:continue, {:connect_amqp, 4000}}}
  end

  def handle_amqp_connection(state, err) do
    FarmbotCore.Logger.error(1, "Terminal connection failed: #{inspect(err)}")
    {:noreply, %{state | chan: nil}, {:continue, {:connect_amqp, 4000}}}
  end

  def handle_continue({:connect_amqp, wait}, state) do
    Process.sleep(wait)
    handle_amqp_connection(state, Support.get_channel(state.jwt.bot))
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
    :ok = Support.tty_send(state.jwt.bot, state.chan, data)
  end

  def default_state(args) do
    %State{chan: nil, iex_pid: nil, jwt: Keyword.fetch!(args, :jwt)}
  end
end
