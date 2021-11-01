defmodule FarmbotOS.Platform.Target.PinBindingWorker.CircuitsGPIOHandler do
  @moduledoc "Circuits gpio handler for PinBindings"

  @behaviour FarmbotOS.AssetWorker.FarmbotOS.Asset.PinBinding
  require Logger
  use GenServer
  alias Circuits.GPIO
  require FarmbotOS.Logger
  FarmbotOS.Logger.report_termination()

  @debounce_timeout_ms 1000

  def start_link(pin_number, fun) do
    GenServer.start_link(__MODULE__, [pin_number, fun], name: name(pin_number))
  end

  def init([pin_number, fun]) do
    Logger.info("CircuitsGPIOHandler #{pin_number} init")
    {:ok, pin} = GPIO.open(pin_number, :input)
    :ok = GPIO.set_interrupts(pin, :rising)
    # this has been checked on v1.3 and v1.5 hardware
    # and it seems to be fine.
    :ok = GPIO.set_pull_mode(pin, :pulldown)
    {:ok, %{pin_number: pin_number, pin: pin, fun: fun, debounce: nil}}
  end

  def handle_info(:timeout, state) do
    Logger.info("CircuitsGPIOHandler #{state.pin_number} debounce cleared")
    {:noreply, %{state | debounce: nil}}
  end

  def handle_info(
        {:circuits_gpio, pin, _timestamp, _},
        %{debounce: timer} = state
      )
      when is_reference(timer) do
    left = Process.read_timer(timer)
    Logger.info("CircuitsGPIOHandler #{pin} still debounced for #{left} ms")
    {:noreply, state}
  end

  def handle_info({:circuits_gpio, pin, _timestamp, _signal}, state) do
    Logger.debug("CircuitsGPIOHandler #{pin} triggered")
    state.fun.()
    {:noreply, %{state | debounce: debounce_timer()}}
  end

  def name(pin_number), do: :"#{__MODULE__}.#{pin_number}"

  defp debounce_timer,
    do: Process.send_after(self(), :timeout, @debounce_timeout_ms)
end
