defmodule Farmbot.Peripheral.Supervisor do
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, [name: __MODULE__])
  end

  def init([]) do
    children = [
      {Farmbot.Peripheral.Worker, []}
    ]
    Supervisor.init(children, [strategy: :one_for_one])
  end
end
