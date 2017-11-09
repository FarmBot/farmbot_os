defmodule Farmbot.HTTP.Supervisor do
  @moduledoc false

  use Supervisor

  @doc false
  def start_link() do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    children = [
      worker(Farmbot.HTTP, []),
      worker(Farmbot.HTTP.ImageUploader, [])
    ]

    opts = [strategy: :one_for_all]
    supervise(children, opts)
  end
end
