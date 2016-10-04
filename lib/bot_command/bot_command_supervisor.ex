defmodule BotCommandSupervisor do
  @moduledoc """
    Supervises Bot Commands
  """
  def start_link(_) do
    import Supervisor.Spec
    children = [
      worker(BotCommandHandler, [[]])
    ]
    Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{}}
  end
end
