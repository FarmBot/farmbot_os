defmodule FarmbotOS.Platform.Target.Uevent.Supervisor do
  @moduledoc false
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
  @moduledoc false

  use GenServer
  require FarmbotCore.Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    :ok = SystemRegistry.register()
    {:ok, nil}
  end

  def handle_info({:system_registry, :global, new_reg}, %{} = old_reg) do
    new_ttys = get_in(new_reg, [:state, "subsystems", "tty"]) || []
    old_ttys = get_in(old_reg, [:state, "subsystems", "tty"]) || []

    case new_ttys -- old_ttys do
      [new] -> new |> List.last() |> maybe_new_tty()
      [_ | _] -> FarmbotCore.Logger.warn(3, "Multiple new tty devices detected. Ignoring.")
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
    FarmbotCore.Logger.warn(1, "Unknown tty: #{inspect(unknown)}")
  end

  def new_tty(tty) do
    raise("FIXME: #{tty}")
  end
end
