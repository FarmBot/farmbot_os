defmodule FarmbotOS.Platform.Target.FirmwareReset.GPIO do
  @moduledoc """
  Uses GPIO pin 19 to reset the firmware.
  """
  @behaviour FarmbotFirmware.Reset

  use GenServer
  require Logger

  @impl FarmbotFirmware.Reset
  def reset(server \\ __MODULE__) do
    Logger.debug("calling gpio reset/0")
    GenServer.call(server, :reset)
  end

  @impl GenServer
  def init(_args) do
    Logger.debug("initializing gpio thing for firmware reset")
    {:ok, gpio} = Circuits.GPIO.open(19, :output)
    {:ok, %{gpio: gpio}}
  end

  @impl GenServer
  def handle_call(:reset, _from, state) do
    Logger.warn("doing firmware gpio reset")

    with :ok <- Circuits.GPIO.write(state.gpio, 1),
         :ok <- Circuits.GPIO.write(state.gpio, 0) do
      {:reply, :ok, state}
    else
      error -> {:reply, error, state}
    end
  end
end
