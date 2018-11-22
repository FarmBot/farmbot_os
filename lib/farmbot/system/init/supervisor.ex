defmodule Farmbot.System.Init.Suprevisor do
  @moduledoc false
  use Supervisor
  import Farmbot.System.Init

  def start_link(args \\ []) do
    Supervisor.start_link(__MODULE__, args, [name: __MODULE__])
  end

  def init([]) do
    init_mods =
      Application.get_env(:farmbot, :init)
      |> Enum.map(fn child -> fb_init(child, [[], [name: child]]) end)

    children = [
      # Load kernel modules
      worker(Farmbot.System.Init.KernelMods, [[], []]),
      # Ensure filesystem
      worker(Farmbot.System.Init.FSCheckup, [[], []]),
      # Ensure ecto + migrations
      supervisor(Farmbot.System.Init.Ecto, [[], []]),
      # Ensure config_storage
      supervisor(Farmbot.System.ConfigStorage, []),
      worker(Farmbot.System.ConfigStorage.Dispatcher, []),
    ] ++ init_mods

    Supervisor.init(children, [strategy: :one_for_one])
  end
end
