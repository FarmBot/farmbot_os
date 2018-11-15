defmodule Farmbot.PinBindingWorker.ElixirALEGPIOHandler do
  @moduledoc "ElixirALE gpio handler for PinBindings"
  @behaviour Farmbot.AssetWorker.Farmbot.Asset.PinBinding
  require Logger
  use GenServer
  alias ElixirALE.GPIO

  @debounce_timeout_ms 1000

  def start_link(pin_number, fun) do
    GenServer.start_link(__MODULE__, [pin_number, fun], name: name(pin_number))
  end

  def terminate(reason, _state) do
    Logger.warn("AleBindingHandler crash: #{inspect(reason)}")
  end

  def init([pin_number, fun]) do
    Logger.info("AleBindingHandler init")
    {:ok, pid} = GPIO.start_link(pin_number, :input)
    :ok = GPIO.set_int(pid, :both)
    {:ok, %{pin_number: pin_number, pid: pid, fun: fun, debounce: nil}}
  end

  def handle_info(:timeout, state) do
    Logger.info("AleBindingHandler #{state.pin_number} debounce cleared")
    {:noreply, %{state | debounce: nil}}
  end

  def handle_info({:gpio_interupt, pin, _}, %{debounce: timer} = state)
      when is_reference(timer) do
    left = Process.read_timer(timer)
    Logger.info("AleBindingHandler #{pin} still debounced for #{left} ms")
    {:noreply, state}
  end

  def handle_info({:gpio_interupt, _pin, _signal}, state) do
    state.fun.()
    {:noreply, state, %{state | debounce: debounce_timer()}}
  end

  def name(pin_number), do: :"#{__MODULE__}.#{pin_number}"

  defp debounce_timer, do: Process.send_after(self(), :timeout, @debounce_timeout_ms)
end
