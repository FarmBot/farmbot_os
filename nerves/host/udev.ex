if Mix.env() == :dev do
defmodule Farmbot.System.Udev.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link(_,_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    children = [
      worker(Farmbot.System.Udev, [])
    ]
    supervise(children, [strategy: :one_for_one])
  end
end

defmodule Farmbot.System.Udev do
  use GenServer
  use Farmbot.Logger

  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    {:ok, udev} = Udev.Monitor.start_link self(), :udev
    {:ok, %{udev: udev}}
  end

  def terminate(_reason, state) do
    if Process.alive?(state.udev) do
      Udev.Monitor.stop(state.udev)
    end
  end

  def handle_info({:udev, %Udev.Device{action: :add, devnode: tty, subsystem: "tty"}}, state) do
    Logger.busy 3, "Detected new UART Device: #{tty}"
    Application.put_env(:farmbot, :uart_handler, tty: tty)
    old_env = Application.get_env(:farmbot, :behaviour)

    if old_env[:firmware_handler] == Farmbot.Firmware.StubHandler do
      new_env = Keyword.put(old_env, :firmware_handler, Farmbot.Firmware.UartHandler)
      Application.put_env(:farmbot, :behaviour, new_env)
      GenServer.stop(Farmbot.Firmware, :shutdown)
    end
    {:noreply, state}
  end

  def handle_info({:udev, _msg}, state) do
    {:noreply, state}
  end
end
end
