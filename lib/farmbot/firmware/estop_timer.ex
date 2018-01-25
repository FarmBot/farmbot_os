defmodule Farmbot.Firmware.EstopTimer do
  @moduledoc """
  Module responsible for timing emails about E stops.
  """
  use GenServer
  use Farmbot.Logger

  @msg "Farmbot has been E-Stopped for more than 10 minutes."
  # Ten minutes.
  @timer_ms 600000
  # fifteen seconds.
  # @timer_ms 15000

  @doc "Checks if the timer is active."
  def timer_active? do
    GenServer.call(__MODULE__, :timer_active?)
  end

  @doc "Starts a new timer if one isn't started."
  def start_timer do
    GenServer.call(__MODULE__, :start_timer)
  end

  @doc "Cancels a timer if it exists."
  def cancel_timer do
    GenServer.call(__MODULE__, :cancel_timer)
  end

  @doc false
  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  @doc false
  def init([]) do
    {:ok, %{timer: nil, already_sent: false}}
  end

  def handle_call(:timer_active?, _, state) do
    {:reply, is_timer_active?(state.timer), state}
  end

  def handle_call(:start_timer, _from, state) do
    if !is_timer_active?(state.timer) do
      {:reply, :ok, %{state | timer: do_start_timer(self())}}
    else
      {:reply, :ok, state}
    end
  end

  def handle_call(:cancel_timer, _from, state) do
    if is_timer_active?(state.timer) do
      Process.cancel_timer(state.timer)
    end
    {:reply, :ok, %{state | timer: nil, already_sent: false}}
  end

  def handle_info(:timer, state) do
    if state.already_sent do
      {:noreply, %{state | timer: nil}}
    else
      Logger.warn 1, @msg, [channels: [:email]]
      {:noreply, %{state | timer: nil, already_sent: true}}
    end
  end

  defp is_timer_active?(timer) do
    if timer, do: is_number(Process.read_timer(timer)), else: false
  end

  defp do_start_timer(pid) do
    Process.send_after(pid, :timer, @timer_ms)
  end
end
