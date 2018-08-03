defmodule Farmbot.Peripheral.Worker do
  use GenServer
  alias Farmbot.{Asset, Registry}
  alias Asset.Peripheral
  require Farmbot.Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [name: __MODULE__])
  end

  def init([]) do
    Registry.subscribe()
    {:ok, %{}}
  end

  def handle_info({Registry, {Asset, {:deletion, %Peripheral{pin: _pin, mode: _mode}}}}, state) do
    {:noreply, state}
  end

  def handle_info({Registry, {Asset, {_action, %Peripheral{pin: pin, mode: mode}}}}, state) do
    mode = if mode == 0, do: :digital, else: :analog
    Farmbot.Firmware.read_pin(pin, mode)
    Farmbot.Logger.busy 3, "Read peripheral (#{pin} - #{mode})"
    {:noreply, state}
  end

  def handle_info({Registry, _}, state) do
    {:noreply, state}
  end
end
