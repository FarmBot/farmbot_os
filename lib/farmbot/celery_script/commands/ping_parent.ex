defmodule Farmbot.CeleryScript.Command.PingParent do
  @moduledoc """
    PingParent
  """

  alias Farmbot.CeleryScript.Command
  require Logger

  @behaviour Command

  @doc ~s"""
  """
  @spec run(%{context: map}, []) :: no_return
  def run(%{context: context}, []) do
    parent = context[:parent]
    if parent do
      :pong = Farmbot.SequenceRunner.call(parent, :ping)
      Logger.debug "SUCCESS!!!!!"
    else
      Logger.warn "THIS SEQUENCE HAS NO PARENT: #{inspect self()}"
    end
  end

end
