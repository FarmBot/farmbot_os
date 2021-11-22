defmodule FarmbotOS.Lua.PinWatcher do
  alias FarmbotOS.Firmware.UARTCore

  defstruct [:pin, :callback, :parent]

  def new([pin, callback], lua) do
    GenServer.start_link(__MODULE__, [pin, callback, self()])
    {[], lua}
  end

  def init([pin, callback, parent]) do
    UARTCore.watch_pin(pin)
    {:ok, %__MODULE__{pin: pin, callback: callback, parent: parent}}
  end

  def handle_info({:pin_data, pin, val}, state) do
    if Process.alive?(state.parent) do
      state.callback.([[pin: pin, value: val]])
      {:noreply, state}
    else
      # Stop process if CSVM is done/crashed
      {:stop, :normal, state}
    end
  end

  def terminate(_reason, _state), do: UARTCore.unwatch_pin()
end
