defmodule Farmbot.Core.FirmwareEstopTimer do
  @moduledoc """
  Process that wraps a `Process.send_after/3` call.
  When `:timeout` is received, a `fatal_email` log message will be
  dispatched.
  """

  use GenServer
  require Farmbot.Logger

  @msg "Farmbot has been E-Stopped for more than 10 minutes."

  @ten_minutes_ms 60_0000

  def start_timer(timer_server \\ __MODULE__) do
    GenServer.call(timer_server, :start_timer)
  end

  def cancel_timer(timer_server \\ __MODULE__) do
    GenServer.call(timer_server, :cancel_timer)
  end

  @doc """
  optional args:
    * `timeout_ms` - amount of milliseconds to run timer for
    * `timeout_function` - function to call instead of logging
  opts - GenServer.options()
  """
  @spec start_link(Keyword.t(), GenServer.options()) :: GenServer.on_start()
  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(args) do
    timeout_ms = Keyword.get(args, :timeout_ms, @ten_minutes_ms)
    timeout_fun = Keyword.get(args, :timeout_function, &do_log/0)
    state = %{timer: nil, timeout_ms: timeout_ms, timeout_function: timeout_fun}
    {:ok, state, :hibernate}
  end

  def handle_call(:start_timer, _from, state) do
    timer = Process.send_after(self(), :timeout, state.timeout_ms)
    {:reply, timer, %{state | timer: timer}}
  end

  def handle_call(:cancel_timer, _from, state) do
    state.timer && Process.cancel_timer(state.timer)
    {:reply, state.timer, %{state | timer: nil}, :hibernate}
  end

  def handle_info(:timeout, state) do
    _ = apply(state.timeout_function, [])
    {:noreply, %{state | timer: nil}, :hibernate}
  end

  @doc false
  def do_log, do: Farmbot.Logger.warn(1, @msg, channels: [:fatal_email])
end
