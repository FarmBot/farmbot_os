defmodule FarmbotOS.Init.Supervisor do
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    config = Application.get_env(:farmbot, __MODULE__)

    children =
      (config[:init_children] || []) ++
        [
          {FarmbotOS.Init.FSCheckup, []}
        ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
