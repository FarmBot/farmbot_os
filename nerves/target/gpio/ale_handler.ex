defmodule Farmbot.Target.GPIO.AleHandler do
  @moduledoc "GPIO handler that uses Elixir.Ale"

  use GenStage
  alias ElixirALE.GPIO
  @behaviour Farmbot.System.GPIO.Handler

  # GPIO Handler Callbacks
  def start_link do
    GenStage.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def register_pin(num) do
    GenStage.call(__MODULE__, {:register_pin, num})
  end

  # GenStage Callbacks

  defmodule State do
    @moduledoc false
    defstruct [:pins]
  end

  defmodule PinState do
    @moduledoc false
    defstruct [:pin, :state, :signal, :timer]
  end

  def init([]) do
    {:producer, struct(State, [pins: %{}]), [dispatcher: GenStage.BroadcastDispatcher]}
  end

  def handle_demand(_amnt, state) do
    {:noreply, [], state}
  end

  def handle_call({:register_pin, num}, _from, state) do
    with {:ok, pin} <- GPIO.start_link(num, :input),
    :ok <- GPIO.set_int(pin, :rising) do
      {:reply, :ok, [], %{state | pins: Map.put(state.pins, num, struct(PinState, [pin: pin, state: nil, signal: :rising]))}}
    else
      {:error, _} = err-> {:reply, err, [], state}
      err -> {:reply, {:error, err}, [], state}
    end
  end

  def handle_info({:gpio_interrupt, pin, :rising}, state) do
    pin_state = state.pins[pin]
    if pin_state.timer do
      new_state = %{state | pins: %{state.pins | pin => %{pin_state | state: :rising}}}
      {:noreply, [], new_state}
    else
      timer = Process.send_after(self(), {:gpio_timer, pin}, 5000)
      new_state = %{state | pins: %{state.pins | pin => %{pin_state | timer: timer, state: :rising}}}
      {:noreply, [{:pin_trigger, pin}], new_state}
    end
  end

  def handle_info({:gpio_interrupt, pin, signal}, state) do
    pin_state = state.pins[pin]
    new_state = %{state | pins: %{state.pins | pin => %{pin_state | state: signal}}}
    {:noreply, [], new_state}
  end

  def handle_info({:gpio_timer, pin}, state) do
    pin_state = state.pins[pin]
    if pin_state do
      new_pin_state = %{pin_state | timer: nil}
      {:noreply, [], %{state | pins: %{state.pins | pin => new_pin_state}}}
    else
      {:noreply, [], state}
    end
  end
end
