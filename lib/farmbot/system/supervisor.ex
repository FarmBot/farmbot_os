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
    :farmbot
    |> Application.get_env(:init)
    |> Enum.map(fn(child) -> fb_init(child, [args, [name: child]]) end)
    |> Kernel.++([supervisor(Farmbot.System.ConfigStorage, [])])
    |> supervise([strategy: :one_for_all])
  end
end
