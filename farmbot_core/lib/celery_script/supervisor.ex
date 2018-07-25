defmodule Farmbot.CeleryScript.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, [name: __MODULE__])
  end

  def init([]) do
    children = [
      {Farmbot.CeleryScript.CsvmWrapper, []}
    ]
    Supervisor.init(children, [strategy: :one_for_one])
  end
end
