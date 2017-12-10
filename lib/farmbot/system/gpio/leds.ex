defmodule Farmbot.System.GPIO.Leds do
  @moduledoc false

  use GenServer

  @led_status_on Application.get_env(:farmbot, :gpio, :status_led_off) || true

  def led_status_ok do
    GenServer.call(__MODULE__, :led_status_ok)
  end

  def led_status_err do
    GenServer.call(__MODULE__, :led_status_err)
  end

  @doc false
  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    names = Application.get_env(:nerves_leds, :names) || []
    status_led_name = Keyword.get(names, :status)
    {:ok, %{status: status_led_name}}
  end

  def handle_call(_, _from, %{status: nil} = state) do
    {:reply, :ok, state}
  end

  def handle_call(:led_status_ok, _from, %{status: _} = state) do
    Nerves.Leds.set status: @led_status_on
    {:reply, :ok, state}
  end

  def handle_call(:led_status_err, _from, %{status: _} = state) do
    Nerves.Leds.set status: :slowblink
    {:reply, :ok, state}
  end
end
