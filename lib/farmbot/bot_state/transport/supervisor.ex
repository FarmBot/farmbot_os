defmodule Farmbot.BotState.Transport.Supervisor do
  @moduledoc """
  Supervises services that communicate with the outside world.
  """
  use Supervisor

  @error_msg """
  Could not find :transport configuration.
  config.exs should have:

  config: :farmbot, :transport, [
    # any transport modules here.
  ]
  """

  @doc "Start the Transport Supervisor."
  def start_link(token, bot_state_tracker, opts \\ []) do
    Supervisor.start_link(__MODULE__, [token, bot_state_tracker], opts)
  end

  def init([token, bot_state_tracker]) do
    transports = Application.get_env(:farmbot, :transport) || raise @error_msg
    # Start workers that consume the bots state, and push it somewhere else.
    children = Enum.map(transports, fn(transport) ->
      worker(transport, [token, bot_state_tracker, [name: transport]])
    end)
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
