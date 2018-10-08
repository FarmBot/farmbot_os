defmodule Farmbot.Target.Uevent.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link(_,_) do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    children = [worker(Farmbot.Target.Uevent, [])]
    supervise(children, [strategy: :one_for_one])
  end
end

defmodule Farmbot.Target.Uevent do
  @moduledoc false

  use GenServer
  use Farmbot.Logger

  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    :ok = SystemRegistry.register()
    {:ok, nil}
  end

  def handle_info({:system_registry, :global, new_reg}, %{} = old_reg) do
    require IEx; IEx.pry
    new_ttys = get_in(new_reg, [:state, "subsystems", "tty"]) || []
    old_ttys = get_in(old_reg, [:state, "subsystems", "tty"]) || []
    case new_ttys -- old_ttys do
      [new]   -> new |> List.last() |> maybe_new_tty()
      [_ | _] -> Logger.warn(3, "Multiple new tty devices detected. Ignoring.")
      [] -> :ok
    end
    {:noreply, new_reg}
  end

  def handle_info({:system_registry, :global, reg}, _) do
    {:noreply, reg}
  end

  def maybe_new_tty("ttyUSB" <> _ = tty), do: new_tty(tty)
  def maybe_new_tty("ttyACM" <> _ = tty), do: new_tty(tty)
  def maybe_new_tty("ttyS" <> _), do: :ok
  def maybe_new_tty("tty" <> _), do: :ok
  def maybe_new_tty(unknown) do
    Logger.warn 1, "Unknown tty: #{inspect(unknown)}"
  end

  def new_tty(tty) do
    Logger.busy 3, "Detected new UART Device: #{tty}"
    Application.put_env(:farmbot, :uart_handler, tty: "/dev/" <> tty)
    old_env = Application.get_env(:farmbot, :behaviour)

    if old_env[:firmware_handler] == Farmbot.Firmware.StubHandler do
      new_env = Keyword.put(old_env, :firmware_handler, Farmbot.Firmware.UartHandler)
      Application.put_env(:farmbot, :behaviour, new_env)
      if Process.whereis(Farmbot.Firmware) do
        GenServer.stop(Farmbot.Firmware, :shutdown)
      end
    end
  end
end
