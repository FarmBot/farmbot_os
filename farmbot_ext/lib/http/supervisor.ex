defmodule Farmbot.HTTP.Supervisor do
  @moduledoc false

  use Supervisor

  @doc false
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, [name: __MODULE__])
  end

  def init([]) do
    children = [
      {Farmbot.HTTP.ImageUploader, []}
    ]

    opts = [strategy: :one_for_all]
    Supervisor.init(children, opts)
  end
end
