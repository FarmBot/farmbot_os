defmodule Farmbot.Target.PinBinding.AleHandler do
  @moduledoc "PinBinding handler that uses Elixir.Ale"

  use GenServer
  alias Circuits.GPIO
  @behaviour Farmbot.PinBinding.Handler

  # PinBinding.Handler Callbacks
  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def register_pin(num) do
    GenServer.call(__MODULE__, {:register_pin, num})
  end

  def unregister_pin(num) do
    GenServer.call(__MODULE__, {:unregister_pin, num})
  end

  # GenServer Callbacks

  defmodule State do
    @moduledoc false
    defstruct [:pins]
  end

  defmodule PinState do
    @moduledoc false
    defstruct [:pin, :state, :signal, :gpio]
  end

  def init([]) do
    {:ok, %State{pins: %{}}}
  end

  def handle_call({:register_pin, num}, _from, state) do
    with {:ok, out_gpio} <- GPIO.open(num, :output),
         :ok <- GPIO.write(out_gpio, 0),
         :ok <- GPIO.close(out_gpio),
         {:ok, gpio} <- GPIO.open(num, :input),
         :ok <- GPIO.set_interrupts(gpio, :both),
         new_pins <-
           Map.put(state.pins, num, %PinState{pin: num, gpio: gpio, state: nil, signal: :rising}) do
      {:reply, :ok, %{state | pins: new_pins}}
    else
      {:error, _} = err -> {:reply, err, state}
      err -> {:reply, {:error, err}, state}
    end
  end

  def handle_call({:unregister_pin, num}, _from, state) do
    case state.pins[num] do
      nil ->
        {:reply, :ok, state}

      %PinState{gpio: gpio} ->
        GPIO.close(gpio)
        {:reply, :ok, %{state | pins: Map.delete(state.pins, num)}}
    end
  end

  def handle_info({:gpio_interrupt, pin, signal}, state) do
    pin_state = state.pins[pin]
    new_state = %{state | pins: %{state.pins | pin => %{pin_state | state: signal}}}
    Farmbot.PinBinding.Manager.trigger(pin, signal)
    {:noreply, new_state}
  end
end
