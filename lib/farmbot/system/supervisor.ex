defmodule Farmbot.System.Supervisor do
  @moduledoc """
  Supervises Platform specific stuff for Farmbot to operate
  """
  use Supervisor

  @doc false
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, [name: __MODULE__])
  end

  def init([]) do
    children = [
      supervisor(Farmbot.System.Init.Suprevisor, []),
      worker(Farmbot.System.NervesHub, []),
      supervisor(Farmbot.System.Updates, []),
      worker(Farmbot.EasterEggs, []),
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
