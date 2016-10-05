defmodule FactoryReset do
  @reset_pin Application.get_env(:fb, :factory_reset_pin)
  use GenServer
  require Logger
  def init(_args) do
    {:ok, pid} = Gpio.start_link(@reset_pin, :input)
    Process.send_after(__MODULE__, {:set_int, :rising, pid}, 2000)
    {:ok, pid}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def handle_info({:gpio_interrupt, @reset_pin, :rising}, state) do
    Logger.debug("rising")
    {:noreply, state}
  end

  def handle_info({:gpio_interrupt, @reset_pin, :falling}, state) do
    Logger.debug("falling")
    {:noreply, state}
  end

  def handle_info({:set_int, int, pid}, state) do
    Gpio.set_int(pid, int)
    {:noreply, state}
  end

  def handle_info(event, state) do
    Logger.debug("got event: #{inspect event}" )
    {:noreply, state}
  end
end
