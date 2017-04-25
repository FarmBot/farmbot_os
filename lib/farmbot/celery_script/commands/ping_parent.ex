defmodule Farmbot.CeleryScript.Command.PingParent do
  @moduledoc """
    PingParent
  """

  alias Farmbot.CeleryScript.Command
  require Logger
  use Farmbot.DebugLog

  @behaviour Command

  @doc ~s"""
  """
  @spec run(%{context: map}, []) :: no_return
  def run(%{context: context}, []) do
    parent = context[:parent]
    if parent do
      :pong = Farmbot.SequenceRunner.call(parent, :ping)
      debug_log "Established communication with parent sequence: #{inspect parent}"
      :ok
    else
      debug_log "This sequence has no parent."
      :ok
    end
  end

end
