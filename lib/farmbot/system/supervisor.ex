defmodule Farmbot.System.Supervisor do
  @moduledoc """
  Supervises Platform specific stuff for Farmbot to operate
  """
  use Supervisor
  import Farmbot.System.Init

  @doc false
  def start_link() do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    children = [
      worker(Farmbot.System.Init.FSCheckup, [[], []]),
      supervisor(Farmbot.System.Init.Ecto, [[], []]),
      supervisor(Farmbot.System.ConfigStorage, []),
      worker(Farmbot.System.ConfigStorage.Dispatcher, [])
    ]

    init_mods =
      Application.get_env(:farmbot, :init)
      |> Enum.map(fn child -> fb_init(child, [[], [name: child]]) end)

    supervise(children ++ init_mods, strategy: :one_for_all)
  end
end
