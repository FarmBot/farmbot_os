defmodule Farmbot.Farmware.Supervisor do
  @moduledoc """
  Supervises Farmware.
  """
  alias Farmbot.Farmware
  use Supervisor

  @doc "Start the supervisor."
  def start_link(token, bot_state, process_info, opts \\ []) do
    Supervisor.start_link(__MODULE__, [token, bot_state, process_info], opts)
  end

  def init([token, bot_state, process_info]) do
    children = [
      worker(Farmware.Manager, [token, bot_state, process_info, [name: Farmware.Manager]])
    ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
