defmodule FarmbotOS.Platform.Target.Uevent.Supervisor do
  @moduledoc """
  Supervisor responsible for monitoring the Uevent process
  """

  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    children = [{FarmbotOS.Platform.Target.Uevent, []}]
    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule FarmbotOS.Platform.Target.Uevent do
  @moduledoc """
  Process responsible for monitoring uevent linux subsystem for
  events relating to serial devices being plugged and unplugged
  """

  use GenServer
  require Logger
  require FarmbotCore.Logger
  require FarmbotTelemetry
  alias FarmbotCore.{Config, FirmwareTTYDetector}

  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl GenServer
  def init([]) do
    :ok = SystemRegistry.register()
    {:ok, nil}
  end

  def handle_info({:system_registry, :global, new_reg}, %{} = old_reg) do
    new_ttys = get_in(new_reg, [:state, "subsystems", "tty"]) || []
    old_ttys = get_in(old_reg, [:state, "subsystems", "tty"]) || []

    case new_ttys -- old_ttys do
      [new] -> new |> List.last() |> maybe_new_tty()
      [_ | _] -> Logger.warn("Multiple new tty devices detected. Ignoring.")
      [] -> :ok
    end

    {:noreply, new_reg}
  end

  def handle_info({:system_registry, :global, reg}, _) do
    {:noreply, reg}
  end

  @doc false
  def maybe_new_tty("ttyUSB" <> _ = tty), do: new_tty(tty)
  def maybe_new_tty("ttyACM" <> _ = tty), do: new_tty(tty)
  def maybe_new_tty("ttyS" <> _), do: :ok
  def maybe_new_tty("tty" <> _), do: :ok

  def maybe_new_tty(unknown) do
    Logger.debug("Unknown tty: #{inspect(unknown)}")
  end

  # called when a new TTY is detected
  @doc false
  def new_tty(tty) do
    case FirmwareTTYDetector.tty() do
      nil ->
        FarmbotTelemetry.event(:firmware, :tty_detected, nil, tty: tty)
        FarmbotCore.Logger.busy(1, "new firmware interfaces detected: #{tty}")
        FirmwareTTYDetector.set_tty(tty)
        Config.update_config_value(:bool, "settings", "firmware_needs_flash", true)
        Config.update_config_value(:bool, "settings", "firmware_needs_open", false)

      tty ->
        Logger.debug("firmware interface already detected: #{tty}")
        :ok
    end
  end
end
