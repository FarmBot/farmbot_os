defmodule Farmbot.System.Supervisor do
  @moduledoc """
  Supervises Platform specific stuff for Farmbot to operate
  """
  use Supervisor
  import Farmbot.System.Init

  @doc "Start the System Services. This is more or less `init`."
  def start_link(args, opts \\ []) do
    Supervisor.start_link(__MODULE__, args, opts)
  end

  def init(args) do
    children = [
      worker(Farmbot.System.Init.FSCheckup, [[], []]),
      supervisor(Farmbot.System.Init.Ecto, [[], []]),
      supervisor(Farmbot.System.ConfigStorage, [])
    ]

    init_mods = Application.get_env(:farmbot, :init)
      |> Enum.map(fn(child) -> fb_init(child, [args, [name: child]]) end)
    supervise(children ++ init_mods, [strategy: :one_for_all])
  end
end
