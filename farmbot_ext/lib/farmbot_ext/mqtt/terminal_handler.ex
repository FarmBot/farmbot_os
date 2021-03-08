defmodule FarmbotExt.MQTT.TerminalHandler do
  use GenServer
  require FarmbotCore.Logger

  # 5 minutes
  @iex_timeout 300 * 1000

  defstruct [:client_id, :username, :iex_pid]

  alias __MODULE__, as: State
  alias FarmbotExt.MQTT

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
    tty_send(state, "Starting IEx...")
    {:noreply, start_iex(state)}
  end

  # INCOMING MESSAGE: IEx already running.
  def handle_info({:inbound, _topic, payload}, state) do
    ExTTY.send_text(state.iex_pid, payload)
    {:noreply, state, @iex_timeout}
  end

  def handle_info({:tty_data, data}, state) do
    tty_send(state, data)
    {:noreply, state, @iex_timeout}
  end

  def handle_info(:timeout, state) do
    tty_send(state, "=== Session inactivity timeout ===")

    {:noreply, stop_iex(state)}
  end

  def handle_info(req, state) do
    tty_send(state, "UNKNOWN TERMINAL MSG - #{inspect(req)}")
    {:noreply, state}
  end

  def start_iex(state) do
    process = Process.whereis(:ex_tty_handler_farmbot)

    if process do
      %{state | iex_pid: process}
    else
      opts = [
        type: :elixir,
        shell_opts: shell_opts(),
        handler: self(),
        name: :ex_tty_handler_farmbot
      ]

      {:ok, iex_pid} = ExTTY.start_link(opts)
      %{state | iex_pid: iex_pid}
    end
  end

  def stop_iex(%{iex_pid: nil} = state), do: state

  def stop_iex(%{iex_pid: iex} = state) do
    _ = Process.unlink(iex)
    :ok = GenServer.stop(iex, 10_000)
    %{state | iex_pid: nil}
  end

  def tty_send(state, data) do
    MQTT.publish(state.client_id, "bot/#{state.username}/terminal_output", data)
  end

  def shell_opts do
    [
      [
        dot_iex_path:
          [".iex.exs", "~/.iex.exs", "/etc/iex.exs"]
          |> Enum.map(&Path.expand/1)
          |> Enum.find("", &File.regular?/1)
      ]
    ]
  end
end
