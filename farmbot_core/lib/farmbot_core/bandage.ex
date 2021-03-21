defmodule FarmbotCore.Bandage do
  @moduledoc """
  There is a nasty race condition in the Firmware system that
  occurs on Express 1.5 bots.
  Since the firmware handler is scheduled for a re-write and
  a root cause was never isolated, this module acts as a
  stop-gap solution until we do the full re-write.
  """
  use GenServer
  require Logger
  defstruct [count: 0, children: nil]
  alias __MODULE__, as: State

  # 180_000 ms == 3 minutes
  @iter_time 5_000
  @wait_cycles 16
  @children [
    FarmbotCore.FirmwareOpenTask,
]

  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(_) do
    Logger.info("%%% Starting up probably")
    Process.send_after(self(), :wait_for_boot, @iter_time)
    {:ok, %State{}}
  end

  def handle_info(:wait_for_boot, state) do
    if state.count < @wait_cycles do
      Logger.info("%%% Waiting #{@wait_cycles - state.count} cycles")
      Process.send_after(self(), :wait_for_boot, @iter_time)
    else
      Logger.info("%%% Ready to boot firmware.")
      Process.send_after(self(), :boot, 1)
    end
    {:noreply, %{state | count: state.count + 1}}
  end

  def handle_info(:boot, %{children: nil} = state) do
    Logger.info("%%% Booting firmware.")
    args = [strategy: :one_for_one]
    {:ok, pid} = Supervisor.start_link(@children, args)
    {:noreply, %{state | count: @wait_cycles, children: pid}}
  end

  def handle_info(message, state) do
    Logger.info("%%% UNKNOWN MESSAGE: #{inspect(message)}")
    {:noreply, state}
  end
end
