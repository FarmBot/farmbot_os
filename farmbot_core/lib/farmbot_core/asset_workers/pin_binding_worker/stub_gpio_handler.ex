defmodule FarmbotCore.PinBindingWorker.StubGPIOHandler do
  @moduledoc "Stub gpio handler for PinBindings"
  @behaviour FarmbotCore.AssetWorker.FarmbotCore.Asset.PinBinding
  require Logger
  use GenServer

  def start_link(pin_number, fun) do
    GenServer.start_link(__MODULE__, [pin_number, fun], name: name(pin_number))
  end

  def terminate(reason, _state) do
    Logger.warn("StubBindingHandler crash: #{inspect(reason)}")
  end

  def debug_trigger(pin_number) do
    GenServer.call(name(pin_number), :debug_trigger)
  end

  def init([pin_number, fun]) do
    Logger.info("StubBindingHandler init")
    {:ok, %{pin_number: pin_number, fun: fun}}
  end

  def handle_call(:debug_trigger, _from, state) do
    Logger.debug("DebugTrigger: #{state.pin_number}")
    r = state.fun.()
    {:reply, r, state}
  end

  def name(pin_number), do: :"#{__MODULE__}.#{pin_number}"
end
