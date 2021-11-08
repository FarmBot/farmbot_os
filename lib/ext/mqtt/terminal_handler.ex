defmodule FarmbotOS.MQTT.TerminalHandler do
  use GenServer
  require FarmbotOS.Logger

  # 5 minutes
  @iex_timeout 300 * 1000

  defstruct [:client_id, :username, :iex_pid]

  alias __MODULE__, as: State
  alias FarmbotOS.MQTT.TerminalHandlerSupport, as: Support

  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(args) do
    state = %State{
      client_id: Keyword.fetch!(args, :client_id),
      username: Keyword.fetch!(args, :username),
      iex_pid: nil
    }

    {:ok, state}
  end

  # {:inbound, [a, b, "ping", d], payload}
  # INCOMING MESSAGE: We must lazily instantiate an IEX session
  def handle_info({:inbound, _topic, _payload}, %{iex_pid: nil} = state) do
    Support.tty_send(state, "Starting IEx...")
    {:noreply, Support.start_iex(state)}
  end

  # INCOMING MESSAGE: IEx already running.
  def handle_info({:inbound, _topic, payload}, state) do
    ExTTY.send_text(state.iex_pid, payload)
    {:noreply, state, @iex_timeout}
  end

  def handle_info({:tty_data, data}, state) do
    Support.tty_send(state, data)
    {:noreply, state, @iex_timeout}
  end

  def handle_info(:timeout, state) do
    Support.tty_send(state, "=== Session inactivity timeout ===")

    {:noreply, Support.stop_iex(state)}
  end

  def handle_info(req, state) do
    Support.tty_send(state, "UNKNOWN TERMINAL MSG - #{inspect(req)}")
    {:noreply, state}
  end
end
