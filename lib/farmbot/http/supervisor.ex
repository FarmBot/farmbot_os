defmodule Farmbot.HTTP.Supervisor do
  @moduledoc false

  use Supervisor

  @doc false
  def start_link(token, opts \\ []) do
    Supervisor.start_link(__MODULE__, token, opts)
  end

  def init(_token) do
    children = [
      worker(Farmbot.HTTP, [])
    ]

    opts = [strategy: :one_for_all]
    supervise(children, opts)
  end
end
