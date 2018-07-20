defmodule Farmbot.PinBinding.StubHandler do
  @moduledoc "Stub for handling PinBinding."
  @behaviour Farmbot.PinBinding.Handler
  use GenServer

  def test_fire(pin) do
    GenServer.call(__MODULE__, {:test_fire, pin})
  end

  def register_pin(num) do
    GenServer.call(__MODULE__, {:register_pin, num})
  end

  def unregister_pin(num) do
    GenServer.call(__MODULE__, {:unregister_pin, num})
  end

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    {:ok, %{}}
  end

  def handle_call({:register_pin, num}, _from, state) do
    {:reply, :ok, Map.put(state, num, :enabled)}
  end

  def handle_call({:unregister_pin, num}, _from, state) do
    {:reply, :ok, Map.delete(state, num)}
  end

  def handle_call({:test_fire, pin}, _from, state) do
    case state[pin] do
      nil ->
        {:reply, :error, state}

      :enabled ->
        send(self(), {:do_test_fire, pin})
        {:reply, :ok, state}
    end
  end

  def handle_info({:do_test_fire, pin}, state) do
    Farmbot.PinBinding.Manager.trigger(pin, :falling)
    Farmbot.PinBinding.Manager.trigger(pin, :rising)
    {:noreply, state}
  end
end
