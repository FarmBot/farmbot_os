defmodule FarmbotCore.Firmware.Watchdog do
  # At UART start time, watch dog is initialized.
  # when initialized, a 60 second timer is started.
  # when the timer matures, an bark procedure is called.
  # The bark proceedure cancels all other timers.
  # The bark procedure re-flashes the bot.
  # The watchdog is not reset.
  # WatchDog must get pet every minute
  # When an inbound message arrives, pet watchdog
  # petting watch
  alias __MODULE__, as: State

  require FarmbotCore.Logger
  require Logger

  defstruct [
    # PID That receives "bark"
    parent: nil,
    timer: nil,
    barks: 0,
    pets: 0
  ]

  @timeout 60 * 1000
  @max_pets 10

  def new(parent) when is_pid(parent) do
    Logger.debug("==== NEW WATCHDOG")

    %State{parent: parent}
    |> new_timer()
  end

  def pet(%State{} = state) do
    if state.pets < @max_pets do
      do_pet(state)
    else
      dont_pet(state)
    end
  end

  # Once it barks, it is deactivated.
  def bark(%State{} = state) do
    FarmbotCore.Logger.debug(3, "Firmware watchdog activated.")

    state
    |> cancel_timer()
    |> increment_barks()
  end

  defp cancel_timer(%State{} = state) do
    if state.timer, do: Process.cancel_timer(state.timer)
    %{state | timer: nil}
  end

  defp new_timer(%State{} = state) do
    timer = Process.send_after(state.parent, :watchdog_bark!, @timeout)
    %{state | timer: timer}
  end

  defp increment_barks(%State{} = state), do: %{state | barks: state.barks + 1}

  defp increment_pets(%State{} = state), do: %{state | pets: state.pets + 1}

  defp dont_pet(%State{pets: @max_pets} = state) do
    Logger.debug("==== CANCELLING WATCHDOG")

    state
    |> cancel_timer()
    |> increment_pets()
  end

  defp dont_pet(%State{} = state), do: state

  defp do_pet(state) do
    Logger.debug("==== PETTING WATCHDOG")

    state
    |> cancel_timer()
    |> new_timer()
    |> increment_pets()
  end
end
