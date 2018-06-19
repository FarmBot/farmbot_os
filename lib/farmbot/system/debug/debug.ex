defmodule Farmbot.System.Debug do
  @moduledoc "Supervisor for Various debugging modules."
  use Supervisor

  def start_link(_, opts) do
    Supervisor.start_link(__MODULE__, [], opts)
  end

  def init([]) do
    children = []

    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
