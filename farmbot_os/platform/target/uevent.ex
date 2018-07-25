defmodule Farmbot.Target.Uevent.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, [name: __MODULE__])
  end

  def init([]) do
    children = [{Farmbot.Target.Uevent, []}]
    Supervisor.init(children, [strategy: :one_for_one])
  end
end

defmodule Farmbot.Target.Uevent do
  @moduledoc false

  use GenServer
  require Farmbot.Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [name: __MODULE__])
  end

  def init([]) do
    :ok = SystemRegistry.register()
    {:ok, nil}
  end

  def handle_info({:system_registry, :global, new_reg}, %{} = old_reg) do
    new_ttys = get_in(new_reg, [:state, "subsystems", "tty"]) || []
    old_ttys = get_in(old_reg, [:state, "subsystems", "tty"]) || []
    case new_ttys -- old_ttys do
      [new]   -> new |> List.last() |> maybe_new_tty()
      [_ | _] -> Farmbot.Logger.warn(3, "Multiple new tty devices detected. Ignoring.")
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
    Farmbot.Logger.warn 1, "Unknown tty: #{inspect(unknown)}"
  end

  def new_tty(tty) do
    Farmbot.Logger.busy 3, "Detected new UART Device: #{tty}"
    Application.put_env(:farmbot_core, :uart_handler, tty: "/dev/" <> tty)
    old_env = Application.get_env(:farmbot_core, :behaviour)

    if old_env[:firmware_handler] == Farmbot.Firmware.StubHandler do
      new_env = Keyword.put(old_env, :firmware_handler, Farmbot.Firmware.UartHandler)
      Application.put_env(:farmbot_core, :behaviour, new_env)
      if Process.whereis(Farmbot.Firmware) do
        GenServer.stop(Farmbot.Firmware, :shutdown)
      end
    end
  end
end
