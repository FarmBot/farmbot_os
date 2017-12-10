defmodule Farmbot.BotState.Supervisor do
  @moduledoc false
  use Supervisor

  @doc false
  def start_link() do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    children = [
      worker(Farmbot.BotState, []),
    ]

    supervise(children, strategy: :one_for_one)
  end
end
