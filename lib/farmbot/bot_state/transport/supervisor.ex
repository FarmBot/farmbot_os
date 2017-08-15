defmodule Farmbot.BotState.Transport.Supervisor do
  @moduledoc """
  Supervises services that communicate with the outside world.
  """
  use Supervisor

  @doc "Start the Transport Supervisor."
  def start_link(token, bot_state_tracker, opts \\ []) do
    Supervisor.start_link(__MODULE__, [token, bot_state_tracker], opts)
  end

  def init([token, bot_state_tracker]) do
    children = [
      # Start workers that consume the bots state, and push it somewhere else.
    ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
