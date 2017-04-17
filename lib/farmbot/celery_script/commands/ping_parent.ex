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
      IO.puts "Established communication with parent sequence: #{inspect parent}"
      Logger.debug "SUCCESS!!!!!"
      :ok
    else
      IO.puts "This sequence has no parent. }"
      :ok
    end
  end

end
