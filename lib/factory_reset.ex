defmodule FactoryReset do
  @reset_pin Application.get_env(:fb, :factory_reset_pin)
  require Logger
  use GenServer

  def init(_args) do
    Process.flag(:trap_exit, true)
    {:ok, spawn_link(fn -> Shush.start end)}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def handle_info({:EXIT, _pid, reason}, state) do
    Logger.debug("hes dead jim")
    IO.inspect(reason)
    {:noreply, state}
  end

  def handle_info(event, state) do
    Logger.debug("got event: #{inspect event}" )
    {:noreply, state}
  end
end

defmodule Shush do
  @reset_pin Application.get_env(:fb, :factory_reset_pin)
  def start do
    {:ok, pid} =  Gpio.start_link(@reset_pin, :input)
    Gpio.set_int(pid, :both)
    do_stuff(pid)
  end

  def do_stuff(pid) do
    receive do
      {:gpio_interrupt, @reset_pin, :falling} -> IO.puts("falling")
      {:gpio_interrupt, @reset_pin, :rising}  -> IO.puts("rising")
    end
    Process.sleep(80)
    do_stuff(pid)
  end
end
