defmodule Farmbot.System.Init.Supervisor do
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, [name: __MODULE__])
  end

  def init([]) do
    children = Application.get_env(:farmbot_os, :init_children, []) ++ [
      {Farmbot.System.Init.FSCheckup, []},
      {Farmbot.System.Init.Ecto, []},
    ]
    Supervisor.init(children, [strategy: :one_for_all])
  end
end
